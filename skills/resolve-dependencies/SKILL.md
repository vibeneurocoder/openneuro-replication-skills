---
name: resolve-dependencies
description: Detects, installs, and resolves Python dependencies for neuroscience analyses — maps MATLAB toolboxes (EEGLAB, ERPLAB, FieldTrip, SPM, FSL, R/JASP/SPSS) to Python equivalents with exact function signatures. Includes brain atlas reference (AAL, Harvard-Oxford, Schaefer, Yeo, DiFuMo), EEG montage templates (10-20, EGI, BioSemi), and nilearn/MNE visualization tool mapping. Use when there are missing packages, import errors, dependency issues, or when the user asks what packages are needed.
---

# Dependency Resolution for Neuroscience Analysis

When building a replication pipeline, check and resolve all required packages.

## Reference Documents

| Reference | Purpose |
|-----------|---------|
| `references/package-api-mapping.md` | Detailed MATLAB → Python function mapping (EEGLAB, ERPLAB, FieldTrip, SPM, FSL, R) with exact signatures |

---

## Core Dependencies (should already be installed)

```bash
python3 -c "import numpy, scipy, matplotlib, pandas, mne; print('Core OK')"
```

## Quick Install by Analysis Type

```bash
# ERP replication (most common)
pip install mne pingouin matplotlib pandas scipy numpy autoreject

# fMRI replication
pip install nilearn nibabel matplotlib pandas scipy numpy pingouin

# Full replication stack
pip install mne nilearn nibabel pingouin statsmodels autoreject \
    mne-bids matplotlib pandas scipy numpy seaborn scikit-learn
```

## Package Reference Table

| Package | Purpose | Key Functions | Install |
|---------|---------|---------------|---------|
| **mne** ≥1.6 | EEG/MEG processing | `read_raw_eeglab()`, `Epochs()`, `ICA()` | `pip install mne` |
| **pingouin** ≥0.5.3 | RM-ANOVA, effect sizes, BF | `rm_anova()`, `ttest()`, `pairwise_tests()` | `pip install pingouin` |
| **nilearn** ≥0.10 | fMRI analysis | `FirstLevelModel()`, `Decoder()`, `NiftiMasker()` | `pip install nilearn` |
| **nibabel** ≥5.0 | NIfTI I/O | `load()`, `save()` | `pip install nibabel` |
| **statsmodels** ≥0.14 | Mixed models, advanced stats | `mixedlm()`, `AnovaRM()`, `multipletests()` | `pip install statsmodels` |
| **autoreject** ≥0.4 | Automated artifact rejection | `AutoReject()`, `Ransac()` | `pip install autoreject` |
| **mne-bids** ≥0.14 | BIDS-native loading | `read_raw_bids()`, `BIDSPath()` | `pip install mne-bids` |
| **scipy** ≥1.11 | Signal processing, I/O | `loadmat()`, `sosfiltfilt()`, `butter()` | `pip install scipy` |
| **scikit-learn** | Classification, cross-validation | `SVC()`, `cross_val_score()` | `pip install scikit-learn` |
| **seaborn** | Statistical plots | `violinplot()`, `barplot()` | `pip install seaborn` |
| **mne-connectivity** | Connectivity metrics | `spectral_connectivity_epochs()` | `pip install mne-connectivity` |
| **mne-icalabel** | ICA component labeling | `label_components()` | `pip install mne-icalabel` |
| **python-picard** | Fast ICA algorithm | `method='picard'` in `ICA()` | `pip install python-picard` |

## Analysis-Specific Dependencies

| Analysis Type | Required Packages | Key Signatures |
|--------------|-------------------|----------------|
| EEG/ERP | mne, scipy, numpy | `mne.io.read_raw_eeglab(fname, preload=True)` |
| fMRI GLM | nilearn, nibabel | `FirstLevelModel(t_r=2.0, hrf_model='spm')` |
| MVPA/Decoding | scikit-learn, nilearn | `Decoder(estimator='svc', cv=5)` |
| RM-ANOVA | pingouin | `pg.rm_anova(data, dv, within, subject, effsize='np2')` |
| Mixed models | statsmodels | `smf.mixedlm("dv ~ condition", data, groups="subject")` |
| Cluster permutation | mne | `mne.stats.permutation_cluster_test(X, n_permutations=5000)` |
| Connectivity | mne-connectivity | `spectral_connectivity_epochs(epochs, method='coh')` |
| Automated cleaning | autoreject | `AutoReject(n_jobs=-1).fit_transform(epochs)` |
| Source localization | mne | `mne.minimum_norm.apply_inverse(evoked, inverse)` |

---

## Virtual Environment Setup

**Before installing any packages**, ensure a proper Python virtual environment is active.

### Step 1: Check for active virtual environment

```python
python3 -c "import sys; print(f'Prefix: {sys.prefix}'); print(f'Same as base: {sys.prefix == sys.base_prefix}')"
```

- If `Same as base: False` → virtual environment is active
- If `Same as base: True` → system Python, need a venv

### Step 2: Ask the user which environment to use

Present these options:
1. **Create new venv**: `python3 -m venv .venv && source .venv/bin/activate`
2. **Use existing conda**: `conda activate <name>`
3. **Use existing venv**: `source /path/to/venv/bin/activate`
4. **Install globally** (not recommended) — warn about system-wide side effects

Wait for the user's choice. Do NOT install packages into system Python without explicit confirmation.

### Step 3: Activate and verify

```python
python3 -c "import sys; print('Environment:', sys.prefix)"
```

---

## Resolution Strategy

When a paper mentions a tool/package:

1. **Ensure virtual environment is active**
2. **Check if installed**: `python3 -c "import package_name; print(package_name.__version__)"`
3. **If not installed**: Tell the user the exact pip command
4. **If MATLAB-only**: Look up Python equivalent in `references/package-api-mapping.md`
5. **If no equivalent exists**: Write custom code with numpy/scipy

## MATLAB Toolbox to Python Mapping (Summary)

See `references/package-api-mapping.md` for complete function-level mapping tables.

| MATLAB Toolbox | Python Equivalent | Example Mapping |
|---------------|-------------------|-----------------|
| EEGLAB | mne | `pop_eegfiltnew()` → `raw.filter(method='fir')` |
| ERPLAB | mne | `pop_averager()` → `epochs.average()` |
| FieldTrip | mne | `ft_timelockanalysis()` → `epochs.average()` |
| SPM12 | nilearn | `spm_spm` → `FirstLevelModel().fit()` |
| FSL | nilearn | `feat` → `FirstLevelModel` + `SecondLevelModel` |
| Brainstorm | mne | Source localization functions |
| CONN | nilearn.connectome | `ConnectivityMeasure(kind='correlation')` |
| Chronux | scipy.signal, mne.time_frequency | `tfr_morlet()` |
| MVPA-Light | scikit-learn | `SVC`, `cross_val_score` |
| R / lme4 | statsmodels | `mixedlm()` |
| JASP / SPSS | pingouin | `rm_anova()`, `ttest()` |

## Known Issues & Workarounds

| Issue | Cause | Fix |
|-------|-------|-----|
| `mne.io.read_raw_eeglab` fails | Corrupted .set or MATLAB v7.3 format | Use `scipy.io.loadmat()` or `h5py.File()` |
| `pip3` not found | Conda environment | `source ~/miniconda3/bin/activate && pip install` |
| Large datasets (>10 GB) | Full multimodal download | Use `--exclude "*_meg*" --exclude "*.nii*"` |
| `nilearn` import error | Old API (`nilearn.input_data`) | Update to ≥0.10: `nilearn.maskers.NiftiMasker` |
| `mne` deprecation warnings | Old function names | Use current API: `raw.pick()` not `raw.pick_types()` |
| `autoreject` slow | Large epoch counts | Set `n_jobs=-1` for parallel processing |

## When to Ask the User

Ask the user for help when:
- Paper uses proprietary software with no open-source equivalent
- Paper cites a custom toolbox without public code
- Paper's method description is too vague to implement
- Multiple Python packages could work and you're unsure which matches the paper's approach
- Package version conflict exists between requirements
