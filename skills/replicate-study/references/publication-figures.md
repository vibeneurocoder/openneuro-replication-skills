<!-- openneuro-replication-skills | domain: Publication-Quality Figures -->
<!-- target libraries: matplotlib>=3.7, mne>=1.6, nilearn>=0.10 -->

# Domain: Publication-Quality Figures for Replication

Replication papers need figures that directly compare with the original.
Match the paper's figure style wherever possible.

---

## Global Figure Defaults

Set once at the top of every replication script:

```python
import matplotlib
matplotlib.use("Agg")  # non-interactive backend for scripts
import matplotlib.pyplot as plt

# Publication defaults
plt.rcParams.update({
    "figure.dpi": 300,
    "savefig.dpi": 300,
    "savefig.bbox_inches": "tight",
    "font.size": 10,
    "axes.titlesize": 11,
    "axes.labelsize": 10,
    "xtick.labelsize": 9,
    "ytick.labelsize": 9,
    "legend.fontsize": 9,
    "font.family": "sans-serif",
    "font.sans-serif": ["Arial", "DejaVu Sans"],
    "axes.spines.top": False,
    "axes.spines.right": False,
    "figure.facecolor": "white",
    "axes.facecolor": "white",
})
```

---

## Color Palette (Colorblind-Safe)

### Okabe-Ito Palette (Recommended)

```python
# Okabe-Ito: universally readable, recommended by Nature and most journals
COLORS = {
    "orange":     "#E69F00",
    "sky_blue":   "#56B4E9",
    "green":      "#009E73",
    "yellow":     "#F0E442",
    "blue":       "#0072B2",
    "vermillion": "#D55E00",
    "purple":     "#CC79A7",
    "black":      "#000000",
}

# For 2-condition ERP comparisons:
COLOR_A = COLORS["blue"]       # condition A (e.g., face)
COLOR_B = COLORS["vermillion"] # condition B (e.g., car)
COLOR_DIFF = COLORS["green"]   # difference wave
```

### Condition-to-Color Mapping Convention

```python
def get_condition_colors(conditions):
    """Assign colorblind-safe colors to conditions."""
    palette = ["#0072B2", "#D55E00", "#009E73", "#E69F00", "#56B4E9", "#CC79A7"]
    return {cond: palette[i % len(palette)] for i, cond in enumerate(conditions)}
```

---

## ERP Waveform Plot

The most common figure in ERP replication papers.

### `mne.viz.plot_compare_evokeds(...)`

**Signature:**
```text
mne.viz.plot_compare_evokeds(
    evokeds, picks=None, combine=None, colors=None,
    linestyles=None, styles=None, ci=True, gfp=False,
    truncate_yaxis='auto', truncate_xaxis=True,
    ylim=None, invert_y=False, legend='upper left',
    show_sensors=None, title=None, axes=None,
    show=True, split_legend=None, vlines='auto'
)
# Returns: list of Figure
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `evokeds` | `dict \| list` | — | `{name: Evoked}` or `{name: [list of Evoked per subject]}`. |
| `picks` | `str \| list` | `None` | Channel(s) to plot. |
| `combine` | `str \| None` | `None` | `'mean'`, `'median'`, `'gfp'` for multi-channel. |
| `ci` | `bool \| float` | `True` | Confidence interval (requires list of Evoked per condition). |
| `colors` | `dict` | `None` | `{condition_name: color}`. |
| `invert_y` | `bool` | `False` | `True` for negative-up convention (common in ERP papers). |
| `ylim` | `dict` | `None` | `{"eeg": [-5, 5]}` in µV. |

**Example (standard ERP comparison figure):**

```python
import mne

fig = mne.viz.plot_compare_evokeds(
    {"Face": evoked_face, "Car": evoked_car},
    picks=["P7", "P8"],
    combine="mean",
    colors={"Face": "#0072B2", "Car": "#D55E00"},
    invert_y=True,        # negative up (ERP convention)
    ylim=dict(eeg=[-8, 4]),
    title="N170 at P7/P8",
    show=False,
)
fig[0].savefig("figures/n170_erp.png", dpi=300)
```

### Custom ERP Plot with matplotlib (More Control)

```python
import numpy as np
import matplotlib.pyplot as plt

def plot_erp_comparison(evokeds, picks, conditions, colors, tmin_shade=None,
                        tmax_shade=None, title="", ylabel="Amplitude (µV)",
                        invert_y=True, figsize=(8, 4)):
    """Publication-quality ERP comparison plot.

    Args:
        evokeds: dict of {condition: Evoked}
        picks: list of channel names to average
        conditions: list of condition names (plot order)
        colors: dict of {condition: color}
        tmin_shade, tmax_shade: time window to highlight (seconds)
        invert_y: True for negative-up convention
    """
    fig, ax = plt.subplots(figsize=figsize)

    for cond in conditions:
        ev = evokeds[cond].copy().pick(picks)
        data = ev.get_data().mean(axis=0) * 1e6  # µV
        times = ev.times * 1000  # ms
        ax.plot(times, data, color=colors[cond], linewidth=1.5, label=cond)

    # Time window highlight
    if tmin_shade is not None and tmax_shade is not None:
        ax.axvspan(tmin_shade * 1000, tmax_shade * 1000, alpha=0.15,
                   color="gray", label=f"{tmin_shade*1000:.0f}–{tmax_shade*1000:.0f} ms")

    # Reference lines
    ax.axhline(0, color="black", linewidth=0.5, linestyle="-")
    ax.axvline(0, color="black", linewidth=0.5, linestyle="--")

    # Labels
    ax.set_xlabel("Time (ms)")
    ax.set_ylabel(ylabel)
    ax.set_title(title)
    ax.legend(frameon=False)

    if invert_y:
        ax.invert_yaxis()

    fig.tight_layout()
    return fig

# Usage:
fig = plot_erp_comparison(
    evokeds={"Face": evoked_face, "Car": evoked_car},
    picks=["P7", "P8"],
    conditions=["Face", "Car"],
    colors={"Face": "#0072B2", "Car": "#D55E00"},
    tmin_shade=0.150, tmax_shade=0.200,
    title="N170 at P7/P8",
)
fig.savefig("figures/n170_erp.png", dpi=300)
plt.close(fig)
```

---

## Topographic Map

### `mne.viz.plot_topomap(...)`

**Signature:**
```text
mne.viz.plot_topomap(
    data, pos, vmin=None, vmax=None, cmap=None,
    sensors=True, res=64, axes=None, names=None,
    show_names=False, mask=None, mask_params=None,
    outlines='head', contours=6, image_interp='cubic',
    show=True, onselect=None, extrapolate='auto',
    sphere=None, border='mean', ch_type='eeg',
    cnorm=None, vlim=(None, None)
)
```

**Example (topographic map at a time point):**

```python
import mne

# Topomap at N170 peak
fig = evoked_face.plot_topomap(
    times=[0.170],
    average=0.040,  # average ±20 ms around the time point
    cmap="RdBu_r",
    vlim=(-5, 5),
    show=False,
)
fig.savefig("figures/n170_topo.png", dpi=300)
```

### Multi-Time Topographic Map

```python
fig = evoked_face.plot_topomap(
    times=[0.100, 0.150, 0.170, 0.200, 0.300],
    average=0.020,
    cmap="RdBu_r",
    vlim=(-5, 5),
    show=False,
    nrows=1,
)
fig.savefig("figures/topo_timeseries.png", dpi=300)
```

---

## EEG Sensor Layout / Montage Plot

```python
import mne

# Plot channel positions on head model
montage = mne.channels.make_standard_montage("standard_1020")
fig = montage.plot(show_names=True, kind="topomap", show=False)
fig.savefig("figures/sensor_layout.png", dpi=300)

# Plot from raw/epochs info (shows actual channel positions in data)
fig = raw.plot_sensors(show_names=True, show=False)
fig.savefig("figures/data_sensor_layout.png", dpi=300)

# 3D sensor layout
fig = raw.plot_sensors(kind="3d", show=False)
fig.savefig("figures/sensors_3d.png", dpi=300)
```

### Highlight Specific Channels on Sensor Layout

```python
import mne
import matplotlib.pyplot as plt

def plot_roi_sensors(info, roi_channels, title="", figsize=(5, 5)):
    """Plot sensor layout with ROI channels highlighted."""
    fig, ax = plt.subplots(figsize=figsize)
    mne.viz.plot_sensors(
        info, show_names=True, axes=ax, show=False,
    )
    # Highlight ROI channels
    pos = mne.channels.layout._find_topomap_coords(info, picks=roi_channels)
    ax.scatter(pos[:, 0], pos[:, 1], s=100, c="red", edgecolors="black",
               linewidths=1.5, zorder=10, label="ROI")
    ax.set_title(title)
    ax.legend(frameon=False)
    fig.tight_layout()
    return fig

# Usage: highlight P7/P8 for N170 analysis
fig = plot_roi_sensors(
    epochs.info,
    roi_channels=["P7", "P8"],
    title="N170 electrode sites",
)
fig.savefig("figures/n170_sensors.png", dpi=300)
plt.close(fig)
```

---

## ERP Joint Plot (Waveform + Topomaps)

The most informative single-figure ERP visualization.

### `evoked.plot_joint(...)`

**Signature:**
```text
Evoked.plot_joint(
    times='peaks', title='', picks=None,
    exclude='bads', show=True, ts_args=None,
    topomap_args=None
)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `times` | `list \| str` | `'peaks'` | Time points for topomaps (seconds). `'peaks'` auto-detects. |
| `ts_args` | `dict \| None` | `None` | Kwargs for the ERP time series plot. |
| `topomap_args` | `dict \| None` | `None` | Kwargs for the topomap subplots. |

```python
import mne

# Auto-detect peaks
fig = evoked_face.plot_joint(
    title="Face ERP",
    ts_args=dict(spatial_colors=True),
    topomap_args=dict(cmap="RdBu_r", vlim=(-5, 5)),
    show=False,
)
fig.savefig("figures/face_erp_joint.png", dpi=300)

# Specific time points matching paper's analysis windows
fig = evoked_face.plot_joint(
    times=[0.100, 0.170, 0.300, 0.500],  # P1, N170, P3, LPC
    title="Face ERP with topographies",
    topomap_args=dict(cmap="RdBu_r", vlim=(-5, 5)),
    show=False,
)
fig.savefig("figures/face_erp_joint_custom.png", dpi=300)
```

---

## ERP Image (Single-Trial Heatmap)

Shows individual trial activity sorted by amplitude, RT, or condition:

### `epochs.plot_image(...)`

**Signature:**
```text
Epochs.plot_image(
    picks=None, sigma=0.0, vmin=None, vmax=None,
    colorbar=True, order=None, show=True, units=None,
    scalings=None, cmap='RdBu_r', fig=None, axes=None,
    overlay_times=None, combine=None, group_by=None,
    evoked=True, ts_args=None, title=None, clear=False
)
```

```python
# Single-trial heatmap at Pz
fig = epochs["target"].plot_image(
    picks=["Pz"],
    cmap="RdBu_r",
    vmin=-10, vmax=10,       # µV
    title="P300 at Pz — single trials",
    show=False,
)
fig.savefig("figures/erp_image_pz.png", dpi=300)

# Sort by reaction time
import numpy as np
rt_order = np.argsort(reaction_times)
fig = epochs["target"].plot_image(
    picks=["Pz"],
    order=rt_order,
    cmap="RdBu_r",
    title="P300 sorted by RT",
    show=False,
)
fig.savefig("figures/erp_image_sorted.png", dpi=300)
```

---

## Butterfly Plot

All channels overlaid to show the global spatiotemporal pattern:

```python
# Standard butterfly with spatial colors
fig = evoked_face.plot(
    spatial_colors=True,
    gfp=True,               # show Global Field Power trace
    time_unit="ms",
    show=False,
)
fig.savefig("figures/butterfly_face.png", dpi=300)
```

---

## GFP (Global Field Power) Plot

```python
import numpy as np
import matplotlib.pyplot as plt

def plot_gfp(evokeds, conditions, colors, title="Global Field Power",
             figsize=(8, 3)):
    """Plot GFP for multiple conditions."""
    fig, ax = plt.subplots(figsize=figsize)

    for cond in conditions:
        ev = evokeds[cond]
        gfp = ev.get_data().std(axis=0) * 1e6  # µV
        times = ev.times * 1000  # ms
        ax.plot(times, gfp, color=colors[cond], linewidth=1.5, label=cond)

    ax.axvline(0, color="black", linewidth=0.5, linestyle="--")
    ax.set_xlabel("Time (ms)")
    ax.set_ylabel("GFP (µV)")
    ax.set_title(title)
    ax.legend(frameon=False)
    fig.tight_layout()
    return fig

fig = plot_gfp(
    {"Face": evoked_face, "Car": evoked_car},
    conditions=["Face", "Car"],
    colors={"Face": "#0072B2", "Car": "#D55E00"},
)
fig.savefig("figures/gfp.png", dpi=300)
plt.close(fig)
```

---

## Power Spectral Density (PSD) Plot

```python
import mne

# PSD of raw data
fig = raw.compute_psd(fmin=0.5, fmax=50).plot(show=False)
fig.savefig("figures/psd_raw.png", dpi=300)

# PSD by condition
fig, ax = plt.subplots(figsize=(8, 4))
for cond, color in [("face", "#0072B2"), ("car", "#D55E00")]:
    psd = epochs[cond].compute_psd(fmin=1, fmax=40)
    psd.plot(axes=ax, color=color, show=False, spatial_colors=False)
ax.set_title("Power Spectral Density by Condition")
ax.legend(["Face", "Car"], frameon=False)
fig.savefig("figures/psd_conditions.png", dpi=300)
```

---

## Time-Frequency Plot

```python
import mne
import numpy as np

freqs = np.arange(4, 40, 1)
n_cycles = freqs / 2

power = mne.time_frequency.tfr_morlet(
    epochs["target"], freqs=freqs, n_cycles=n_cycles,
    return_itc=False, n_jobs=-1,
)

# Standard TF plot with baseline correction
fig = power.plot(
    picks=["Pz"],
    baseline=(-0.2, 0),
    mode="logratio",           # dB scale: 10 * log10(power / baseline)
    cmap="RdBu_r",
    title="Time-Frequency at Pz (Target)",
    show=False,
)
fig.savefig("figures/tf_pz.png", dpi=300)

# TF topomaps at specific frequency bands
fig = power.plot_topomap(
    tmin=0.3, tmax=0.5,        # P300 window
    fmin=8, fmax=13,            # alpha band
    baseline=(-0.2, 0),
    mode="logratio",
    title="Alpha power (300-500 ms)",
    show=False,
)
fig.savefig("figures/tf_alpha_topo.png", dpi=300)
```

---

## ICA Component Visualization

```python
import mne

# Component topomaps (grid)
fig = ica.plot_components(picks=range(15), show=False)
fig.savefig("figures/ica_components.png", dpi=300)

# Component time series
fig = ica.plot_sources(raw, picks=range(5), show=False)
fig.savefig("figures/ica_sources.png", dpi=300)

# Properties of a specific component (topo + time + spectrum + epochs)
fig = ica.plot_properties(epochs, picks=[0], show=False)
fig[0].savefig("figures/ica_component0_props.png", dpi=300)

# Overlay: before vs after ICA
fig = ica.plot_overlay(raw, exclude=ica.exclude, show=False)
fig.savefig("figures/ica_overlay.png", dpi=300)
```

---

## EEG Source Localization Visualization

```python
import mne

# Volume source estimate on MNI slices
fig = mne.viz.plot_volume_source_estimates(
    stc, src,
    subjects_dir=subjects_dir,
    mode="stat_map",
    show=False,
)

# Surface source estimate (requires pyvista or matplotlib 3D)
brain = stc.plot(
    hemi="both",
    views=["lateral", "medial"],
    subjects_dir=subjects_dir,
    subject="fsaverage",
    clim=dict(kind="percent", lims=[90, 95, 99]),
    smoothing_steps=7,
    time_viewer=False,
)
brain.save_image("figures/source_estimate.png")
```

---

## Multi-Subject ERP Comparison (Spaghetti Plot)

```python
import matplotlib.pyplot as plt
import numpy as np

def plot_subject_erps(all_evokeds, picks, condition, color, title="",
                       figsize=(8, 4)):
    """Plot individual subject ERPs with grand average overlay."""
    fig, ax = plt.subplots(figsize=figsize)

    # Individual subjects (thin, transparent)
    for ev in all_evokeds:
        data = ev.copy().pick(picks).get_data().mean(axis=0) * 1e6
        times = ev.times * 1000
        ax.plot(times, data, color=color, alpha=0.2, linewidth=0.5)

    # Grand average (thick)
    import mne
    grand = mne.grand_average(all_evokeds)
    data = grand.copy().pick(picks).get_data().mean(axis=0) * 1e6
    ax.plot(times, data, color=color, linewidth=2.5, label=f"Grand average (N={len(all_evokeds)})")

    ax.axhline(0, color="black", linewidth=0.5)
    ax.axvline(0, color="black", linewidth=0.5, linestyle="--")
    ax.invert_yaxis()
    ax.set_xlabel("Time (ms)")
    ax.set_ylabel("Amplitude (µV)")
    ax.set_title(title)
    ax.legend(frameon=False)
    fig.tight_layout()
    return fig

fig = plot_subject_erps(
    [subj_evoked_face for subj_evoked_face in all_subjects_face],
    picks=["P7", "P8"],
    condition="Face",
    color="#0072B2",
    title="Individual subject ERPs — Face N170",
)
fig.savefig("figures/subject_erps.png", dpi=300)
plt.close(fig)
```

---

## Topographic Map Difference (Condition A − Condition B)

```python
import mne

# Create difference evoked
diff = mne.combine_evoked([evoked_face, evoked_car], weights=[1, -1])

# Difference topography at component peak
fig = diff.plot_topomap(
    times=[0.170],
    average=0.040,           # ±20 ms
    cmap="RdBu_r",
    vlim=(-3, 3),
    title="Face − Car at N170",
    show=False,
)
fig.savefig("figures/topo_diff_n170.png", dpi=300)

# Difference topography time series
fig = diff.plot_topomap(
    times=[0.100, 0.150, 0.170, 0.200, 0.250, 0.300],
    average=0.020,
    cmap="RdBu_r",
    vlim=(-3, 3),
    nrows=1,
    show=False,
)
fig.savefig("figures/topo_diff_series.png", dpi=300)
```

---

## Bar Plot with Individual Data Points

For mean amplitude or effect size comparisons:

```python
import matplotlib.pyplot as plt
import numpy as np

def plot_bar_with_points(data_dict, colors, ylabel="Mean Amplitude (µV)",
                         title="", figsize=(4, 5)):
    """Bar plot with individual subject points overlaid.

    Args:
        data_dict: {condition_name: array of per-subject values}
        colors: {condition_name: color}
    """
    fig, ax = plt.subplots(figsize=figsize)
    conditions = list(data_dict.keys())
    x_positions = np.arange(len(conditions))

    for i, cond in enumerate(conditions):
        values = np.array(data_dict[cond])
        mean_val = values.mean()
        sem_val = values.std() / np.sqrt(len(values))

        # Bar
        ax.bar(i, mean_val, width=0.6, color=colors[cond], alpha=0.7,
               edgecolor="black", linewidth=0.5)

        # Error bar (SEM)
        ax.errorbar(i, mean_val, yerr=sem_val, color="black",
                    capsize=4, linewidth=1.5, capthick=1.5)

        # Individual data points
        jitter = np.random.normal(0, 0.05, len(values))
        ax.scatter(np.full(len(values), i) + jitter, values,
                   color=colors[cond], edgecolor="black", linewidth=0.5,
                   s=20, zorder=3, alpha=0.6)

    ax.set_xticks(x_positions)
    ax.set_xticklabels(conditions)
    ax.set_ylabel(ylabel)
    ax.set_title(title)
    ax.axhline(0, color="black", linewidth=0.5)

    fig.tight_layout()
    return fig

# Usage:
fig = plot_bar_with_points(
    {"Face": face_amplitudes, "Car": car_amplitudes},
    colors={"Face": "#0072B2", "Car": "#D55E00"},
    ylabel="N170 Mean Amplitude (µV)",
    title="N170 at P7/P8 (150–200 ms)",
)
fig.savefig("figures/n170_bar.png", dpi=300)
plt.close(fig)
```

---

## Multi-Panel Figure Layout

For combining ERP waveform, topography, and bar plot:

```python
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import string

def create_replication_figure(figsize=(12, 4)):
    """Create standard 3-panel replication figure layout."""
    fig = plt.figure(figsize=figsize)
    gs = gridspec.GridSpec(1, 3, width_ratios=[2, 1, 1], wspace=0.3)

    ax_erp = fig.add_subplot(gs[0])    # Panel A: ERP waveform
    ax_topo = fig.add_subplot(gs[1])   # Panel B: Topography
    ax_bar = fig.add_subplot(gs[2])    # Panel C: Bar plot

    # Panel labels
    for ax, label in zip([ax_erp, ax_topo, ax_bar], string.ascii_uppercase):
        ax.text(-0.15, 1.05, label, transform=ax.transAxes,
                fontsize=14, fontweight="bold", va="top")

    return fig, (ax_erp, ax_topo, ax_bar)

fig, (ax_erp, ax_topo, ax_bar) = create_replication_figure()
# ... draw into each axis ...
fig.savefig("figures/figure1_replication.png", dpi=300)
fig.savefig("figures/figure1_replication.pdf")  # vector for journal submission
plt.close(fig)
```

---

## Replication Comparison Figure (Our Results vs Paper)

The key figure for any replication paper:

```python
def plot_replication_comparison(our_data, paper_data, metric_names,
                                 our_label="Replication", paper_label="Original",
                                 figsize=(8, 5)):
    """Side-by-side comparison of replication vs original results."""
    fig, ax = plt.subplots(figsize=figsize)

    n = len(metric_names)
    x = np.arange(n)
    width = 0.35

    bars1 = ax.bar(x - width/2, [our_data[m] for m in metric_names],
                   width, label=our_label, color="#0072B2", edgecolor="black", linewidth=0.5)
    bars2 = ax.bar(x + width/2, [paper_data[m] for m in metric_names],
                   width, label=paper_label, color="#D55E00", edgecolor="black", linewidth=0.5)

    ax.set_xticks(x)
    ax.set_xticklabels(metric_names, rotation=30, ha="right")
    ax.set_ylabel("Value")
    ax.set_title("Replication vs Original Results")
    ax.legend(frameon=False)
    ax.axhline(0, color="black", linewidth=0.5)

    fig.tight_layout()
    return fig
```

---

## Brain Activation Maps (fMRI)

### Statistical Map on MNI Template

```python
from nilearn import plotting

# Standard ortho view (sagittal + coronal + axial)
fig = plotting.plot_stat_map(
    z_map,
    threshold=3.0,
    display_mode="ortho",
    cut_coords=(0, -52, 18),     # focus on FFA
    cmap="cold_hot",
    colorbar=True,
    title="Face > House (z > 3.0)",
    output_file="figures/activation_ortho.png",
)

# Multi-slice axial view (common in papers)
fig = plotting.plot_stat_map(
    z_map,
    threshold=3.0,
    display_mode="z",
    cut_coords=[-20, -10, 0, 10, 20, 30, 40, 50],
    cmap="cold_hot",
    colorbar=True,
    title="Face > House",
    output_file="figures/activation_axial.png",
)

# Glass brain (three projections)
fig = plotting.plot_glass_brain(
    z_map,
    threshold=3.0,
    display_mode="lyrz",  # left, back, right, top
    colorbar=True,
    plot_abs=False,        # show positive and negative
    title="Face > House",
    output_file="figures/glass_brain.png",
)
```

### ROI Overlay on Anatomy

```python
from nilearn import plotting, datasets

# Show AAL ROI on MNI template
aal = datasets.fetch_atlas_aal()
fig = plotting.plot_roi(
    aal.maps,
    display_mode="ortho",
    cut_coords=(0, 0, 0),
    title="AAL Atlas",
    output_file="figures/aal_overlay.png",
)

# Show specific ROI (e.g., extracted amygdala mask)
fig = plotting.plot_roi(
    roi_mask_img,
    bg_img=datasets.load_mni152_template(),
    display_mode="ortho",
    cut_coords=(-24, -4, -18),
    title="Left Amygdala ROI",
    alpha=0.5,
    output_file="figures/amygdala_roi.png",
)
```

### Atlas-Based ROI Visualization with Labels

```python
from nilearn import plotting, datasets, image
import numpy as np
import nibabel as nib

def plot_atlas_roi(atlas_img, atlas_labels, roi_name, bg_img=None, **kwargs):
    """Plot a single ROI from an atlas, highlighted by name."""
    atlas_data = atlas_img.get_fdata()
    # Find the label index
    roi_idx = [i for i, lbl in enumerate(atlas_labels) if roi_name.lower() in lbl.lower()]
    if not roi_idx:
        raise ValueError(f"ROI '{roi_name}' not found. Available: {atlas_labels[:10]}...")

    # Create binary mask for this ROI
    mask = np.isin(atlas_data, [i + 1 for i in roi_idx]).astype(np.float32)
    mask_img = nib.Nifti1Image(mask, atlas_img.affine)

    return plotting.plot_roi(mask_img, bg_img=bg_img, title=roi_name, **kwargs)

# Usage: highlight left fusiform from AAL
aal = datasets.fetch_atlas_aal()
aal_img = nib.load(aal.maps)
plot_atlas_roi(aal_img, aal.labels, "Fusiform_L",
               output_file="figures/fusiform_l.png")
```

### Surface Activation Map

```python
from nilearn import plotting, datasets, surface

fsaverage = datasets.fetch_surf_fsaverage()

# Project volume stat map onto cortical surface
texture_left = surface.vol_to_surf(z_map, fsaverage["pial_left"])
texture_right = surface.vol_to_surf(z_map, fsaverage["pial_right"])

# Two-panel figure: lateral views of both hemispheres
import matplotlib.pyplot as plt

fig, axes = plt.subplots(1, 2, figsize=(12, 5),
                          subplot_kw={"projection": "3d"})

for ax, hemi, texture in zip(axes, ["left", "right"], [texture_left, texture_right]):
    plotting.plot_surf_stat_map(
        fsaverage[f"infl_{hemi}"],
        texture,
        hemi=hemi,
        view="lateral",
        threshold=3.0,
        cmap="cold_hot",
        bg_map=fsaverage[f"sulc_{hemi}"],
        axes=ax,
    )
    ax.set_title(f"{hemi.capitalize()} hemisphere")

fig.savefig("figures/surface_both_hemi.png", dpi=300, bbox_inches="tight")
plt.close(fig)
```

### Connectivity Matrix + Connectome

```python
from nilearn import plotting, datasets
import numpy as np

# Connectivity matrix heatmap
atlas = datasets.fetch_atlas_schaefer_2018(n_rois=100)
coords = plotting.find_parcellation_cut_coords(atlas.maps)

# Shortened labels for readability
short_labels = [lbl.decode().split("_", 2)[-1] if isinstance(lbl, bytes)
                else lbl.split("_", 2)[-1] for lbl in atlas.labels]

# Matrix plot
fig = plotting.plot_matrix(
    connectivity_matrix,
    labels=short_labels,
    figure=(10, 10),
    tri="lower",
    vmin=-1, vmax=1,
    title="Functional Connectivity (Schaefer 100)",
)
fig.figure.savefig("figures/connectivity_matrix.png", dpi=300, bbox_inches="tight")

# Brain network visualization
fig = plotting.plot_connectome(
    connectivity_matrix,
    coords,
    edge_threshold="95%",
    node_size=20,
    display_mode="lzr",
    colorbar=True,
    title="Top 5% Connections",
    output_file="figures/connectome.png",
)
```

---

## EEG Source Localization Visualization

```python
import mne

# Source estimate on fsaverage
brain = stc.plot(
    hemi="both",
    views=["lateral", "medial"],
    subjects_dir=subjects_dir,
    subject="fsaverage",
    clim=dict(kind="percent", lims=[90, 95, 99]),
    smoothing_steps=7,
    time_viewer=False,
)
brain.save_image("figures/source_estimate.png")

# Alternatively using nilearn (if source is volumetric)
plotting.plot_stat_map(
    stc_vol_img,
    threshold=3.0,
    title="Source localization (dSPM)",
    output_file="figures/source_vol.png",
)
```

---

## Saving Figures

```python
# For journal submission: vector format
fig.savefig("figures/figure1.pdf", dpi=300, bbox_inches="tight")
fig.savefig("figures/figure1.eps", dpi=300, bbox_inches="tight")

# For preprint / review: high-res raster
fig.savefig("figures/figure1.png", dpi=300, bbox_inches="tight")
fig.savefig("figures/figure1.tiff", dpi=300, bbox_inches="tight")

# Always close to free memory
plt.close(fig)
```

---

## Figure Checklist for Replication Papers

- [ ] **300 DPI** minimum (most journals require this)
- [ ] **Colorblind-safe** palette (Okabe-Ito or similar)
- [ ] **Panel labels** (A, B, C...) in bold, upper-left corner
- [ ] **Axis labels** with units (Time (ms), Amplitude (µV))
- [ ] **Negative up** for ERP waveforms (convention in most ERP papers)
- [ ] **Consistent y-axis** across conditions for fair comparison
- [ ] **Time window** highlighted with shading for measurement windows
- [ ] **Error bars** labeled (SEM vs SD vs 95% CI)
- [ ] **Legend** outside plot area or non-occluding position
- [ ] **Both PDF and PNG** saved (vector for submission, raster for preview)
