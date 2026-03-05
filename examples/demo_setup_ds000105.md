# Skill Demo: `/setup-replication ds000105`

## Run Date: 2026-03-05
## Test Type: Fresh install in isolated `test/` subfolder

## Input
- **Dataset ID**: ds000105 (Haxby et al. 2001, Visual Object Recognition)
- **Paper**: No PDF provided — fetched methods from web (PubMed, Zenodo, PMC review)
- **Skill**: `/setup-replication` (installed via `install.sh` from export package)
- **Working Directory**: `test/` (completely isolated from main project)

---

## Step-by-Step Execution Log

### Step 0: Install Skills ✓
- Ran `bash install.sh ./test`
- Fixed CRLF line ending issue (WSL environment)
- 4 skill files installed to `test/.claude/skills/`

### Step 1: Parse Input ✓
- dataset_id = `ds000105`
- paper_source = None (start from scratch)
- Found in known datasets table: Haxby et al. (2001), DOI: 10.1126/science.1063736

### Step 2: Create Folder Structure ✓
```
test/replications/ds000105/
├── references/methods/
├── figures/
├── results/
├── configs/
```

### Step 3: Download & Validate Dataset ✓
- Copied BIDS root files + 2 subjects (sub-1, sub-2) from existing data
- **6 subjects total** in dataset
- **12 runs per subject**, each with 8 category blocks
- **fMRI format**: NIfTI .nii.gz
- **TR**: 2.5s
- **8 conditions**: face, house, cat, bottle, scissors, shoe, chair, scrambledpix
- **Block design**: 12 stimuli × (500ms + 1500ms ISI) = 24s blocks
- Events verified from events.tsv

### Step 4: Paper Check ✓
- No PDF in references/ (expected — start from scratch)
- Known dataset: Haxby et al. (2001), Science
- Searched web for full methods
- WebFetch on PDF URLs failed (binary content / TLS errors / 403)
- Successfully fetched methods from: PubMed abstract, Zenodo dataset page, PMC review (PMC3389290)

### Step 5: Read Paper & Extract Pipeline ✓
- Compiled methods from multiple web sources
- Extracted complete methodology:
  - 6 subjects, 5F/1M, right-handed
  - GE 3T, TR=2500ms, TE=30ms, 3.75×3.75×3.5mm voxels
  - 8 categories, blocked design, 12 runs
  - Preprocessing: motion correction → linear detrend → percent signal change
  - **Two smoothing levels**: 40mm FWHM for ROI, NONE for patterns
  - GLM: 8 boxcar regressors + HRF convolution
  - ROI: ventral temporal, p<10⁻⁶ uncorrected, objects > scrambled
  - MVPA: split-half (even/odd runs) correlation, Pearson r
  - Test: within-category r > between-category r

### Step 6: Generate Documentation ✓
- Wrote `references/methods/extracted_pipeline.md` (156 lines, 13 sections)
- Wrote `references/methods/required_references.md` (105 lines)
- Identified 3 critical gaps, 1 important, 1 optional

### Step 7: Build Config ✓
- Wrote `configs/ds000105_replication.yaml` (104 lines)
- Wrote `configs/dataset_info.json`
- Config includes full MVPA specification: split-half correlation, even/odd runs, ROI definition

### Step 8: Summary ✓

---

## Final Status

```
=== REPLICATION SETUP COMPLETE ===

Study: ds000105 — Haxby et al. (2001) MVPA Object Recognition
Directory: test/replications/ds000105/

Dataset:
  Subjects: 6 total (2 downloaded)
  Modality: fMRI (.nii.gz, GE 3T, TR=2.5s)
  Task: objectviewing (8 categories, 12 runs)
  Status: ✓ validated (2 subjects)

Paper Pipeline:
  extracted_pipeline.md: ✓ written (156 lines)
  required_references.md: ✓ written (105 lines)
  Config YAML: ✓ written (104 lines)

Gaps to Fill:
  CRITICAL: fMRI loading — need nibabel (pip install nibabel)
  CRITICAL: GLM first-level model — need nilearn (pip install nilearn)
  CRITICAL: ROI masking — functional ROI at p<1e-6
  IMPORTANT: Split-half correlation wrapper function
  OPTIONAL: Brain map visualization (nilearn.plotting)

Additional References Needed:
  - Original paper PDF → place in references/
  - Hanson et al. (2004) re-analysis → for comparison

Next Steps:
  1. pip install nilearn nibabel
  2. Place original paper PDF in references/
  3. Download remaining 4 subjects
  4. Build fMRI analysis module (GLM + MVPA)
  5. Run /replicate-study to execute the replication
```

---

## Generated Files

| File | Lines | Description |
|------|-------|-------------|
| `configs/dataset_info.json` | 16 | Dataset metadata (6 subjects, 12 runs, 8 conditions) |
| `configs/ds000105_replication.yaml` | 104 | Full MVPA replication config |
| `references/methods/extracted_pipeline.md` | 156 | Complete pipeline extraction (13 sections) |
| `references/methods/required_references.md` | 105 | Required papers, code, gap analysis |

---

## Key Differences from Previous Tests

| Aspect | ds003645 (test 1) | ds004621 (test 2) | ds000105 (this test) |
|--------|-------------------|-------------------|---------------------|
| Install method | Skills already in project | Skills already in project | **install.sh from export package** |
| Working directory | Main project | Main project | **Isolated test/ subfolder** |
| Modality | EEG | EEG | **fMRI** (new modality!) |
| File format | EEGLAB .set/.fdt | BrainVision .vhdr | **NIfTI .nii.gz** |
| Analysis type | ERP (N170) | ERP (P300) | **MVPA split-half correlation** |
| Paper access | Local PDF | Web (PMC) | **Multiple web sources** |
| Toolbox support | Partial (EEG pipeline) | Partial (EEG pipeline) | **None** (entire fMRI module needed) |

## Observations

1. **install.sh worked** after fixing CRLF line endings (WSL issue — should add `dos2unix` or use LF in Write tool)
2. **Skill handled fMRI** — correctly identified it as a completely different modality from EEG
3. **Multiple web sources needed** — no single source had full methods; combined PubMed + Zenodo + PMC review
4. **Gap analysis was comprehensive** — correctly identified that the ENTIRE fMRI pipeline is missing (3 critical gaps)
5. **MVPA config format worked** — the YAML config naturally extended to include `mvpa:` and `roi:` sections
6. **Isolated test folder worked** — the skill doesn't depend on being in the main project
