---
name: replicate-study
description: Replicates a neuroscience study from a paper and OpenNeuro dataset — loads data, preprocesses, analyzes, and compares results with the original paper. Integrates verification checkpoints, publication-quality visualization, and systematic debugging for discrepancies. Use when the user wants to replicate, reproduce, or re-run a study analysis.
argument-hint: "[dataset_id]"
---

# Neuroscience Study Replication

You are an expert neuroscience methods replicator. When the user asks to replicate a study, follow this process:

> **Tip**: Run `/setup-replication` first to automatically create folders, download data, extract the pipeline, and create planning files.
>
> **Companion skills**: This skill integrates practices from `verification-before-completion`, `scientific-visualization`, `systematic-debugging`, and `planning-with-files`. Use those skills for deeper guidance on any specific aspect.

## Step 1: Read the Paper

Ask the user for:
- Paper source (DOI, URL, or PDF path)
- OpenNeuro dataset ID (if they know it)

Extract from the paper:
- **Modality**: EEG, fMRI, MEG, iEEG (look for: electrode, BOLD, magnetometer, depth electrode)
- **Paradigm**: What task subjects performed
- **Preprocessing**: Filter settings, reference, artifact rejection, epoch window
- **Analysis method**: ERP components, MVPA, GLM, connectivity, spectral, source localization
- **Statistical tests**: t-test, ANOVA, permutation test, correction method
- **Reported results**: Effect sizes, p-values, accuracy, key findings

**Update `findings.md`** with paper reference values after extraction.

## Step 2: Identify What's Needed

For each method step in the paper, determine:
1. **Is there a Python equivalent?** Map the paper's toolbox to available packages:
   - EEGLAB/ERPLAB → MNE-Python + scipy.io for .set/.fdt files
   - SPM/FSL/AFNI → nilearn + nibabel
   - FieldTrip → MNE-Python
   - MATLAB custom → write Python equivalent using numpy/scipy
   - R packages → scipy.stats, pingouin, statsmodels

2. **Is the package installed?** Check with:
   ```python
   python3 -c "import package_name"
   ```

3. **If not installed**, tell the user:
   ```
   pip install package_name
   ```

4. **If no Python equivalent exists**, either:
   - Write custom code using numpy/scipy primitives
   - Ask the user for the cited reference paper that describes the method
   - Use direct scipy.io / scipy.signal for low-level operations

### Recommended packages for replication
| Package | Purpose |
|---------|---------|
| numpy, scipy | Core array ops, signal processing, I/O |
| pandas | Data management, CSV export |
| matplotlib, seaborn | Visualization (see Step 5b) |
| mne | EEG/MEG processing (note: scipy.io may be needed for some .set/.fdt files) |
| pingouin | RM-ANOVA, effect sizes (eta-squared), Bayesian factors |
| statsmodels | Advanced statistics, mixed models |

## Step 3: Resolve References

Papers often say "preprocessing followed Smith et al. (2005)". When you encounter this:
- Ask the user: "Can you provide Smith et al. 2005 or describe their preprocessing?"
- Search for the reference if it's a well-known method
- Common references and their meanings:
  - "Delorme & Makeig (2004)" → EEGLAB preprocessing defaults
  - "Oostenveld et al. (2011)" → FieldTrip toolbox
  - "Gramfort et al. (2013)" → MNE-Python
  - "Maris & Oostenveld (2007)" → cluster-based permutation test
  - "Haxby et al. (2001)" → split-half correlation MVPA
  - "Kriegeskorte et al. (2008)" → representational similarity analysis

## Step 4: Build the Pipeline

Write a standalone Python script (not a notebook) that implements the full pipeline:

### 4a: Script structure
```python
#!/usr/bin/env python3
"""Replication of {Paper} — {Component}
Dataset: {dataset_id} from OpenNeuro
"""
import os, sys, glob, warnings
import numpy as np
import scipy.io, scipy.signal
import pandas as pd
import matplotlib
matplotlib.use('Agg')  # non-interactive backend
import matplotlib.pyplot as plt

# ── Constants from paper ──
# (all preprocessing parameters as named constants)

# ── Helper functions ──
# discover_subjects(), load_data(), preprocess(), analyze(), statistics()

# ── Main pipeline ──
if __name__ == '__main__':
    # 1. Discover subjects (exclude non-subject dirs like sub-emptyroom)
    # 2. Process each subject
    # 3. Run group statistics
    # 4. Generate figures
    # 5. Write report
    # 6. Verification checkpoint
```

### 4b: Key implementation patterns (proven in practice)

**Data I/O for EEGLAB .set/.fdt files:**
```python
# MNE has known bugs with some .set/.fdt datasets — use scipy.io as fallback
import scipy.io
mat = scipy.io.loadmat(set_path, squeeze_me=True, struct_as_record=False)
eeg = mat['EEG']
data = eeg.data  # channels × samples
srate = float(eeg.srate)
```

**Filtering (SOS-based, zero-phase):**
```python
from scipy.signal import butter, sosfiltfilt
sos = butter(5, cutoff / (srate/2), btype='low', output='sos')
filtered = sosfiltfilt(sos, data, axis=1)
```

**Variance-based bad channel detection:**
```python
def detect_bad_channels(data, n_eeg, threshold_z=5.0, max_bad=4):
    variances = np.var(data[:n_eeg], axis=1)
    log_var = np.log(variances + 1e-10)
    median_lv = np.median(log_var)
    mad_lv = np.median(np.abs(log_var - median_lv))
    if mad_lv < 1e-10:
        return []
    z_scores = (log_var - median_lv) / (mad_lv * 1.4826)
    bad = np.where(np.abs(z_scores) > threshold_z)[0].tolist()
    if len(bad) > max_bad:
        bad = sorted(np.argsort(np.abs(z_scores))[::-1][:max_bad].tolist())
    return bad
```

**EOG artifact rejection (after baseline correction):**
```python
def reject_eog(epoch_bl, heog_idx, veog_idx, threshold_uv=100):
    """Reject based on absolute amplitude AFTER baseline correction."""
    heog = epoch_bl[heog_idx]
    veog = epoch_bl[veog_idx]
    return np.abs(heog).max() > threshold_uv or np.abs(veog).max() > threshold_uv
```

**Statistics with pingouin:**
```python
import pingouin as pg

# RM-ANOVA with Greenhouse-Geisser correction
aov = pg.rm_anova(data=df, dv='amplitude', within='condition', subject='subject')
# → includes F, p-unc, p-GG-corr, sphericity, eta-squared

# Pairwise t-tests with Bonferroni correction
pw = pg.pairwise_tests(data=df, dv='amplitude', within='condition',
                        subject='subject', padjust='bonf', effsize='hedges')
# → includes t, p-unc, p-corr, BF10, hedges g

# Bayes Factor for evidence of null (familiarity effects)
# BF10 < 1/3 = moderate evidence for null
```

### 4c: Verification checkpoints (embed in script)

Add verification checkpoints at key stages:
```python
# After preprocessing
print(f"[VERIFY] {subject}: {n_good}/{n_total} epochs retained "
      f"({100*n_good/n_total:.0f}%), {len(bad_ch)} bad channels")

# After analysis
print(f"[VERIFY] {subject}: N170 = {amp:.2f} µV @ {lat:.0f} ms")

# After statistics
print(f"[VERIFY] RM-ANOVA: F({df1},{df2}) = {F:.2f}, p = {p:.6f}")
print(f"[VERIFY] Faces vs Scrambled: t = {t:.2f}, p = {p:.6f}, d = {d:.2f}")
```

**Update `task_plan.md`** status after each phase completes.

## Step 5: Handle Novel Methods

### 5a: Method resolution
If the paper uses a method not in standard packages:

1. **Check if it's a combination of existing primitives**
   - e.g., "time-frequency connectivity" = compute_tfr + compute_correlation_matrix

2. **Write custom code** using numpy/scipy:
   ```python
   # Example: custom method
   from scipy.stats import spearmanr
   r, p = spearmanr(x, y)
   ```

3. **Ask the user** if you can't figure out the method from the paper description

### 5b: Publication-quality figures (scientific-visualization)

All figures MUST follow these standards:

**Color palette — Okabe-Ito (colorblind-safe):**
```python
OKABE_ITO = {
    'Famous': '#D55E00',      # Vermillion
    'Unfamiliar': '#0072B2',  # Blue
    'Scrambled': '#009E73',   # Bluish green
    'Faces': '#E69F00',       # Orange
}
```

**Figure requirements:**
- 300 DPI minimum for all raster output
- Vector formats (PDF) preferred for line art
- Sans-serif fonts (Arial/Helvetica), 7-9pt axis labels
- Remove top/right spines (`ax.spines['top'].set_visible(False)`)
- Error bars: SEM with shaded bands for waveforms, specify in caption
- Multi-panel figures with bold letter labels (A, B, C)
- Save both PNG (300 DPI) and PDF

**Grand average ERP figure template:**
```python
fig, axes = plt.subplots(1, 2, figsize=(10, 4))

# Panel A: Grand average waveforms with SEM bands
ax = axes[0]
for cond, color in OKABE_ITO.items():
    ax.plot(times_ms, mean_erp[cond], color=color, linewidth=1.5, label=cond)
    ax.fill_between(times_ms,
                    mean_erp[cond] - sem_erp[cond],
                    mean_erp[cond] + sem_erp[cond],
                    color=color, alpha=0.2)
ax.invert_yaxis()  # EEG convention: negative up
ax.axhline(0, color='gray', linewidth=0.5)
ax.axvline(0, color='gray', linewidth=0.5, linestyle='--')
ax.set_xlabel('Time (ms)')
ax.set_ylabel('Amplitude (µV)')
ax.legend(frameon=False)
ax.text(-0.12, 1.05, 'A', transform=ax.transAxes, fontsize=12, fontweight='bold')

# Panel B: Bar chart with individual data points
ax = axes[1]
# ... bar plot with significance markers ...
ax.text(-0.12, 1.05, 'B', transform=ax.transAxes, fontsize=12, fontweight='bold')

for ax in axes:
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)

plt.tight_layout()
fig.savefig('figures/grand_average_n170.png', dpi=300, bbox_inches='tight')
fig.savefig('figures/grand_average_n170.pdf', bbox_inches='tight')
```

## Step 6: Run and Compare

### 6a: Execute and verify

Run the script and verify output:
```bash
python3 replications/${DATASET_ID}/replicate_*.py 2>&1 | tee results/run_log.txt
```

**Verification checkpoint (do NOT skip):**
- Check that results CSV was written and has expected N subjects
- Check that figures were saved
- Check that all statistical tests produced valid p-values
- Read the terminal output for any warnings or errors

### 6b: Compare against paper

After running the analysis, compare against the paper values recorded in `findings.md`:

| Metric | Threshold | Interpretation |
|--------|-----------|----------------|
| Effect direction matches | Required | Must match or investigate |
| Effect significance matches | Required | Same conclusion (sig/n.s.) |
| Effect size within 20% | Strong replication |
| Effect size within 50% | Partial replication |
| Effect size >50% different | Investigate discrepancies |

### 6c: Investigate discrepancies (systematic-debugging)

If results diverge from the paper, apply systematic debugging:

1. **Root cause investigation** — Do NOT guess. Check:
   - Different artifact rejection thresholds or rates
   - Different filter implementations (FIR vs IIR, filter order)
   - Different baseline correction window
   - Different channel selection or labeling
   - Different epoch window or trial selection criteria
   - Software-specific algorithm differences (SPM vs MNE vs scipy)
   - Sample differences (N subjects, which subjects excluded)

2. **Trace data flow** — Pick one subject and verify each step:
   - Raw data loaded correctly? (check scales, units)
   - Filtering applied correctly? (check frequency response)
   - Epochs extracted at correct times? (check event alignment)
   - Artifact rejection rates reasonable? (compare with paper)
   - Baseline correction window correct?

3. **Document in findings.md** — Record discrepancies with evidence:
   ```markdown
   ### Discrepancies
   - Our rejection rates higher for sub-003 (84%) vs paper max 153 trials
     → Investigated: genuine noise in this subject, paper may have excluded
   - Paper used 16/19 subjects; we used 18 (all except sub-emptyroom)
   ```

4. **Do NOT adjust parameters to force-match paper values** — Document honest differences.

### 6d: Generate replication report

Write `replications/${DATASET_ID}/replication_report.md` with:
- Methods summary (what we did)
- Results table (our values vs paper values)
- Statistical tests with full output
- Replication verdict per finding
- Discrepancy analysis
- Figures referenced

### 6e: Update planning files

After completing analysis:
- Mark phases complete in `task_plan.md`
- Record final results in `findings.md`
- Log session actions in `progress.md`

## Available Tools

### Direct scipy/numpy approach (recommended for .set/.fdt files)
- `scipy.io.loadmat` — Load EEGLAB .set files
- `scipy.signal.butter/sosfiltfilt` — Butterworth filtering
- `scipy.stats` — Basic statistical tests
- `numpy` — Array operations, epoch extraction

### MNE-Python (when it works with the dataset)
- `mne.io.read_raw_eeglab` — Load EEGLAB files
- `mne.Epochs` — Epoch management
- `mne.filter` — Filtering
- `mne.Evoked` — ERP computation

### Statistics packages
- `pingouin` — RM-ANOVA, pairwise tests, effect sizes, Bayes factors
- `statsmodels` — Mixed models, advanced regression
- `scipy.stats` — t-tests, correlations, basic tests

### Visualization
- `matplotlib` — Core plotting, multi-panel figures
- `seaborn` — Statistical plots, violin plots, heatmaps

## OpenNeuro Data Access

All datasets are public on AWS S3:
```bash
aws s3 sync s3://openneuro.org/{dataset_id}/ ./data/{dataset_id}/ --no-sign-request
```

For EEG-only datasets, exclude non-EEG modalities:
```bash
aws s3 sync s3://openneuro.org/{dataset_id}/ ./data/{dataset_id}/ \
    --no-sign-request \
    --exclude "*_meg*" --exclude "*_bold*" --exclude "*/anat/*" \
    --exclude "*.fif" --exclude "*.fif.gz" --exclude "*.nii*"
```

## Key Datasets

| ID | Study | Modality | Analysis |
|----|-------|----------|----------|
| ds003645 | Wakeman & Henson 2015 | EEG (75ch, 1100Hz) | N170 face perception |
| ds000117 | Wakeman & Henson 2015 | EEG/MEG/fMRI | Face processing (multi-modal) |
| ds003645 | Kappenman et al. 2021 (ERP CORE) | EEG 30ch 1024Hz | N170, P300, N400, MMN, ERN |
| ds000105 | Haxby et al. 2001 | fMRI | MVPA object decoding |
| ds003061 | Cahn et al. 2012 | EEG | P300 auditory oddball |
| ds000246 | Jas et al. 2018 | MEG | Auditory M100 |
