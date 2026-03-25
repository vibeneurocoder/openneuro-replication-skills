# OpenNeuro Replication Skills for Claude Code

A set of [Claude Code skills](https://docs.anthropic.com/en/docs/claude-code) that automate neuroscience study replication workflows. Downloads OpenNeuro datasets, extracts analysis pipelines from papers, generates documentation, and runs replications with verification checkpoints and publication-quality output. Covers EEG, fMRI, and MEG modalities with full API-grounded references for MNE-Python, nilearn, pingouin, and scipy — plus MATLAB-to-Python mapping for EEGLAB, FieldTrip, and SPM papers.

## Architecture

Each skill follows a **multi-layer architecture** with API-grounded reference documents:

```
skills/
├── replicate-study/
│   ├── SKILL.md                     ← Primary skill (workflow + tested code snippets)
│   ├── references/                  ← Deep-dive API docs per domain
│   │   ├── eeg-data-loading.md      ← mne.io, scipy.io, mne-bids, montage templates
│   │   ├── preprocessing-pipeline.md ← filter, reference, epoch, ICA with param tables
│   │   ├── erp-analysis.md          ← ERP computation, peak detection, grand average, TF
│   │   ├── statistics-and-comparison.md ← pingouin, MNE stats, replication comparison
│   │   ├── fmri-replication.md      ← nilearn GLM, MVPA, atlases (AAL, Schaefer, HO), connectivity
│   │   └── publication-figures.md   ← ERP/topo/TF/brain/surface templates, Okabe-Ito
│   └── assets/
│       ├── api-quick-reference.md   ← Compact function lookup (montages, atlases, viz)
│       └── openneuro-format-guide.md ← BIDS structure, file formats, download patterns
│
├── analyze-paper/
│   ├── SKILL.md                     ← Paper extraction with Python mapping
│   └── references/
│       └── method-vocabulary.md     ← Every neuro method term → exact Python function
│
├── setup-replication/
│   ├── SKILL.md                     ← 9-step setup workflow
│   ├── references/
│   │   ├── toolbox-capabilities.md  ← Gap analysis with function signatures
│   │   └── openneuro-data-access.md ← AWS S3 patterns, BIDS validation, metadata
│   └── assets/
│       └── templates.md             ← File templates for generated docs
│
└── resolve-dependencies/
    ├── SKILL.md                     ← Dependency resolution with version matrix
    └── references/
        └── package-api-mapping.md   ← EEGLAB/FieldTrip/SPM/FSL/R → Python function mapping,
                                       brain atlases (AAL, Harvard-Oxford, Schaefer, Yeo, DiFuMo),
                                       EEG montage templates (10-20, EGI, BioSemi, EasyCap),
                                       nilearn/MNE visualization tool reference
```

### What makes this detailed

Every reference doc provides:
- **Exact function signatures** with source locations
- **Parameter tables** (type, default, description)
- **Tested code examples** matching common paper descriptions
- **Pitfalls** section for each API (common mistakes and edge cases)
- **Paper-to-code mapping** ("paper says X" → `function(params)`)
- **Brain atlas reference** — AAL, Harvard-Oxford, Schaefer, Destrieux, Yeo, Talairach, DiFuMo, Pauli with fetch functions and region labels
- **EEG montage templates** — Standard 10-20, 10-05, EGI HydroCel (32–257ch), BioSemi (16–256ch), EasyCap, with channel name mapping tables
- **Visualization tools** — ERP waveforms, topomaps, joint plots, TF images, butterfly plots, GFP, ICA components, brain activation maps, surface projections, connectomes, ROI overlays

## Included Skills

| Skill | Command | What It Does |
|-------|---------|--------------|
| **setup-replication** | `/setup-replication ds003645` | Full 9-step workflow: create folders, planning files, download data, fetch paper, extract pipeline, generate configs, verify setup |
| **replicate-study** | `/replicate-study ds003645` | Execute replication: load data, preprocess, analyze, verify results, generate pub-quality figures, compare with paper |
| **analyze-paper** | `/analyze-paper paper.pdf` | Extract complete methodology from a paper (DOI, URL, or PDF) and map every step to Python |
| **resolve-dependencies** | `/resolve-dependencies` | Detect, install, and resolve Python dependencies with MATLAB → Python function mapping |

## How It Works — Self-Contained with Optional Companions

**These skills work standalone.** All methodology (planning, verification, visualization, debugging) is written directly into the skill files — no other skills are required.

The practices were originally learned from two companion skill collections. We integrated the best parts into the replication skills so you don't need to install them separately:

### Optional: Academic-Forge (workflow methodology)

By [@HughYau](https://github.com/HughYau/AcademicForge) — a collection of workflow skills that bundles contributions from multiple authors:
- **superpowers** (by [@obra](https://github.com/obra/superpowers)) — verification-before-completion, systematic-debugging, executing-plans
- **planning-with-files** (by [@OthmanAdi](https://github.com/OthmanAdi/planning-with-files)) — file-based planning with task_plan.md
- **scientific-visualization** — publication figure standards
- **AI-research-SKILLs** (by [@zechenzhangAGI](https://github.com/zechenzhangAGI/AI-research-SKILLs) / Orchestra Research) — research workflow skills
- **claude-scientific-skills** (by [K-Dense-AI](https://github.com/K-Dense-AI/claude-scientific-skills)) — 140+ scientific domain skills

```bash
# Optional: install for full reference docs
git clone https://github.com/HughYau/AcademicForge.git
```

### Optional: NeuroForge Skills (domain API reference)

By [@HughYau](https://github.com/HughYau/neuroforge-skills) — neuroscience library API documentation built with the [OpenSci-Skill](https://github.com/HughYau/opensci-skill) framework:

| Skill | Library | Coverage |
|-------|---------|----------|
| **mne-python** | MNE-Python | EEG/MEG preprocessing, epoching, filtering, source localization |
| **nilearn** | nilearn | fMRI — GLM, MVPA, ROI analysis, brain plotting |
| **spikeinterface** | SpikeInterface | Extracellular electrophysiology / spike sorting |
| **brian2** | Brian2 | Spiking neural network simulations |
| **pynibs** | pyNIBS | Non-invasive brain stimulation (TMS/NIBS) |
| **spm12** | SPM12 (MATLAB) | fMRI GLM, VBM, EEG source reconstruction, DCM, batch scripting |
| **eeglab** | EEGLAB (MATLAB) | EEG data import, filtering, ICA, epoching, ERP, time-frequency, STUDY |
| **fieldtrip** | FieldTrip (MATLAB) | MEG/EEG preprocessing, TF analysis, source reconstruction, connectivity, cluster permutation |

The MATLAB toolbox skills (SPM12, EEGLAB, FieldTrip) are especially useful for replication — most neuroscience papers describe their methods in MATLAB terms. These skills provide exact function signatures and cfg parameter tables so the AI can map paper methods to Python equivalents.

```bash
# Optional: install for API reference
git clone https://github.com/HughYau/neuroforge-skills.git
```

## Installation

### Install Script

```bash
git clone https://github.com/vibeneurocoder/openneuro-replication-skills.git
cd openneuro-replication-skills
bash install.sh /path/to/your/project
```

### Manual Install

```bash
git clone https://github.com/vibeneurocoder/openneuro-replication-skills.git
cp -r openneuro-replication-skills/skills/* YOUR_PROJECT/.claude/skills/
```

This copies each skill directory (including `SKILL.md`, `references/`, and `assets/`) into your project's `.claude/skills/`.

### Resulting Structure

```
YOUR_PROJECT/.claude/skills/
├── setup-replication/
│   ├── SKILL.md
│   ├── references/
│   │   ├── toolbox-capabilities.md
│   │   └── openneuro-data-access.md
│   └── assets/
│       └── templates.md
├── replicate-study/
│   ├── SKILL.md
│   ├── references/
│   │   ├── eeg-data-loading.md
│   │   ├── preprocessing-pipeline.md
│   │   ├── erp-analysis.md
│   │   ├── statistics-and-comparison.md
│   │   ├── fmri-replication.md
│   │   └── publication-figures.md
│   └── assets/
│       ├── api-quick-reference.md
│       └── openneuro-format-guide.md
├── analyze-paper/
│   ├── SKILL.md
│   └── references/
│       └── method-vocabulary.md
└── resolve-dependencies/
    ├── SKILL.md
    └── references/
        └── package-api-mapping.md
```

## Usage

```
# Full setup — downloads ALL subjects into data/
> /setup-replication ds003645

# Demo mode — downloads only 2 subjects into demo_data/ (for quick testing)
> /setup-replication ds003645 --demo

# With a paper source
> /setup-replication ds004621 --paper https://doi.org/10.1093/gigascience/giac015

# Extract methods from a paper
> /analyze-paper replications/ds003645/references/paper.pdf

# Check dependencies
> /resolve-dependencies

# Run the replication
> /replicate-study ds003645
```

### Full vs Demo Mode

| | Full (default) | Demo (`--demo`) |
|---|---|---|
| **Subjects** | All subjects | 2 subjects only |
| **Data directory** | `data/{dataset_id}/` | `demo_data/{dataset_id}/` |
| **Use case** | Production replication with group statistics | Quick pipeline validation, testing |
| **Disk space** | Full dataset (can be 10-100+ GB for fMRI) | Minimal (~1-2 GB) |

## Prerequisites

```bash
# ERP replication (most common)
pip install mne pingouin matplotlib pandas scipy numpy autoreject

# fMRI replication
pip install nilearn nibabel matplotlib pandas scipy numpy pingouin

# Full stack
pip install mne nilearn nibabel pingouin statsmodels autoreject \
    mne-bids matplotlib pandas scipy numpy seaborn scikit-learn

# AWS CLI for OpenNeuro downloads (no credentials needed)
pip install awscli

# Claude Code
npm install -g @anthropic-ai/claude-code
```

## What Gets Generated

After running `/setup-replication`:

```
project_root/
├── task_plan.md                       # Phase tracker with status
├── findings.md                        # Paper values + replication results
├── progress.md                        # Session activity log
└── replications/{dataset_id}/
    ├── references/
    │   ├── methods/
    │   │   ├── extracted_pipeline.md  # Full pipeline with exact parameters
    │   │   └── required_references.md # Papers, code repos, gap analysis
    │   └── (place paper PDFs here)
    ├── figures/                        # Publication-quality figures (PNG + PDF)
    ├── results/                        # CSV results, run logs
    └── configs/
        ├── dataset_info.json          # Dataset metadata
        └── {dataset_id}_replication.yaml # Pipeline config
```

## Examples

See the [`examples/`](examples/) directory for full execution logs covering EEG and fMRI datasets.

## Supported Paradigms & Datasets

| Paradigm | Example Dataset | Status |
|----------|----------------|--------|
| N170 (face perception) | ds003645 (Wakeman & Henson 2015) | **Fully replicated** (18 subjects, RM-ANOVA, pub figures) |
| N170 (face perception) | ds000117 | Tested (setup) |
| P300 (auditory oddball) | ds004621, ds003061, ds006480 | Tested (setup) |
| P300 under arousal | ds006480 (EGI HydroCel) | Tested (setup) |
| MMN (mismatch negativity) | ds003645 (MMN task) | Planned |
| fMRI MVPA | ds000105 | Tested (setup) |

## License

MIT License. See [LICENSE](LICENSE).
