<!-- openneuro-replication-skills | domain: Package API Mapping -->

# Detailed MATLAB → Python Function Mapping

When a paper describes analysis in MATLAB/EEGLAB/SPM/FieldTrip, use this reference
to find the exact Python equivalent with the correct function signature.

---

## EEGLAB → MNE-Python

| EEGLAB Function | Purpose | Python Equivalent |
|----------------|---------|-------------------|
| `pop_loadset()` | Load .set file | `mne.io.read_raw_eeglab(fname, preload=True)` |
| `pop_eegfiltnew()` | FIR bandpass filter | `raw.filter(l_freq, h_freq, method='fir', fir_design='firwin')` |
| `pop_reref()` | Re-reference | `raw.set_eeg_reference(ref_channels, projection=False)` |
| `pop_epoch()` | Extract epochs | `mne.Epochs(raw, events, event_id, tmin, tmax)` |
| `pop_rmbase()` | Baseline removal | `baseline=(tmin, tmax)` parameter in `mne.Epochs()` |
| `pop_runica()` | Run ICA (infomax) | `ICA(method='infomax', fit_params=dict(extended=True)).fit(raw)` |
| `pop_selectcomps()` | Remove ICA components | `ica.exclude = [indices]; ica.apply(raw)` |
| `pop_rejepoch()` | Reject epochs manually | `epochs.drop(indices)` |
| `pop_interp()` | Interpolate channels | `raw.interpolate_bads()` or `epochs.interpolate_bads()` |
| `pop_resample()` | Resample data | `raw.resample(sfreq)` |
| `pop_saveset()` | Save dataset | `raw.save(fname)` (saves as .fif) |
| `pop_chanedit()` | Edit channel locations | `raw.set_montage(montage)` |
| `pop_select()` | Select channels | `raw.pick(picks)` |
| `eeg_checkset()` | Validate structure | (not needed in MNE — validation is automatic) |

## ERPLAB → MNE-Python

| ERPLAB Function | Purpose | Python Equivalent |
|----------------|---------|-------------------|
| `pop_averager()` | Average epochs → ERP | `epochs["condition"].average()` |
| `pop_binlister()` | Define event bins | Use `event_id` dict in `mne.Epochs()` |
| `pop_creabasiceventlist()` | Create event list | `mne.events_from_annotations(raw)` |
| `pop_artmwppth()` | Moving window artifact | `reject=dict(eeg=threshold)` in `Epochs()` |
| `pop_erpchanoperations()` | Channel math | `mne.combine_evoked()` with weights |
| `pop_erpbinoperations()` | Bin math (difference wave) | `mne.combine_evoked([a, b], weights=[1, -1])` |
| `pop_geterpvalues()` | Measure ERP amplitude | `evoked.get_data()` + time window indexing |
| `pop_filterp()` | Butterworth filter | `raw.filter(..., method='iir', iir_params=dict(order=N, ftype='butter'))` |
| `erplab_ERP.bindata` | ERP data array | `evoked.get_data()` (shape: channels × times) |
| `chanoperations` bin diff | Lateralized (contra-ipsi) | Compute per-hemisphere, then subtract |

## FieldTrip → MNE-Python

| FieldTrip Function | Purpose | Python Equivalent |
|-------------------|---------|-------------------|
| `ft_preprocessing()` | Filter + epoch | `raw.filter()` then `mne.Epochs()` |
| `ft_definetrial()` | Define trials/epochs | Event selection + `mne.Epochs()` |
| `ft_timelockanalysis()` | Time-locked average (ERP) | `epochs.average()` |
| `ft_freqanalysis()` | Time-frequency | `mne.time_frequency.tfr_morlet()` |
| `ft_sourceanalysis()` | Source localization | `mne.minimum_norm.apply_inverse()` |
| `ft_connectivityanalysis()` | Connectivity | `mne_connectivity.spectral_connectivity_epochs()` |
| `ft_statistics_*()` | Statistical testing | `mne.stats.permutation_cluster_test()` |
| `ft_rejectvisual()` | Visual artifact rejection | `epochs.plot(block=True)` or `autoreject.AutoReject()` |
| `ft_componentanalysis()` | ICA | `mne.preprocessing.ICA()` |
| `ft_rejectcomponent()` | Remove ICA components | `ica.exclude = idx; ica.apply(raw)` |
| `ft_prepare_neighbours()` | Channel adjacency | `mne.channels.find_ch_adjacency()` |
| `ft_multiplotER()` | Multi-channel ERP plot | `evoked.plot()` |
| `ft_topoplotER()` | Topographic map | `evoked.plot_topomap()` |
| `ft_singleplotER()` | Single-channel ERP plot | `evoked.plot(picks=[ch_name])` |

## SPM → nilearn

| SPM Function | Purpose | Python Equivalent |
|-------------|---------|-------------------|
| `spm_fmri_design` | Design matrix | `FirstLevelModel(hrf_model='spm')` |
| `spm_spm` | Estimate GLM | `glm.fit(func_img, events=events)` |
| `spm_contrasts` | Compute contrasts | `glm.compute_contrast("A - B")` |
| `spm_results_ui` | View results | `plotting.plot_stat_map(z_map)` |
| `spm_smooth` | Gaussian smoothing | `smoothing_fwhm=6.0` in `FirstLevelModel` |
| `spm_normalise` | MNI normalization | Already in MNI space if fMRIPrep used |
| `spm_segment` | Tissue segmentation | Use fMRIPrep output |
| `spm_realign` | Motion correction | Use fMRIPrep output |
| `spm_hrf` | HRF convolution | `hrf_model='spm'` in `FirstLevelModel` |

**SPM-specific parameter mapping:**
- SPM "128 s high-pass" → `high_pass=1/128` (0.0078 Hz)
- SPM "AR(1)" → `noise_model='ar1'`
- SPM microtime resolution/onset → handled automatically by nilearn
- SPM global normalization → `standardize=True` in `NiftiMasker`

## FSL → nilearn

| FSL Tool | Purpose | Python Equivalent |
|----------|---------|-------------------|
| `feat` | Full GLM pipeline | `FirstLevelModel` + `SecondLevelModel` |
| `fslmaths` | Image math | `nilearn.image.math_img("img1 + img2", ...)` |
| `flirt` | Registration | Use fMRIPrep output |
| `fnirt` | Non-linear reg | Use fMRIPrep output |
| `bet` | Brain extraction | Use fMRIPrep brain mask |
| `susan` | Smoothing | `smoothing_fwhm` in model or `nilearn.image.smooth_img()` |
| `cluster` | Cluster thresholding | `threshold_stats_img(..., cluster_threshold=N)` |
| `randomise` | Permutation testing | `mne.stats.permutation_cluster_test()` (conceptually similar) |

**FSL-specific parameter mapping:**
- FSL default high-pass = 100 s → `high_pass=1/100` (0.01 Hz)
- FSL double-gamma HRF → `hrf_model='glover'`
- FSL FILM → `noise_model='ar1'`

## R / JASP / SPSS → Python

| R / SPSS Function | Purpose | Python Equivalent |
|-------------------|---------|-------------------|
| `aov()` / RM-ANOVA in SPSS | Repeated-measures ANOVA | `pingouin.rm_anova(data, dv, within, subject)` |
| `t.test(paired=TRUE)` | Paired t-test | `pingouin.ttest(x, y, paired=True)` |
| `wilcox.test()` | Wilcoxon signed-rank | `pingouin.wilcoxon(x, y)` |
| `lmer()` (lme4) | Linear mixed model | `statsmodels.formula.api.mixedlm()` |
| `BayesFactor::ttestBF()` | Bayesian t-test | `BF10` column from `pingouin.ttest()` |
| `p.adjust(method='bonf')` | Multiple comparisons | `statsmodels.stats.multitest.multipletests(method='bonferroni')` |
| `p.adjust(method='BH')` | FDR correction | `multipletests(method='fdr_bh')` |
| `cohen.d()` (effsize) | Cohen's d | `cohen-d` from `pingouin.ttest()` |
| `etaSquared()` | Eta-squared | `np2` from `pingouin.rm_anova(effsize='np2')` |
| `shapiro.test()` | Normality test | `pingouin.normality(data)` |
| `leveneTest()` | Homogeneity of variance | `pingouin.homoscedasticity(data)` |
| `mauchly.test()` | Sphericity | `eps` column from `pingouin.rm_anova()` |

---

## Brain Atlases & Templates → nilearn / MNE

Papers reference atlases for ROI definition, parcellation, and reporting coordinates.
All major atlases are available through `nilearn.datasets`.

### `nilearn.datasets` Atlas Fetchers

| Atlas | Function | Regions | Use Case |
|-------|----------|---------|----------|
| AAL (Automated Anatomical Labeling) | `fetch_atlas_aal(version='SPM12')` | 116 regions | Classic ROI parcellation, SPM-convention papers |
| AAL3 | `fetch_atlas_aal(version='3v2')` | 166 regions | Updated AAL with cerebellum/subcortical subdivisions |
| Harvard-Oxford (cortical) | `fetch_atlas_harvard_oxford('cort-maxprob-thr25-2mm')` | 48 cortical | FSL-convention papers, probability-based |
| Harvard-Oxford (subcortical) | `fetch_atlas_harvard_oxford('sub-maxprob-thr25-2mm')` | 21 subcortical | Amygdala, hippocampus, thalamus ROIs |
| Schaefer 2018 | `fetch_atlas_schaefer_2018(n_rois=100)` | 100–1000 | Modern parcellation, functional networks, connectivity |
| Destrieux (FreeSurfer) | `fetch_atlas_destrieux_2009()` | 148 (74/hemi) | Surface-based, FreeSurfer convention papers |
| Talairach | `fetch_atlas_talairach('ba')` | ~40 BA areas | Brodmann area reporting |
| BASC | `fetch_atlas_basc_multiscale_2015()` | 7–444 | Multi-scale functional parcellation |
| DiFuMo | `fetch_atlas_difumo(dimension=64)` | 64–1024 | Data-driven functional modes |
| Yeo 2011 | `fetch_atlas_yeo_2011()` | 7 or 17 networks | Resting-state network assignment |
| MSDL | `fetch_atlas_msdl()` | 39 regions | Multi-subject dictionary learning |
| Smith ICA | `fetch_atlas_smith_2009()` | 10 or 20 | ICA-based resting-state networks |
| Pauli 2017 | `fetch_atlas_pauli_2017()` | 12 subcortical | High-res subcortical atlas |
| Juelich | `fetch_atlas_juelich('maxprob-thr25-2mm')` | ~121 | Cytoarchitectonic atlas |

### AAL Atlas (Most Common in Papers)

**Signature:**
```text
nilearn.datasets.fetch_atlas_aal(
    version='SPM12', data_dir=None, url=None, resume=True, verbose=1
)
# Returns: Bunch(maps, indices, labels, description)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `version` | `str` | `'SPM12'` | `'SPM12'` (AAL original) or `'3v2'` (AAL3v2, 166 regions). |

```python
from nilearn import datasets, plotting
from nilearn.maskers import NiftiLabelsMasker

# Fetch AAL atlas
aal = datasets.fetch_atlas_aal(version="SPM12")
print(f"AAL regions: {len(aal.labels)}")
print(f"Labels: {aal.labels[:10]}")  # ['Precentral_L', 'Precentral_R', ...]

# Use as ROI masker
masker = NiftiLabelsMasker(
    labels_img=aal.maps,
    labels=aal.labels,
    standardize=True,
    t_r=2.0,
)
roi_signals = masker.fit_transform(func_img, confounds=confounds)
# roi_signals shape: (n_timepoints, 116)

# Look up region by name
def get_aal_index(aal, region_name):
    """Find AAL region index by name (case-insensitive partial match)."""
    matches = [(i, lbl) for i, lbl in enumerate(aal.labels)
               if region_name.lower() in lbl.lower()]
    return matches

# Paper says "left amygdala" → find AAL index
print(get_aal_index(aal, "amygdala"))
# [(41, 'Amygdala_L'), (42, 'Amygdala_R')]
```

**Pitfalls:**
- AAL uses MNI152 space. Ensure your data is in MNI space before applying.
- AAL region numbering starts at 1 in SPM, but nilearn may use 0-indexed depending on usage.
- Some papers say "AAL atlas" but use AAL2 or AAL3 — check which version by counting regions (90 cortical in AAL, 116 total with cerebellum, 166 in AAL3).

### Harvard-Oxford Atlas

```python
# Cortical (48 regions at 25% threshold)
ho_cort = datasets.fetch_atlas_harvard_oxford("cort-maxprob-thr25-2mm")
# Subcortical (21 regions)
ho_sub = datasets.fetch_atlas_harvard_oxford("sub-maxprob-thr25-2mm")

# Probabilistic version (for weighted ROIs)
ho_prob = datasets.fetch_atlas_harvard_oxford("cort-prob-2mm")
# ho_prob.maps: 4D NIfTI (x, y, z, n_regions), each volume is a probability map
```

**Threshold variants:**
- `thr0` — no threshold (raw probability)
- `thr25` — 25% probability threshold (most common)
- `thr50` — 50% probability threshold (more conservative)

### Schaefer 2018 (Modern Functional Parcellation)

```python
# Available at 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000 parcels
atlas = datasets.fetch_atlas_schaefer_2018(
    n_rois=200,
    yeo_networks=7,  # 7 or 17 network assignment
    resolution_mm=2,
)
print(atlas.labels[:5])
# ['7Networks_LH_Vis_1', '7Networks_LH_Vis_2', ...]

# Each label contains network assignment (Vis, SomMot, DorsAttn, SalVentAttn, Limbic, Cont, Default)
```

### MNI152 Template

```python
from nilearn import datasets

# Standard MNI template for underlay
mni = datasets.load_mni152_template(resolution=2)
mni_mask = datasets.load_mni152_brain_mask(resolution=2)
mni_gm = datasets.load_mni152_gm_template(resolution=2)
mni_wm = datasets.load_mni152_wm_template(resolution=2)
```

### Desikan-Killiany / Destrieux (FreeSurfer Surface Atlases)

```python
# Destrieux (148 regions, surface-based)
destrieux = datasets.fetch_atlas_destrieux_2009()
# Use with vol_to_surf for surface projection

# For Desikan-Killiany, use FreeSurfer's aparc atlas:
# Available through nibabel.freesurfer if FreeSurfer is installed
```

### Custom ROI from MNI Coordinates

When a paper specifies an ROI by center coordinate and radius:

```python
from nilearn.maskers import NiftiSpheresMasker

# Paper: "8mm sphere centered on left FFA (-42, -52, -18)"
masker = NiftiSpheresMasker(
    seeds=[(-42, -52, -18)],  # MNI coordinates
    radius=8.0,                # mm
    standardize=True,
    t_r=2.0,
)
roi_signal = masker.fit_transform(func_img, confounds=confounds)
# roi_signal shape: (n_timepoints, 1)
```

### Multiple Coordinate-Based ROIs

```python
# Paper defines multiple ROIs by coordinates
seeds = {
    "left_FFA":  (-42, -52, -18),
    "right_FFA": (42, -52, -18),
    "left_PPA":  (-28, -40, -12),
    "right_PPA": (28, -40, -12),
    "left_EBA":  (-48, -72, 4),
    "right_EBA": (48, -72, 4),
}

masker = NiftiSpheresMasker(
    seeds=list(seeds.values()),
    radius=6.0,
    standardize=True,
    t_r=2.0,
)
roi_signals = masker.fit_transform(func_img, confounds=confounds)
# roi_signals shape: (n_timepoints, 6)
```

---

## Visualization Tool Mapping

### MATLAB Visualization → Python

| MATLAB Tool | Purpose | Python Equivalent |
|-------------|---------|-------------------|
| `xjView` | Interactive SPM result viewer | `nilearn.plotting.view_img()` → HTML interactive |
| `MRIcroGL` | 3D rendering + overlays | `nilearn.plotting.plot_stat_map()` + `plot_glass_brain()` |
| `BrainNet Viewer` | Network/connectome 3D viz | `nilearn.plotting.plot_connectome()` |
| `marsbar` | ROI definition & extraction | `NiftiLabelsMasker` / `NiftiSpheresMasker` |
| `SPM overlay` | Stat map on structural | `nilearn.plotting.plot_stat_map(bg_img=t1)` |
| `FSLeyes` | General MRI viewer | `nilearn.plotting.view_img()` or `plot_anat()` |
| `FreeSurfer tksurfer` | Surface visualization | `nilearn.plotting.plot_surf_stat_map()` |
| `CONN display` | Connectivity matrices | `nilearn.plotting.plot_matrix()` + `plot_connectome()` |
| `ft_topoplotER` (FieldTrip) | EEG/MEG topography | `mne.viz.plot_topomap()` / `evoked.plot_topomap()` |
| `ft_sourceplot` (FieldTrip) | Source localization | `mne.viz.plot_source_estimates()` |
| `topoplot()` (EEGLAB) | EEG scalp map | `mne.viz.plot_topomap()` |
| `pop_topoplot()` (EEGLAB) | ERP topography series | `evoked.plot_topomap(times=[...])` |
| `headplot()` (EEGLAB) | 3D head with scalp map | `evoked.plot_topomap()` (2D) or `pyvista` for 3D |

### nilearn Plotting Functions Reference

| Function | Purpose | Key Parameters |
|----------|---------|----------------|
| `plot_stat_map(img)` | Statistical map on MNI | `threshold`, `display_mode`, `cut_coords`, `bg_img` |
| `plot_glass_brain(img)` | Glass brain projection | `threshold`, `display_mode='lyrz'`, `colorbar` |
| `plot_anat(img)` | Structural/anatomical display | `cut_coords`, `display_mode`, `annotate` |
| `plot_roi(roi_img)` | ROI overlay on anatomy | `bg_img`, `alpha`, `display_mode` |
| `plot_epi(img)` | Functional EPI display | `cut_coords`, `display_mode` |
| `plot_prob_atlas(atlas_img)` | Probabilistic atlas overlay | `view_type='filled_contours'` |
| `plot_connectome(matrix, coords)` | Brain network graph | `node_size`, `edge_threshold`, `colorbar` |
| `plot_matrix(matrix)` | Connectivity/correlation matrix | `labels`, `figure`, `tri='lower'` |
| `plot_surf_stat_map(surf_mesh, stat_map)` | Surface statistical map | `hemi`, `view`, `threshold`, `bg_map` |
| `plot_surf(surf_mesh)` | Surface mesh rendering | `hemi`, `view`, `bg_map` |
| `view_img(img)` | Interactive HTML viewer | `threshold`, `symmetric_cmap`, `cut_coords` |
| `view_surf(surf_mesh, stat_map)` | Interactive surface viewer | `hemi`, `threshold` |
| `view_connectome(matrix, coords)` | Interactive network viewer | `edge_threshold`, `node_size` |

### nilearn Plotting Signatures

**`nilearn.plotting.plot_stat_map(...)`**

```text
nilearn.plotting.plot_stat_map(
    stat_map_img, bg_img=None, cut_coords=None,
    output_file=None, display_mode='ortho', colorbar=True,
    figure=None, axes=None, title=None, threshold=1e-6,
    annotate=True, draw_cross=True, black_bg=False,
    cmap=None, symmetric_cmap=True, dim='auto',
    vmax=None, resampling_interpolation='continuous',
    radiological=False
)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `stat_map_img` | `Nifti1Image \| str` | — | Statistical map to display. |
| `bg_img` | `Nifti1Image \| str \| None` | `None` | Background image. `None` = MNI template. |
| `cut_coords` | `int \| tuple \| None` | `None` | Slice coordinates. `None` = auto. Tuple = `(x, y, z)`. |
| `display_mode` | `str` | `'ortho'` | `'ortho'`, `'x'`, `'y'`, `'z'`, `'xz'`, `'yz'`, `'tiled'`. |
| `threshold` | `float \| None` | `1e-6` | Values below this are transparent. |
| `cmap` | `str` | `None` | Colormap. `'cold_hot'`, `'RdBu_r'`, `'viridis'`. |
| `symmetric_cmap` | `bool` | `True` | Center colormap at 0 (for pos/neg values). |
| `output_file` | `str \| None` | `None` | Save directly to file (`.png`, `.pdf`, `.svg`). |
| `radiological` | `bool` | `False` | Radiological convention (left=right). |

**`nilearn.plotting.plot_glass_brain(...)`**

```text
nilearn.plotting.plot_glass_brain(
    stat_map_img, output_file=None, display_mode='ortho',
    figure=None, axes=None, title=None, threshold='auto',
    annotate=True, black_bg=False, cmap=None,
    colorbar=False, plot_abs=True, radiological=False,
    symmetric_cmap=True, vmax=None, alpha=0.7
)
```

**`nilearn.plotting.plot_connectome(...)`**

```text
nilearn.plotting.plot_connectome(
    adjacency_matrix, node_coords, node_color='auto',
    node_size=50, edge_cmap=None, edge_vmin=None,
    edge_vmax=None, edge_threshold=None, output_file=None,
    display_mode='ortho', figure=None, axes=None,
    title=None, annotate=True, black_bg=False,
    alpha=0.7, edge_kwargs=None, node_kwargs=None,
    colorbar=False, radiological=False
)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `adjacency_matrix` | `ndarray (n, n)` | — | Connectivity matrix (symmetric). |
| `node_coords` | `ndarray (n, 3)` | — | MNI coordinates of each node. |
| `node_color` | `str \| array` | `'auto'` | Color per node. Array for network coloring. |
| `node_size` | `float \| array` | `50` | Size per node. Scale by degree or strength. |
| `edge_threshold` | `str \| float` | `None` | `'80%'` for top 20% edges, or absolute threshold. |

### EEG Montage & Channel Template Reference

| MNE Montage Name | System | Channels | Use When |
|-------------------|--------|----------|----------|
| `standard_1020` | International 10-20 | 94 | Paper says "10-20 system" (most common) |
| `standard_1005` | Extended 10-05 | 343 | High-density 10-10 or 10-05 papers |
| `standard_alphabetic` | 10-20 old naming | 94 | T3/T4 convention papers |
| `GSN-HydroCel-32` | EGI 32ch | 32 | EGI net (E-numbered channels) |
| `GSN-HydroCel-64_1.0` | EGI 64ch | 64 | EGI net |
| `GSN-HydroCel-65_1.0` | EGI 65ch | 65 | EGI net (with Cz) |
| `GSN-HydroCel-128` | EGI 128ch | 128 | EGI net |
| `GSN-HydroCel-129` | EGI 129ch | 129 | EGI net (with Cz) |
| `GSN-HydroCel-256` | EGI 256ch | 256 | EGI net |
| `biosemi16` | BioSemi 16ch | 16 | BioSemi Active Two |
| `biosemi32` | BioSemi 32ch | 32 | BioSemi Active Two |
| `biosemi64` | BioSemi 64ch | 64 | BioSemi Active Two |
| `biosemi128` | BioSemi 128ch | 128 | BioSemi Active Two |
| `biosemi256` | BioSemi 256ch | 256 | BioSemi Active Two |
| `easycap-M1` | EasyCap M1 | 74 | Brain Products EasyCap |
| `easycap-M10` | EasyCap M10 | 61 | Brain Products EasyCap |
| `mgh60` | MGH 60ch | 60 | MGH/Martinos Center |
| `mgh70` | MGH 70ch | 70 | MGH/Martinos Center |
| `brainproducts-RNP-BA-128` | R-Net 128ch | 128 | Brain Products R-Net |
| `artinis-octamon` | Artinis fNIRS | 8 | fNIRS |
| `artinis-brite23` | Artinis fNIRS | 23 | fNIRS |

```python
import mne

# Create and apply montage
montage = mne.channels.make_standard_montage("standard_1020")
raw.set_montage(montage, match_case=False, on_missing="warn")

# List all available montages
print(mne.channels.get_builtin_montages())

# Custom montage from BIDS electrodes.tsv
import pandas as pd, numpy as np
elec = pd.read_csv("sub-001_electrodes.tsv", sep="\t")
ch_pos = {r["name"]: np.array([r["x"], r["y"], r["z"]]) / 1000
           for _, r in elec.iterrows()}
montage = mne.channels.make_dig_montage(ch_pos=ch_pos, coord_frame="head")
```

### MNE Visualization Functions Reference

| Function | Purpose | Key Parameters |
|----------|---------|----------------|
| `evoked.plot()` | ERP butterfly plot | `spatial_colors`, `picks`, `time_unit` |
| `evoked.plot_topomap(times)` | Topographic map series | `times`, `average`, `cmap`, `vlim` |
| `evoked.plot_joint()` | ERP + topomaps combined | `times`, `topomap_args` |
| `epochs.plot_image()` | Trial × time heatmap | `picks`, `combine`, `cmap` |
| `raw.plot_psd()` | Power spectral density | `fmin`, `fmax`, `picks` |
| `ica.plot_components()` | ICA component topomaps | `picks`, `inst` |
| `ica.plot_sources()` | ICA time courses | `inst`, `picks` |
| `mne.viz.plot_compare_evokeds()` | Multi-condition ERP | `picks`, `combine`, `ci`, `colors` |
| `mne.viz.plot_topomap(data, pos)` | Custom data on scalp | `vmin`, `vmax`, `cmap`, `mask` |
| `mne.viz.plot_source_estimates()` | Source space activity | `hemi`, `views`, `clim` |
| `mne.viz.plot_alignment()` | Sensor/head/source 3D | `surfaces`, `coord_frame` |

### MNE `evoked.plot_joint(...)` (ERP + Topomaps)

**Signature:**
```text
Evoked.plot_joint(
    times='peaks', title='', picks=None,
    exclude='bads', show=True, ts_args=None,
    topomap_args=None
)
```

```python
# Combined ERP waveform with topographic maps at selected times
fig = evoked_face.plot_joint(
    times=[0.100, 0.170, 0.300],  # time points for topomaps
    title="Face ERP with topographies",
    ts_args=dict(spatial_colors=True),
    topomap_args=dict(cmap="RdBu_r", vlim=(-5, 5)),
    show=False,
)
fig.savefig("figures/erp_joint.png", dpi=300)
```

---

## MATLAB Visualization Tools → Python (Detailed)

### xjView → nilearn interactive

```python
# xjView equivalent: interactive HTML viewer
from nilearn import plotting
view = plotting.view_img(
    z_map,
    threshold=3.0,
    symmetric_cmap=True,
    title="Face > House (z > 3.0)",
)
view.save_as_html("results/activation_viewer.html")
# Open in browser — click to navigate slices
```

### MRIcroGL → nilearn multi-view

```python
from nilearn import plotting

# MRIcroGL-style multi-slice rendering
fig = plotting.plot_stat_map(
    z_map,
    threshold=3.0,
    display_mode="mosaic",       # "ortho", "x", "y", "z", "xz", "mosaic", "tiled"
    cut_coords=8,                 # number of slices
    cmap="cold_hot",
    colorbar=True,
    title="Face > House",
    output_file="figures/activation_mosaic.png",
)
```

### BrainNet Viewer → nilearn connectome plot

```python
import numpy as np
from nilearn import plotting, datasets

# Load atlas for node coordinates
atlas = datasets.fetch_atlas_schaefer_2018(n_rois=100)
coords = plotting.find_parcellation_cut_coords(atlas.maps)

# Plot connectivity matrix as brain network
fig = plotting.plot_connectome(
    connectivity_matrix,          # (100, 100) correlation matrix
    coords,
    edge_threshold="95%",         # show top 5% connections
    node_size=20,
    node_color=network_colors,    # color by Yeo network
    display_mode="lzr",
    title="Functional Connectivity",
    output_file="figures/connectome.png",
)

# Also plot as matrix
fig_mat = plotting.plot_matrix(
    connectivity_matrix,
    labels=atlas.labels,
    tri="lower",
    colorbar=True,
    vmin=-1, vmax=1,
    title="Connectivity Matrix",
)
fig_mat.figure.savefig("figures/conn_matrix.png", dpi=300)
```

### marsbar → NiftiSpheresMasker / NiftiLabelsMasker

```python
from nilearn.maskers import NiftiSpheresMasker, NiftiLabelsMasker

# marsbar sphere ROI → NiftiSpheresMasker
# Paper: "ROI: 6mm sphere at left amygdala (-24, -4, -18)"
masker = NiftiSpheresMasker(
    seeds=[(-24, -4, -18)],
    radius=6.0,
    standardize=True,
)

# marsbar atlas ROI → NiftiLabelsMasker with AAL
from nilearn import datasets
aal = datasets.fetch_atlas_aal()
masker = NiftiLabelsMasker(
    labels_img=aal.maps,
    labels=aal.labels,
    standardize=True,
)
```

### FreeSurfer tksurfer → nilearn surface plotting

```python
from nilearn import plotting, datasets, surface

# Load fsaverage surface
fsaverage = datasets.fetch_surf_fsaverage()

# Project volume stat map to surface
texture = surface.vol_to_surf(z_map, fsaverage["pial_left"])

# Plot on surface
fig = plotting.plot_surf_stat_map(
    fsaverage["infl_left"],       # inflated surface mesh
    texture,
    hemi="left",
    view="lateral",
    threshold=3.0,
    cmap="cold_hot",
    colorbar=True,
    bg_map=fsaverage["sulc_left"],
    title="Face > House (left hemisphere)",
)
fig.savefig("figures/surface_activation.png", dpi=300)

# Both hemispheres
for hemi in ["left", "right"]:
    texture = surface.vol_to_surf(z_map, fsaverage[f"pial_{hemi}"])
    fig = plotting.plot_surf_stat_map(
        fsaverage[f"infl_{hemi}"],
        texture,
        hemi=hemi,
        view="lateral",
        threshold=3.0,
        colorbar=True,
        bg_map=fsaverage[f"sulc_{hemi}"],
    )
    fig.savefig(f"figures/surface_{hemi}.png", dpi=300)
```

---

## Package Version Compatibility Matrix

| Package | Minimum Version | Recommended | Key Feature Added |
|---------|----------------|-------------|-------------------|
| mne | 1.4 | ≥1.6 | Stable EEGLAB reader, improved ICA |
| nilearn | 0.10 | ≥0.10 | Updated masker API (`maskers.NiftiMasker`) |
| pingouin | 0.5.3 | ≥0.5.3 | Greenhouse-Geisser in rm_anova |
| scipy | 1.11 | ≥1.11 | Improved loadmat for large .set files |
| statsmodels | 0.14 | ≥0.14 | Stable AnovaRM |
| autoreject | 0.4 | ≥0.4 | Bayesian optimization threshold |
| mne-bids | 0.14 | ≥0.14 | Stable read_raw_bids |
| nibabel | 5.0 | ≥5.0 | Improved NIfTI-2 support |
| matplotlib | 3.7 | ≥3.7 | Improved figure layout engine |

---

## Quick Install for Common Analysis Types

```bash
# ERP replication (most common)
pip install mne pingouin matplotlib pandas scipy numpy autoreject

# fMRI replication
pip install nilearn nibabel matplotlib pandas scipy numpy pingouin

# Full replication stack
pip install mne nilearn nibabel pingouin statsmodels autoreject \
    mne-bids matplotlib pandas scipy numpy seaborn scikit-learn

# With connectivity analysis
pip install mne-connectivity

# With ICA label detection
pip install mne-icalabel
```
