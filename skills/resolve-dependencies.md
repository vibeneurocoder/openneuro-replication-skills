---
description: Detect, install, and resolve Python dependencies for neuroscience analyses
match:
  - install
  - dependency
  - missing package
  - import error
  - toolbox
  - what packages
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

## Resolution Strategy

When a paper mentions a tool/package:

1. **Check if installed**: `python3 -c "import X"`
2. **If not installed**: Tell the user the exact pip command
3. **If MATLAB-only**: Find Python equivalent (see mapping below)
4. **If no equivalent exists**: Write custom code with numpy/scipy

## MATLAB Toolbox → Python Mapping

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
