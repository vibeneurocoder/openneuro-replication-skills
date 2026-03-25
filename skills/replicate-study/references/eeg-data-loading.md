<!-- openneuro-replication-skills | domain: EEG Data Loading -->
<!-- target libraries: mne>=1.6, scipy>=1.11, mne-bids>=0.14 -->

# Domain: EEG Data Loading for OpenNeuro Replication

Loading data correctly is the single most common failure point in replications.
OpenNeuro datasets use BIDS format, but the underlying EEG files vary widely.

---

## Format Detection from BIDS Layout

OpenNeuro datasets follow BIDS with an `eeg/` or `meg/` subdirectory per subject.
Detect the format before choosing a reader:

```python
from pathlib import Path

def detect_eeg_format(bids_root, subject="01"):
    """Detect EEG file format from BIDS dataset structure."""
    eeg_dir = Path(bids_root) / f"sub-{subject}" / "eeg"
    if not eeg_dir.exists():
        eeg_dir = Path(bids_root) / f"sub-{subject}" / "ses-01" / "eeg"

    suffixes = {p.suffix for p in eeg_dir.iterdir() if p.is_file()}
    if ".set" in suffixes:
        return "eeglab"
    elif ".vhdr" in suffixes:
        return "brainvision"
    elif ".edf" in suffixes:
        return "edf"
    elif ".bdf" in suffixes:
        return "bdf"
    elif ".fif" in suffixes:
        return "fif"
    elif ".cnt" in suffixes:
        return "cnt"
    else:
        return "unknown"
```

---

## EEGLAB `.set` / `.fdt` Files

Most common format on OpenNeuro for EEG. Two loading paths depending on MNE version and file quirks.

### `mne.io.read_raw_eeglab(...)`

**Signature:**
```text
mne.io.read_raw_eeglab(
    input_fname, eog=(), preload=False, uint16_codec=None, verbose=None
)
# Source: mne/io/eeglab/eeglab.py
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `input_fname` | `str \| Path` | — | Path to `.set` file. `.fdt` must be in same directory. |
| `eog` | `tuple of str` | `()` | Channel names to designate as EOG type. |
| `preload` | `bool` | `False` | If `True`, load all data into memory. Required for filtering. |
| `uint16_codec` | `str \| None` | `None` | Codec for uint16 event codes (rare, use `"latin1"` if codes garbled). |

**Example:**
```python
import mne

raw = mne.io.read_raw_eeglab("sub-001/eeg/sub-001_task-N170_eeg.set", preload=True)
print(f"Channels: {len(raw.ch_names)}, Sfreq: {raw.info['sfreq']} Hz")
print(f"Duration: {raw.times[-1]:.1f} s")
```

**Pitfalls:**
- The `.fdt` file MUST be in the same directory as the `.set` file. If you moved only the `.set`, loading will fail silently or raise a cryptic error.
- Some EEGLAB files store data in the `.set` file itself (older MATLAB format). MNE handles both cases.
- Channel locations may be missing or in a non-standard coordinate frame. Always verify with `raw.get_montage()`.

### Fallback: `scipy.io` for Problematic `.set` Files

When MNE fails (corrupted headers, non-standard EEGLAB plugins), load the MATLAB structure directly:

```python
import scipy.io
import numpy as np
import mne

# Load .set as MATLAB structure
eeg = scipy.io.loadmat("sub-001_task-N170_eeg.set", squeeze_me=True, struct_as_record=False)
data = eeg["EEG"]

# Extract arrays
eeg_data = data.data  # shape: (n_channels, n_samples) or load from .fdt
sfreq = float(data.srate)
ch_names = [str(ch.labels) for ch in data.chanlocs]

# Build MNE Raw
info = mne.create_info(ch_names=ch_names, sfreq=sfreq, ch_types="eeg")
raw = mne.io.RawArray(eeg_data, info)
```

**Pitfalls:**
- For large files, data lives in the `.fdt` file: `np.fromfile("file.fdt", dtype=np.float32).reshape(n_channels, -1)`
- Channel names may have trailing spaces. Always strip: `[ch.strip() for ch in ch_names]`
- `scipy.io.loadmat` fails on MATLAB v7.3 files. Use `h5py` instead:
  ```python
  import h5py
  f = h5py.File("sub-001_task-N170_eeg.set", "r")
  data = np.array(f["EEG"]["data"])
  ```

---

## BrainVision `.vhdr` / `.vmrk` / `.eeg` Files

Common in European labs. Three files form a single recording.

### `mne.io.read_raw_brainvision(...)`

**Signature:**
```text
mne.io.read_raw_brainvision(
    vhdr_fname, eog=('HEOG', 'VEOG', 'hEOG', 'vEOG'),
    misc='auto', scale=1.0, preload=False, verbose=None
)
# Source: mne/io/brainvision/brainvision.py
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `vhdr_fname` | `str \| Path` | — | Path to `.vhdr` header file. `.vmrk` and `.eeg` must be alongside. |
| `eog` | `tuple of str` | `('HEOG', 'VEOG', ...)` | Channel names auto-typed as EOG. |
| `misc` | `str \| list` | `'auto'` | Channels to mark as misc (non-EEG, non-EOG). |
| `scale` | `float` | `1.0` | Scaling factor applied to data. |

**Example:**
```python
import mne

raw = mne.io.read_raw_brainvision(
    "sub-001/eeg/sub-001_task-oddball_eeg.vhdr",
    eog=("VEOG", "HEOG"),
    preload=True,
)
# Check events from .vmrk annotations
events, event_id = mne.events_from_annotations(raw)
print(f"Found {len(events)} events: {event_id}")
```

**Pitfalls:**
- All three files (`.vhdr`, `.vmrk`, `.eeg`) must be present and co-located.
- The `.vhdr` file contains internal references to the other files by name. If renamed, edit the header.
- BrainVision uses `Stimulus/S  1` annotation format. MNE strips this to `"S  1"` or `"S1"` depending on version.

---

## EDF / EDF+ / BDF Files

### `mne.io.read_raw_edf(...)` / `mne.io.read_raw_bdf(...)`

**Signature:**
```text
mne.io.read_raw_edf(
    input_fname, eog=None, misc=None, stim_channel='auto',
    exclude=(), infer_types=False, preload=False, verbose=None
)
# Source: mne/io/edf/edf.py
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `input_fname` | `str \| Path` | — | Path to `.edf` or `.bdf` file. |
| `stim_channel` | `str` | `'auto'` | Status/trigger channel. Use `'auto'` for EDF+, explicit name for EDF. |
| `exclude` | `tuple of str` | `()` | Channel names to exclude from loading. |
| `infer_types` | `bool` | `False` | Infer channel types from names (EEG, EOG, EMG). |

**Example:**
```python
import mne

raw = mne.io.read_raw_edf("sub-001/eeg/sub-001_task-rest_eeg.edf", preload=True)
# BDF variant:
# raw = mne.io.read_raw_bdf("sub-001/eeg/sub-001_task-rest_eeg.bdf", preload=True)
```

---

## BIDS-Native Loading with `mne-bids`

### `mne_bids.read_raw_bids(...)`

**Signature:**
```text
mne_bids.read_raw_bids(
    bids_path, extra_params=None, verbose=None
)
# Source: mne_bids/read.py
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `bids_path` | `BIDSPath` | — | BIDS-compliant path object specifying subject, task, etc. |
| `extra_params` | `dict \| None` | `None` | Extra keyword args forwarded to the underlying reader. |

**Example:**
```python
import mne_bids

bids_path = mne_bids.BIDSPath(
    subject="001",
    task="N170",
    datatype="eeg",
    root="ds003645",
)
raw = mne_bids.read_raw_bids(bids_path)
# Automatically reads sidecar JSON for channel types, events from _events.tsv
print(raw.info["line_freq"])  # Line noise freq from dataset_description.json
```

**Pitfalls:**
- Requires `mne-bids` package: `pip install mne-bids`
- BIDS metadata may override channel types. Verify with `raw.get_channel_types()`.
- Event descriptions come from `_events.tsv` sidecar, not from the raw file annotations.

---

## BIDS Events from Sidecar TSV

OpenNeuro stores events in `*_events.tsv` files alongside the EEG data:

```python
import pandas as pd
import numpy as np

# Read BIDS events
events_df = pd.read_csv(
    "sub-001/eeg/sub-001_task-N170_events.tsv",
    sep="\t",
)
print(events_df.columns.tolist())  # ['onset', 'duration', 'trial_type', ...]

# Convert to MNE events array
# onset is in seconds; convert to samples
sfreq = raw.info["sfreq"]
event_samples = (events_df["onset"].values * sfreq).astype(int)
event_ids = {name: i + 1 for i, name in enumerate(events_df["trial_type"].unique())}
id_lookup = {v: k for k, v in event_ids.items()}

events = np.column_stack([
    event_samples,
    np.zeros(len(event_samples), dtype=int),
    [event_ids[t] for t in events_df["trial_type"]],
])
print(f"Event IDs: {event_ids}")
```

**Pitfalls:**
- `onset` column is in seconds from recording start, not sample indices.
- Some datasets have `value` or `event_type` columns instead of `trial_type`. Always inspect first.
- Missing or `n/a` values in `trial_type` are common for boundary/break events. Filter them:
  ```python
  events_df = events_df[events_df["trial_type"].notna() & (events_df["trial_type"] != "n/a")]
  ```

---

## Setting Channel Montage

After loading, channels often lack positions or have non-standard names:

### `raw.set_montage(...)`

**Signature:**
```text
Raw.set_montage(
    montage, match_case=True, match_alias=False,
    on_missing='raise', verbose=None
)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `montage` | `str \| DigMontage` | — | Standard name (`"standard_1020"`) or custom `DigMontage`. |
| `match_case` | `bool` | `True` | Case-sensitive channel matching. |
| `match_alias` | `bool` | `False` | Use alternative names (e.g., `T7` ↔ `T3`). |
| `on_missing` | `str` | `'raise'` | `'raise'`, `'warn'`, or `'ignore'` for unmatched channels. |

**Common montage workflow:**
```python
import mne

# Standard 10-20 system
raw.set_montage("standard_1020", match_case=False, on_missing="warn")

# For EGI (E1, E2, ... numbered electrodes):
montage = mne.channels.make_standard_montage("GSN-HydroCel-65_1.0")
# Rename channels if needed
mapping = {raw.ch_names[i]: montage.ch_names[i] for i in range(len(raw.ch_names))}
raw.rename_channels(mapping)
raw.set_montage(montage)

# For custom locations from BIDS electrodes.tsv:
# mne-bids handles this automatically via read_raw_bids()
```

---

## Standard EEG Montage Templates

MNE includes built-in montage definitions for every major EEG system. Use the correct one
to get accurate channel positions for topographic maps and source localization.

### `mne.channels.make_standard_montage(...)`

**Signature:**
```text
mne.channels.make_standard_montage(
    kind, head_size=0.095
)
# Returns: DigMontage
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `kind` | `str` | — | Montage name (see table below). |
| `head_size` | `float` | `0.095` | Head radius in meters. |

### Available Built-in Montages

```python
import mne
# List all available montages
print(mne.channels.get_builtin_montages())
```

#### Standard 10-20 / 10-10 / 10-05 Systems

| Montage Name | Channels | Use When |
|-------------|----------|----------|
| `standard_1020` | 94 | Paper says "10-20 system" — most common |
| `standard_1005` | 343 | Paper says "10-10" or "10-05 system", high-density |
| `standard_alphabetic` | 94 | 10-20 with old naming (T3/T4 instead of T7/T8) |
| `standard_postfixed` | 94 | 10-20 with postfixed names |
| `standard_primed` | 94 | 10-20 with primed names |

```python
# Standard 10-20 (most papers)
montage = mne.channels.make_standard_montage("standard_1020")
print(f"Channels: {len(montage.ch_names)}")
print(f"Names: {montage.ch_names[:10]}")
# ['Fp1', 'Fp2', 'F7', 'F3', 'Fz', 'F4', 'F8', 'T7', 'C3', 'Cz']

# Visualize montage
fig = montage.plot(show_names=True, show=False)
fig.savefig("figures/montage_1020.png", dpi=300)
```

#### EGI (Electrical Geodesics / HydroCel) Systems

| Montage Name | Channels | Use When |
|-------------|----------|----------|
| `GSN-HydroCel-32` | 32 | EGI 32-channel net |
| `GSN-HydroCel-64_1.0` | 64 | EGI 64-channel net |
| `GSN-HydroCel-65_1.0` | 65 | EGI 65-channel net (with Cz) |
| `GSN-HydroCel-128` | 128 | EGI 128-channel net |
| `GSN-HydroCel-129` | 129 | EGI 129-channel net (with Cz) |
| `GSN-HydroCel-256` | 256 | EGI 256-channel net |
| `GSN-HydroCel-257` | 257 | EGI 257-channel net (with Cz) |

```python
# EGI systems use E-numbered channels (E1, E2, ...)
montage = mne.channels.make_standard_montage("GSN-HydroCel-65_1.0")

# Channels are named 'E1', 'E2', ... 'E65' or 'Cz'
# May need renaming from dataset's convention
mapping = {}
for i, ch in enumerate(raw.ch_names[:65]):
    mapping[ch] = montage.ch_names[i]
raw.rename_channels(mapping)
raw.set_montage(montage, on_missing="warn")
```

**EGI → 10-20 Approximate Mapping (Common Equivalents):**

| EGI Channel | 10-20 Equivalent | Region |
|------------|-------------------|--------|
| E1 | Fp1 (approx) | Left frontal pole |
| E6 | F3 (approx) | Left frontal |
| E9 | Fz (approx) | Midline frontal |
| E11 | Cz | Midline central (vertex) |
| E22 | Fp2 (approx) | Right frontal pole |
| E24 | F4 (approx) | Right frontal |
| E33 | T7 (approx) | Left temporal |
| E36 | C3 (approx) | Left central |
| E45 | T8 (approx) | Right temporal |
| E52 | P3 (approx) | Left parietal |
| E58 | P7 (approx) | Left parieto-occipital |
| E62 | Pz (approx) | Midline parietal |
| E75 | Oz (approx) | Midline occipital |
| E83 | P4 (approx) | Right parietal |
| E92 | P8 (approx) | Right parieto-occipital |
| E96 | C4 (approx) | Right central |
| E104 | F8 (approx) | Right frontal |
| E108 | T8 (approx) | Right temporal |

*Note: EGI montages vary by version. Always verify against the dataset's electrode layout file.*

#### BioSemi Systems

| Montage Name | Channels | Use When |
|-------------|----------|----------|
| `biosemi16` | 16 | BioSemi 16-channel |
| `biosemi32` | 32 | BioSemi 32-channel |
| `biosemi64` | 64 | BioSemi 64-channel |
| `biosemi128` | 128 | BioSemi 128-channel |
| `biosemi160` | 160 | BioSemi 160-channel |
| `biosemi256` | 256 | BioSemi 256-channel |

```python
# BioSemi uses A1-A32 + B1-B32 (64ch) or similar
montage = mne.channels.make_standard_montage("biosemi64")
raw.set_montage(montage, on_missing="warn")
```

#### Other Systems

| Montage Name | Channels | System |
|-------------|----------|--------|
| `easycap-M1` | 74 | EasyCap M1 layout |
| `easycap-M10` | 61 | EasyCap M10 layout |
| `mgh60` | 60 | MGH 60-channel |
| `mgh70` | 70 | MGH 70-channel |
| `artinis-octamon` | 8 | Artinis OctaMon fNIRS |
| `artinis-brite23` | 23 | Artinis Brite23 fNIRS |
| `brainproducts-RNP-BA-128` | 128 | Brain Products R-Net 128 |

### Creating Custom Montages

When datasets provide electrode positions in non-standard formats:

```python
import mne
import pandas as pd
import numpy as np

# From BIDS electrodes.tsv
elec_df = pd.read_csv("sub-001/eeg/sub-001_electrodes.tsv", sep="\t")
# Columns: name, x, y, z

ch_pos = {row["name"]: np.array([row["x"], row["y"], row["z"]]) / 1000  # mm→m
           for _, row in elec_df.iterrows()}
montage = mne.channels.make_dig_montage(ch_pos=ch_pos, coord_frame="head")
raw.set_montage(montage)
```

```python
# From spherical coordinates (theta, phi)
montage = mne.channels.make_standard_montage("standard_1020")
# Access positions:
pos = montage.get_positions()
ch_pos = pos["ch_pos"]  # dict of {name: (x, y, z)}
```

### Montage Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `set_montage()` raises ValueError | Channel names don't match montage | `raw.rename_channels(mapping)` first |
| Missing channels in montage | EOG/EMG/misc not in standard layout | Set `on_missing='warn'` or `'ignore'` |
| Wrong coordinate system | BIDS uses mm, MNE uses meters | Divide by 1000 |
| Old naming convention | T3/T4 vs T7/T8, TP9 vs M1 | Use `match_alias=True` or rename |
| Flat topomaps | No channel positions set | Apply montage before plotting |
| "Digitization points..." warning | Montage has fiducials, raw doesn't | Safe to ignore for EEG-only |

### Channel Name Conventions

| Convention | Example Names | Common In |
|-----------|--------------|-----------|
| Standard 10-20 | Fp1, Fp2, F7, F3, Fz, F4, F8, T7, C3, Cz | Most papers |
| Old 10-20 | T3→T7, T4→T8, T5→P7, T6→P8, Fpz→Fp1/Fp2 | Older papers |
| BioSemi | A1-A32, B1-B32, EXG1-EXG8 | BioSemi Active Two |
| EGI/HydroCel | E1, E2, ..., E256 | EGI systems |
| Generic BIDS | EEG001, EEG002, ..., EOG001 | Some OpenNeuro datasets |
| Neuroscan | FP1, FPZ, FP2, F7 (uppercase) | Neuroscan SynAmps |
| Brain Products | Fp1, Fp2, F3 (mixed case) | BrainVision |

```python
# Rename old convention to new
old_to_new = {"T3": "T7", "T4": "T8", "T5": "P7", "T6": "P8"}
raw.rename_channels({ch: old_to_new[ch] for ch in raw.ch_names if ch in old_to_new})

# Rename generic BIDS to 10-20 (need dataset-specific mapping)
# Check *_channels.tsv for the mapping
channels_df = pd.read_csv("sub-001_channels.tsv", sep="\t")
mapping = dict(zip(channels_df["name"], channels_df["description"]))  # if description has 10-20 names
```

---

## MEG Channel Templates

For MEG datasets on OpenNeuro:

```python
# MEG systems have built-in sensor layouts — loaded automatically from .fif files
# Common systems:
# - Elekta/MEGIN Neuromag: 306 channels (102 magnetometers + 204 gradiometers)
# - CTF: 275 channels
# - KIT: 160 channels
# - BTi/4D: 248 channels

# Read CTF dataset
raw = mne.io.read_raw_ctf("sub-01/meg/sub-01_task-rest_meg.ds/", preload=True)

# Read Elekta/Neuromag
raw = mne.io.read_raw_fif("sub-01/meg/sub-01_task-auditory_meg.fif", preload=True)
print(f"MEG channels: {len(mne.pick_types(raw.info, meg=True))}")
print(f"Magnetometers: {len(mne.pick_types(raw.info, meg='mag'))}")
print(f"Gradiometers: {len(mne.pick_types(raw.info, meg='grad'))}")
```

---

## Format Decision Tree

```
OpenNeuro dataset
├── Has _eeg.set file?
│   ├── Yes → mne.io.read_raw_eeglab()
│   │         └── Fails? → scipy.io.loadmat() fallback
│   └── No
├── Has _eeg.vhdr file?
│   └── Yes → mne.io.read_raw_brainvision()
├── Has _eeg.edf/.bdf file?
│   └── Yes → mne.io.read_raw_edf() / read_raw_bdf()
├── Has _eeg.fif file?
│   └── Yes → mne.io.read_raw_fif()
└── Use mne_bids.read_raw_bids() for automatic detection
```
