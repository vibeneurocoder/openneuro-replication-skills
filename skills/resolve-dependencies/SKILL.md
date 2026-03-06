---
name: resolve-dependencies
description: Detects, installs, and resolves Python dependencies for neuroscience analyses — maps MATLAB toolboxes to Python equivalents, checks installed packages, and provides install commands. Use when there are missing packages, import errors, dependency issues, or when the user asks what packages are needed.
---

# Dependency Resolution for Neuroscience Analysis

When building a replication pipeline, check and resolve all required packages.

## Core Dependencies (should already be installed)

```
numpy, scipy, matplotlib, pandas, mne
```

Check: `python3 -c "import numpy, scipy, matplotlib, pandas, mne; print('Core OK')"`

## Analysis-Specific Dependencies

| Analysis Type | Required Packages | Install Command |
|--------------|-------------------|-----------------|
| EEG/ERP | mne, scipy, numpy | `pip install mne` |
| fMRI (any) | nibabel, nilearn | `pip install nibabel nilearn` |
| MVPA/Decoding | scikit-learn, nibabel, nilearn | `pip install scikit-learn nibabel nilearn` |
| Connectivity | mne-connectivity | `pip install mne-connectivity` |
| Source localization | mne (with freesurfer) | `pip install mne` |
| Sleep staging | yasa | `pip install yasa` |
| Statistics (advanced) | pingouin, statsmodels | `pip install pingouin statsmodels` |
| RSA | rsatoolbox | `pip install rsatoolbox` |
| BCI/Motor imagery | mne, scikit-learn | `pip install mne scikit-learn` |
| Deep learning decoding | torch, braindecode | `pip install torch braindecode` |
| Automated preprocessing | autoreject, mne | `pip install autoreject` |
| ICA (extended) | mne, picard | `pip install mne python-picard` |
| Phase-amplitude coupling | pactools or tensorpac | `pip install pactools` |

## Virtual Environment Setup

**Before installing any packages**, ensure a proper Python virtual environment is active.

### Step 1: Check for active virtual environment

Run: `python3 -c "import sys; print(sys.prefix)"`

- If inside a venv/conda env already, confirm with the user: *"You have an active environment at `<path>`. Should I install dependencies here?"*
- If **no** virtual environment is active (sys.prefix == sys.base_prefix), proceed to Step 2.

### Step 2: Ask the user which environment to use

Present these options:

1. **Create a new virtual environment** in the project directory (`python3 -m venv .venv` then `source .venv/bin/activate`)
2. **Use an existing conda environment** — ask which one (`conda activate <name>`)
3. **Use an existing venv** — ask for the path (`source /path/to/venv/bin/activate`)
4. **Install globally** (not recommended) — warn about system-wide side effects

Wait for the user's choice before proceeding. Do NOT install packages into the system Python without explicit confirmation.

### Step 3: Activate and verify

After creating or selecting an environment:
- Activate it in the current shell session
- Verify: `python3 -c "import sys; print('Environment:', sys.prefix)"`
- Then proceed with dependency installation below

## Resolution Strategy

When a paper mentions a tool/package:

1. **Ensure virtual environment is active** (see above)
2. **Check if installed**: `python3 -c "import X"`
3. **If not installed**: Tell the user the exact pip command
4. **If MATLAB-only**: Find Python equivalent (see mapping below)
5. **If no equivalent exists**: Write custom code with numpy/scipy

## MATLAB Toolbox to Python Mapping

| MATLAB Toolbox | Python Equivalent | Notes |
|---------------|-------------------|-------|
| EEGLAB | mne | Most functions map directly |
| ERPLAB | mne.Evoked | ERP measurement and plotting |
| FieldTrip | mne | ft_preprocessing → mne.filter, ft_timelockanalysis → mne.Evoked |
| SPM12 | nilearn | GLM, smoothing, normalization |
| CONN | nilearn.connectome | Functional connectivity |
| Brainstorm | mne | Source localization |
| BESA | mne | Dipole fitting, source analysis |
| Chronux | scipy.signal, mne.time_frequency | Spectral analysis |
| MVPA-Light | scikit-learn | Classification, cross-validation |
| CoSMoMVPA | nilearn.decoding, scikit-learn | MVPA, searchlight |
| LIBSVM | scikit-learn.svm | SVM classification |

## When to Ask the User

Ask the user for help when:
- Paper uses proprietary software with no open-source equivalent
- Paper cites a custom toolbox without public code
- Paper's method description is too vague to implement
- Multiple Python packages could work and you're unsure which matches the paper's approach
