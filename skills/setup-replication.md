---
description: Set up a complete replication study — download data, create folders, extract pipeline from paper, generate methods documentation
match:
  - setup replication
  - setup study
  - new replication
  - prepare replication
  - setup openneuro
---

# Setup Replication Study

You are setting up a new neuroscience replication study. This is the **first step** before running any analysis. Follow each step in order. Do NOT skip steps.

## Step 1: Parse Input

The user should provide:
- **`dataset_id`** (required): An OpenNeuro dataset ID like `ds003645`, `ds000105`, `ds003061`
- **`paper_source`** (optional): A DOI, URL, or path to a PDF of the original paper
- **`--demo`** (optional flag): If present, download only 2 subjects into `demo_data/` instead of all subjects into `data/`. Use for quick testing and pipeline validation before committing to a full download.

If the user didn't provide a dataset_id, ask them:
> What OpenNeuro dataset ID should I set up? (e.g., ds003645, ds000105)

Store the dataset_id, paper_source, and demo mode flag for use in all subsequent steps.

---

## Step 2: Create Folder Structure

Create the complete replication directory:

```bash
DATASET_ID=<the dataset id>
mkdir -p replications/${DATASET_ID}/references/methods
mkdir -p replications/${DATASET_ID}/figures
mkdir -p replications/${DATASET_ID}/results
mkdir -p replications/${DATASET_ID}/configs
```

Confirm to the user what was created.

---

## Step 3: Download & Validate Dataset

### 3a: Choose Data Directory

Pick directory based on demo mode:

```bash
if [ "$DEMO_MODE" = true ]; then
    DATA_DIR=demo_data/${DATASET_ID}
else
    DATA_DIR=data/${DATASET_ID}
    # Fall back to demo_data if it already exists there
    if [ -d "demo_data/${DATASET_ID}" ] && [ ! -d "data/${DATASET_ID}" ]; then
        DATA_DIR=demo_data/${DATASET_ID}
    fi
fi
```

### 3b: Download

If data already exists, skip to validation.

**Step 1: Always download BIDS root files first** (small, fast — gives us metadata):
```bash
aws s3 sync s3://openneuro.org/${DATASET_ID}/ ${DATA_DIR}/ \
    --no-sign-request \
    --exclude "sub-*" --exclude "derivatives/*" \
    2>&1
```

**Step 2: Download subject data** — behavior depends on mode:

#### Full mode (default — no `--demo` flag):
Download **ALL subjects** for complete replication:
```bash
aws s3 sync s3://openneuro.org/${DATASET_ID}/ ${DATA_DIR}/ \
    --no-sign-request \
    --exclude "derivatives/*" \
    2>&1
```

#### Demo mode (`--demo` flag):
Download only **2 subjects** for quick pipeline testing:
```bash
# Get subject list from participants.tsv or S3 listing
# Pick first 2 subjects (e.g., sub-01, sub-02 or sub-1, sub-2)
for SUB in sub-01 sub-02; do
    aws s3 sync s3://openneuro.org/${DATASET_ID}/${SUB}/ ${DATA_DIR}/${SUB}/ \
        --no-sign-request \
        2>&1
done
```
If subjects use non-zero-padded IDs (sub-1, sub-2), adapt accordingly by checking the S3 listing first:
```bash
aws s3 ls s3://openneuro.org/${DATASET_ID}/ --no-sign-request | grep "sub-" | head -2
```

**Important notes:**
- Do NOT use `--exclude '*.nii.gz'` — fMRI datasets need their NIfTI files
- The `derivatives/` folder is excluded (preprocessed data we don't need)
- EEG datasets: typically 1-5 GB total. fMRI datasets: can be 10-100+ GB
- If the dataset is very large (>50 GB) and NOT in demo mode, tell the user the estimated size and ask before downloading
- In demo mode, report: "Downloaded 2 subjects in demo mode. Run without --demo for full dataset."

**If AWS CLI is not available**, try the Python downloader:
```python
import sys; sys.path.insert(0, '.')
from toolbox.io.openneuro import OpenNeuroDownloader
d = OpenNeuroDownloader()
d.download('DATASET_ID', output_dir='data/' if not demo_mode else 'demo_data/')
```

**If both fail**, tell the user:
```
AWS CLI not found. Install with: pip install awscli
Then re-run the setup.
```

### 3c: Validate

After download, inspect what we got:
1. List subjects: `ls ${DATA_DIR}/`
2. Check for data files: Look for `.set`, `.fdt`, `.vhdr`, `.edf`, `.nii.gz`, `.eeg`, `.vmrk` files
3. Check for BIDS files: `dataset_description.json`, `participants.tsv`, events files
4. Count subjects and runs per subject
5. Check file sizes to confirm data is complete (not truncated)

Report to user:
```
Dataset {dataset_id} validated:
  - Location: {DATA_DIR}/
  - Subjects: N downloaded / N total
  - Modality: EEG/fMRI/MEG
  - Files: .set/.fdt (or .nii.gz, etc.)
  - Runs per subject: N
  - Total size: X GB
  - Events/conditions found: [list]
```

If only partial data downloaded (network error, disk space), note which subjects are missing and flag it.

### 3d: Save Dataset Summary

Write a `configs/dataset_info.json` with what was discovered:
```json
{
  "dataset_id": "dsXXXXXX",
  "data_dir": "data/dsXXXXXX",
  "n_subjects": N,
  "subjects_downloaded": ["sub-001", ...],
  "subjects_total": ["sub-001", ...],
  "modality": "eeg|fmri|meg",
  "file_format": ".set|.nii.gz|...",
  "runs_per_subject": N,
  "conditions": ["cond1", "cond2"],
  "sampling_rate": null,
  "n_channels": null,
  "total_size_gb": null,
  "download_complete": true,
  "demo_mode": false,
  "validated_at": "ISO timestamp"
}
```

---

## Step 4: Request Original Paper

### 4a: Check for existing papers

Look for PDF files in `replications/{dataset_id}/references/`:
```bash
ls replications/{dataset_id}/references/*.pdf 2>/dev/null
```

### 4b: If paper_source is a PDF path

Read it directly and proceed to Step 5.

### 4c: If paper_source is a DOI or URL

Tell the user:
> I found the paper reference. However, I need the full PDF to extract the exact analysis pipeline.
> Please download the paper and place it in:
> `replications/{dataset_id}/references/`
>
> Paper: {DOI or URL}

Then STOP and wait for the user to confirm they placed the PDF.

### 4d: If no paper_source provided and no PDFs found

Look up the dataset on OpenNeuro for the associated paper. Known datasets:

| Dataset | Paper | DOI |
|---------|-------|-----|
| ds003645 | Kappenman et al. (2021) ERP CORE | 10.1016/j.neuroimage.2020.117465 |
| ds003061 | Cahn, Delorme & Polich (2012) | 10.1007/s10339-012-0444-6 |
| ds000105 | Haxby et al. (2001) | 10.1126/science.1063736 |
| ds000117 | Wakeman & Henson (2015) | 10.1038/sdata.2015.1 |

Tell the user:
> To extract the exact analysis pipeline, I need the original paper PDF.
> This dataset is associated with: **{paper citation}** (DOI: {doi})
>
> Please download and place it in:
> **`replications/{dataset_id}/references/`**
>
> Then tell me and I'll read it to extract the pipeline.

Then STOP and wait.

---

## Step 5: Read Paper & Extract Pipeline

Once a PDF is available, read it using the Read tool (which supports PDFs).

### 5a: Read the paper
Read the full PDF. For large papers (>10 pages), read in chunks using the `pages` parameter.

### 5b: Extract methodology
From the paper text, identify and record ALL of the following. If something is not specified, note "Not specified in paper":

**Participants:**
- N subjects, demographics, inclusion/exclusion criteria

**Stimuli & Task:**
- Task description, conditions, N trials per condition
- Stimulus duration, ISI/SOA, block/event-related design

**Recording System:**
- Modality (EEG/fMRI/MEG), system (BioSemi/Neuroscan/Siemens/GE)
- N channels or voxel size, sampling rate or TR
- Reference electrode (EEG), coil type (MRI)

**Preprocessing Pipeline (in exact order):**
Number each step. For each, record the exact parameters:
1. Raw data format and software
2. Filtering — highpass, lowpass, notch (exact Hz and filter type)
3. Re-referencing scheme
4. Artifact rejection — method (ICA, threshold, manual) and parameters
5. Additional cleaning (interpolation, eye movement correction)
6. Epoching — exact time window in ms
7. Baseline correction — exact time window in ms
8. Spatial processing (smoothing FWHM, normalization)

**Analysis:**
- Primary method (ERP peak, mean amplitude, MVPA, GLM, connectivity, spectral)
- Time windows, channels/ROIs, frequency bands
- Specific measurement (peak amplitude, mean amplitude, 50% area latency)

**Statistics:**
- Test type (t-test, ANOVA, permutation, etc.)
- Factors and levels, correction method, alpha level
- Effect size measure

**Key Findings (to replicate):**
- Main effects with exact statistics (t, F, p, d, η²)
- Direction of effects

**Software & Cited Methods:**
- Software mentioned (EEGLAB, ERPLAB, SPM, MNE, etc.)
- Methods papers cited for specific steps (e.g., "ICA following Bell & Sejnowski 1995")

### 5c: Check for mismatches

Compare the paper's recording parameters against the dataset:
- Does the paper's N channels match the dataset?
- Does the sampling rate match?
- Are the expected conditions present in the events files?
- Any discrepancies (e.g., paper used 19-ch but dataset has 64-ch)?

Flag any mismatches clearly.

---

## Step 6: Generate Documentation

### 6a: Write `extracted_pipeline.md`

Write to `replications/{dataset_id}/references/methods/extracted_pipeline.md` with this structure:

```markdown
# {Component/Analysis} — Exact Analysis Pipeline
## {Authors} ({Year}). {Title}. {Journal}.
## DOI: {doi}

---

## 1. Participants
{details}

## 2. Stimuli
| Stimulus | Details |
|----------|---------|
{table rows}

## 3. Recording
- System: ...
- Channels: ...
- Sampling rate: ...
- Reference: ...

## 4. Preprocessing Pipeline (Exact from Paper)

### Step 1: {first step}
{exact parameters}

### Step 2: {second step}
{exact parameters}

...continue for all steps...

## 5. Analysis
{exact method, time windows, channels, measures}

## 6. Statistical Analysis
{test type, factors, correction, alpha}

## 7. Key Findings to Replicate
1. {finding 1 with exact statistics}
2. {finding 2}

## 8. What Our Current Replication Does vs. Paper
| Aspect | Paper | Our Toolbox |
|--------|-------|-------------|
| Filter | ... | ... |
| Artifact rejection | ... | ... |
| Analysis | ... | ... |
| Statistics | ... | ... |

## 9. Recommended Pipeline Improvements
1. {specific improvement to match paper}
2. {another improvement}
```

### 6b: Write `required_references.md`

Write to `replications/{dataset_id}/references/methods/required_references.md`:

```markdown
# Required References & Code — {Study Name} ({dataset_id})

## Required Papers

### 1. {Paper Title}
- **Citation**: {full citation}
- **DOI**: {doi}
- **Why needed**: {explanation}
- **Priority**: HIGH/MEDIUM/LOW

### 2. ...

---

## Required Code / Software

### 1. {Code Name}
- **URL**: {github/website}
- **What's needed**: {specific files or functions}
- **Why**: {explanation}
- **Priority**: HIGH/MEDIUM/LOW

---

## Implementation Gap Analysis

### What We Have
- [x] {capability 1 — e.g., Bandpass filtering (SOS-based)}
- [x] {capability 2}
- ...

### What We Need to Add
- [ ] {missing capability 1 — e.g., ICA artifact rejection}
- [ ] {missing capability 2}
- ...

### Python Packages Needed
| Package | Status | Install |
|---------|--------|---------|
| mne | Installed | — |
| nilearn | NOT installed | `pip install nilearn` |
```

### Toolbox capability reference

To fill in the gap analysis, check what the toolbox currently provides:

**EEG Preprocessing (toolbox/preprocessing/):**
- `bandpass_filter()`, `highpass_filter()`, `lowpass_filter()` — SOS-based filtering
- `create_epochs()` — epoch extraction from continuous data
- `baseline_correct()` — pre-stimulus baseline subtraction
- `reject_epochs()` — amplitude-based artifact rejection (with channel selection)
- NO: ICA, average re-referencing, channel interpolation, microsaccade rejection

**EEG Analysis (toolbox/analysis/ + toolbox/preprocessing/epoching.py):**
- `compute_erp()` — average across epochs
- `find_peak()` — peak amplitude/latency in time window (pos or neg mode)
- `compute_mean_amplitude()` — mean amplitude in time window
- `paired_ttest()`, `compute_effect_size()` — basic statistics
- NO: time-frequency (Morlet wavelets), RM-ANOVA, permutation tests, source localization

**fMRI (NOT implemented):**
- NO: GLM, MVPA, ROI definition, NIfTI loading — needs nilearn + nibabel

**Visualization (toolbox/visualization/):**
- `plot_erp()`, `plot_erp_comparison()`, `plot_butterfly()`, `plot_difference_wave()`, `plot_erp_image()`
- NO: topomaps, brain maps, time-frequency plots

---

## Step 7: Build Initial Config

Generate `replications/{dataset_id}/configs/{dataset_id}_replication.yaml` from extracted parameters:

```yaml
name: "{Study description}"
dataset:
  id: {dataset_id}
  subjects: [sub-001, ...]  # or null for all
  runs: [1, 2, ...]  # or null for all
analysis:
  type: erp|glm|mvpa|connectivity
  preprocessing:
    filter_lowcut: {highpass Hz}
    filter_highcut: {lowpass Hz}
    artifact_threshold: {µV threshold}
    baseline: [{start_s}, {end_s}]
    epoch_window: [{start_s}, {end_s}]
  erp:  # if ERP study
    component: {name}
    time_window: [{start_s}, {end_s}]
    channels: [{ch1}, {ch2}, ...]
    measure: peak|mean
    mode: pos|neg
    conditions: [{cond1}, {cond2}]
  statistics:
    test_type: paired_ttest|rm_anova|permutation
    alpha: 0.05
    effect_size: true
reference:
  paper: "{citation}"
  doi: "{doi}"
```

---

## Step 8: Summary

Print a final summary:

```
=== REPLICATION SETUP COMPLETE ===

Study: {dataset_id} — {paper citation}
Directory: replications/{dataset_id}/
Mode: {demo | full}

Dataset:
  Location: {data/ or demo_data/}{dataset_id}/
  Subjects: N downloaded / N total
  Modality: EEG/fMRI
  Status: ✓ validated

Paper Pipeline:
  extracted_pipeline.md: ✓ written
  required_references.md: ✓ written
  Config YAML: ✓ written

Gaps to Fill:
  - {critical gap 1}
  - {critical gap 2}

Additional References Needed:
  - {reference 1}: {why} → place in references/
  - {reference 2}: {why} → place in references/

Next Steps:
  1. Review extracted_pipeline.md for accuracy
  2. Place any required reference papers in references/
  3. Fill gaps in the config YAML
  4. Run /replicate-study to execute the replication
```

If in **demo mode**, also append:
```
⚠ DEMO MODE: Only 2 subjects downloaded to demo_data/.
   For full replication, re-run without --demo to download all N subjects to data/.
```

---

## Known Datasets Quick Reference

| Dataset | Paper | Modality | Key Analysis |
|---------|-------|----------|-------------|
| ds003645 | Kappenman et al. 2021 (ERP CORE) | EEG 30ch 1024Hz | N170 face perception |
| ds003061 | Cahn, Delorme & Polich 2012 | EEG 64ch 256Hz | P300 auditory oddball (time-freq) |
| ds000105 | Haxby et al. 2001 | fMRI 3T | MVPA object decoding |
| ds000117 | Wakeman & Henson 2015 | EEG+MEG+fMRI | N170 face processing |
| ds000246 | Jas et al. 2018 | MEG | Auditory M100 |

## Critical Reminders

- ALWAYS read the actual paper PDF — do NOT rely on memory or assumptions about methods
- ALWAYS check for mismatches between paper and dataset (channels, sfreq, N subjects)
- ALWAYS flag methods that reference other papers (e.g., "following Smith et al. 2005")
- When in doubt about a parameter, write "Not specified in paper — default: {value}" rather than guessing
- The `extracted_pipeline.md` should be detailed enough that someone could implement the pipeline from it alone
