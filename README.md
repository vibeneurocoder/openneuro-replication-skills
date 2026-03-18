# OpenNeuro Replication Skills for Claude Code

A set of [Claude Code skills](https://docs.anthropic.com/en/docs/claude-code) that automate neuroscience study replication workflows. Downloads OpenNeuro datasets, extracts analysis pipelines from papers, generates documentation, and runs replications with verification checkpoints and publication-quality output.

## Included Skills

| Skill | Command | What It Does |
|-------|---------|--------------|
| **setup-replication** | `/setup-replication ds003645` | Full 9-step workflow: create folders, planning files, download data, fetch paper, extract pipeline, generate configs, verify setup |
| **replicate-study** | `/replicate-study ds003645` | Execute replication: load data, preprocess, analyze, verify results, generate pub-quality figures, compare with paper |
| **analyze-paper** | `/analyze-paper paper.pdf` | Extract complete methodology from a paper (DOI, URL, or PDF) into structured format |
| **resolve-dependencies** | `/resolve-dependencies` | Detect, install, and resolve Python dependencies for neuroscience analyses |

## How It Works — Self-Contained with Optional Companions

**These skills work standalone.** All methodology (planning, verification, visualization, debugging) is written directly into the skill files — no other skills are required.

The practices were originally learned from two companion skill collections. We integrated the best parts into the replication skills so you don't need to install them separately. But if you want the full reference materials, you can optionally install the originals:

### Optional: Academic-Forge (workflow methodology)

By [@HughYau](https://github.com/HughYau/AcademicForge) — a collection of workflow skills that bundles contributions from multiple authors:
- **superpowers** (by [@obra](https://github.com/obra/superpowers)) — verification-before-completion, systematic-debugging, executing-plans
- **planning-with-files** (by [@OthmanAdi](https://github.com/OthmanAdi/planning-with-files)) — file-based planning with task_plan.md
- **scientific-visualization** — publication figure standards
- **AI-research-SKILLs** (by [@zechenzhangAGI](https://github.com/zechenzhangAGI/AI-research-SKILLs) / Orchestra Research) — research workflow skills
- **claude-scientific-skills** (by [K-Dense-AI](https://github.com/K-Dense-AI/claude-scientific-skills)) — 140+ scientific domain skills

What's baked into our skills from academic-forge:
| Practice | Where It's Used | What It Does |
|----------|----------------|--------------|
| File-based planning | `setup-replication` Step 2b | Creates `task_plan.md`, `findings.md`, `progress.md` |
| Verification-before-completion | `setup-replication` Step 8, `replicate-study` Step 6a | No completion claims without running evidence |
| Scientific visualization | `replicate-study` Step 5b | Okabe-Ito palette, 300 DPI, multi-panel figures |
| Systematic debugging | `replicate-study` Step 6c | Root-cause analysis for result discrepancies |

```bash
# Optional: install for full reference docs
git clone https://github.com/HughYau/AcademicForge.git
```

### Optional: NeuroForge Skills (domain API reference)

By [@HughYau](https://github.com/HughYau/neuroforge-skills) — neuroscience library API documentation built with the [OpenSci-Skill](https://github.com/HughYau/opensci-skill) framework:

| Skill | Library |
|-------|---------|
| **mne-python** | EEG/MEG preprocessing, epoching, filtering, source localization |
| **nilearn** | fMRI — GLM, MVPA, ROI analysis, brain plotting |
| **spikeinterface** | Extracellular electrophysiology / spike sorting |
| **brian2** | Spiking neural network simulations |
| **pynibs** | Non-invasive brain stimulation (TMS/NIBS) |

These provide detailed API docs that Claude can reference when writing analysis code. Not required — Claude already knows these libraries from training, but the skills give more accurate, up-to-date API details.

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

This copies each skill directory (containing `SKILL.md`) into your project's `.claude/skills/`.

### Resulting Structure

```
YOUR_PROJECT/.claude/skills/
├── setup-replication/
│   └── SKILL.md
├── replicate-study/
│   └── SKILL.md
├── analyze-paper/
│   └── SKILL.md
└── resolve-dependencies/
    └── SKILL.md
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
# Python environment (core + replication stack)
pip install numpy scipy matplotlib pandas mne pingouin statsmodels seaborn

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

## Adapting for Other Projects

The skills reference specific toolbox modules (`toolbox/preprocessing/`, etc.) but adapt to any project:

1. **Methodology extraction works universally** — reads papers and generates structured docs regardless of your stack
2. **Config YAML is generic** — use as input to MNE-Python, your own scripts, or any pipeline
3. **Gap analysis** — update the "Toolbox capability reference" in `setup-replication/SKILL.md` to match your codebase

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
