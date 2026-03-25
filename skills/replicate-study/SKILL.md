---
name: replicate-study
description: Replicates a neuroscience study from a paper and OpenNeuro dataset — loads data, preprocesses, analyzes, and compares results with the original paper. Covers EEG (EEGLAB .set, BrainVision .vhdr, EDF), fMRI (NIfTI), and MEG formats with montage templates (10-20, EGI, BioSemi) and brain atlases (AAL, Harvard-Oxford, Schaefer). Integrates MNE-Python, pingouin, nilearn, and scipy pipelines with verification checkpoints and publication-quality visualization. Maps MATLAB toolbox methods (EEGLAB, FieldTrip, SPM) to Python via companion neuroforge skills. Use when the user wants to replicate, reproduce, or re-run a study analysis.
argument-hint: "[dataset_id]"
---

# Neuroscience Study Replication

You are an expert neuroscience methods replicator. When the user asks to replicate a study, follow this process:

> **Tip**: Run `/setup-replication` first to automatically create folders, download data, extract the pipeline, and create planning files.
>
> **Companion skills**: This skill integrates practices from `verification-before-completion`, `scientific-visualization`, `systematic-debugging`, and `planning-with-files`. Use those skills for deeper guidance on any specific aspect.

## Reference Documents

This skill has detailed API references for each pipeline domain. Consult them for exact function signatures, parameter tables, pitfalls, and tested code:

| Reference | Domain | Key APIs |
|-----------|--------|----------|
| `references/eeg-data-loading.md` | Loading EEG from OpenNeuro | `mne.io.read_raw_eeglab()`, `read_raw_brainvision()`, `scipy.io.loadmat()`, `mne_bids.read_raw_bids()` |
| `references/preprocessing-pipeline.md` | Filtering, re-referencing, ICA, epoching | `raw.filter()`, `raw.set_eeg_reference()`, `mne.Epochs()`, `mne.preprocessing.ICA()` |
| `references/erp-analysis.md` | ERP computation and measurement | `epochs.average()`, `evoked.get_peak()`, `mne.grand_average()`, `mne.combine_evoked()` |
| `references/statistics-and-comparison.md` | Statistical testing and replication comparison | `pingouin.rm_anova()`, `pingouin.ttest()`, `mne.stats.permutation_cluster_test()` |
| `references/fmri-replication.md` | fMRI GLM, MVPA, connectivity | `FirstLevelModel()`, `SecondLevelModel()`, `Decoder()`, `NiftiMasker()` |
| `references/publication-figures.md` | Publication-quality figures | `mne.viz.plot_compare_evokeds()`, matplotlib templates, Okabe-Ito palette |

**Assets:**
- `assets/api-quick-reference.md` — Compact function lookup table for all pipeline stages
- `assets/openneuro-format-guide.md` — BIDS structure, file formats, download patterns

---

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

---

## Step 2: Load the Data

Detect format and choose the correct reader. See `references/eeg-data-loading.md` for full details.

```python
import mne

# Detect format from file extensions, then load:
# EEGLAB .set/.fdt (most common on OpenNeuro):
raw = mne.io.read_raw_eeglab("sub-001/eeg/sub-001_task-N170_eeg.set", preload=True)

# BrainVision .vhdr/.vmrk/.eeg:
raw = mne.io.read_raw_brainvision("sub-001/eeg/sub-001_task-oddball_eeg.vhdr", preload=True)

# EDF:
raw = mne.io.read_raw_edf("sub-001/eeg/sub-001_task-rest_eeg.edf", preload=True)

# fMRI NIfTI:
import nibabel as nib
img = nib.load("sub-01/func/sub-01_task-localizer_bold.nii.gz")
```

**Verify after loading:**
```python
print(f"Channels: {len(raw.ch_names)}, Sfreq: {raw.info['sfreq']} Hz")
print(f"Duration: {raw.times[-1]:.1f} s")
print(f"Channel types: {set(raw.get_channel_types())}")
```

If `mne.io.read_raw_eeglab()` fails, use `scipy.io.loadmat()` fallback — see `references/eeg-data-loading.md`.

---

## Step 3: Identify What's Needed

For each method step in the paper, determine:
1. **Is there a Python equivalent?** Map the paper's toolbox to available packages:
   - EEGLAB/ERPLAB → MNE-Python + scipy.io for .set/.fdt files
   - SPM/FSL/AFNI → nilearn + nibabel
   - FieldTrip → MNE-Python
   - MATLAB custom → write Python equivalent using numpy/scipy
   - R packages → scipy.stats, pingouin, statsmodels

2. **Is the package installed?** Check: `python3 -c "import package_name"`

3. **If not installed**, tell the user: `pip install package_name`

### Recommended packages for replication
| Package | Purpose | Key Functions |
|---------|---------|---------------|
| mne | EEG/MEG processing | `read_raw_eeglab()`, `Epochs()`, `ICA()` |
| numpy, scipy | Core array ops, signal processing, I/O | `loadmat()`, `sosfiltfilt()` |
| pandas | Data management, CSV export | `read_csv()`, `DataFrame` |
| matplotlib | Visualization | `subplots()`, `savefig()` |
| pingouin | RM-ANOVA, effect sizes, Bayes factors | `rm_anova()`, `ttest()`, `pairwise_tests()` |
| statsmodels | Advanced statistics, mixed models | `mixedlm()`, `AnovaRM()` |
| nilearn | fMRI analysis | `FirstLevelModel()`, `Decoder()` |
| nibabel | NIfTI I/O | `load()`, `save()` |

---

## Step 4: Resolve References

Papers often say "preprocessing followed Smith et al. (2005)". When you encounter this:
- Ask the user: "Can you provide Smith et al. 2005 or describe their preprocessing?"
- Search for the reference if it's a well-known method
- Common references and their meanings:
  - "Delorme & Makeig (2004)" → EEGLAB preprocessing defaults
  - "Oostenveld et al. (2011)" → FieldTrip toolbox
  - "Gramfort et al. (2013)" → MNE-Python
  - "Maris & Oostenveld (2007)" → cluster-based permutation test (see `references/statistics-and-comparison.md`)
  - "Haxby et al. (2001)" → split-half correlation MVPA
  - "Kriegeskorte et al. (2008)" → representational similarity analysis

---

## Step 5: Build the Pipeline

Write a standalone Python script that implements the full pipeline. See reference docs for exact API signatures.

### 5a: Preprocessing (match paper exactly)

```python
import mne

# 1. Load (see references/eeg-data-loading.md for format-specific details)
raw = mne.io.read_raw_eeglab(fname, preload=True)

# 2. Set montage (see references/eeg-data-loading.md)
raw.set_montage("standard_1020", match_case=False, on_missing="warn")

# 3. Filter — match paper's Hz exactly (see references/preprocessing-pipeline.md)
raw.filter(l_freq=0.1, h_freq=30.0)  # "bandpass filtered 0.1–30 Hz"

# 4. Re-reference — match paper (see references/preprocessing-pipeline.md)
raw.set_eeg_reference(ref_channels="average", projection=False)

# 5. ICA if paper used it (see references/preprocessing-pipeline.md)
ica = mne.preprocessing.ICA(n_components=15, method="infomax", random_state=42)
raw_ica = raw.copy().filter(l_freq=1.0, h_freq=None)
ica.fit(raw_ica, picks="eeg")
eog_idx, _ = ica.find_bads_eog(raw)
ica.exclude = eog_idx
ica.apply(raw)

# 6. Epoch (see references/preprocessing-pipeline.md)
events, event_id = mne.events_from_annotations(raw)
epochs = mne.Epochs(raw, events, event_id,
                    tmin=-0.2, tmax=0.8,
                    baseline=(-0.2, 0),
                    reject=dict(eeg=100e-6),
                    preload=True)

# Verification checkpoint
print(f"[VERIFY] Kept {len(epochs)} of {len(events)} epochs")
```

### 5b: ERP Analysis (see `references/erp-analysis.md`)

```python
# Condition-specific ERPs
evoked_face = epochs["face"].average()
evoked_car = epochs["car"].average()

# Mean amplitude in paper's time window
def mean_amplitude(evoked, tmin, tmax, picks):
    data = evoked.copy().pick(picks).get_data()
    times = evoked.times
    mask = (times >= tmin) & (times <= tmax)
    return data[:, mask].mean() * 1e6  # convert V → µV

n170_face = mean_amplitude(evoked_face, 0.150, 0.200, ["P7", "P8"])
n170_car = mean_amplitude(evoked_car, 0.150, 0.200, ["P7", "P8"])
print(f"[VERIFY] N170 face: {n170_face:.2f} µV, car: {n170_car:.2f} µV")
```

### 5c: Statistics (see `references/statistics-and-comparison.md`)

```python
import pingouin as pg

# RM-ANOVA — match paper's design exactly
aov = pg.rm_anova(data=df, dv="amplitude", within="condition",
                  subject="subject", effsize="np2")
print(f"[VERIFY] F({aov['ddof1'][0]},{aov['ddof2'][0]}) = {aov['F'][0]:.2f}, "
      f"p = {aov['p-unc'][0]:.6f}, ηp² = {aov['np2'][0]:.3f}")

# Pairwise comparisons
pw = pg.pairwise_tests(data=df, dv="amplitude", within="condition",
                       subject="subject", padjust="bonf", effsize="hedges")
```

### 5d: fMRI Pipeline (see `references/fmri-replication.md`)

```python
from nilearn.glm.first_level import FirstLevelModel
import pandas as pd

events = pd.read_csv("sub-01_task-localizer_events.tsv", sep="\t")
glm = FirstLevelModel(t_r=2.0, hrf_model="spm", high_pass=1/128,
                       smoothing_fwhm=6.0, noise_model="ar1")
glm.fit(func_img, events=events)
z_map = glm.compute_contrast("face - house", output_type="z_score")
```

---

## Step 6: Figures (see `references/publication-figures.md`)

**Color palette — Okabe-Ito (colorblind-safe):**
```python
COLORS = {"Face": "#0072B2", "Car": "#D55E00", "Diff": "#009E73"}
```

**ERP waveform plot:**
```python
fig = mne.viz.plot_compare_evokeds(
    {"Face": evoked_face, "Car": evoked_car},
    picks=["P7", "P8"], combine="mean",
    colors={"Face": "#0072B2", "Car": "#D55E00"},
    invert_y=True, show=False,
)
fig[0].savefig("figures/n170_erp.png", dpi=300, bbox_inches="tight")
```

**Figure requirements:**
- 300 DPI minimum
- Colorblind-safe palette (Okabe-Ito)
- Negative up for ERP waveforms
- Panel labels (A, B, C) in bold
- Both PNG (300 DPI) and PDF saved

---

## Step 7: Run and Compare

### 7a: Execute and verify

```bash
python3 replications/${DATASET_ID}/replicate_*.py 2>&1 | tee results/run_log.txt
```

**Verification checkpoint (do NOT skip):**
- Check that results CSV was written and has expected N subjects
- Check that figures were saved
- Check that all statistical tests produced valid p-values

### 7b: Compare against paper

After running, compare against paper values in `findings.md`:

```python
# Quantitative comparison (see references/statistics-and-comparison.md)
comparisons = [
    {"metric": "N170 face (µV)", "ours": n170_face, "paper": -4.8},
    {"metric": "N170 peak (ms)", "ours": peak_lat, "paper": 168},
    {"metric": "ηp²", "ours": eta_sq, "paper": 0.78},
]
```

| Metric | Threshold | Interpretation |
|--------|-----------|----------------|
| Effect direction matches | Required | Must match or investigate |
| Effect significance matches | Required | Same conclusion (sig/n.s.) |
| Effect size within 20% | Strong replication |
| Effect size within 50% | Partial replication |
| Effect size >50% different | Investigate discrepancies |

### 7c: Investigate discrepancies (systematic-debugging)

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
   - Raw data loaded correctly? (check scales, units — MNE uses volts, papers use µV)
   - Filtering applied correctly? (check frequency response)
   - Epochs extracted at correct times? (check event alignment)
   - Artifact rejection rates reasonable? (compare with paper)

3. **Document in findings.md** — Record discrepancies with evidence.

4. **Do NOT adjust parameters to force-match paper values** — Document honest differences.

### 7d: Update planning files

After completing analysis:
- Mark phases complete in `task_plan.md`
- Record final results in `findings.md`
- Log session actions in `progress.md`

---

## OpenNeuro Data Access

All datasets are public on AWS S3. See `assets/openneuro-format-guide.md` for full details.

```bash
# Full download
aws s3 sync s3://openneuro.org/{dataset_id}/ ./data/{dataset_id}/ --no-sign-request

# Demo (2 subjects)
aws s3 sync s3://openneuro.org/{dataset_id}/ ./data/{dataset_id}/ \
    --no-sign-request --exclude "sub-*"
aws s3 sync s3://openneuro.org/{dataset_id}/sub-001/ ./data/{dataset_id}/sub-001/ --no-sign-request
aws s3 sync s3://openneuro.org/{dataset_id}/sub-002/ ./data/{dataset_id}/sub-002/ --no-sign-request
```

## Key Datasets

| ID | Study | Modality | Analysis |
|----|-------|----------|----------|
| ds003645 | Kappenman et al. 2021 (ERP CORE) | EEG 30ch 1024Hz | N170, P300, N400, MMN, ERN |
| ds000105 | Haxby et al. 2001 | fMRI | MVPA object decoding |
| ds000117 | Wakeman & Henson 2015 | EEG/MEG/fMRI | Face processing (multi-modal) |
| ds004621 | Dzianok et al. 2022 | EEG 127ch 1000Hz | P300 auditory oddball |
| ds006480 | Kim et al. 2025 | EEG 65ch 1000Hz | Auditory oddball with arousal |
| ds003061 | Cahn et al. 2012 | EEG | P300 auditory oddball |
| ds000246 | Jas et al. 2018 | MEG | Auditory M100 |
