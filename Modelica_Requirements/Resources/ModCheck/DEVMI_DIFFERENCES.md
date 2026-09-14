# The `DevMI` branch versus upstream — what differs, and what to keep

`hubertus65/Modelica_Requirements`, branch `DevMI` (last commit 2025-06-23,
"Latest status for debugging moving window code"), is an attempt to make the
library run on Modelon Impact. It forked from `a427b5c` (2018, MSL 3.2) and
never merged upstream's later work; upstream `modelica-3rdparty/master` (last
commit 2025-02-14, version 0.7.0) meanwhile solved some of the same problems
differently. This compares DevMI against **today's upstream**, with the
package rename normalised, so the diff shows only what one side did that the
other did not. Written 2026-09-14, after the ModCheck baselines of both tools
beside this file exposed the same issues from the outside.

## 1. What DevMI is

| aspect | upstream `master` (0.7.0) | `DevMI` |
|---|---|---|
| package name | `Modelica_Requirements` | **`Requirements`** — every `.mo`, every `modelica://` link, the images path, a `ConvertFromModelica_Requirements_0.6.mos` conversion script, `conversion(from(version="0.6", …))` in `package.mo` |
| MSL | 4.0.0 (converted with Dymola, 0.7.0) | 4.0 ("Automated update to Modelica 4.0 without any other changes") — the same conversion, done independently |
| license | BSD 3-Clause (0.6.1) | still Modelica License 2 in `package.mo` (forked before the change) |
| release notes | 0.6.1, 0.7.0 classes present | absent; `versionDate` still 2016 |
| tool artefacts | none | `.impact/` workspace metadata, 104 Impact `experiment_1.json` + `Metadata.json` definitions (one per example), 6 Impact Views (`impact-analysis-dashboard-view-*.json`), and two Dymola build leftovers (`Requirements/dslog.txt`, `dsmodel.c`) that should not be in a repository |
| `.mo` files | 30 | 30 — no class added or removed |

Real (non-rename, non-whitespace) `.mo` differences against upstream, by
size: `ChecksInSlidingWindow.mo` 251 lines, `Internal.mo` 42,
`ChecksInFixedWindow_withFFT.mo` 41, `package.mo` 37,
`Examples/SimplePumpingSystem.mo` 36, `Examples/BackupPowerSupply.mo` 36,
`LogicalFunctions.mo` 32, `Examples/Elementary.mo` 23,
`Examples/AirCircuitSystem.mo` 14, `ChecksInFixedWindow.mo` 12, `Verify.mo`
10, `Interfaces.mo` 10, two more with 2 each. Everything else is identical.

## 2. The same problem, solved twice: `pre(buffer)` on the sliding-window record

Both sides hit the sliding-window checks (`ChecksInSlidingWindow.*`,
`Examples.BackupPowerSupply`, `Examples.AircraftRequirements.LimitedControlFrequency`):
the original `buffer = SlidingWindow.push(pre(buffer), time, check)` applies
`pre()` to a record, which the specification does not allow and which Dymola,
OpenModelica and OPTIMICA all refused (upstream issue #3).

* **Upstream** (`addb5a0`, `38f3dfd`): builds a fresh record inline from the
  `pre()` of each field — `SlidingWindow.push(Buffer(T=pre(buffer.T),
  t0=pre(buffer.t0), …), time, check)` — a pure expression, one equation.
* **DevMI** (`f5ef0eb`, `09a7aa2`, `55bbdc1`): declares a second record
  `buffer_temp`, assigns each `pre(buffer.x)` field to it in the `when`, then
  `buffer = SlidingWindow.push(buffer_temp, …)`; initialises `buffer_temp`
  through `push(init(window, time), …)`; and, still debugging, fills
  `Internal.SlidingWindow.push()` with `Modelica.Utilities.Streams.print`
  calls, marks `init` `impure`, comments out `newBuffer := buffer` ("THIS
  STATEMENT does not seem to work in MI!") in favour of field-by-field copies,
  and gives the `Buffer` arrays `start` values. Its own note on
  `Examples.Elementary.ChecksInSlidingWindow.MaxDuration`: *"gives wrong
  results in MI … even the buffer values are different from Dymola, and don't
  make sense. No workaround found yet."*

**Measured with ModCheck (2026-09-13), on upstream's version:** Dymola 2026x
runs every sliding-window example; OpenModelica 1.27.1 refuses all of them at
code generation — *"No runtime support for this record assignment:
`<block>.buffer = SlidingWindow.push(…)`"* — so upstream's refactor fixed
Dymola and not omc. DevMI's variant was not tried in omc; its `buffer_temp`
assignment is the same record-from-function pattern and is unlikely to fare
better.

**Measured in Modelon Impact (2026-09-14), on this fork — upstream's refactor
plus MSL 4.1.0:** every sliding-window example compiles and runs, and the
results match the Dymola baseline. All 14 were run (`impact_compare.py`,
client API) and compared on the `ncp` grid: 13 have a Dymola baseline
(`BackupPowerSupply` is over Dymola's license cap) and all 13 have identical
switch instants for every `*.y`, with at most one grid point different, at an
event instant. What is left is not a buffer error: `MaxIncrease` and
`MaxPercentageIncrease` cross their thresholds 3–20 ms apart (event location
on a continuous signal), and `MaxRisingFrequency` in Impact carries zero-
duration `0→1→0` samples at each new rising edge inside the violated window
— Impact stores the event iteration's intermediate value, Dymola does not; the
value held between events is the same. So the "erroneous results" DevMI was
debugging belong to its own `buffer_temp` variant, not to the library.
**Keep upstream's form.**

## 3. `terminal()` — the Impact-specific change worth keeping as an option

Impact did not support `terminal()` (DevMI's README: *"most things seem to
work in Modelon Impact, except for everything that uses `terminal()`, e.g.
the requirements needing FFTs"*). DevMI replaces it in two places:

* `Verify.BooleanRequirement` and `Interfaces.PartialRequirements`: a new
  `parameter Modelica.Units.SI.Time evaluationTime = 1` and
  `when time >= evaluationTime` instead of `when terminal()`; the
  `DynamicSelect` icon text shows `evaluationTime` instead of `time`.
* `ChecksInFixedWindow_withFFT`: `terminal() and time <= nextTime` instead of
  `< nextTime` (the FFT checks are the ones DevMI still could not run).

This changes semantics — the requirement's final verdict is taken at a fixed
instant instead of at the end of the simulation, and `evaluationTime = 1`
silently misreports any experiment that stops later — so it cannot go
upstream as is. **Ported to this fork as an opt-in (2026-09-14):**
`PrintViolations` (and `PartialVerify`) gained `useEvaluationTime = false`
and `evaluationTime`; `PartialRequirements` reads both from the `inner`
instance rather than carrying its own; every example sets
`evaluationTime` to its own `StopTime` (`CheckAirCircuitSystem` has no
`experiment()` and keeps the default). Default off, so Dymola and OpenModelica
keep `terminal()` and their ModCheck baselines still pass. Measured in Impact
on `Verify.Requirement`: with the default the run succeeds and prints **no
verdict** — Impact reports *"The terminal() operator is not supported, and is
currently evaluated to false"*; with `printViolations.useEvaluationTime=true`
the full report appears at 5 s (50 % satisfied, 1 violated, 1 untested).

### 3a. The FFT checks in Impact — four separate problems, all fixed on this fork

DevMI's README says the FFT-based requirements never worked in Impact. Taking
them apart (2026-09-14) found four independent causes, three of them in
Impact and one in the library:

1. **`checkDomain`'s local arrays `diff[:]`, `f[:]`** — Impact refuses an
   undefined size ("Using variables with undefined size is not supported").
   DevMI's `2436e15` had the right idea but not a valid fix (`diff[size(A,1)]`
   then assigned a shorter vector; `f[iMax - iMin + 1]` sized by variables
   assigned later in the algorithm). Here: both sized `size(A,1)` from the
   input, the checked band is the slice `1:n`, and the division is guarded
   against an all-zero limit curve. Bit-identical in Dymola.
2. **The sampling chain never started.** `PartialFFT` seeds `iTick = 1` through
   `startFFT = condition and not pre(condition)` with `pre(condition) = false`
   in an initial equation; Impact initialises `pre(condition)` to `condition`
   instead, so the edge never happens, `iTick` starts at 0 and the block is dead
   for the whole run (`FFT_computation` false from t = 0, measured). Fix:
   `startFFT = (condition and not pre(condition)) or (initial() and condition)`
   — identical results in Dymola and OpenModelica.
3. **`terminate()` drops the edge's own values.** The examples end with
   `FallingEdgeTerminate` once the FFT is done; Impact's result then holds the
   pre-event state of that instant (verdict still Undecided), Dymola the post-
   event one. Deferring `terminate()` to the next event iteration does not help;
   a finite delay does. `FallingEdgeTerminate` gained `delay = 0` (upstream
   behaviour); with `terminate1.delay = 0.01` Impact records the verdict and
   ends 10 ms later. Dymola treats that parameter as evaluated and refuses to
   set it at run time ("Setting terminate1.delay has no effect") — ModCheck's
   Dymola source now re-translates on that message.
4. **Stale values inside a `when`.** `WithinRelativeDomain` scaled its limit
   curve by the base amplitude and checked against it in one `when`; Impact
   evaluated the check with the *pre-event* curve (zero before the first FFT)
   and reported Violated while `scaledDistance` from the very same call was
   positive. An eleven-line model reproduces it: of a two-output function
   called in a `when` whose matrix input is assigned in that `when`, the Real
   output comes back right and the Integer output wrong; OpenModelica gets
   both right. Splitting into several `when`-clauses fixes the value but makes
   Impact build a nonlinear block around them that fails initialisation in a
   fraction of the runs. What works everywhere: **one `when`, one function
   call for the whole chain** — `Internal.checkRelativeDomain` and
   `Internal.checkTHD`, inputs only from other `when`-clauses and parameters.
   Bit-identical in Dymola; the THD verdicts in Impact now follow the THD
   values they are computed from.

With all four, every FFT example runs in Impact; the two with a Dymola
baseline (`WithinAbsoluteDomain1`, `WithinRelativeDomain1`) switch to
Satisfied at exactly Dymola's instant, 4.975 s, given `terminate1.delay`.
Also observed: bursts of non-deterministic initialisation failures in Impact
("Failed to update the events at time 0", `IllegalResidualOutput` in block
1.1) hitting 0 to 9 of 16 identical runs, across every model form and even
the examples that had never failed, then gone — server-side, not the
library's, and worth a report to Modelon if it recurs. OpenModelica still
cannot build any FFT check (`lowerWhenEqn: equation not handled`).

## 4. Impact-specific workarounds that should not survive a merge

* `LogicalFunctions.card / cardSatisfied / cardUndecided / cardViolated`:
  `sum(if e then 1 else 0 for e in b)` rewritten as a `for` loop over an
  `output Integer result(start=0)`, `Inline=false`. A `start` attribute on a
  function output is not how a function result is initialised, and the array
  reduction is standard Modelica — this works around a compiler, not the
  language. The compiler problem is real, though: Impact still fails
  *"Exception caught while scalarizing function
  'Modelica_Requirements.LogicalFunctions.cardSatisfied'"* on the
  element-iterator form, which took `AircraftRequirements.
  MinimumOperationalServiceLife` down with it (2026-09-14). Measured with a
  three-function test package: the reduction over **indices**,
  `sum(if p[i] == Property.Satisfied then 1 else 0 for i in 1:size(p, 1))`,
  compiles and gives the right count, as does DevMI's loop. This fork uses
  the index form in all four functions — one token of change, `Inline=true`
  kept, no `start` on an output; Dymola and OpenModelica results for the
  five cases that reach these functions are unchanged (39/39 checks each).
* Documentation links `modelica://Requirements.X` shortened to `Requirements.X`
  in `LogicalFunctions`, `ChecksInFixedWindow*`, `Verify`, `Elementary` —
  breaks the `modelica://` URI scheme every other tool resolves.
* `ChecksInFixedWindow`: `type Color = Integer[3](min=0, max=255)` without
  `each` (a spec violation the other way), `textColor` → `lineColor` in
  several annotations (the pre-3.4 attribute name; upstream is correct).
* `Examples.SimplePumpingSystem`: `import NonSI = Modelica.Units.NonSI` turned
  into a plain `import Modelica.Units.NonSI`, and every `Requirements.X`
  reference made global (`.Requirements.X`) — Impact's re-serialisation, not a
  fix.
* `Examples.Elementary`: `time < 5` → `time <= 5` in the frequency-schedule
  expressions and `time >= 1` → `time > 1` in `expr3` — event-timing nudges
  whose effect on the examples' documented results was not checked.
* Icon graphics: a red `Ellipse` added to several block icons (a debugging
  marker?), `visible=port_b_exposesState` on `AirCircuitSystem` graphics.

## 5. Two findings DevMI recorded that ModCheck confirmed

* **"passing classes instead of records"** — `Examples.MotorsWithLosses`
  (`watchDCMotor(obj=DCPM_withLosses.dcpm1)`) and
  `Examples.SimplePumpingSystem.CheckPumpingSystem`
  (`SourceObservation_from_PartialSource(partialSource=source)`) hand a model
  instance to a function. DevMI's comment: *"Same (stupid) issue as with pump
  system: passing classes instead of records. doh!"* OpenModelica 1.27.1
  refuses both with a type mismatch; Dymola accepts them (and then refuses
  both under its license cap, so neither tool actually ran them here), and
  Modelon Impact does not compile them either. Legality (checked 2026-09-14):
  the Modelica Language Specification 3.6, section 12.6.1 -- unchanged in the
  3.7/3.8 drafts -- allows a model instance as a record argument only through
  an **explicit** record constructor call, `R(m)`, which copies the public
  components whose names match; the implicit form the library uses is a
  Dymola extension. Making the two examples legal means wrapping the
  arguments (`watchDCMotor(obj=MotorData(dcpm1))` and the like) and moving
  the record types (`MotorData`, `InertiaData`) out of the functions'
  protected sections so the models can name them. Left as is on this branch.
* **The FFT checks** are the hardest corner for every tool: Impact (per
  DevMI's README), OpenModelica (*"lowerWhenEqn: equation not handled"*), and
  Dymola's license for four of the six examples.

## 6. Recommendation

Do not merge `DevMI` as a branch. Rebase the two things worth keeping onto
upstream `master`:

1. an **opt-in `evaluationTime`** for tools without `terminal()` (§3), default
   off — done on this fork's `modcheck-baseline` branch;
2. the Impact **experiment definitions and Views** (the `.json` files) — if a
   Modelon Impact workspace for the library is wanted — under
   `Resources/Impact/` rather than beside the models, and without `.impact/`.

Everything in §4 is a workaround for a 2025 Impact that a maintained library
should not carry, and §2 is already solved upstream in a cleaner form. The
`ModCheck/` folder beside this file gives the regression baselines to check
any such rebase against, on two independent compilers.

## Method

```
git fetch hubertus65
git diff --stat a427b5c hubertus65/DevMI            # the raw picture: 332 files
# rename-normalised, per-file, whitespace-insensitive:
git show upstream/master:Modelica_Requirements/X.mo | sed 's/Modelica_Requirements/Requirements/g' > up/X.mo
git show hubertus65/DevMI:Requirements/X.mo > dev/X.mo
diff -wB --unified=0 up/X.mo dev/X.mo
```
