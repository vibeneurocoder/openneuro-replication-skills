<!-- openneuro-replication-skills | asset: OpenNeuro Format Guide -->

# OpenNeuro Dataset Format Guide

Quick reference for navigating OpenNeuro datasets in BIDS format.

---

## BIDS Directory Structure

```
ds003645/                              # dataset root
├── dataset_description.json           # name, authors, license, BIDS version
├── participants.tsv                   # subject demographics
├── participants.json                  # column descriptions
├── README                             # dataset description
├── CHANGES                            # version history
├── task-N170_eeg.json                 # task-level EEG sidecar (shared params)
├── task-N170_events.json              # event column descriptions
│
├── sub-001/                           # per-subject directory
│   ├── sub-001_scans.tsv              # scan listing with timestamps
│   └── eeg/                           # modality directory
│       ├── sub-001_task-N170_eeg.set  # EEG data file
│       ├── sub-001_task-N170_eeg.fdt  # EEG data (binary, if separate)
│       ├── sub-001_task-N170_eeg.json # subject-level sidecar overrides
│       ├── sub-001_task-N170_channels.tsv    # channel metadata
│       ├── sub-001_task-N170_electrodes.tsv  # electrode positions
│       ├── sub-001_task-N170_coordsystem.json # coordinate system
│       └── sub-001_task-N170_events.tsv      # event timing & labels
│
├── sub-002/
│   └── eeg/ ...
│
└── derivatives/                       # processed data (if available)
    └── fmriprep/ ...                  # fMRIPrep outputs
```

### fMRI BIDS Structure

```
ds000105/
├── sub-01/
│   ├── anat/
│   │   └── sub-01_T1w.nii.gz
│   └── func/
│       ├── sub-01_task-objectviewing_run-01_bold.nii.gz
│       ├── sub-01_task-objectviewing_run-01_events.tsv
│       └── sub-01_task-objectviewing_run-01_bold.json
```

---

## Key BIDS Files

### `dataset_description.json`

```json
{
    "Name": "ERP CORE",
    "BIDSVersion": "1.6.0",
    "License": "CC0",
    "Authors": ["Emily S. Kappenman", "..."],
    "DatasetDOI": "doi:10.18112/openneuro.ds003645.v2.0.1"
}
```

### `participants.tsv`

```
participant_id  age  sex  handedness
sub-001         22   F    right
sub-002         25   M    right
```

### `*_events.tsv`

```
onset       duration    trial_type    value    response_time
0.512       0.200       face          101      0.432
1.024       0.200       car           102      0.521
```

| Column | Description | Notes |
|--------|-------------|-------|
| `onset` | Event start time in seconds from recording start | Required |
| `duration` | Event duration in seconds | Required (use `n/a` if instantaneous) |
| `trial_type` | Condition label | Primary column for analysis |
| `value` | Numeric event code | Original trigger code |
| `response_time` | RT in seconds | Optional |

### `*_channels.tsv`

```
name    type    units    sampling_frequency    status
Fp1     EEG     µV       1024                  good
VEOG    EOG     µV       1024                  good
Cz      EEG     µV       1024                  bad
```

### `*_eeg.json` (Sidecar)

```json
{
    "TaskName": "N170",
    "SamplingFrequency": 1024,
    "EEGReference": "Cz",
    "PowerLineFrequency": 60,
    "SoftwareFilters": {
        "Anti-aliasing filter": {
            "half-amplitude cutoff (Hz)": 350
        }
    },
    "EEGChannelCount": 30,
    "EOGChannelCount": 2,
    "RecordingType": "continuous"
}
```

---

## Downloading from OpenNeuro via AWS S3

### Full Dataset

```bash
# No AWS credentials needed (public bucket)
aws s3 sync --no-sign-request \
    s3://openneuro.org/ds003645 \
    ds003645/
```

### Demo Mode (2 Subjects)

```bash
# Download only shared files + 2 subjects
aws s3 sync --no-sign-request \
    --exclude "sub-*" \
    s3://openneuro.org/ds003645 ds003645/

aws s3 sync --no-sign-request \
    --include "sub-001/*" --include "sub-002/*" --exclude "*" \
    s3://openneuro.org/ds003645 ds003645/
```

### Python Download

```python
import subprocess

def download_openneuro(dataset_id, output_dir=None, subjects=None):
    """Download OpenNeuro dataset via AWS S3.

    Args:
        dataset_id: e.g., "ds003645"
        output_dir: local path (default: dataset_id)
        subjects: list of subject IDs for partial download, or None for all
    """
    output_dir = output_dir or dataset_id
    base_cmd = ["aws", "s3", "sync", "--no-sign-request"]
    s3_path = f"s3://openneuro.org/{dataset_id}"

    if subjects is None:
        # Full download
        subprocess.run(base_cmd + [s3_path, output_dir], check=True)
    else:
        # Shared files first
        subprocess.run(
            base_cmd + ["--exclude", "sub-*", s3_path, output_dir],
            check=True,
        )
        # Then selected subjects
        for subj in subjects:
            subj_str = f"sub-{subj}" if not subj.startswith("sub-") else subj
            subprocess.run(
                base_cmd + [f"{s3_path}/{subj_str}", f"{output_dir}/{subj_str}"],
                check=True,
            )
```

---

## Common File Formats on OpenNeuro

| Format | Extensions | Reader | Prevalence |
|--------|-----------|--------|------------|
| EEGLAB | `.set` + `.fdt` | `mne.io.read_raw_eeglab()` | ~40% of EEG datasets |
| BrainVision | `.vhdr` + `.vmrk` + `.eeg` | `mne.io.read_raw_brainvision()` | ~30% of EEG datasets |
| EDF/EDF+ | `.edf` | `mne.io.read_raw_edf()` | ~15% of EEG datasets |
| BDF (BioSemi) | `.bdf` | `mne.io.read_raw_bdf()` | ~5% of EEG datasets |
| NIfTI | `.nii.gz` | `nibabel.load()` | ~100% of fMRI datasets |
| FIF (MNE) | `.fif` | `mne.io.read_raw_fif()` | ~5% of MEG datasets |
| CTF | `.ds/` | `mne.io.read_raw_ctf()` | ~3% of MEG datasets |

---

## BIDS Validation

```bash
# Install BIDS validator
npm install -g bids-validator

# Validate dataset
bids-validator ds003645/
```

```python
# Or check basic structure in Python
from pathlib import Path

def validate_bids_basic(bids_root):
    """Basic BIDS structure validation."""
    root = Path(bids_root)
    checks = {
        "dataset_description.json": (root / "dataset_description.json").exists(),
        "participants.tsv": (root / "participants.tsv").exists(),
        "has_subjects": any(root.glob("sub-*")),
    }

    # Check first subject has data
    first_sub = next(root.glob("sub-*"), None)
    if first_sub:
        checks["has_eeg_or_func"] = (
            any(first_sub.rglob("*_eeg.*")) or
            any(first_sub.rglob("*_bold.*"))
        )
        checks["has_events"] = any(first_sub.rglob("*_events.tsv"))

    for check, passed in checks.items():
        status = "PASS" if passed else "FAIL"
        print(f"  [{status}] {check}")

    return all(checks.values())
```

---

## Common Dataset Quirks

| Issue | Symptom | Fix |
|-------|---------|-----|
| Missing `.fdt` file | `read_raw_eeglab` errors | Check S3 bucket for incomplete download |
| Channel name mismatch | Montage won't apply | Rename channels: `raw.rename_channels(mapping)` |
| Event code mismatch | Paper codes ≠ BIDS codes | Map via `_events.tsv` `trial_type` column |
| Mixed sampling rates | Different sfreq per subject | Resample to common rate |
| Extra non-EEG channels | Unexpected channel types | Set types: `raw.set_channel_types(mapping)` |
| No electrode positions | `set_montage` fails | Use standard montage or load from `_electrodes.tsv` |
| Session subdirectory | `sub-01/ses-01/eeg/` vs `sub-01/eeg/` | Check both paths |
| Stimulus channel conflicts | `find_events` returns garbage | Use `events_from_annotations` instead |
