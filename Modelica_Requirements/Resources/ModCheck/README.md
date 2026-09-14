# ModCheck baselines for Modelica_Requirements

Regression baselines for the library's `Examples`, established with
[ModCheck](https://github.com/MBILLC/ModCheck) on 2026-09-13 by two Modelica
tools. Both case lists were generated from the models' own `experiment()`
annotations (`generate_cases_from_experiment.py`, `--variables '*.y'`: every
block output, which for this library is the requirement `Property` signals);
the two baselines share `ReferenceResults/` under different case-name prefixes.

| file | tool | cases | stored | not stored |
|---|---|---|---|---|
| `regression_cases_modelica_requirements.yaml` | Dymola 2026x, Cvode | 68 | 60 | 8 refused by the Dymola license ("too complex for the current license"), reported SKIPPED |
| `regression_cases_modelica_requirements_openmodelica.yaml` | OpenModelica 1.27.1, cvode | 68 | 48 | 20 do not build in omc — disabled with omc's words: the `SlidingWindow.push()` buffer record (14), the FFT checks (6). Two more (`CheckMotorWithLosses`, `CheckPumpingSystem`) were unblocked on 2026-09-14, `DEVMI_DIFFERENCES.md` §5 |
| `Impact/regression_cases_modelica_requirements_impact.yaml` | Modelon Impact (Sept. 2026), cvode | 68 | — | runs against the composite reference in `Impact/ReferenceResults/`: Dymola's 60 references plus OpenModelica's for the three cases Dymola's license refuses and omc builds (`LimitedCabinAltitudeRateOfChange`, `CheckMotorWithLosses`, `CheckPumpingSystem`); 5 cases have no reference from either tool and are reported SKIPPED |
| `Impact/ImpactOnly/regression_cases_modelica_requirements_impact_only.yaml` | Modelon Impact (Sept. 2026), cvode | 5 | 5 | the five cases above with no Dymola or OpenModelica reference (`MainPowerSupplyRequirements`, four FFT examples), checked against Impact's own stored result in `Impact/ImpactOnly/ReferenceResults/`: 63/63 at the 100× spread |

Both suites pass at ModCheck's 100× rtol spread. One case is hand-tuned in
each list — `SimplePumpingSystem.Components.PumpingSystem`, an on-off pressure
controller over 2000 s whose switching instants move with tolerance; its relay
signals are checked by accumulated |difference| at a measured tolerance.

## Modelon Impact

The fork's library (upstream's sliding-window refactor, `uses Modelica 4.1.0`)
imports into an Impact workspace as a project and its sliding-window examples
run there with results matching the Dymola baseline — see
`DEVMI_DIFFERENCES.md` §2 for the measurement. Impact evaluates `terminal()`
to `false`, so a requirement model there needs
`printViolations(useEvaluationTime=true)` to print its verdict; every example
carries `evaluationTime = StopTime` for that purpose. The FFT checks needed
four separate fixes to run there (`DEVMI_DIFFERENCES.md` §3a) and now do; the
examples that stop through `FallingEdgeTerminate` need `terminate1.delay > 0`
for Impact to record their final verdict, which the Impact case list sets as a
modifier on the two examples concerned.

**Full run, 2026-09-14** (`Impact/`, against the composite Dymola + OpenModelica
reference): **296/296 checks pass** on the 63 cases with a reference — every
funnel error exactly 0, 205 of 208 final values identical and the other three
within 5e-9, `PumpingSystem`'s relay signals within their integral tolerance.
Impact simulates all 68 examples. Two of them, `CheckMotorWithLosses` and
`CheckPumpingSystem`, did not compile in Impact (nor build in OpenModelica)
until the library stopped passing model instances to functions the same day;
their references are OpenModelica's, and `DEVMI_DIFFERENCES.md` §5 has the
tool-by-form measurement behind the fix — the Modelica-legal record cast
`R(m)` is implemented by Dymola alone. The 5 examples with no reference
(`MainPowerSupplyRequirements` and the four FFT examples above Dymola's
license cap) have their own list, `Impact/ImpactOnly/`, with Impact as its own
baseline: 63/63 checks at the 100× spread, so a change in the library or in
Impact that moves them is caught even without a second tool. The library
changes this took are listed in the library's own release notes,
`UsersGuide.ReleaseNotes.Version_0_7_1`.

## OpenModelica vs Dymola

`cross_engine_openmodelica_vs_dymola.txt` is the comparison of the **45 cases
both tools run**, every variable on the `ncp` grid, produced by

    python3 cross_engine.py --config regression_cases_modelica_requirements_openmodelica.yaml \
        --sources default,dymola

What it says:

* Every continuous signal agrees to better than **1e-4 of its range**
  (worst: `SignalAnalysis.MovingAverage` at 9.4e-5; most at 1e-13 or exactly 0).
* Every discrete signal — the Boolean conditions and checks, the `Property`
  outputs — has **identical switch instants** in both tools. The grid points
  that differ (1 to 27 per case) are exactly those instants, where the two
  tools sample opposite sides of the event; the `points_off` column counts
  them, and a switch that lands on a round time in a 0.01-step grid is why
  the `…Rising` examples show more of them than the others.
* `Components.PumpingSystem` differs at 91 of 5001 grid points: the relay
  controller's switching, tolerance-sensitive within one tool and between
  two, as its hand-tuned cases record.

No verdict is issued by that comparison — there is no reference, only two
runs — but nothing in it points at a disagreement about the models.

Rendered reports (`HtmlReports*/`) are gitignored. To read the two tools'
reports side by side, render both with `--aligned-batches`: pages are then cut
by each case's slot in the list, so the same model sits on the same page at
the same position in both, with a DISABLED or SKIPPED card where one tool
could not run it:

    python3 regression_testing.py --config regression_cases_modelica_requirements.yaml \
        --aligned-batches --html-report-dir HtmlReports
    python3 regression_testing.py --config regression_cases_modelica_requirements_openmodelica.yaml \
        --aligned-batches --html-report-dir HtmlReports_OpenModelica
    python3 regression_testing.py --config Impact/regression_cases_modelica_requirements_impact.yaml \
        --aligned-batches --html-report-dir Impact/HtmlReports
    python3 regression_testing.py --config Impact/ImpactOnly/regression_cases_modelica_requirements_impact_only.yaml         --html-report-dir Impact/ImpactOnly/HtmlReports

## Branches

`modcheck-baseline` (this branch) carries the library plus this folder.
`upstream-pr` is the same library without `Resources/ModCheck/` — only
Modelica code and Modelica documentation, on top of `upstream/master`, for
a pull request upstream. Library changes are committed on `upstream-pr` and
merged into `modcheck-baseline`; the two differ only by this folder.
