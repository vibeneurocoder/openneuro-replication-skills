# OpenNeuro Replication Skills for Claude Code

A set of [Claude Code skills](https://docs.anthropic.com/en/docs/claude-code) that automate neuroscience study replication workflows. Downloads OpenNeuro datasets, extracts analysis pipelines from papers, generates documentation, and runs replications with verification checkpoints and publication-quality output.

## Included Skills

| Skill | Command | What It Does |
|-------|---------|--------------|
| **setup-replication** | `/setup-replication ds003645` | Full 9-step workflow: create folders, planning files, download data, fetch paper, extract pipeline, generate configs, verify setup |
| **replicate-study** | `/replicate-study ds003645` | Execute replication: load data, preprocess, analyze, verify results, generate pub-quality figures, compare with paper |
| **analyze-paper** | `/analyze-paper paper.pdf` | Extract complete methodology from a paper (DOI, URL, or PDF) into structured format |
| **resolve-dependencies** | `/resolve-dependencies` | Detect, install, and resolve Python dependencies for neuroscience analyses |

## Required Skills Together

A full replication needs three skill layers working together. Install all three for the complete workflow.

### Layer 1: Core Replication (this repo — required)

These four skills orchestrate the entire replication pipeline:

| Skill | Stage | What It Does |
|-------|-------|--------------|
| `setup-replication` | 1. Setup | Creates folders, planning files, downloads data, extracts pipeline, generates configs |
| `analyze-paper` | 2. Extraction | Reads PDF, extracts exact preprocessing/analysis/statistics parameters |
| `resolve-dependencies` | 3. Environment | Installs Python packages (pingouin, seaborn, statsmodels, mne, scipy) |
| `replicate-study` | 4. Execution | Runs full analysis with verification checkpoints, pub figures, paper comparison |

### Layer 2: Workflow & Quality (academic-forge — recommended)

These companion skills from [`academic-forge`](https://github.com/anthropics/courses/tree/master/claude-code/skills) provide the methodology that the replication skills build on:

| Skill | Used By | Why Needed |
|-------|---------|------------|
| **writing-plans** | `setup-replication` | File-based planning methodology (`task_plan.md`, `findings.md`, `progress.md`) |
| **verification-before-completion** | `replicate-study` | No completion claims without running evidence — prevents false positives |
| **scientific-visualization** | `replicate-study` | Okabe-Ito colorblind-safe palette, 300 DPI, multi-panel figure standards |
| **systematic-debugging** | `replicate-study` | Root-cause analysis when results diverge from paper (not guessing) |
| **executing-plans** | `replicate-study` | Task-by-task execution with checkpoints |

> The core replication skills have these practices **baked in** — you don't invoke them separately. But having the academic-forge skills installed gives Claude the full reference when it needs deeper guidance on any aspect.

### Layer 3: Domain API Reference (neuroforge-skills — optional)

These provide library-specific API documentation for the neuroscience packages used in replications:

| Skill | When Needed |
|-------|-------------|
| **mne-python** | EEG/MEG preprocessing, epoching, filtering, source localization |
| **nilearn** | fMRI studies — GLM, MVPA, ROI analysis, brain plotting |
| **spikeinterface** | Extracellular electrophysiology / spike sorting |
| **brian2** | Computational neuroscience simulations |
| **pynibs** | Brain stimulation (TMS/NIBS) studies |

### Installation — All Three Layers

```bash
# Layer 1: Core replication skills (required)
git clone https://github.com/vibeneurocoder/openneuro-replication-skills.git
cp -r openneuro-replication-skills/skills/* YOUR_PROJECT/.claude/skills/

# Layer 2: Academic-forge workflow skills (recommended)
# Install from .opencode/skills/academic-forge/ — provides writing-plans,
# verification-before-completion, scientific-visualization, systematic-debugging

# Layer 3: Neuroforge domain skills (optional, as needed)
# Install mne-python, nilearn, etc. skills for API reference
```

### Workflow — How They Connect

```
/setup-replication ds003645 --paper references/paper.pdf
│
├─ Layer 1: setup-replication creates folders, downloads data
├─ Layer 2: writing-plans → creates task_plan.md, findings.md, progress.md
├─ Layer 1: analyze-paper → extracts pipeline from PDF
└─ Layer 1: resolve-dependencies → installs pingouin, seaborn, etc.

/replicate-study ds003645
│
├─ Layer 1: replicate-study runs preprocessing + analysis
├─ Layer 3: mne-python / scipy API reference (as needed)
├─ Layer 2: scientific-visualization → Okabe-Ito, 300 DPI, multi-panel
├─ Layer 2: verification-before-completion → checkpoints at each stage
├─ Layer 2: systematic-debugging → if results diverge from paper
└─ Layer 1: generates replication report + updates findings.md
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
