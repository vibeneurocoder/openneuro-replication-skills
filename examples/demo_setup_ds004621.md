# Skill Demo: `/setup-replication ds004621`

## Run Date: 2026-03-04
## Cold Test: Dataset never referenced in codebase before

## Input
- **Dataset ID**: ds004621 (Nencki-Symfonia EEG/ERP)
- **Paper**: No PDF provided — fetched methods from web (PMC8900497)
- **Skill**: `/setup-replication` (from `.claude/skills/setup-replication.md`)

---

## Step-by-Step Execution Log

### Step 1: Parse Input ✓
- dataset_id = `ds004621`
- paper_source = None (cold test — no prior knowledge of this dataset)
- Found via WebSearch: Dzianok et al. (2022), DOI: 10.1093/gigascience/giac015

### Step 2: Create Folder Structure ✓
```
replications/ds004621/
├── references/methods/
├── figures/
├── results/
├── configs/
```

### Step 3: Download & Validate Dataset ✓
- Downloaded root BIDS files (dataset_description.json, participants.tsv)
- Downloaded 2 subjects (sub-01, sub-02) with full EEG data
- **42 subjects total** in dataset (all subject dirs created from metadata sync)
- **4 tasks per subject**: oddball, msit, srt, rest
- **BrainVision format**: .eeg/.vhdr/.vmrk (NOT EEGLAB — new format for our toolbox!)
- **127 channels** (128 minus FCz online reference), 1000 Hz
- **~665 MB per subject per task** (oddball)
- Events verified: S5=standard, S6=distractor, S7=target, S1=response

### Step 4: Paper Check ✓
- No PDF in references/ (expected — cold test)
- Found paper via web: GigaScience open access
- Fetched full methods from PMC (PMC8900497)
- Extracted all parameters from the Methods section

### Step 5: Read Paper & Extract Pipeline ✓
- Read via WebFetch (PMC full text)
- Extracted complete methodology:
  - 42 subjects, 22F/20M, age 20-34
  - actiCHamp 128-ch, 1000 Hz, FCz reference
  - Oddball: 660 stimuli, 200 ms duration, 1200-1600 ms ISI
  - Preprocessing: average ref → 0.5-40 Hz bandpass → ICA → visual inspection
  - Epochs: -200 to 1000 ms, baseline -200 to 0 ms
  - ERP: N200 at Fz (200-350 ms), P300 at Pz (300-600 ms)
  - Statistics: RM-ANOVA, Greenhouse-Geisser, Bonferroni
- **Important**: Paper does NOT report exact ERP amplitudes — only qualitative effects

### Step 6: Generate Documentation ✓
- Wrote `references/methods/extracted_pipeline.md`
- Wrote `references/methods/required_references.md`

### Step 7: Build Config ✓
- Wrote `configs/ds004621_replication.yaml`
- Wrote `configs/dataset_info.json`
- Identified 5 gaps (1 critical, 3 important, 1 optional)

### Step 8: Summary ✓

---

## Final Status

```
=== REPLICATION SETUP COMPLETE ===

Study: ds004621 — Dzianok et al. (2022) Nencki-Symfonia Oddball P300
Directory: replications/ds004621/

Dataset:
  Subjects: 42 total (2 downloaded)
  Modality: EEG (127 ch, 1000 Hz, BrainVision .vhdr)
  Tasks: oddball, msit, srt, rest
  Status: ✓ validated (2 subjects)

Paper Pipeline:
  extracted_pipeline.md: ✓ written
  required_references.md: ✓ written
  Config YAML: ✓ written

Gaps to Fill:
  CRITICAL: BrainVision .vhdr loading (toolbox only has EEGLAB .set loader)
  IMPORTANT: Average re-referencing
  IMPORTANT: ICA artifact correction
  IMPORTANT: Repeated-measures ANOVA (need pingouin)
  OPTIONAL: No exact ERP values in paper for comparison

Additional References Needed:
  - Original paper PDF → place in references/
  - Polich (2007) P300 norms → for result validation

Next Steps:
  1. Add BrainVision loader to toolbox (or use MNE: mne.io.read_raw_brainvision())
  2. Place original paper PDF in references/
  3. pip install pingouin (for RM-ANOVA)
  4. Download remaining 40 subjects for full group analysis
  5. Run /replicate-study to execute the replication
```

---

## Generated Files

| File | Description |
|------|-------------|
| `configs/dataset_info.json` | Dataset metadata (42 subjects, 127ch, 1000Hz) |
| `configs/ds004621_replication.yaml` | Pipeline config (oddball P300 at Pz) |
| `references/methods/extracted_pipeline.md` | Full pipeline extraction from paper |
| `references/methods/required_references.md` | Required refs + gap analysis |

---

## Key Differences from ds003645 Test

| Aspect | ds003645 (previous) | ds004621 (this test) |
|--------|---------------------|---------------------|
| Prior knowledge | In codebase, paper PDF local | Never seen before |
| Paper access | Read local PDF | Fetched from web (PMC) |
| File format | EEGLAB .set/.fdt | **BrainVision .vhdr** (NEW) |
| Channels | 75 (EEG+EOG+ECG+trigger) | **127** (high-density EEG) |
| Paradigm | Face perception (N170) | **Auditory oddball (P300)** |
| Conditions | famous/unfamiliar/scrambled | standard/distractor/target |
| Paper completeness | Exact amplitudes in Table 3 | **Qualitative only** (no numbers) |
| Missing toolbox | Re-reference, ICA, microsaccade | **BrainVision loader**, re-ref, ICA, RM-ANOVA |

## Observations

1. **The skill handled a completely unknown dataset** — zero prior codebase references
2. **WebFetch worked as paper source** when no PDF was available
3. **New file format discovered** — BrainVision .vhdr/.eeg/.vmrk requires toolbox extension
4. **Gap analysis was accurate** — correctly identified BrainVision loading as the critical blocker
5. **Event code mapping worked** — correctly identified S5/S6/S7 from events.tsv inspection
6. **Qualitative-only results flagged** — the skill correctly noted that replication can only verify effect directions, not exact values
