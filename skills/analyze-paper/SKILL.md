---
name: analyze-paper
description: Extract and analyze complete methodology from a neuroscience research paper — preprocessing pipeline, analysis parameters, statistics, and software used. Use when the user wants to extract methods, read a paper, understand what analysis was done, or asks about paper methods.
user-invocable: true
argument-hint: "<paper-path-or-doi>"
---

# Paper Methods Extraction

When the user provides a neuroscience paper (DOI, URL, or PDF), extract the complete methodology.

## What to Extract

### Data Acquisition
- Modality (EEG, fMRI, MEG, iEEG, PET, NIRS)
- Number of subjects
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
1. Raw data format and software used
2. Filtering (highpass, lowpass, bandpass, notch — get exact Hz)
3. Re-referencing scheme
4. Artifact rejection method and threshold
5. ICA or other cleaning
6. Epoching window (exact ms)
7. Baseline correction window (exact ms)
8. Any spatial processing (smoothing, interpolation)

### Analysis
- Primary analysis method (ERP measurement, MVPA, GLM, connectivity, etc.)
- Time windows for components
- Channels/ROIs of interest
- Frequency bands (if spectral)
- Classification method (if decoding)
- Any secondary analyses

### Statistics
- Statistical test(s) used
- Factors and levels
- Multiple comparison correction
- Significance threshold (alpha)
- Effect size measure

### Reported Results
- Key statistics (t-values, F-values, p-values)
- Effect sizes (Cohen's d, eta-squared)
- Accuracy (if classification)
- Direction of effects
- Confidence intervals

## What to Flag as Missing

If the paper doesn't specify something, flag it explicitly:
- "Filter settings not specified — need to check supplementary or cited methods paper"
- "Artifact threshold not mentioned — common default is +/-100 uV for EEG"
- "Channel selection unclear — paper says 'posterior electrodes' without listing them"

## Software-to-Python Mapping

When the paper mentions software, map to Python equivalents:
- **EEGLAB** → MNE-Python (mne), our toolbox/preprocessing/
- **ERPLAB** → MNE-Python ERP functions, our toolbox/analysis/erp.py
- **FieldTrip** → MNE-Python
- **SPM** → nilearn (for fMRI), MNE (for M/EEG source)
- **FSL** → nilearn, nibabel
- **AFNI** → nilearn
- **BrainVoyager** → nilearn, nibabel
- **BESA** → MNE-Python
- **Brainstorm** → MNE-Python
- **CONN toolbox** → nilearn.connectome
- **FreeSurfer** → nibabel.freesurfer
- **R / lme4** → statsmodels, pingouin
- **JASP / SPSS** → scipy.stats, pingouin
- **Custom MATLAB** → write numpy/scipy equivalent

## Output Format

Present extracted methods as a structured summary:
```
MODALITY: EEG (64 channels, BioSemi, 512 Hz)
SUBJECTS: 24 (12F, age 18-35)
TASK: Visual oddball (faces vs houses vs scrambled)
PREPROCESSING: 0.1-30 Hz bandpass → average reference → epoch -200 to 800ms → baseline -200 to 0ms → +/-100 uV rejection
ANALYSIS: N170 peak amplitude at P7/P8 (140-200ms)
STATISTICS: 2x3 repeated-measures ANOVA (hemisphere x condition), Greenhouse-Geisser corrected
KEY RESULTS: N170 faces > houses, F(2,46)=15.3, p<.001, eta-squared=0.40
```

Then list gaps that need user input.
