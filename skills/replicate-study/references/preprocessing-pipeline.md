<!-- openneuro-replication-skills | domain: EEG Preprocessing Pipeline -->
<!-- target libraries: mne>=1.6, autoreject>=0.4 -->

# Domain: EEG Preprocessing Pipeline for Replication

Preprocessing must match the original paper exactly. Each step below includes the
API signature, parameter tables, and common paper-described variations.

---

## Filtering

Papers specify filters as "bandpass X–Y Hz" or separate highpass/lowpass.

### `raw.filter(...)`

**Signature:**
```text
Raw.filter(
    l_freq, h_freq, picks=None, filter_length='auto',
    l_trans_bandwidth='auto', h_trans_bandwidth='auto',
    n_jobs=None, method='fir', iir_params=None,
    phase='zero', fir_window='hamming', fir_design='firwin',
    pad='reflect_limited', verbose=None
)
# Returns: Raw (modified in-place)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `l_freq` | `float \| None` | — | Lower passband edge (Hz). `None` for lowpass only. |
| `h_freq` | `float \| None` | — | Upper passband edge (Hz). `None` for highpass only. |
| `method` | `str` | `'fir'` | `'fir'` or `'iir'`. Papers using EEGLAB typically used FIR. |
| `fir_design` | `str` | `'firwin'` | `'firwin'` (default) or `'firwin2'`. |
| `phase` | `str` | `'zero'` | `'zero'` (non-causal) or `'zero-double'` or `'minimum'`. |
| `l_trans_bandwidth` | `float \| str` | `'auto'` | Transition bandwidth (Hz). `'auto'` = `min(max(l_freq * 0.25, 2), l_freq)`. |
| `h_trans_bandwidth` | `float \| str` | `'auto'` | Transition bandwidth (Hz). `'auto'` = `min(max(h_freq * 0.25, 2), h_freq)`. |

**Common paper specifications and their MNE equivalents:**

```python
# "Bandpass filtered 0.1–30 Hz" (most common in ERP papers)
raw.filter(l_freq=0.1, h_freq=30.0)

# "Highpass 0.1 Hz, lowpass 40 Hz" (same as bandpass, just stated separately)
raw.filter(l_freq=0.1, h_freq=40.0)

# "Highpass 1 Hz" (for ICA — many papers apply higher cutoff before ICA)
raw_for_ica = raw.copy().filter(l_freq=1.0, h_freq=None)

# "Butterworth 4th-order bandpass 0.1–30 Hz" (IIR, common in FieldTrip papers)
raw.filter(l_freq=0.1, h_freq=30.0, method='iir',
           iir_params=dict(order=4, ftype='butter'))

# "Notch filter at 50 Hz" (line noise removal)
raw.notch_filter(freqs=50.0)  # or 60.0 for US data
# Multiple harmonics:
raw.notch_filter(freqs=[50, 100, 150])
```

**Pitfalls:**
- Filter BEFORE epoching (unless the paper explicitly states otherwise).
- Highpass > 0.1 Hz can distort ERP waveform shape. If paper used 0.01 Hz or "DC-coupled", use `l_freq=0.01`.
- EEGLAB's default `pop_eegfiltnew` maps to MNE's `method='fir', fir_design='firwin'`.
- ERPLAB's Butterworth filter maps to `method='iir', iir_params=dict(order=N, ftype='butter')`.

---

## Re-Referencing

### `raw.set_eeg_reference(...)`

**Signature:**
```text
Raw.set_eeg_reference(
    ref_channels='average', projection=True, ch_type='auto',
    forward=None, joint=False, verbose=None
)
# Returns: (Raw, list_of_projectors)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `ref_channels` | `str \| list` | `'average'` | `'average'`, list of channel names, or `'REST'`. |
| `projection` | `bool` | `True` | Apply as projection (`True`) or directly modify data (`False`). |

**Common paper specifications:**

```python
# "Average reference" (most common)
raw.set_eeg_reference(ref_channels="average", projection=False)

# "Referenced to linked mastoids" (M1, M2 or TP9, TP10)
raw.set_eeg_reference(ref_channels=["M1", "M2"], projection=False)

# "Referenced to Cz" (then Cz becomes flat — drop it after)
raw.set_eeg_reference(ref_channels=["Cz"], projection=False)
raw.drop_channels(["Cz"])

# "Referenced to left mastoid" (single reference)
raw.set_eeg_reference(ref_channels=["M1"], projection=False)

# "Infinity reference (REST)"
raw.set_eeg_reference(ref_channels="REST", projection=False)
```

**Pitfalls:**
- Must set `projection=False` for the reference to actually be applied to data. With `projection=True` (default), it's stored as a projector and only applied during computation.
- Remove the reference channel from data if it was used as a physical reference (e.g., Cz).
- If original reference was not recorded (common in BioSemi/EGI systems), add it back before re-referencing:
  ```python
  mne.add_reference_channels(raw, ref_channels="Cz", copy=False)
  ```

---

## Epoching

### `mne.Epochs(...)`

**Signature:**
```text
mne.Epochs(
    raw, events, event_id=None, tmin=-0.2, tmax=0.5,
    baseline=(None, 0), picks=None, preload=False,
    reject=None, flat=None, proj=True, decim=1,
    reject_tmin=None, reject_tmax=None, detrend=None,
    on_missing='raise', reject_by_annotation=True,
    metadata=None, event_repeated='error', verbose=None
)
# Source: mne/epochs.py
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `raw` | `Raw` | — | Continuous data to epoch. |
| `events` | `ndarray (n, 3)` | — | Events array from `mne.events_from_annotations()` or `mne.find_events()`. |
| `event_id` | `dict \| int \| None` | `None` | Mapping of condition name → event code. |
| `tmin` | `float` | `-0.2` | Start of epoch relative to event (seconds). |
| `tmax` | `float` | `0.5` | End of epoch relative to event (seconds). |
| `baseline` | `tuple (a, b) \| None` | `(None, 0)` | Baseline correction interval. `(None, 0)` = start-to-event. |
| `reject` | `dict \| None` | `None` | Peak-to-peak rejection thresholds per channel type. |
| `flat` | `dict \| None` | `None` | Minimum signal variation thresholds (detects dead channels). |
| `decim` | `int` | `1` | Downsample factor (applied after filtering). |
| `detrend` | `int \| None` | `None` | `0` for DC removal, `1` for linear detrend, `None` for nothing. |
| `reject_by_annotation` | `bool` | `True` | Exclude epochs overlapping `BAD_*` annotations. |

**Example (typical ERP replication):**

```python
import mne
import numpy as np

# Get events from annotations
events, event_id = mne.events_from_annotations(raw)
print(f"Event mapping: {event_id}")

# Select conditions matching the paper
# Paper says: "Epochs were extracted from -200 to 800 ms"
epochs = mne.Epochs(
    raw,
    events,
    event_id={"face": 1, "car": 2},  # map to paper's conditions
    tmin=-0.2,
    tmax=0.8,
    baseline=(-0.2, 0),  # "baseline corrected using -200 to 0 ms"
    reject=dict(eeg=100e-6),  # "epochs exceeding ±100 µV were rejected"
    preload=True,
)
print(f"Kept {len(epochs)} of {len(events)} epochs")
print(f"  face: {len(epochs['face'])}, car: {len(epochs['car'])}")
```

**Pitfalls:**
- Event IDs from `mne.events_from_annotations()` may not match paper's codes. Always print and verify the mapping.
- Papers report epoch windows as "–200 to 800 ms" but may mean different things: check if `tmax` is inclusive or the paper used a different convention.
- `reject=dict(eeg=100e-6)` means 100 µV peak-to-peak. Papers sometimes report "±100 µV" which means the same 200 µV peak-to-peak range, or sometimes truly ±100 µV from zero.
- `baseline=(None, 0)` uses the entire pre-stimulus interval. If the paper says "–100 to 0 ms baseline", use `baseline=(-0.1, 0)`.

---

## Artifact Rejection

### Peak-to-Peak Rejection (Manual Threshold)

```python
# "Epochs with voltage exceeding ±100 µV were rejected"
epochs = mne.Epochs(raw, events, event_id, tmin=-0.2, tmax=0.8,
                    reject=dict(eeg=100e-6),  # 100 µV in volts
                    preload=True)
print(f"Dropped: {len(epochs.drop_log) - len(epochs)} epochs")
```

### `autoreject` for Automated Rejection

When papers use "automated artifact rejection" or you need a robust pipeline:

**Signature:**
```text
autoreject.AutoReject(
    n_interpolate=None, consensus=None, thresh_method='bayesian_optimization',
    n_jobs=1, random_state=None, verbose=True
)
# Source: autoreject/autoreject.py
```

```python
from autoreject import AutoReject

ar = AutoReject(n_jobs=-1, random_state=42)
epochs_clean, reject_log = ar.fit_transform(epochs, return_log=True)
print(f"Rejected {reject_log.bad_epochs.sum()} epochs")
```

### EOG / Blink Rejection via ICA

### `mne.preprocessing.ICA(...)`

**Signature:**
```text
mne.preprocessing.ICA(
    n_components=None, noise_cov=None, random_state=None,
    method='fastica', fit_params=None, max_iter='auto',
    allow_ref_meg=False, verbose=None
)
# Source: mne/preprocessing/ica.py
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `n_components` | `int \| float \| None` | `None` | Number of components. `None` = rank of data. `0.999` for 99.9% variance. |
| `method` | `str` | `'fastica'` | `'fastica'`, `'infomax'`, or `'picard'`. |
| `random_state` | `int \| None` | `None` | For reproducibility. |
| `max_iter` | `int \| str` | `'auto'` | Max iterations for ICA algorithm. |

**Full ICA workflow matching common paper descriptions:**

```python
import mne

# Papers often say: "ICA was performed using the infomax algorithm"
ica = mne.preprocessing.ICA(
    n_components=15,  # or 0.999 for variance-based
    method="infomax",  # or 'fastica', 'picard'
    random_state=42,
)

# Fit on highpass-filtered copy (1 Hz) for better decomposition
raw_for_ica = raw.copy().filter(l_freq=1.0, h_freq=None)
ica.fit(raw_for_ica, picks="eeg")

# Find EOG components automatically
eog_indices, eog_scores = ica.find_bads_eog(raw, ch_name=["VEOG", "HEOG"])
ica.exclude = eog_indices
print(f"Excluding {len(eog_indices)} EOG components: {eog_indices}")

# Apply to original (not highpass copy)
ica.apply(raw)
```

**Pitfalls:**
- Fit ICA on 1 Hz highpass copy, then apply to original data. This improves decomposition without affecting final filter settings.
- `n_components` should not exceed data rank. After average reference, rank = n_channels - 1.
- If no EOG channel exists, use `ica.find_bads_eog(raw, ch_name="Fp1")` (frontal channel).
- Papers using EEGLAB's `runica` correspond to `method='infomax'` with `fit_params=dict(extended=True)`.

---

## Bad Channel Detection and Interpolation

### `raw.info['bads']` and `raw.interpolate_bads(...)`

```python
# Manual (from paper's exclusion list):
raw.info["bads"] = ["Fp1", "T8"]

# Automatic detection:
from mne.preprocessing import find_bad_channels_maxwell  # for MEG
# For EEG, use RANSAC from autoreject:
from autoreject import Ransac
ransac = Ransac(n_jobs=-1, random_state=42)
ransac.fit(epochs)
print(f"Bad channels: {ransac.bad_chs_}")
epochs.info["bads"] = ransac.bad_chs_
```

### `epochs.interpolate_bads(...)`

**Signature:**
```text
Epochs.interpolate_bads(
    reset_bads=True, mode='accurate', origin='auto',
    method=None, exclude=(), verbose=None
)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `reset_bads` | `bool` | `True` | Clear `info['bads']` after interpolation. |
| `mode` | `str` | `'accurate'` | `'accurate'` (spherical splines) or `'fast'`. |

```python
# Interpolate and clear bads list
epochs.interpolate_bads(reset_bads=True)
```

---

## Downsampling / Resampling

### `raw.resample(...)`

**Signature:**
```text
Raw.resample(
    sfreq, npad='auto', window='auto', stim_picks=None,
    n_jobs=None, events=None, pad='auto', method='fft',
    verbose=None
)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `sfreq` | `float` | — | New sampling frequency in Hz. |
| `npad` | `int \| str` | `'auto'` | Padding for FFT. |
| `method` | `str` | `'fft'` | `'fft'` or `'polyphase'`. |

```python
# "Data were downsampled to 256 Hz"
raw.resample(sfreq=256)

# Or after epoching (preferred — avoids jitter):
epochs.resample(sfreq=256)
```

**Pitfalls:**
- Apply anti-aliasing filter (lowpass) before resampling if not already done.
- Resample AFTER epoching when possible — resampling continuous data can shift event timing by up to 1 sample.
- Event times are automatically adjusted when using `raw.resample(events=events)`.

---

## Preprocessing Order (Standard Replication Template)

Most ERP papers follow this order. Match the paper's described sequence exactly:

```python
# 1. Load data
raw = mne.io.read_raw_eeglab(fname, preload=True)

# 2. Set montage (if not embedded)
raw.set_montage("standard_1020", on_missing="warn")

# 3. Filter
raw.filter(l_freq=0.1, h_freq=30.0)
raw.notch_filter(freqs=50.0)  # if paper mentions it

# 4. Re-reference
raw.set_eeg_reference(ref_channels="average", projection=False)

# 5. ICA artifact correction (if paper used ICA)
ica = mne.preprocessing.ICA(n_components=15, method="infomax", random_state=42)
raw_ica = raw.copy().filter(l_freq=1.0, h_freq=None)
ica.fit(raw_ica, picks="eeg")
eog_idx, _ = ica.find_bads_eog(raw)
ica.exclude = eog_idx
ica.apply(raw)

# 6. Epoch
events, event_id = mne.events_from_annotations(raw)
epochs = mne.Epochs(raw, events, event_id, tmin=-0.2, tmax=0.8,
                    baseline=(-0.2, 0), reject=dict(eeg=100e-6), preload=True)

# 7. (Optional) Interpolate bad channels
epochs.interpolate_bads(reset_bads=True)

# 8. Proceed to analysis
evoked = epochs.average()
```

**Warning:** Some papers filter AFTER epoching or re-reference before filtering. Always follow the paper's stated order, even if it's non-standard.
