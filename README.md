# OpenNeuro Replication Skills for Claude Code

A set of [Claude Code skills](https://docs.anthropic.com/en/docs/claude-code) that automate neuroscience study replication workflows. Downloads OpenNeuro datasets, extracts analysis pipelines from papers, generates documentation, and runs replications.

## Included Skills

| Skill | Command | What It Does |
|-------|---------|--------------|
| **setup-replication** | `/setup-replication ds003645` | Full 8-step workflow: create folders, download data, fetch paper, extract pipeline, generate configs, identify gaps |
| **replicate-study** | `/replicate-study ds003645` | Execute a replication analysis: load data, preprocess, analyze, compare with paper results |
| **analyze-paper** | `/analyze-paper paper.pdf` | Extract complete methodology from a paper (DOI, URL, or PDF) into structured format |
| **resolve-dependencies** | `/resolve-dependencies` | Detect, install, and resolve Python dependencies for neuroscience analyses |

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
# Python environment
pip install numpy scipy matplotlib pandas mne

# AWS CLI for OpenNeuro downloads (no credentials needed)
pip install awscli

# Claude Code
npm install -g @anthropic-ai/claude-code
```

## What Gets Generated

After running `/setup-replication`:

```
replications/{dataset_id}/
├── references/
│   ├── methods/
│   │   ├── extracted_pipeline.md    # Full pipeline with exact parameters
│   │   └── required_references.md   # Papers, code repos, gap analysis
│   └── (place paper PDFs here)
├── figures/
├── results/
└── configs/
    ├── dataset_info.json            # Dataset metadata
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
| N170 (face perception) | ds003645, ds000117 | Tested |
| P300 (auditory oddball) | ds004621, ds003061, ds006480 | Tested |
| P300 under arousal | ds006480 (EGI HydroCel) | Tested (setup) |
| MMN (mismatch negativity) | ds003645 (MMN task) | Planned |
| fMRI MVPA | ds000105 | Tested (setup) |

## License

MIT License. See [LICENSE](LICENSE).
