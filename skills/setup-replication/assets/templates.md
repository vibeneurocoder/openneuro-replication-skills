# Output Templates

## extracted_pipeline.md Template

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

## required_references.md Template

```markdown
# Required References & Code — {Study Name} ({dataset_id})

## Required Papers

### 1. {Paper Title}
- **Citation**: {full citation}
- **DOI**: {doi}
- **Why needed**: {explanation}
- **Priority**: HIGH/MEDIUM/LOW

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
- [x] {capability 1}

### What We Need to Add
- [ ] {missing capability 1}

### Python Packages Needed
| Package | Status | Install |
|---------|--------|---------|
| mne | Installed | — |
| nilearn | NOT installed | `pip install nilearn` |
```

## replication config YAML Template

```yaml
name: "{Study description}"
dataset:
  id: {dataset_id}
  subjects: [sub-001, ...]  # or null for all
  runs: [1, 2, ...]  # or null for all
  exclude_subjects: []  # e.g., [sub-emptyroom]
analysis:
  type: erp|glm|mvpa|connectivity
  preprocessing:
    filter_lowcut: {highpass Hz or null}
    filter_highcut: {lowpass Hz}
    filter_order: 5  # Butterworth order
    artifact_threshold: {uV threshold}
    artifact_channels: [HEOG_idx, VEOG_idx]  # channel indices for EOG rejection
    baseline: [{start_s}, {end_s}]
    epoch_window: [{start_s}, {end_s}]
    epoch_trim: [{trim_start_s}, {trim_end_s}]  # optional: trim after filtering
    bad_channel_detection:
      method: variance_z  # log-variance z-score
      threshold_z: 5.0
      max_bad: 4
    rereference: average  # average|linked_mastoid|Cz|none
  erp:  # if ERP study
    component: {name}
    time_window: [{start_s}, {end_s}]
    channels: [{ch1}, {ch2}, ...]
    measure: peak|mean
    mode: pos|neg
    conditions: [{cond1}, {cond2}]
  statistics:
    test_type: rm_anova  # rm_anova|paired_ttest|permutation
    posthoc: pairwise_ttest
    correction: bonferroni  # bonferroni|holm|fdr_bh
    alpha: 0.05
    effect_size: true
    effect_size_measure: hedges_g  # hedges_g|cohens_d|eta_squared
    bayes_factor: true  # compute BF10 for null effects
    sphericity_correction: greenhouse_geisser  # for RM-ANOVA
  figures:
    palette: okabe_ito  # colorblind-safe
    dpi: 300
    formats: [png, pdf]
    style: publication  # publication|presentation
reference:
  paper: "{citation}"
  doi: "{doi}"
```

## dataset_info.json Template

```json
{
  "dataset_id": "dsXXXXXX",
  "data_dir": "data/dsXXXXXX",
  "n_subjects": null,
  "subjects_downloaded": [],
  "subjects_total": [],
  "modality": "eeg|fmri|meg",
  "file_format": ".set|.nii.gz|...",
  "runs_per_subject": null,
  "conditions": [],
  "sampling_rate": null,
  "n_channels": null,
  "total_size_gb": null,
  "download_complete": true,
  "demo_mode": false,
  "validated_at": "ISO timestamp"
}
```
