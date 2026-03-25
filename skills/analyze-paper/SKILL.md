---
name: analyze-paper
description: Extracts and analyzes complete methodology from a neuroscience research paper — preprocessing pipeline, analysis parameters, statistics, and software used. Maps every method term (EEGLAB, FieldTrip, SPM, FSL, R) to its exact Python implementation via the method-vocabulary reference. Covers ERP components (N170, P300, N400, MMN, ERN), time-frequency terms, fMRI GLM terms, source localization methods, and statistical tests. Use when the user wants to extract methods, read a paper, understand what analysis was done, or asks about paper methods.
argument-hint: "[paper-path-or-doi]"
---

# Paper Methods Extraction

When the user provides a neuroscience paper (DOI, URL, or PDF), extract the complete methodology and map every step to its Python implementation.

## Reference Documents

| Reference | Purpose |
|-----------|---------|
| `references/method-vocabulary.md` | Maps every neuroscience method term → exact Python function call |

---

## What to Extract

### Data Acquisition
- Modality (EEG, fMRI, MEG, iEEG, PET, NIRS)
- Number of subjects (and exclusions)
- Recording system/scanner
- Sampling rate / TR
- Number of channels / voxel size
- Reference electrode (EEG/MEG)

### Experimental Design
- Task description
- Conditions and their labels
- Number of trials per condition
- Stimulus timing (duration, ISI, SOA)
- Block vs event-related design

### Preprocessing Pipeline (in order)

Extract each step with **exact parameters** and map to Python:

| Step | Paper Description | Python Implementation |
|------|-------------------|----------------------|
| 1. Load | "Data recorded in X format" | See `method-vocabulary.md` → Data Loading |
| 2. Filter | "Bandpass X–Y Hz" | `raw.filter(l_freq=X, h_freq=Y)` |
| 3. Reference | "Re-referenced to average" | `raw.set_eeg_reference('average', projection=False)` |
| 4. Artifact | "ICA / ±100 µV rejection" | `ICA()` / `reject=dict(eeg=100e-6)` |
| 5. Epoch | "–200 to 800 ms" | `mne.Epochs(raw, events, tmin=-0.2, tmax=0.8)` |
| 6. Baseline | "–200 to 0 ms" | `baseline=(-0.2, 0)` |

**When the paper names a method, look it up in `references/method-vocabulary.md`** for the exact Python function and parameters.

### Analysis

Extract and map to implementation:

| Paper Description | Python Implementation |
|-------------------|----------------------|
| "N170 mean amplitude at P7/P8, 150–200 ms" | `evoked.get_data(picks=['P7','P8'])[:, mask].mean() * 1e6` |
| "Peak latency in 130–210 ms window" | `evoked.get_peak(tmin=0.130, tmax=0.210, mode='neg')` |
| "GLM with 6mm smoothing, 128s highpass" | `FirstLevelModel(smoothing_fwhm=6, high_pass=1/128)` |
| "Searchlight MVPA with SVM" | `nilearn.decoding.SearchLight(estimator=LinearSVC())` |

### Statistics

Map each test to its exact pingouin/MNE call:

| Paper Description | Python Implementation |
|-------------------|----------------------|
| "2×3 RM-ANOVA, GG corrected" | `pg.rm_anova(data, dv, within=[f1,f2], subject)` → `p-GG-corr` |
| "Paired t-test with Bonferroni" | `pg.pairwise_tests(..., padjust='bonf')` |
| "Cluster permutation (Maris 2007)" | `mne.stats.permutation_cluster_test(X, n_permutations=5000)` |
| "Cohen's d effect size" | `cohen-d` column from `pg.ttest(..., paired=True)` |
| "BF10 Bayes factor" | `BF10` column from `pg.ttest()` |

### Reported Results
- Key statistics (t-values, F-values, p-values) — **record exact numbers**
- Effect sizes (Cohen's d, eta-squared) — **record exact numbers**
- Accuracy (if classification)
- Direction of effects
- Confidence intervals

---

## What to Flag as Missing

If the paper doesn't specify something, flag it explicitly with a default:

```
[MISSING] Filter settings not specified — default: 0.1–30 Hz FIR (common ERP default)
[MISSING] Artifact threshold not mentioned — default: ±100 µV peak-to-peak
[MISSING] Channel selection unclear — paper says 'posterior electrodes' without listing them
[MISSING] ICA method not specified — default: infomax (EEGLAB default)
[MISSING] Number of ICA components not specified — default: n_components=0.999 (99.9% variance)
[MISSING] Baseline correction not mentioned — default: prestimulus interval
```

---

## Software-to-Python Mapping

When the paper mentions software, map to Python equivalents:

| Paper Software | Python Package | Key Function |
|---------------|----------------|-------------|
| EEGLAB | mne | `read_raw_eeglab()`, `filter()`, `Epochs()` |
| ERPLAB | mne | `average()`, `combine_evoked()` |
| FieldTrip | mne | `filter()`, `Epochs()`, `tfr_morlet()` |
| SPM12 | nilearn | `FirstLevelModel()`, `SecondLevelModel()` |
| FSL | nilearn | `FirstLevelModel()`, `threshold_stats_img()` |
| AFNI | nilearn | `FirstLevelModel()` |
| BrainVoyager | nilearn, nibabel | `NiftiMasker()`, `Decoder()` |
| BESA | mne | Source localization functions |
| Brainstorm | mne | `apply_inverse()`, `make_forward_solution()` |
| CONN toolbox | nilearn.connectome | `ConnectivityMeasure()` |
| FreeSurfer | nibabel.freesurfer | Surface processing |
| R / lme4 | statsmodels | `mixedlm()` |
| JASP / SPSS | pingouin | `rm_anova()`, `ttest()` |
| Custom MATLAB | numpy/scipy | Write equivalent using primitives |

See `references/method-vocabulary.md` for detailed function-level mapping tables.

---

## Output Format

Present extracted methods as a structured summary with Python mapping:

```
MODALITY:       EEG (64 channels, BioSemi, 512 Hz)
SUBJECTS:       24 (12F, age 18-35)
TASK:           Visual oddball (faces vs houses vs scrambled)

PREPROCESSING:
  1. Load:      BioSemi .bdf → mne.io.read_raw_bdf()
  2. Filter:    0.1–30 Hz bandpass → raw.filter(0.1, 30.0)
  3. Reference: Average reference → raw.set_eeg_reference('average', projection=False)
  4. ICA:       runica, 15 components → ICA(n_components=15, method='infomax')
  5. Epoch:     –200 to 800 ms → mne.Epochs(tmin=-0.2, tmax=0.8)
  6. Baseline:  –200 to 0 ms → baseline=(-0.2, 0)
  7. Reject:    ±100 µV → reject=dict(eeg=100e-6)

ANALYSIS:       N170 peak amplitude at P7/P8 (140–200 ms)
                → evoked.get_peak(tmin=0.14, tmax=0.2, mode='neg')

STATISTICS:     2×3 RM-ANOVA (hemisphere × condition), GG corrected
                → pg.rm_anova(data, dv='amplitude', within=['hemisphere','condition'],
                              subject='subject', effsize='np2')

KEY RESULTS:    N170 faces > houses, F(2,46)=15.3, p<.001, ηp²=0.40

GAPS:
  [MISSING] ICA component selection criteria not described
  [MISSING] Bad channel detection method not specified
```

Then list gaps that need user input.

---

## Update Planning Files

After extraction, update:
- **`findings.md`** — Record paper reference values (exact statistics, N, effect sizes)
- **`task_plan.md`** — Mark paper extraction phase as complete
- **`progress.md`** — Log what was extracted and any ambiguities

## Key Extraction Tips (from practice)

1. **Check for timing delays**: Some datasets have known delays between trigger and stimulus onset (e.g., ds003645 has 34ms MEG trigger delay — check if it applies to EEG)
2. **Channel naming**: Generic labels (EEG001-EEG075) may not match standard 10-20 names. Check dataset `*_channels.tsv` for mapping.
3. **EOG/ECG channels**: Often embedded in the EEG channel array. Common patterns:
   - EEG061=HEOG, EEG062=VEOG, EEG063=ECG (ds003645)
   - Check `*_channels.tsv` in BIDS datasets for channel types
4. **Subject exclusions**: Papers often use a subset (e.g., 16 of 19). Note which subjects and why.
5. **Event labeling**: BIDS events in `*_events.tsv` may use different labels than the paper. Map them explicitly.
6. **Preprocessing order matters**: The exact sequence (e.g., epoch THEN filter THEN trim vs filter THEN epoch) affects results.
7. **Unit conventions**: Papers report µV, MNE uses volts. Papers report ms, MNE uses seconds. Always convert.
