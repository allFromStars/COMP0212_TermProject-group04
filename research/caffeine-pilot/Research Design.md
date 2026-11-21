# Caffeine timing: a feasible group research design

Prepared 19 November 2026. Recommendation: continue as a small pharmacokinetic simulation study with empirical checks. The current evidence supports an exploratory design, not validated predictions of individual responses.

## 1. Question, cases, and outcomes

**At the same total caffeine intake, how does moving caffeine from the morning to later in the day change the peak and the amount remaining at 22:00, and how sensitive is that trade-off to clearance differences?**

The reference setting is a caffeine-free starting morning, with illustrative inputs expressed in measured caffeine mass. A 100 mg serving is a modelling input, not a claim that all cups contain 100 mg. Calibration comes from healthy young men; extrapolation to other groups is not established.

- **Case 1: concentration versus spacing.** Compare 200 mg at 08:00 against 100 mg at 08:00 plus 100 mg at 14:00. Both supply 200 mg. Compare the maximum plasma concentration between 08:00 and 22:00, concentration at 22:00, and residual concentration at 08:00 the next morning before any further intake.
- **Case 2: timing the second serving.** Compare 100 mg at 08:00 plus 100 mg at 12:00 against 100 mg at 08:00 plus 100 mg at 16:00. This isolates the timing of the second serving while holding both dose sizes fixed.

The answer is the paired change in these outcomes, its range under plausible clearance variation, and its dependence on model choice. The sign of some timing effects follows directly from exponential decay; the research contribution is quantifying the effect and establishing whether the approximation is supported. Do not present an inevitable sign as a newly discovered biological result. Evening concentration is a pharmacokinetic outcome; it does not establish sleep impairment or alertness.

## 2. Baseline and candidate

Use hours since 08:00, caffeine mass in mg, and concentration in mg/L. Numerically, 1 microgram/mL equals 1 mg/L.

Define X=A/F, where A is systemic caffeine mass and F is a constant oral bioavailability. X is systemic mass expressed in oral-dose equivalents. Let V_e=V/F. This parameterization avoids trying to estimate F and V independently from oral concentration data.

### Baseline: instantaneous absorption

Between administrations:

\[
\dot X=-k_eX,\qquad C_p=X/V_e.
\]

At administration time t_j:

\[
X(t_j^+)=X(t_j^-)+D_j.
\]

For a finite drinking duration, replace the jump with \(\dot X=u(t)-k_eX\), where u is ingested caffeine mass per hour. This baseline assumes that ingestion immediately supplies the central state. It is useful for late decay but cannot describe a delayed oral peak.

### Candidate: absorption depot plus central compartment

\[
\dot G=u(t)-k_aG,\qquad
\dot X=k_aG-k_eX,\qquad
C_p=X/V_e.
\]

For a short drink represented as a bolus, use u=0 between administrations and \(G(t_j^+)=G(t_j^-)+D_j\). G is caffeine awaiting absorption; X is the central oral-equivalent amount. Both have units mg. The rates k_a and k_e have units h^-1, V_e has units L, and u has units mg/h. Apparent clearance is the derived quantity CL/F=k_e V_e, in L/h.

For a caffeine-free starting day, G(0^-)=X(0^-)=0. The first administration is then added to G. For a withdrawal record starting after prior intake, X(0) must reflect the observed residual; it cannot be set to zero. Late after absorption, G approximately equals zero. A measured predose concentration C_0 would give X(0)=V_e C_0.

For one oral dose with zero initial state:

\[
C_p(t)=\frac{D}{V_e}\frac{k_a}{k_a-k_e}
\left(e^{-k_et}-e^{-k_at}\right).
\]

Repeated-input responses add because the ODE is linear for fixed parameters. When k_a=k_e, the continuous limit is \(Dk_at e^{-k_at}/V_e\).

The candidate adds a physically motivated delay and a second meaningful state. It does not add organs or metabolites that the intended data cannot identify. Seng et al. provide an original population-model precedent for a central compartment with first-order absorption and elimination [3].

Important assumptions are constant clearance within the simulated day, approximately dose-proportional kinetics over the chosen input range, a constant observation scale, and an initially caffeine-free system. Meals, formulation changes, adaptation during prolonged intake, smoking, and other physiological differences can violate those assumptions. The short intake in the calibration experiment is represented as a bolus; a 20-minute drink should instead use a finite input. White et al. supply an original experiment on this distinction [2].

Oral curves do not independently identify F and V. There is also an absorption/elimination exchange ambiguity without external constraints. The pilot selects k_a>k_e, consistent with rapid absorption and slower terminal elimination in the cited studies. Nine successful starting values under that constraint are an optimizer check, not proof of general identifiability. A model fitted to a group mean has effective parameters; they need not equal the mean of the participants' parameters.

## 3. Data audit and model-to-data mapping

The original oral arm in Teekachunhatean et al. is the main calibration source, despite the article's broader comparison with an enema arm. Only the oral arm is used. The article is available as full-text XML and its original Figure 2 image was downloaded and inspected [1].

The original `Data_Sheet_1.docx` supplement to Lin et al. was inspected during source preparation. Table S1 contains numeric group means and SDs, not individual trajectories. The accompanying original article PDF was inspected, including Figures 1 and 2. The paper reports one noncompliant caffeine condition excluded; Table S1 does not supply per-cell sample sizes. Its exact internal sample times are missing from the table [4]. Original article packages are not bundled in this repository; the extracted CSVs and provenance are included, with optional retrieval instructions in the README.

| Required quantity | Original dataset and exact source field | Local field, units, sampling | Use and status |
|---|---|---|---|
| C_p(t), observed output | [1], Figure 2, CC open triangles | `teekachunhatean2013_cc_digitized.csv`: `time_h`, `mean_mg_L`, `pixel_y`, `extraction_envelope_mg_L`, `split`; mg/L | Ten approximate group-mean points. Times are 10, 20, 30, 40, 60, 90, 120, 240, 480, 720 min. Manual y readings use 69 pixels per mg/L and a +/-3 pixel envelope. Fit six and reserve four. Not individual records. |
| Predose C_0 | [1], Methods 2.6; predose sample is part of protocol | No numerical individual predose field supplied; assay LLOQ 0.1 mg/L in Methods 2.8 | Long abstention makes zero a useful starting assumption. Test C_0 between 0 and 0.1 mg/L; no claim that individual zero values were verified. |
| D_j and short input duration | [1], Results paragraph 1; Methods 2.4 | `teekachunhatean2013_protocol.csv`: `dose_mg=96.34`, `dose_sd_mg=1.39`, `assayed_servings=6`, `consumption_max_minutes=1` | Dose sets the input. SD describes six assayed servings, not participant-to-participant intake or biological variability. |
| G, absorption state | No direct gut measurements in these studies | No observation field; mg, continuously simulated | Latent state reconstructed under the assumed absorption law. G(0^+)=D for an isolated bolus. Cannot validate gut amount independently. |
| X, central state | Plasma concentrations in [1]; no direct whole-body mass measurement | Derived as V_e C_p; mg dose equivalents | Model state, not an independently measured body burden. |
| k_a | [1] rising concentration points; [2] Table 1 `MAT (min)` provides a different-study plausibility check | `curve_parameters.csv: ka_per_h`; h^-1 | Estimate jointly with k_e and V_e under k_a>k_e. Do not equate published mean Tmax to 1/k_a. MAT from a finite input also includes input timing. |
| k_e and clearance variability | [1], Table 1, oral column, `t_1/2 (h)` = 4.87 +/-1.39 | `teekachunhatean2013_oral_summary.csv`: `metric=half_life`, `mean`, `sd`; h; one participant-summary row | Fit effective k_e to the concentration curve. The participant half-life summary separately anchors an assumed variability scenario, k_e=ln(2)/H. No raw distribution is supplied. |
| V_e=V/F | [1], known dose plus plasma curve | `curve_parameters.csv: apparent_volume_L`; L | Estimate concentration scale. Actual V and F remain inseparable. [5] supports near-complete oral bioavailability as context, not an independently estimated F here. |
| Independent late-decay diagnostic | [4], Table S1, `acute caffeine deprivation` / `CA` / `Sample 1` and `Sample 11`; Figure 1 withdrawal endpoints | `lin2022_saliva_summary.csv`: `condition`, `analyte`, `sample_id`, `mean_mg_L`, `sd_mg_L`; endpoints 24 and 43 h after last dose | Compare a dimensionless endpoint ratio. Saliva is not plasma; assume stable proportionality only for this diagnostic. Endpoint means are 0.46 and 0.05 mg/L. Internal `time_h` entries are deliberately blank; nominal intervals are 105-120 min. |
| Repeated-intake supporting observations | [4], Table S1, `caffeine` / `CA`, Samples 1-11; Figure 1 input protocol | Same CSV; 150 mg at 0.75, 4, 8 h after waking, on repeated days | Available for a later condition-level check after exact timestamps and input history are reconciled. Do not treat the juxtaposed 43-h figure as one uninterrupted participant record. |
| Exposure and peak checks | [1], Table 1, oral column: `Cmax`, `Tmax`, `AUC0-12`, `AUC0-infinity` | Summary CSV `metric`, `mean`, `sd`, `n`; mg/L, h, mg h/L | Same-study consistency checks. Mean participant Cmax is not necessarily the peak of the plotted mean curve. These summaries are correlated with the trajectory, not independent validation. |

The numerical saliva file has 66 rows: 11 samples x 3 conditions x 2 analytes. Paraxanthine observations are retained for provenance but are not used to add a third biological state.

The previously found FAIRDOM/PK-DB records remain discovery leads rather than accepted raw data. The testing record inspected for Blanchard1983a explicitly listed no reuse license and had unreliable example metadata. The design does not depend on resolving it [7].

**Revised claim:** assess group-mean concentration dynamics and model-based equal-dose timing scenarios. Individual risk probabilities, sleep effects, and a unique physiological parameter distribution cannot be tested with these aggregate data. More digitization cannot recover missing individual records.

## 4. Simulation, fitting, evaluation, and uncertainty

### Fit and comparison

1. Fix the split before optimization: calibration at 10, 30, 60, 120, 240, 720 min; holdout at 20, 40, 90, 480 min. This split was fixed before fitting in the pilot, but was not prospectively registered or blinded.
2. Fit both models on the same six group-mean points with least-squares concentration error using `fminsearch`. The baseline estimates k_e and V_e; the candidate also estimates k_a. Optimize transformed positive parameters, impose k_a>k_e, and inspect multiple starting values and broad parameter bounds. The pilot bounds are k_e in [0.02,1] h^-1, V_e in [5,150] L, and k_a<100 h^-1; these are numerical guardrails, not empirical population ranges.
3. Evaluate held-out RMSE without refitting. Inspect early and late residuals separately: a single RMSE can reward the peak while missing late clearance. Repeat fitting with a predeclared late-tail/log-error sensitivity analysis in the final report, without selecting its winner on repeatedly reused holdout points.
4. Use original Table 1 exposure summaries as consistency checks, with their dependence acknowledged. The pilot also includes a deliberately separate exercise matching mean peak, mean peak time, and mean half-life; it overpredicts unused AUC summaries by about 13-16%. Those parameters are not used for the main fitted-curve schedule predictions.
5. Treat the Lin withdrawal endpoint as a separate-study stress test, not a clean replication. It differs in habitual intake, dosing history, observation matrix, and cohort. Obtain exact individual timestamps and histories before claiming a full external trajectory validation. White et al. offer a second plasma study, but its mixed cohort and formulation/input conditions also require reconciliation before direct numerical pooling.

### Meaningful randomness

The primary random quantity is the **between-person elimination half-life H**. Draw it once for a virtual person and hold it constant throughout that person's day and across both compared schedules. This represents biological clearance variation, not random noise injected into the bloodstream at every solver step.

For an initial exploration, assume a lognormal distribution with arithmetic mean 4.87 h and SD 1.39 h, matching the participant summaries in [1]:

\[
\sigma^2=\log\{1+(1.39/4.87)^2\},\quad
\mu=\log(4.87)-\sigma^2/2,\quad
H=\exp(\mu+\sigma Z),\ Z\sim N(0,1).
\]

This is a positive distribution selected to match two moments; the study does not establish lognormality or a general population distribution. The pilot uses 5,000 paired draws, seed 212, holding V_e and k_a fixed. It consequently omits their variability and correlations. Seng et al. independently support the relevance of interindividual variability [3], but their abstract does not provide a joint parameter covariance suitable for importing a full multivariate distribution.

Repeated runs describe conditional ranges of paired differences in C_22. Report medians and 2.5th/97.5th scenario percentiles, explicitly separated from confidence intervals for a population mean. Do not interpret the fraction of virtual runs as an empirically validated probability for students or patients. Check an alternative bounded range or distribution to show dependence on the assumed variability law.

Keep three other uncertainties separate:

- Digitization: repeat extraction independently; the pilot perturbs calibration means uniformly within +/-3 pixels for 100 refits, seed 213. Uniformity is a sensitivity device, not an inferred measurement-error law. Holdout points also need independent re-reading.
- Parameter estimation: profile k_a and k_e and inspect near-optimal parameter combinations. Similar multistart answers under one constraint do not prove physiological identification. Do not bootstrap ten dependent means as if they were ten independent participants.
- Model discrepancy: compare the baseline and candidate and inspect persistent tail errors. Do not remove a failed external check by adding unidentifiable compartments.

### Sensitivity with a purpose

Vary half-life over 2, 4.87, and 8 h as an exploratory range, then vary k_a over 1, 3, and 10 h^-1 while holding the fitted elimination rate and volume fixed. These grids are scenarios, not observed quantiles.

For the split 08:00/14:00 schedule, the pilot's C_22 ranges from about 0.19 to 2.04 mg/L over the half-life grid. Over the absorption grid it ranges from about 1.09 to 0.92 mg/L. Within these specified ranges, evening residuals are much more sensitive to clearance than to absorption. Absorption remains relevant to early peaks; a dose immediately before the observation time would change that comparison. This helps decide whether the baseline is adequate for a particular output rather than declaring one model universally superior.

## 5. Runnable pilot and actual findings

Open this directory in MATLAB and run `run_caffeine_pilot`. It needs base MATLAB only. Included source-derived CSVs make the run independent of future website availability.

The first plot is `output/first_plot.png`: two fitted curves, six calibration means, four withheld means, and a descriptive RMSE comparison. Extraction bars represent the +/-3-pixel reading envelope, not participant SDs or confidence intervals.

Verified in MATLAB R2025b:

- Candidate fitted effective parameters: k_a approximately 4.43 h^-1, k_e approximately 0.166 h^-1, V_e approximately 39.9 L; effective half-life about 4.17 h. All nine candidate starts converged to the same constrained solution in this exercise.
- Calibration RMSE: baseline 0.389, candidate 0.108 mg/L. Withheld-point RMSE: baseline 0.276, candidate 0.181 mg/L. This is descriptive evidence for an absorption delay in this group mean, not participant-level validation or a significance test.
- Known single-dose, repeated-dose, nonzero-initial-state, nonnegativity, mass-balance, and solver-precision checks passed. Analytic/ODE discrepancies were small; tightening tolerances changed the summary-anchor AUC by about 3e-11 relative. A separate check also verifies the fitted curve numerically.
- The Lin endpoint ratio is 0.05/0.46=0.109 over 19 h. The fitted curve rate predicts 0.043; the published 4.87 h half-life predicts 0.067. The external tail is therefore not reproduced by either point estimate. Ratios of group means, assay background, and cohort/input differences prevent this from identifying a unique biological explanation. The last observed mean is near the lower end of the stated assay calibration range.
- Illustrative candidate predictions in Case 1: all-morning peak 4.41 mg/L and C_22 0.51 mg/L; split-day peak 3.06 and C_22 0.94 mg/L. In Case 2, moving the second serving from noon to 16:00 changes C_22 from 0.75 to 1.22 mg/L. These are simulations under fitted effective parameters, not observations of those schedules.

**Biggest unresolved issue:** whether an effective clearance rate fitted to one aggregate single-dose experiment can support late-residual predictions in repeated consumers. The current external endpoint comparison exposes this issue rather than resolving it.

**Exact next check:** obtain the Lin participant-level caffeine concentrations, sample timestamps, capsule history, assay quantification/background information, and participant/period identifiers. Fit clearance and observation scale using the caffeine condition, then predict the separate withdrawal period without retuning clearance. First resolve the day-9 dosing inconsistency between the article text and Figure 1. A draft data request can be prepared, but none has been sent. If the records remain unavailable, retain the restricted model-based scope and report the external discrepancy; do not claim validated individual probabilities.

For the presentation, show the question, the two-state mass-flow equations, the first plot, the two schedule comparisons, and this external limitation. The pilot is enough to demonstrate feasibility and the need for critical validation.

For the final report:

1. Have a second group member digitize the original CC curve and compare readings; reconcile discrepancies larger than about 0.05 mg/L. Finalize predose and time-origin handling.
2. Freeze a fitting/evaluation protocol, assess early and late residuals, profile identifiable parameters, and keep source/measurement uncertainty separate from between-person scenarios.
3. Complete the two equal-dose case studies and half-life/absorption sensitivities. Compare baseline predictions after fitting it independently to the same calibration data.
4. Attempt the independent withdrawal-period test if records become available. Otherwise retain the observed failure and bounded interpretation.
5. Report equations, assumptions, source provenance, numerical verification, observational evaluation, uncertainty, and conclusions restricted to concentration dynamics.

## Original references and their roles

1. **Teekachunhatean et al. (2013).** *Pharmacokinetics of Caffeine following a Single Administration of Coffee Enema versus Oral Coffee Consumption in Healthy Male Subjects.* DOI [10.1155/2013/147238](https://doi.org/10.1155/2013/147238). [Full text](https://pmc.ncbi.nlm.nih.gov/articles/PMC3603218/). Main original oral experiment: protocol, dose, plasma curve, assay information, and participant-summary PK values. Full XML and original figure inspected; CC BY figure. The oral arm alone is used.
2. **White et al. (2016).** *Pharmacokinetic analysis and comparison of caffeine administered rapidly or slowly in coffee chilled or hot versus chilled energy drink in healthy young adults.* DOI [10.3109/15563650.2016.1146740](https://doi.org/10.3109/15563650.2016.1146740). [Full text](https://pmc.ncbi.nlm.nih.gov/articles/PMC4898153/). Original 160 mg crossover experiment with 2- versus 20-minute administration and early plasma sampling; guides finite-input modelling and offers an external plasma comparison. No pairwise difference between individual arms reached significance. Full XML inspected; downloaded package contained figure images, not participant CSVs. Article license is CC BY-NC-ND; the pilot does not reproduce or modify its figure.
3. **Seng et al. (2009).** *Population pharmacokinetics of caffeine in healthy male adults using mixed-effects models.* DOI [10.1111/j.1365-2710.2008.00976.x](https://doi.org/10.1111/j.1365-2710.2008.00976.x). [Original abstract](https://pubmed.ncbi.nlm.nih.gov/19125908/). Empirical precedent for first-order absorption/elimination, smoking-related clearance, and interindividual variability. Abstract inspected; full model/covariance not obtained, so its joint parameter distribution is not claimed to be reproduced.
4. **Lin et al. (2022).** *Time to Recover From Daily Caffeine Intake.* DOI [10.3389/fnut.2021.787225](https://doi.org/10.3389/fnut.2021.787225). [Article and supplement](https://pmc.ncbi.nlm.nih.gov/articles/PMC8849224/). Original repeated-intake and withdrawal experiment; Table S1 gives numeric salivary means and SDs. Existing original PDF and DOCX inspected. A fresh API supplement download was incomplete; the manifest records this failure. There is a text/Figure 1 dosing-history inconsistency that must be reconciled before full-period simulation.
5. **Blanchard and Sawers (1983).** *The absolute bioavailability of caffeine in man.* DOI [10.1007/BF00613933](https://doi.org/10.1007/BF00613933). [Original abstract](https://pubmed.ncbi.nlm.nih.gov/6832208/). Original oral-versus-IV crossover supports near-complete oral availability and documents substantial elimination variability. Abstract inspected; not used as a verified raw dataset or to set a physical bioavailability above one.
6. **Denaro et al. (1990).** *Dose-dependency of caffeine metabolism with repeated dosing.* DOI [10.1038/clpt.1990.150](https://doi.org/10.1038/clpt.1990.150). [Original abstract](https://pubmed.ncbi.nlm.nih.gov/2401126/). Original repeated-dose study gives a boundary on constant-clearance linear extrapolation. Abstract inspected; its high-dose clearance number is internally inconsistent with the stated direction, so no numerical coefficient is imported. It motivates restricting scope rather than fitting unsupported saturation parameters.
7. **FAIRDOM/PK-DB discovery record.** [Blanchard1983a testing record](https://testing.sysmo-db.org/data_files/508). Documents digitization provenance but also a missing reuse license and example metadata problems. Excluded from the accepted fitting data. It is a discovery record, not an original clinical study or an additional validation experiment.

## Tools and methodological attribution

Literature retrieval used the installed `paper-lookup` skill; appraisal used `scientific-critical-thinking`. Their procedural attribution is: Kassis, T., Agarwal, V., He, Y., Patel, D., and Brueckner, A. M. (2026), *Scientific Agent Skills: A Library of Procedural Knowledge for Research Agents*, [arXiv:2609.00065](https://doi.org/10.48550/arXiv.2609.00065). The current arXiv record was checked. This is a software/methods credit, not caffeine evidence and not counted among the six original subject references.
