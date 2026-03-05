# Skill Demo: `/setup-replication ds003645`

## Run Date: 2026-03-04

## Input
- **Dataset ID**: ds003645
- **Paper**: `replications/ds003645/references/1-s2.0-S1053811920309502-main.pdf`
- **Skill**: `/setup-replication` (from `.claude/skills/setup-replication.md`)

---

## Step-by-Step Execution Log

### Step 1: Parse Input ✓
- dataset_id = `ds003645`
- paper_source = PDF already in `references/`

### Step 2: Create Folder Structure ✓
```
replications/ds003645/
├── references/
│   ├── methods/
│   └── 1-s2.0-S1053811920309502-main.pdf
├── figures/
├── results/
├── configs/
```

### Step 3: Download & Validate Dataset ✓
- Data already present at `demo_data/ds003645/`
- **18 subjects** with EEG data (sub-002 through sub-019)
- sub-001 exists as directory but has no EEG data
- 6 runs per subject, EEGLAB .set/.fdt format
- 75 channels, ~1100 Hz sampling rate
- Task: FacePerception
- Saved `configs/dataset_info.json`

### Step 4: Paper Check ✓
- Found: `references/1-s2.0-S1053811920309502-main.pdf`
- Kappenman et al. (2021) ERP CORE paper, 10 pages

### Step 5: Read Paper & Extract Pipeline ✓
- Read all 10 pages of the PDF
- Extracted complete methodology from Sections 2.1–2.6 and Tables 1–4
- **Key parameters extracted**:
  - N = 40 (37 after exclusions for N170)
  - 30 scalp electrodes, Biosemi, 1024 Hz → downsampled to 256 Hz
  - N170 measured at PO8, 110–150 ms window
  - Difference wave: Faces minus Cars
  - Mean amplitude: −3.37 µV (d_z = 1.24)
  - Peak amplitude: −5.52 µV (d_z = 1.66)
- **Mismatches found**:
  - Dataset has 75 channels at 1100 Hz (paper says 30 channels at 1024→256 Hz)
  - Dataset conditions: famous/unfamiliar/scrambled (paper: faces/cars/scrambled)

### Step 6: Generate Documentation ✓
- Wrote `references/methods/extracted_pipeline.md` (detailed pipeline with all parameters)
- Wrote `references/methods/required_references.md` (5 papers + 2 code repos + gap analysis)

### Step 7: Build Config ✓
- Wrote `configs/ds003645_replication.yaml` with extracted parameters
- Identified 4 gaps:
  1. **CRITICAL**: Condition mapping (famous/unfamiliar vs cars)
  2. **IMPORTANT**: Microsaccade rejection (HEOG threshold)
  3. **IMPORTANT**: ICA artifact correction
  4. **OPTIONAL**: Individualized thresholds

### Step 8: Summary ✓

---

## Final Status

```
=== REPLICATION SETUP COMPLETE ===

Study: ds003645 — Kappenman et al. (2021) ERP CORE
Directory: replications/ds003645/

Dataset:
  Subjects: 18 downloaded (paper used 37 of 40)
  Modality: EEG (75 ch, 1100 Hz, .set/.fdt)
  Status: ✓ validated

Paper Pipeline:
  extracted_pipeline.md: ✓ written (12 preprocessing steps)
  required_references.md: ✓ written (5 papers, 2 code repos)
  Config YAML: ✓ written

Gaps to Fill:
  - CRITICAL: Verify condition mapping (faces vs cars vs scrambled)
  - IMPORTANT: Add ICA artifact correction
  - IMPORTANT: Add microsaccade rejection on HEOG

Additional References Needed:
  - ERPLAB paper (Lopez-Calderon & Luck 2014): artifact rejection algorithms
  - ERP_CORE GitHub repo: ground-truth analysis scripts
  - ERP CORE OSF materials: processed data for comparison

Next Steps:
  1. Review extracted_pipeline.md for accuracy
  2. Clone ERP_CORE GitHub repo into references/code/
  3. Resolve condition mapping gap (check events.tsv)
  4. Run /replicate-study to execute the replication
```

---

## Generated Files

| File | Size | Description |
|------|------|-------------|
| `configs/dataset_info.json` | ~0.5 KB | Dataset metadata |
| `configs/ds003645_replication.yaml` | ~2.5 KB | Pipeline config |
| `references/methods/extracted_pipeline.md` | ~12 KB | Full pipeline extraction |
| `references/methods/required_references.md` | ~7 KB | Required refs + gap analysis |

## Observations

1. **The skill worked end-to-end** — all 8 steps completed successfully
2. **Paper reading was the most valuable step** — extracted exact parameters from Tables 1-4
3. **Gap identification was accurate** — flagged the condition mapping issue (faces vs cars) which is a real discrepancy between dataset and paper
4. **No code execution needed** — the skill uses Claude's native Read/Write/Bash tools
5. **Idempotent** — re-running would overwrite files without creating duplicates
