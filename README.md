# OpenNeuro Replication Skills for Claude Code

A set of Claude Code skills that automate neuroscience study replication workflows. These skills guide Claude through downloading OpenNeuro datasets, extracting analysis pipelines from papers, generating documentation, and running replications.

## What Are Skills?

[Claude Code skills](https://docs.anthropic.com/en/docs/claude-code) are markdown instruction files placed in `.claude/skills/` within any project. They activate automatically when a user's message matches their keywords. Skills are prompt-based workflows — no code execution engine required.

## Included Skills

| Skill | Trigger Keywords | What It Does |
|-------|-----------------|--------------|
| **setup-replication** | `setup replication`, `new replication`, `prepare replication` | Full 8-step workflow: create folders, download data, fetch paper, extract pipeline, generate configs, identify gaps |
| **replicate-study** | `replicate`, `replication`, `reproduce` | Execute a replication analysis: load data, preprocess, analyze, compare with paper results |
| **analyze-paper** | `extract methods`, `read paper`, `paper methods` | Extract complete methodology from a paper (DOI, URL, or PDF) into structured format |
| **resolve-dependencies** | `install`, `dependency`, `missing package` | Detect, install, and resolve Python dependencies for neuroscience analyses |

## Workflow Order

```
/setup-replication ds003645 [--demo]
       │
       ├── Downloads dataset from OpenNeuro (all subjects, or 2 with --demo)
       ├── Creates replications/{id}/ folder structure
       ├── Reads paper PDF and extracts pipeline
       ├── Generates extracted_pipeline.md
       ├── Generates required_references.md
       ├── Generates replication config YAML
       └── Identifies gaps (missing toolbox features)
       │
       ▼
/replicate-study ds003645
       │
       ├── Loads config YAML
       ├── Downloads remaining subjects (if needed)
       ├── Runs preprocessing pipeline
       ├── Runs ERP/fMRI/MEG analysis
       ├── Compares results with paper
       └── Generates replication report
```

## Installation

### Quick Install (copy files)

```bash
# Clone this repo
git clone https://github.com/vibeneurocoder/openneuro-replication-skills.git

# Copy skills into your project
cp -r neuroscience-replication-skills/skills/ YOUR_PROJECT/.claude/skills/
```

### One-liner

```bash
# From your project root
mkdir -p .claude/skills && curl -sL https://github.com/vibeneurocoder/openneuro-replication-skills/archive/main.tar.gz | tar xz --strip-components=2 -C .claude/skills/ "*/skills/"
```

### Install Script

```bash
# Clone and run the installer
git clone https://github.com/vibeneurocoder/openneuro-replication-skills.git
cd neuroscience-replication-skills
bash install.sh /path/to/your/project
```

## Usage

Once skills are in `.claude/skills/`, they activate automatically in Claude Code:

```
# Full setup — downloads ALL subjects into data/
> setup replication ds003645

# Demo mode — downloads only 2 subjects into demo_data/ (for quick testing)
> setup replication ds003645 --demo

# With a paper source
> setup replication ds004621 --paper https://doi.org/10.1093/gigascience/giac015

# Demo + paper
> setup replication ds000105 --demo --paper references/haxby2001.pdf

# Extract methods from a paper
> read paper replications/ds003645/references/paper.pdf

# Check dependencies
> what packages do I need for this replication?

# Run the replication
> replicate study ds003645
```

### Full vs Demo Mode

| | Full (default) | Demo (`--demo`) |
|---|---|---|
| **Subjects** | All subjects | 2 subjects only |
| **Data directory** | `data/{dataset_id}/` | `demo_data/{dataset_id}/` |
| **Use case** | Production replication with group statistics | Quick pipeline validation, testing |
| **Disk space** | Full dataset (can be 10-100+ GB for fMRI) | Minimal (~1-2 GB) |

After validating your pipeline in demo mode, re-run without `--demo` to download the full dataset.

## Prerequisites

### Python Environment

The skills assume a neuroscience Python environment. Minimum requirements:

```bash
pip install numpy scipy matplotlib pandas mne
```

Full environment (recommended):

```bash
conda create -n neuro-replication python=3.12
conda activate neuro-replication
conda install -c conda-forge mne numpy scipy matplotlib pandas seaborn jupyter
pip install pingouin statsmodels
```

### AWS CLI (for OpenNeuro downloads)

```bash
pip install awscli
# No credentials needed — OpenNeuro is public
```

### Claude Code

Install [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (Anthropic's CLI for Claude):

```bash
npm install -g @anthropic-ai/claude-code
```

## What Gets Generated

After running `/setup-replication`, you get:

```
# Data (full mode → data/, demo mode → demo_data/)
data/{dataset_id}/                       # or demo_data/{dataset_id}/
├── dataset_description.json
├── participants.tsv
├── sub-01/                              # All subjects (full) or 2 (demo)
│   └── eeg/ or func/ or meg/
├── sub-02/
└── ...

# Analysis setup (always in replications/)
replications/{dataset_id}/
├── references/
│   ├── methods/
│   │   ├── extracted_pipeline.md    # Full pipeline with exact parameters
│   │   └── required_references.md   # Papers, code repos, gap analysis
│   └── (place paper PDFs here)
├── figures/
├── results/
└── configs/
    ├── dataset_info.json            # Dataset metadata (includes demo_mode flag)
    └── {dataset_id}_replication.yaml # Pipeline config
```

### Example: extracted_pipeline.md

Contains numbered preprocessing steps with exact parameters from the paper:

```markdown
## 4. Preprocessing Pipeline (Exact from Paper)

### Step 1: Import raw data
Software: EEGLAB 2019.1, ERPLAB 8.0

### Step 2: High-pass filter
- Cutoff: 0.1 Hz
- Type: Butterworth IIR, 2nd order (12 dB/oct)

### Step 3: Low-pass filter
- Cutoff: 30 Hz (Butterworth, same order)
...
```

### Example: replication config YAML

```yaml
name: "N170 Face Perception Replication (ERP CORE)"
dataset:
  id: ds003645
  subjects: null  # all subjects
analysis:
  type: erp
  preprocessing:
    filter_lowcut: 0.1
    filter_highcut: 30.0
    artifact_threshold: 100.0
    baseline: [-0.2, 0.0]
    epoch_window: [-0.2, 0.8]
  erp:
    component: N170
    time_window: [0.11, 0.15]
    channels: [PO8]
    measure: mean
    mode: neg
```

## Adapting for Other Projects

The skills are designed for a neuroscience toolbox with specific modules (`toolbox/preprocessing/`, `toolbox/analysis/`, etc.), but they adapt to any project:

1. **The methodology extraction works universally** — it reads papers and generates structured documentation regardless of your analysis stack
2. **The config YAML format is generic** — use it as input to MNE-Python, your own scripts, or any pipeline
3. **The gap analysis** references toolbox capabilities listed in `setup-replication.md` — update the "Toolbox capability reference" section to match your own codebase

### Customization Points

In `setup-replication.md`:
- **Line ~327**: Update "Toolbox capability reference" to list YOUR project's capabilities
- **Line ~426**: Update "Known Datasets Quick Reference" with datasets you work with
- **Step 3**: Update download commands for your data access method

In `replicate-study.md`:
- **Step 4**: Update pipeline builder references for your framework
- **"Available Tools"** section: List your project's modules

## Adapting for Other Agent Frameworks

The skills are Claude Code-specific (markdown files in `.claude/skills/`), but the domain knowledge transfers:

| Target Framework | How to Adapt |
|-----------------|--------------|
| **LangChain** | Convert each skill to a chain/agent prompt. Steps become tool calls. |
| **AutoGen** | Convert to agent system messages. Each skill = one specialized agent. |
| **CrewAI** | Each skill = one crew member's backstory + goal. |
| **OpenAI Assistants** | Convert to assistant instructions. Use file_search for paper reading. |
| **Custom LLM app** | Use the skill text as system prompts. The methodology extraction sections work with any LLM. |

The key asset is the **structured methodology extraction template** (Step 5 of setup-replication) — this works regardless of framework.

## Examples

See the `examples/` directory for full execution logs:

- **[demo_setup_ds003645.md](examples/demo_setup_ds003645.md)** — EEG warm test with local PDF (Kappenman et al. 2021 ERP CORE, N170 face perception)
- **[demo_setup_ds004621.md](examples/demo_setup_ds004621.md)** — EEG cold test on unknown dataset (Dzianok et al. 2022 Nencki-Symfonia, P300 auditory oddball)
- **[demo_setup_ds000105.md](examples/demo_setup_ds000105.md)** — fMRI test in isolated folder (Haxby et al. 2001, MVPA object recognition)
- **[demo_setup_ds006480.md](examples/demo_setup_ds006480.md)** — EEG EGI HydroCel test (Kim et al. 2025, P300 oddball under arousal)

Key findings from testing:
- The skill handled a completely unknown dataset with zero prior codebase references
- WebFetch worked as paper source when no PDF was available
- New file formats (BrainVision .vhdr) were correctly identified as gaps
- Event code mapping from BIDS events.tsv worked correctly
- fMRI datasets (NIfTI .nii.gz) worked — skill correctly identified the entire fMRI module as missing
- Install script (`install.sh`) worked in an isolated subfolder

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
