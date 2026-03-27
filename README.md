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

## How to Use

### Quick Start

```bash
# 1. Install the replication skills
git clone https://github.com/vibeneurocoder/openneuro-replication-skills.git
cd openneuro-replication-skills && bash install.sh /path/to/your/project

# 2. Install companion skills (workflow methodology + domain API reference)
git clone https://github.com/HughYau/AcademicForge.git
cp -r AcademicForge/.opencode/skills/academic-forge/* YOUR_PROJECT/.claude/skills/

git clone https://github.com/HughYau/neuroforge-skills.git
cp -r neuroforge-skills/skills/* YOUR_PROJECT/.claude/skills/

# 3. Set up a replication (downloads data, reads paper, generates docs)
> /setup-replication ds003645

# 4. Extract methods from the paper
> /analyze-paper replications/ds003645/references/paper.pdf

# 5. Check and install dependencies
> /resolve-dependencies

# 6. Run the full replication
> /replicate-study ds003645
```

### Companion Skill Collections

These replication skills are part of a broader ecosystem. For full functionality, install the companion collections:

#### Academic-Forge (workflow methodology)

By [@HughYau](https://github.com/HughYau/AcademicForge) — provides the engineering discipline practices used throughout the replication workflow: verification checkpoints, systematic debugging, file-based planning, and scientific visualization standards. Bundles contributions from multiple authors (see [Acknowledgements](#acknowledgements)).

```bash
git clone https://github.com/HughYau/AcademicForge.git
cp -r AcademicForge/.opencode/skills/academic-forge/* YOUR_PROJECT/.claude/skills/
```

#### NeuroForge Skills (domain API reference)

By [@HughYau](https://github.com/HughYau/neuroforge-skills) — detailed API documentation for neuroscience libraries built with the [OpenSci-Skill](https://github.com/HughYau/opensci-skill) framework. Provides exact function signatures, parameter tables, and tested code snippets. The MATLAB toolbox skills (SPM12, EEGLAB, FieldTrip) are especially useful — most neuroscience papers describe their methods in MATLAB terms, and these skills help the AI map paper methods to Python equivalents.

```bash
git clone https://github.com/HughYau/neuroforge-skills.git
cp -r neuroforge-skills/skills/* YOUR_PROJECT/.claude/skills/
```

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

## Usage Examples

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

## Acknowledgements

This project builds on work from several open-source skill collections and their authors.

### Companion Skill Authors

- **[@HughYau](https://github.com/HughYau)** — [Academic-Forge](https://github.com/HughYau/AcademicForge) (curated academic workflow skills), [NeuroForge Skills](https://github.com/HughYau/neuroforge-skills) (neuroscience library API documentation for MNE-Python, nilearn, SpikeInterface, Brian2, pyNIBS, SPM12, EEGLAB, FieldTrip), and [OpenSci-Skill](https://github.com/HughYau/opensci-skill) (the framework for generating symbol indices and API docs)
- **[@obra](https://github.com/obra)** — [superpowers](https://github.com/obra/superpowers) — verification-before-completion, systematic-debugging, executing-plans, and other engineering discipline skills
- **[@OthmanAdi](https://github.com/OthmanAdi)** — [planning-with-files](https://github.com/OthmanAdi/planning-with-files) — file-based task planning methodology (task_plan.md, findings.md, progress.md)
- **[@zechenzhangAGI](https://github.com/zechenzhangAGI) / [Orchestra AI](https://github.com/orchestra-ai)** — [AI-research-SKILLs](https://github.com/zechenzhangAGI/AI-research-SKILLs) — research workflow skills for AI/ML development and training pipelines
- **[K-Dense-AI](https://github.com/K-Dense-AI)** — [claude-scientific-skills](https://github.com/K-Dense-AI/claude-scientific-skills) — 140+ scientific domain skills covering bioinformatics, cheminformatics, clinical research, and more

### Practices Integrated

| Practice | Origin | Where It's Used |
|----------|--------|----------------|
| File-based planning | planning-with-files | `setup-replication` Step 2b — creates `task_plan.md`, `findings.md`, `progress.md` |
| Verification-before-completion | superpowers | `setup-replication` Step 8, `replicate-study` Step 7a — no completion claims without evidence |
| Scientific visualization standards | Academic-Forge | `replicate-study` Step 6 — Okabe-Ito palette, 300 DPI, multi-panel figures |
| Systematic debugging | superpowers | `replicate-study` Step 7c — root-cause analysis for result discrepancies |
| Method-to-code mapping | NeuroForge Skills | `analyze-paper` and `resolve-dependencies` — MATLAB → Python function mapping |
| Research workflow patterns | Orchestra AI / AI-research-SKILLs | Structured approach to literature review, experiment tracking, and reproducibility |

## License

MIT License. See [LICENSE](LICENSE).
