<!-- openneuro-replication-skills | domain: ERP Analysis -->
<!-- target libraries: mne>=1.6, numpy, scipy>=1.11 -->

# Domain: ERP Analysis for Replication

ERP replication requires extracting the same components, at the same electrodes,
in the same time windows as the original paper. This reference covers the core
analysis functions with exact signatures.

---

## Computing Evoked Responses

### `epochs.average(...)`

**Signature:**
```text
Epochs.average(
    picks=None, method='mean', by_event_type=False
)
# Returns: Evoked | list[Evoked]
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `picks` | `str \| list \| None` | `None` | Channels to include. `None` = all good channels. |
| `method` | `str \| callable` | `'mean'` | `'mean'` or `'median'` or custom function. |
| `by_event_type` | `bool` | `False` | If `True`, return separate `Evoked` per condition. |

**Example (standard ERP replication):**

```python
# Per-condition evoked responses
evoked_face = epochs["face"].average()
evoked_car = epochs["car"].average()

# Or use by_event_type for all at once
evokeds = epochs.average(by_event_type=True)  # list of Evoked objects

# Grand average across subjects
grand_avg_face = mne.grand_average([subj_evoked_face for subj_evoked_face in all_subjects])
```

### `mne.grand_average(...)`

**Signature:**
```text
mne.grand_average(
    all_inst, interpolate_bads=True, drop_bads=True
)
# Returns: Evoked
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `all_inst` | `list of Evoked` | — | One `Evoked` per subject/condition. |
| `interpolate_bads` | `bool` | `True` | Interpolate bad channels before averaging. |
| `drop_bads` | `bool` | `True` | Drop channels marked bad in any subject. |

---

## Mean Amplitude in Time Window

The most common ERP measure: average voltage in a specified time window at specified electrodes.

### `evoked.get_data(...)` + numpy

```python
import numpy as np

def mean_amplitude(evoked, tmin, tmax, picks):
    """Extract mean amplitude in a time window at selected channels.

    Args:
        evoked: mne.Evoked object
        tmin: Start of window in seconds (e.g., 0.150)
        tmax: End of window in seconds (e.g., 0.200)
        picks: Channel name(s) (str or list of str)

    Returns:
        float: Mean amplitude in volts (multiply by 1e6 for µV)
    """
    data = evoked.copy().pick(picks).get_data()  # (n_channels, n_times)
    times = evoked.times
    time_mask = (times >= tmin) & (times <= tmax)
    return data[:, time_mask].mean() * 1e6  # convert to µV
```

**Full replication example:**

```python
# Paper says: "N170 mean amplitude was measured at P7/P8, 150–200 ms"
n170_face = mean_amplitude(evoked_face, tmin=0.150, tmax=0.200, picks=["P7", "P8"])
n170_car = mean_amplitude(evoked_car, tmin=0.150, tmax=0.200, picks=["P7", "P8"])
print(f"N170 face: {n170_face:.2f} µV")
print(f"N170 car:  {n170_car:.2f} µV")
print(f"Difference: {n170_face - n170_car:.2f} µV")
```

**Pitfalls:**
- MNE stores data in **volts**. Papers report in **µV**. Always multiply by `1e6`.
- Papers may report "peak amplitude" (single max/min) vs "mean amplitude" (average in window). These give different values.
- Time window boundaries: check if the paper says "150–200 ms" inclusive or exclusive. Use `>=` and `<=` for inclusive.

---

## Peak Amplitude and Latency

### `evoked.get_peak(...)`

**Signature:**
```text
Evoked.get_peak(
    ch_type=None, tmin=None, tmax=None, mode='abs',
    time_as_index=False, merge_grads=False, return_amplitude=False
)
# Returns: (channel_name, latency) or (channel_name, latency, amplitude)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `ch_type` | `str \| None` | `None` | Restrict to channel type (e.g., `'eeg'`). |
| `tmin` | `float \| None` | `None` | Start of search window (seconds). |
| `tmax` | `float \| None` | `None` | End of search window (seconds). |
| `mode` | `str` | `'abs'` | `'pos'` for positive peak, `'neg'` for negative, `'abs'` for either. |
| `return_amplitude` | `bool` | `False` | If `True`, also return the amplitude value. |

**Example:**

```python
# "N170 peak latency was identified as the most negative peak between 130–210 ms"
ch, latency, amplitude = evoked_face.get_peak(
    tmin=0.130, tmax=0.210, mode="neg", return_amplitude=True
)
print(f"N170 peak at {ch}: {latency*1000:.0f} ms, {amplitude*1e6:.2f} µV")
```

### Custom peak detection at specific electrodes

`get_peak()` searches all channels. For specific electrodes:

```python
def peak_at_channels(evoked, picks, tmin, tmax, mode="neg"):
    """Find peak amplitude and latency at specific channels.

    Args:
        mode: 'neg' for negative peaks (N170, N2), 'pos' for positive (P3, P1)
    """
    data = evoked.copy().pick(picks).get_data()  # (n_ch, n_times)
    times = evoked.times
    mask = (times >= tmin) & (times <= tmax)

    windowed = data[:, mask]
    mean_across_ch = windowed.mean(axis=0)  # average across selected channels

    if mode == "neg":
        idx = np.argmin(mean_across_ch)
    else:
        idx = np.argmax(mean_across_ch)

    peak_time = times[mask][idx]
    peak_amp = mean_across_ch[idx] * 1e6  # µV
    return peak_time, peak_amp

# Paper: "P3 peak at Pz between 300–500 ms"
p3_lat, p3_amp = peak_at_channels(evoked_target, picks=["Pz"], tmin=0.3, tmax=0.5, mode="pos")
print(f"P3 peak: {p3_lat*1000:.0f} ms, {p3_amp:.2f} µV")
```

---

## Difference Waves

```python
# "The N170 face effect was computed as face minus car"
diff_wave = mne.combine_evoked([evoked_face, evoked_car], weights=[1, -1])

# Measure on the difference wave
n170_effect = mean_amplitude(diff_wave, tmin=0.150, tmax=0.200, picks=["P7", "P8"])
print(f"N170 face effect: {n170_effect:.2f} µV")
```

### `mne.combine_evoked(...)`

**Signature:**
```text
mne.combine_evoked(
    all_evoked, weights='nave'
)
# Returns: Evoked
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `all_evoked` | `list of Evoked` | — | Evoked objects to combine. |
| `weights` | `list of float \| str` | `'nave'` | Per-evoked weights. `[1, -1]` for subtraction. `'equal'` for simple average. |

---

## Laterality Indices

Common in N170 and language lateralization studies:

```python
def laterality_index(evoked, left_picks, right_picks, tmin, tmax):
    """Compute laterality index: (R - L) / (|R| + |L|)."""
    left = mean_amplitude(evoked, tmin, tmax, left_picks)
    right = mean_amplitude(evoked, tmin, tmax, right_picks)
    return (right - left) / (abs(right) + abs(left))

# "N170 laterality computed over P7 (left) vs P8 (right)"
li = laterality_index(evoked_face, ["P7"], ["P8"], 0.150, 0.200)
print(f"N170 laterality index: {li:.3f}")  # positive = right-lateralized
```

---

## Extracting Per-Subject, Per-Condition Amplitudes for Statistics

The bridge between ERP analysis and statistical testing:

```python
import pandas as pd
import numpy as np

def extract_erp_amplitudes(epochs, conditions, picks, tmin, tmax, subject_id):
    """Extract mean amplitudes for statistical analysis.

    Returns DataFrame with columns: subject, condition, amplitude
    """
    rows = []
    for cond_name in conditions:
        cond_epochs = epochs[cond_name]
        evoked = cond_epochs.average()
        amp = mean_amplitude(evoked, tmin, tmax, picks)
        rows.append({
            "subject": subject_id,
            "condition": cond_name,
            "amplitude": amp,
            "n_epochs": len(cond_epochs),
        })
    return pd.DataFrame(rows)

# Per-subject extraction (loop across subjects)
all_data = []
for subj_id, subj_epochs in subject_epochs.items():
    df = extract_erp_amplitudes(
        subj_epochs,
        conditions=["face", "car"],
        picks=["P7", "P8"],
        tmin=0.150,
        tmax=0.200,
        subject_id=subj_id,
    )
    all_data.append(df)

results = pd.concat(all_data, ignore_index=True)
print(results.groupby("condition")["amplitude"].describe())
```

---

## Common ERP Components Reference

| Component | Polarity | Typical Window | Typical Sites | Common Paradigm |
|-----------|----------|---------------|---------------|-----------------|
| P1 | Positive | 80–130 ms | O1, O2, Oz | Visual onset |
| N1 / N100 | Negative | 80–150 ms | Cz, Fz | Auditory onset |
| N170 | Negative | 140–200 ms | P7, P8, PO7, PO8 | Face/object perception |
| N2 / N200 | Negative | 200–350 ms | Fz, FCz | Conflict, novelty |
| P2 / P200 | Positive | 150–250 ms | Cz, Fz | Attention, repetition |
| N2pc | Negative | 200–300 ms | PO7/PO8 contralateral | Visual search |
| P3a | Positive | 250–350 ms | Fz, FCz | Novelty, distraction |
| P3b / P300 | Positive | 300–600 ms | Pz, CPz | Oddball target |
| N400 | Negative | 300–500 ms | Cz, CPz | Semantic violation |
| P600 / LPC | Positive | 500–800 ms | Pz, CPz | Syntactic / memory |
| ERN | Negative | 0–100 ms post-resp | FCz, Cz | Error monitoring |
| LRP | Neg/Pos | -500–0 ms pre-resp | C3, C4 | Motor preparation |

---

## Time-Frequency Analysis (When Paper Uses It)

### `mne.time_frequency.tfr_morlet(...)`

**Signature:**
```text
mne.time_frequency.tfr_morlet(
    inst, freqs, n_cycles, use_fft=False, return_itc=True,
    decim=1, n_jobs=None, picks=None, zero_mean=True,
    average=True, output='power', verbose=None
)
# Returns: AverageTFR (or EpochsTFR if average=False)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `inst` | `Epochs \| Evoked` | — | Data to transform. |
| `freqs` | `ndarray` | — | Frequencies of interest in Hz. |
| `n_cycles` | `float \| ndarray` | — | Wavelet cycles. `freqs / 2` is common. |
| `return_itc` | `bool` | `True` | Also return inter-trial coherence. |
| `average` | `bool` | `True` | Average across epochs. |
| `output` | `str` | `'power'` | `'power'`, `'complex'`, `'phase'`. |

```python
import numpy as np
import mne.time_frequency

freqs = np.arange(4, 40, 1)  # 4–39 Hz
n_cycles = freqs / 2  # adaptive cycles

power, itc = mne.time_frequency.tfr_morlet(
    epochs["target"],
    freqs=freqs,
    n_cycles=n_cycles,
    return_itc=True,
    n_jobs=-1,
)
power.plot(picks=["Pz"], baseline=(-0.2, 0), mode="logratio",
           title="Target power at Pz")
```
