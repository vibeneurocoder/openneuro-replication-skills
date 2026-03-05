# Demo: `/setup-replication ds006480 --demo`

## Dataset
- **ID**: ds006480
- **Title**: Young Adult Resting State and Auditory Oddball Task EEG
- **Paper**: Kim, Morales, Senior & Mather (2025)
- **DOI**: 10.1101/2025.10.02.680040
- **Modality**: EEG (EEGLAB .set)
- **System**: EGI HydroCel Geodesic Sensor Net (65 channels, 1000 Hz)

## What Was Tested
- New EEG system type (EGI with E-numbered channels vs standard 10-20)
- 3-stimulus auditory oddball paradigm
- Arousal manipulation (control vs threat-of-shock)
- Passive and active task conditions
- Demo mode (2 of 68 subjects)

## Steps Executed

### Step 1-2: Parse Input & Create Folders
```
replications/ds006480/
├── references/methods/
├── figures/
├── results/
└── configs/
```

### Step 3: Download Data (Demo Mode)
```bash
aws s3 sync s3://openneuro.org/ds006480/ demo_data/ds006480/ \
    --no-sign-request --exclude "sub-*"
# Then 2 subjects:
aws s3 sync s3://openneuro.org/ds006480/sub-01/ demo_data/ds006480/sub-01/ --no-sign-request
aws s3 sync s3://openneuro.org/ds006480/sub-02/ demo_data/ds006480/sub-02/ --no-sign-request
```
- Downloaded ~1.9 GB total (2 subjects)
- Validated: 68 subjects total, EEGLAB .set format, 65 EEG channels

### Step 4: Paper Source
- Primary: bioRxiv preprint (DOI: 10.1101/2025.10.02.680040) — methods limited
- Supplemented with: HeartBEAM protocol (PMC10941428), dataset metadata (sidecar JSON, events.tsv, channels.tsv, electrodes.tsv)

### Step 5-6: Extract Pipeline & Generate Docs
- Extracted 3-stimulus oddball event codes (standard/target/distractor × control/shock × passive/active)
- Identified EGI channel mapping challenge (E-numbered → 10-20)
- Preprocessing parameters inferred from standard P300 analysis (paper is preprint with limited detail)

### Step 7: Build Config
- Generated YAML with all event codes, ERP components (P3b, P3a, N200), and statistical comparisons
- Noted EGI channel approximations needing verification from electrodes.tsv

## Files Generated

| File | Lines | Content |
|------|-------|---------|
| `extracted_pipeline.md` | 127 | Full pipeline: participants, stimuli, conditions, recording, preprocessing, ERP, stats, gaps |
| `required_references.md` | 95 | 4 papers, 3 software packages, gap analysis with priorities |
| `ds006480_replication.yaml` | 120 | Complete config: events, channels, time windows, statistics |
| `dataset_info.json` | 35 | Dataset metadata with paper info and parent study |

## Gaps Identified

| Gap | Priority |
|-----|----------|
| Average re-reference | Critical |
| EGI channel mapping (E→10-20) | Critical |
| ICA artifact removal | Important |
| Repeated-measures ANOVA | Important |
| Grand average across subjects | Important |

## Key Differences from Previous Tests
- **vs ds003645 (ERP CORE)**: Different EEG system (EGI vs BioSemi), E-numbered channels, arousal manipulation
- **vs ds004621 (BrainVision)**: Different file format (.set vs .vhdr), different cap system
- **vs ds000105 (Haxby fMRI)**: Same modality class (EEG), but tests oddball paradigm support

## Result
All 8 steps completed successfully. The skill correctly handled:
- EGI HydroCel system with non-standard channel names
- Complex event coding (3 factors: stimulus × condition × task)
- Preprint with limited methods (supplemented from dataset metadata)
- Demo mode download of 2 subjects
