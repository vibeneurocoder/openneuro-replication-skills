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
analysis:
  type: erp|glm|mvpa|connectivity
  preprocessing:
    filter_lowcut: {highpass Hz}
    filter_highcut: {lowpass Hz}
    artifact_threshold: {uV threshold}
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
