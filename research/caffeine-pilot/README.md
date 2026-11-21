# Caffeine research pilot

Read `Research Design.md` for the question, evidence, data mapping, and limits.

In MATLAB, open this folder and run:

```matlab
run_caffeine_pilot
```

The entry point requires base MATLAB only. It reads the included CSV files and writes figures and metrics to `output/`. It does not download data or require a toolbox. It was executed with MATLAB R2025b on 19 November 2026.

Inputs:

- `data/teekachunhatean2013_cc_digitized.csv`: 10 approximately digitized group-mean plasma points, with a fixed 6/4 calibration/holdout split and an extraction envelope. Not individual records.
- `data/teekachunhatean2013_oral_summary.csv`: five published oral-arm summary statistics.
- `data/teekachunhatean2013_protocol.csv`: published dose and protocol information.
- `data/lin2022_saliva_summary.csv`: 66 summary cells extracted from the existing original supplement, covering two analytes and three conditions. Internal timestamps intentionally remain blank.

Provenance:

- `sources/retrieval_manifest.json` records bounded literature retrieval, including failures and partial downloads. This was a targeted search, not a systematic review.
- `data/input_manifest.json` records source-file hashes and extraction limits.
- `data/digitization_manifest.json` records the original figure hash, pixel calibration, license, and approximate manual readings.
- `prepare_inputs.py` extracts the original article table and the Lin supplement from explicitly supplied files or the local `sources/` cache.
- `digitize_curve.py` records the manually inspected marker coordinates. Independent re-digitization is still needed.
- `retrieve_literature.py` retrieves the bounded source set. Re-running it is optional and requires network access.

## Optional input preparation

The input CSVs are already included. These preparation scripts are not required
to run MATLAB. They use Python 3's standard library; retrieval also requires `curl`
and internet access. There is no dependency on Codex or a personal course folder.

From this directory, the source-preparation sequence is:

```bash
python3 retrieve_literature.py
python3 prepare_inputs.py
python3 digitize_curve.py
```

Retrieval can fail or return partial packages. Check `sources/retrieval_manifest.json`
and the downloaded files before proceeding. The expected source files are
`sources/PMC3603218.xml`, `sources/Data_Sheet_1.docx`, and
`sources/ISRN.PHARMACOLOGY2013-147238.002.jpg`. Article and supplement links
are documented in the research design and input manifests. Downloaded source
files are ignored by Git.

If the originals are stored elsewhere, pass their locations explicitly:

```bash
python3 prepare_inputs.py --article /path/to/PMC3603218.xml --supplement /path/to/Data_Sheet_1.docx
python3 digitize_curve.py --figure /path/to/ISRN.PHARMACOLOGY2013-147238.002.jpg
```

`digitize_curve.py` reconstructs the CSV from the recorded manual marker readings;
it does not automatically extract points from an arbitrary image. Use the original
image and independently check those readings before final analysis.

## Outputs

The repository includes the two main plots and selected evaluation, parameter,
numerical-check, schedule, and uncertainty tables as reference results. Running
MATLAB regenerates those files and creates the additional diagnostics listed
below. The remaining generated outputs are ignored by Git.

- `first_plot.png`: fitted baseline/candidate versus calibration and withheld group means.
- `curve_evaluation.csv`, `curve_parameters.csv`, `baseline_parameters.csv`, `curve_multistart.csv`.
- `schedule_comparison.png`, `schedule_metrics.csv`: explicitly hypothetical equal-total-dose schedules.
- `paired_uncertainty.csv`, `scenario_draws.csv`: assumed clearance-variation scenarios, not population risk estimates or confidence intervals.
- `extraction_sensitivity.csv`: bounded calibration-point perturbations, not a statistical confidence interval.
- `numerical_checks.csv`, `curve_numerical_checks.csv`: numerical verification.
- `external_endpoint_check.csv`: a separate-study, saliva-based endpoint diagnostic with important transportability limits.
- `summary_anchor_check.png`, `effective_parameters.csv`, `summary_checks.csv`: a separate summary-matching diagnostic. These parameters differ from the trajectory-fit parameters used for schedule plots; do not mix the two.

No sleep, alertness, efficacy, toxicity, or personalized consumption recommendation is estimated.
