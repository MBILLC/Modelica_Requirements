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
| `regression_cases_modelica_requirements_openmodelica.yaml` | OpenModelica 1.27.1, cvode | 68 | 46 | 22 do not build in omc — disabled with omc's words: the `SlidingWindow.push()` buffer record (14), the FFT checks (6), model instances as function arguments (2) |

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
for Impact to record their final verdict.

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

    python3 regression_testing.py --config regression_cases_modelica_requirements.yaml \n        --aligned-batches --html-report-dir HtmlReports
    python3 regression_testing.py --config regression_cases_modelica_requirements_openmodelica.yaml \n        --aligned-batches --html-report-dir HtmlReports_OpenModelica
