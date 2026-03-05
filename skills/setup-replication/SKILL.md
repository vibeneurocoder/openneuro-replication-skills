---
name: setup-replication
description: Sets up a complete neuroscience replication study from an OpenNeuro dataset. Downloads data via AWS S3, creates folder structure, reads the paper PDF, extracts the analysis pipeline, generates config and documentation, and identifies toolbox gaps. Use when setting up a new replication, preparing a new study, or when the user mentions setup, new replication, or prepare replication.
argument-hint: "[dataset_id] [--demo] [--paper path-or-doi]"
---

# Setup Replication Study

Follow each step in order. Do NOT skip steps.

## Step 1: Parse Input

Extract from `$ARGUMENTS`:
- **`dataset_id`** (required): OpenNeuro ID like `ds003645`, `ds000105`
- **`--paper`** (optional): DOI, URL, or path to PDF
- **`--demo`** (optional): Download only 2 subjects into `demo_data/` for quick testing

If no dataset_id, ask the user.

---

## Step 2: Create Folder Structure

```bash
mkdir -p replications/${DATASET_ID}/references/methods
mkdir -p replications/${DATASET_ID}/figures
mkdir -p replications/${DATASET_ID}/results
mkdir -p replications/${DATASET_ID}/configs
```

---

## Step 3: Download & Validate Dataset

### 3a: Data directory

- Demo mode: `demo_data/${DATASET_ID}/`
- Full mode: `data/${DATASET_ID}/`

### 3b: Download

Download BIDS root files first (metadata), then subjects:

```bash
# BIDS root
aws s3 sync s3://openneuro.org/${DATASET_ID}/ ${DATA_DIR}/ \
    --no-sign-request --exclude "sub-*" --exclude "derivatives/*"

# Full mode: all subjects
aws s3 sync s3://openneuro.org/${DATASET_ID}/ ${DATA_DIR}/ \
    --no-sign-request --exclude "derivatives/*"

# Demo mode: 2 subjects only
aws s3 ls s3://openneuro.org/${DATASET_ID}/ --no-sign-request | grep "sub-" | head -2
for SUB in sub-01 sub-02; do
    aws s3 sync s3://openneuro.org/${DATASET_ID}/${SUB}/ ${DATA_DIR}/${SUB}/ --no-sign-request
done
```

- Do NOT exclude `*.nii.gz` (fMRI needs them)
- If >50 GB and full mode, ask user before downloading
- If AWS CLI unavailable: `pip install awscli`

### 3c: Validate

1. List subjects downloaded vs total
2. Check for data files (`.set`, `.vhdr`, `.nii.gz`, etc.)
3. Check BIDS files (`dataset_description.json`, `participants.tsv`, events)
4. Report modality, channels, sampling rate, conditions

### 3d: Save dataset_info.json

Write to `replications/${DATASET_ID}/configs/dataset_info.json`. See [templates.md](templates.md) for the JSON template.

---

## Step 4: Request Original Paper

1. Check `replications/{dataset_id}/references/` for existing PDFs
2. If `--paper` is a PDF path: read it directly (Step 5)
3. If `--paper` is a DOI/URL: ask user to download and place PDF in `references/`
4. If no paper: look up known dataset-paper mapping in [reference.md](reference.md), tell user what to download

---

## Step 5: Read Paper & Extract Pipeline

Read the PDF with the Read tool. For large papers (>10 pages), use the `pages` parameter.

Extract ALL of the following (note "Not specified in paper" where unknown):

- **Participants**: N, demographics, criteria
- **Stimuli & Task**: conditions, N trials, duration, ISI, design type
- **Recording**: modality, system, N channels, sampling rate, reference
- **Preprocessing** (numbered steps with exact parameters): filtering, re-referencing, artifact rejection, ICA, epoching, baseline, spatial processing
- **Analysis**: method, time windows, channels/ROIs, frequency bands, measurement type
- **Statistics**: test type, factors, correction, alpha, effect size
- **Key Findings**: main effects with exact statistics and direction
- **Software**: tools mentioned, methods papers cited

Check for mismatches between paper and dataset (channels, sampling rate, conditions).

---

## Step 6: Generate Documentation

### 6a: Write `extracted_pipeline.md`

Write to `replications/{dataset_id}/references/methods/extracted_pipeline.md`. Use the template in [templates.md](templates.md). Include all sections: participants, stimuli, recording, preprocessing steps, analysis, statistics, findings, gap comparison table.

### 6b: Write `required_references.md`

Write to `replications/{dataset_id}/references/methods/required_references.md`. Use the template in [templates.md](templates.md). Include: required papers, required software, implementation gap analysis (what we have vs what we need), Python packages table.

Use the toolbox capability reference in [reference.md](reference.md) for the gap analysis.

---

## Step 7: Build Initial Config

Generate `replications/{dataset_id}/configs/{dataset_id}_replication.yaml` from extracted parameters. See YAML template in [templates.md](templates.md).

---

## Step 8: Summary

Print:

```
=== REPLICATION SETUP COMPLETE ===

Study: {dataset_id} — {paper citation}
Directory: replications/{dataset_id}/
Mode: {demo | full}

Dataset:
  Location: {DATA_DIR}/
  Subjects: N downloaded / N total
  Modality: EEG/fMRI

Files Generated:
  extracted_pipeline.md
  required_references.md
  {dataset_id}_replication.yaml
  dataset_info.json

Gaps: {list critical gaps}

Next Steps:
  1. Review extracted_pipeline.md
  2. Place required reference papers in references/
  3. Run /replicate-study to execute
```

If demo mode, append:
```
DEMO MODE: Only 2 subjects downloaded.
Re-run without --demo for full dataset.
```

---

## Critical Reminders

- ALWAYS read the actual paper PDF — do NOT rely on assumptions
- ALWAYS check for mismatches between paper and dataset
- ALWAYS flag methods that reference other papers
- When in doubt: "Not specified in paper — default: {value}"
- `extracted_pipeline.md` should be detailed enough to implement from alone
