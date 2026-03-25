<!-- openneuro-replication-skills | domain: OpenNeuro Data Access -->

# Domain: OpenNeuro Data Access & BIDS Validation

Detailed reference for downloading, validating, and navigating OpenNeuro datasets.

---

## AWS S3 Download Patterns

All OpenNeuro datasets are hosted on a public S3 bucket. No credentials needed.

### Full Dataset Download

```bash
aws s3 sync --no-sign-request \
    s3://openneuro.org/ds003645 \
    data/ds003645/
```

### Demo Mode (2 Subjects)

```bash
# Step 1: Shared BIDS files (metadata, task descriptions, etc.)
aws s3 sync --no-sign-request \
    --exclude "sub-*" --exclude "derivatives/*" \
    s3://openneuro.org/ds003645 \
    data/ds003645/

# Step 2: List available subjects
aws s3 ls --no-sign-request s3://openneuro.org/ds003645/ | grep "PRE.*sub-"

# Step 3: Download first 2 subjects
aws s3 sync --no-sign-request \
    s3://openneuro.org/ds003645/sub-001/ \
    data/ds003645/sub-001/
aws s3 sync --no-sign-request \
    s3://openneuro.org/ds003645/sub-002/ \
    data/ds003645/sub-002/
```

### EEG-Only Download (Skip Other Modalities)

```bash
aws s3 sync --no-sign-request \
    --exclude "*_bold*" --exclude "*/anat/*" --exclude "*.nii*" \
    --exclude "*_meg*" --exclude "*.fif" \
    s3://openneuro.org/ds003645 \
    data/ds003645/
```

### Python Download Function

```python
import subprocess
from pathlib import Path

def download_openneuro(dataset_id, output_dir=None, subjects=None, exclude_modalities=None):
    """Download dataset from OpenNeuro via AWS S3.

    Args:
        dataset_id: OpenNeuro ID (e.g., 'ds003645')
        output_dir: Local destination (default: data/{dataset_id})
        subjects: List of subject IDs to download (e.g., ['001', '002']), or None for all
        exclude_modalities: List of modalities to exclude (e.g., ['meg', 'anat'])
    """
    output_dir = Path(output_dir or f"data/{dataset_id}")
    s3_base = f"s3://openneuro.org/{dataset_id}"
    base_cmd = ["aws", "s3", "sync", "--no-sign-request"]

    # Build exclusion args
    excludes = []
    if exclude_modalities:
        modality_patterns = {
            "meg": ["*_meg*", "*.fif", "*.fif.gz"],
            "fmri": ["*_bold*", "*.nii*"],
            "anat": ["*/anat/*"],
        }
        for mod in exclude_modalities:
            for pat in modality_patterns.get(mod, [f"*_{mod}*"]):
                excludes.extend(["--exclude", pat])

    if subjects is None:
        # Full download
        cmd = base_cmd + excludes + [s3_base, str(output_dir)]
        subprocess.run(cmd, check=True)
    else:
        # Shared files first
        cmd = base_cmd + ["--exclude", "sub-*", "--exclude", "derivatives/*"]
        cmd += [s3_base, str(output_dir)]
        subprocess.run(cmd, check=True)

        # Selected subjects
        for subj in subjects:
            subj_id = f"sub-{subj}" if not subj.startswith("sub-") else subj
            cmd = base_cmd + excludes
            cmd += [f"{s3_base}/{subj_id}/", str(output_dir / subj_id) + "/"]
            subprocess.run(cmd, check=True)

    return output_dir

# Examples:
# download_openneuro("ds003645")                          # Full
# download_openneuro("ds003645", subjects=["001", "002"]) # Demo
# download_openneuro("ds003645", exclude_modalities=["meg", "anat"])  # EEG only
```

### Estimating Dataset Size

```bash
# Total size (may take a few seconds)
aws s3 ls --no-sign-request --summarize --recursive s3://openneuro.org/ds003645/ | tail -2
```

```python
def estimate_size(dataset_id):
    """Estimate dataset size from S3."""
    result = subprocess.run(
        ["aws", "s3", "ls", "--no-sign-request", "--summarize", "--recursive",
         f"s3://openneuro.org/{dataset_id}/"],
        capture_output=True, text=True
    )
    for line in result.stdout.strip().split("\n")[-2:]:
        print(line.strip())
```

---

## BIDS Validation After Download

### Quick Python Validation

```python
import json
from pathlib import Path

def validate_download(bids_root):
    """Validate downloaded BIDS dataset structure."""
    root = Path(bids_root)
    report = {"passed": [], "failed": [], "warnings": []}

    # Required files
    for req_file in ["dataset_description.json", "participants.tsv"]:
        path = root / req_file
        if path.exists() and path.stat().st_size > 0:
            report["passed"].append(f"{req_file} exists and non-empty")
        else:
            report["failed"].append(f"{req_file} missing or empty")

    # Subjects
    subjects = sorted([d.name for d in root.iterdir()
                       if d.is_dir() and d.name.startswith("sub-")])
    if subjects:
        report["passed"].append(f"Found {len(subjects)} subjects: {subjects[0]}...{subjects[-1]}")
    else:
        report["failed"].append("No subject directories found")

    # Check first subject for data files
    if subjects:
        first_sub = root / subjects[0]
        data_files = list(first_sub.rglob("*_eeg.*")) + list(first_sub.rglob("*_bold.*"))
        event_files = list(first_sub.rglob("*_events.tsv"))

        if data_files:
            formats = set(f.suffix for f in data_files)
            report["passed"].append(f"Data files found (formats: {formats})")
        else:
            report["failed"].append("No EEG or fMRI data files in first subject")

        if event_files:
            report["passed"].append(f"Event files found ({len(event_files)} files)")
        else:
            report["warnings"].append("No event files in first subject")

    # Dataset description
    desc_path = root / "dataset_description.json"
    if desc_path.exists():
        desc = json.loads(desc_path.read_text())
        report["passed"].append(f"Dataset: {desc.get('Name', 'unnamed')}")

    # Print report
    print("\n=== BIDS Validation ===")
    for item in report["passed"]:
        print(f"  [PASS] {item}")
    for item in report["warnings"]:
        print(f"  [WARN] {item}")
    for item in report["failed"]:
        print(f"  [FAIL] {item}")
    print(f"\nResult: {len(report['passed'])} passed, {len(report['warnings'])} warnings, {len(report['failed'])} failed")

    return len(report["failed"]) == 0
```

### Extracting Dataset Metadata

```python
import json
import pandas as pd
from pathlib import Path

def extract_dataset_info(bids_root):
    """Extract comprehensive dataset metadata for replication planning."""
    root = Path(bids_root)
    info = {}

    # Basic info from dataset_description.json
    desc_path = root / "dataset_description.json"
    if desc_path.exists():
        desc = json.loads(desc_path.read_text())
        info["name"] = desc.get("Name", "")
        info["bids_version"] = desc.get("BIDSVersion", "")
        info["doi"] = desc.get("DatasetDOI", "")

    # Participants
    part_path = root / "participants.tsv"
    if part_path.exists():
        participants = pd.read_csv(part_path, sep="\t")
        info["n_subjects"] = len(participants)
        info["participant_columns"] = participants.columns.tolist()
        if "age" in participants.columns:
            info["age_range"] = f"{participants['age'].min()}-{participants['age'].max()}"
        if "sex" in participants.columns:
            info["sex_distribution"] = participants["sex"].value_counts().to_dict()

    # Modality detection
    subjects = sorted([d for d in root.iterdir() if d.is_dir() and d.name.startswith("sub-")])
    if subjects:
        first_sub = subjects[0]
        has_eeg = any(first_sub.rglob("*_eeg.*"))
        has_meg = any(first_sub.rglob("*_meg.*"))
        has_fmri = any(first_sub.rglob("*_bold.*"))

        modalities = []
        if has_eeg: modalities.append("EEG")
        if has_meg: modalities.append("MEG")
        if has_fmri: modalities.append("fMRI")
        info["modalities"] = modalities

        # EEG sidecar info
        eeg_json = list(root.rglob("*_eeg.json"))
        if eeg_json:
            sidecar = json.loads(eeg_json[0].read_text())
            info["task"] = sidecar.get("TaskName", "")
            info["sampling_frequency"] = sidecar.get("SamplingFrequency", "")
            info["eeg_reference"] = sidecar.get("EEGReference", "")
            info["line_frequency"] = sidecar.get("PowerLineFrequency", "")
            info["eeg_channels"] = sidecar.get("EEGChannelCount", "")
            info["eog_channels"] = sidecar.get("EOGChannelCount", "")

        # File format
        data_files = list(first_sub.rglob("*_eeg.*"))
        if data_files:
            info["file_format"] = set(f.suffix for f in data_files) - {".json", ".tsv"}

    return info
```

---

## Known Dataset-Paper Mapping

| Dataset ID | Paper | DOI | Modality | Key Analysis |
|-----------|-------|-----|----------|-------------|
| ds003645 | Kappenman et al. 2021 (ERP CORE) | 10.1016/j.neuroimage.2020.117465 | EEG 30ch 1024Hz | N170, P300, N400, MMN, ERN, LRP |
| ds000105 | Haxby et al. 2001 | 10.1126/science.1063736 | fMRI | MVPA object category decoding |
| ds000117 | Wakeman & Henson 2015 | 10.1038/sdata.2015.1 | MEG/EEG/fMRI | Face processing, multimodal |
| ds004621 | Dzianok et al. 2022 | 10.1093/gigascience/giac015 | EEG 127ch 1000Hz | P300 auditory oddball |
| ds006480 | Kim et al. 2025 | bioRxiv preprint | EEG 65ch 1000Hz | Auditory oddball + arousal |
| ds003061 | Cahn et al. 2012 | — | EEG | P300 auditory oddball |
| ds000246 | Jas et al. 2018 | 10.3389/fnins.2018.00530 | MEG 306ch | Auditory M100 |
| ds000228 | Richardson et al. 2018 | 10.1038/s41467-018-03399-2 | fMRI | Theory of mind, child/adult |
| ds001246 | Horikawa & Kamitani 2017 | 10.1038/ncomms15037 | fMRI | Visual object decoding (DNN) |

---

## Troubleshooting Downloads

| Issue | Cause | Fix |
|-------|-------|-----|
| `aws: command not found` | AWS CLI not installed | `pip install awscli` |
| Timeout or slow download | Large dataset + slow connection | Use `--exclude` to skip unnecessary modalities |
| Incomplete download | Interrupted transfer | Re-run `aws s3 sync` (it resumes) |
| Permission denied | Bucket requires specific version | Try adding version: `s3://openneuro.org/ds003645/v2.0.1/` |
| Empty subject directories | Dataset uses session subdirs | Check `sub-01/ses-01/eeg/` pattern |
| `.fdt` files missing | Separate binary data files | Ensure no `--exclude "*.fdt"` in command |
