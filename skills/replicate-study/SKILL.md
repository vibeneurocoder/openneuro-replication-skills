---
name: replicate-study
description: Replicate a neuroscience study from a paper and OpenNeuro dataset — load data, preprocess, analyze, and compare results with the original paper. Use when the user wants to replicate, reproduce, or re-run a study analysis.
user-invocable: true
argument-hint: "<dataset_id>"
---

# Neuroscience Study Replication

You are an expert neuroscience methods replicator. When the user asks to replicate a study, follow this process:

> **Tip**: Run `/setup-replication` first to automatically create folders, download data, and extract the paper's exact pipeline before running the replication.

## Step 1: Read the Paper

Ask the user for:
- Paper source (DOI, URL, or PDF path)
- OpenNeuro dataset ID (if they know it)

Extract from the paper:
- **Modality**: EEG, fMRI, MEG, iEEG (look for: electrode, BOLD, magnetometer, depth electrode)
- **Paradigm**: What task subjects performed
- **Preprocessing**: Filter settings, reference, artifact rejection, epoch window
- **Analysis method**: ERP components, MVPA, GLM, connectivity, spectral, source localization
- **Statistical tests**: t-test, ANOVA, permutation test, correction method
- **Reported results**: Effect sizes, p-values, accuracy, key findings

## Step 2: Identify What's Needed

For each method step in the paper, determine:
1. **Is there a Python equivalent?** Map the paper's toolbox to available packages:
   - EEGLAB/ERPLAB → MNE-Python + our toolbox
   - SPM/FSL/AFNI → nilearn + nibabel
   - FieldTrip → MNE-Python
   - MATLAB custom → write Python equivalent
   - R packages → scipy.stats equivalent

2. **Is the package installed?** Check with:
   ```python
   python3 -c "import package_name"
   ```

3. **If not installed**, tell the user:
   ```
   pip install package_name
   ```

4. **If no Python equivalent exists**, either:
   - Write custom code using numpy/scipy primitives
   - Ask the user for the cited reference paper that describes the method
   - Use the `custom_python` primitive in the pipeline builder

## Step 3: Resolve References

Papers often say "preprocessing followed Smith et al. (2005)". When you encounter this:
- Ask the user: "Can you provide Smith et al. 2005 or describe their preprocessing?"
- Search for the reference if it's a well-known method
- Common references and their meanings:
  - "Delorme & Makeig (2004)" → EEGLAB preprocessing defaults
  - "Oostenveld et al. (2011)" → FieldTrip toolbox
  - "Gramfort et al. (2013)" → MNE-Python
  - "Maris & Oostenveld (2007)" → cluster-based permutation test
  - "Haxby et al. (2001)" → split-half correlation MVPA
  - "Kriegeskorte et al. (2008)" → representational similarity analysis

## Step 4: Build the Pipeline

Use the project's pipeline builder to assemble steps:

```python
from neuro_replicator_mcp.pipeline_builder import list_primitives, validate_pipeline
from neuro_replicator_mcp.router import route

# Auto-detect analysis type
routing = route("paste methods text here")

# See available primitives
primitives = list_primitives(modality=routing["modality"])

# Build step sequence
steps = [
    {"primitive": "load_eeg", "params": {"..."}, "note": "why"},
    {"primitive": "bandpass_filter", "params": {"..."}, "note": "paper used X-Y Hz"},
]

# Validate
result = validate_pipeline(steps)
```

## Step 5: Handle Novel Methods

If the paper uses a method not in the primitives:

1. **Check if it's a combination of existing primitives**
   - e.g., "time-frequency connectivity" = compute_tfr + compute_correlation_matrix

2. **Write inline code** using the custom_python primitive:
   ```python
   {"primitive": "custom_python", "params": {
       "code": "from scipy.stats import spearmanr; r, p = spearmanr(x, y)",
       "description": "Spearman correlation between PAC and RT"
   }}
   ```

3. **Ask the user** if you can't figure out the method from the paper description

## Step 6: Run and Compare

After running the analysis, always compare against the paper:
- Match within 20% → strong replication
- Match within 50% → partial replication
- Larger discrepancy → investigate differences in preprocessing, sample, methods

Common reasons for discrepancies:
- Different artifact rejection thresholds
- Different filter implementations (FIR vs IIR)
- Different baseline correction
- Different channel selection
- Software-specific algorithm differences

## Available Tools

The project has these modules:
- `neuro_replicator_mcp/registry.py` — 17 analysis types catalog
- `neuro_replicator_mcp/router.py` — auto-detect modality + analysis from text
- `neuro_replicator_mcp/pipeline_builder.py` — 41 composable primitives
- `neuro_replicator_mcp/orchestrator.py` — step1→step2→step3→step4 flow
- `toolbox/preprocessing/` — filtering (SOS), epoching, artifacts
- `toolbox/analysis/` — ERP, statistics, time-frequency
- `toolbox/io/` — OpenNeuro download, BIDS loading

## OpenNeuro Data Access

All datasets are public on AWS S3:
```bash
aws s3 sync s3://openneuro.org/{dataset_id}/ ./data/{dataset_id}/ --no-sign-request
```

Or use the toolbox:
```python
from toolbox.io.openneuro import OpenNeuroDownloader
downloader = OpenNeuroDownloader()
downloader.download("ds000105", subjects=["sub-001", "sub-002"])
```

## Key Datasets

| ID | Study | Modality | Analysis |
|----|-------|----------|----------|
| ds003645 | ERP-CORE (Kappenman 2021) | EEG | N170, P300, N400, MMN, ERN |
| ds000117 | Wakeman & Henson 2015 | EEG/MEG/fMRI | Face processing N170 |
| ds000105 | Haxby 2001 | fMRI | MVPA object decoding |
| ds003061 | Cahn et al. 2012 | EEG | P300 auditory oddball |
| ds000246 | Jas et al. 2018 | MEG | Auditory M100 |
