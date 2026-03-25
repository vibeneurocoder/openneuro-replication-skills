<!-- openneuro-replication-skills | domain: fMRI Replication -->
<!-- target libraries: nilearn>=0.10, nibabel>=5.0, mne-bids>=0.14 -->

# Domain: fMRI Replication Pipeline

fMRI replication on OpenNeuro data using nilearn and nibabel. Most OpenNeuro fMRI
datasets provide either raw NIfTI or fMRIPrep derivatives.

---

## Loading fMRI Data

### Raw NIfTI

```python
import nibabel as nib

img = nib.load("sub-01/func/sub-01_task-localizer_bold.nii.gz")
print(f"Shape: {img.shape}")       # (x, y, z, n_volumes)
print(f"Voxel size: {img.header.get_zooms()[:3]} mm")
print(f"TR: {img.header.get_zooms()[3]} s")
data = img.get_fdata()  # shape: (x, y, z, n_volumes)
```

### fMRIPrep Derivatives

Many OpenNeuro datasets have fMRIPrep outputs. These are preprocessed and in MNI space:

```python
# fMRIPrep outputs are typically in derivatives/fmriprep/
fmriprep_img = nib.load(
    "derivatives/fmriprep/sub-01/func/"
    "sub-01_task-localizer_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz"
)

# Confounds for denoising
import pandas as pd
confounds = pd.read_csv(
    "derivatives/fmriprep/sub-01/func/"
    "sub-01_task-localizer_desc-confounds_timeseries.tsv",
    sep="\t",
)
```

### Loading Confounds with `nilearn`

### `nilearn.interfaces.fmriprep.load_confounds(...)`

**Signature:**
```text
nilearn.interfaces.fmriprep.load_confounds(
    img_files, strategy=('motion', 'wm_csf'), motion='full',
    wm_csf='basic', global_signal='basic', scrub=5,
    fd_threshold=0.5, std_dvars_threshold=1.5, demean=True
)
# Returns: (confounds_df, sample_mask) or list of tuples
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `img_files` | `str \| list` | — | Path(s) to fMRIPrep BOLD output(s). |
| `strategy` | `tuple` | `('motion', 'wm_csf')` | Denoising strategy components. |
| `motion` | `str` | `'full'` | `'basic'` (6 params), `'derivatives'` (12), `'full'` (24). |
| `scrub` | `int` | `5` | Minimum consecutive volumes after scrubbing. |
| `fd_threshold` | `float` | `0.5` | Framewise displacement threshold for scrubbing. |

```python
from nilearn.interfaces.fmriprep import load_confounds

confounds, sample_mask = load_confounds(
    "sub-01_task-localizer_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz",
    strategy=("motion", "wm_csf", "global_signal"),
    motion="derivatives",
    global_signal="basic",
)
```

---

## First-Level GLM

### `nilearn.glm.first_level.FirstLevelModel(...)`

**Signature:**
```text
nilearn.glm.first_level.FirstLevelModel(
    t_r=None, slice_time_ref=0.0, hrf_model='glover',
    drift_model='cosine', high_pass=0.01, drift_order=1,
    fir_delays=None, min_onset=-24, mask_img=None,
    target_affine=None, target_shape=None, smoothing_fwhm=None,
    memory=None, memory_level=1, standardize=False,
    signal_scaling=0, noise_model='ar1', verbose=0,
    n_jobs=1, minimize_memory=True, subject_label=None,
    random_state=None
)
# Source: nilearn/glm/first_level/first_level_model.py
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `t_r` | `float \| None` | `None` | Repetition time in seconds. Read from NIfTI header if `None`. |
| `hrf_model` | `str` | `'glover'` | `'glover'`, `'spm'`, `'spm + derivative'`, `'fir'`, or custom. |
| `high_pass` | `float` | `0.01` | High-pass filter cutoff (Hz). `1/128 ≈ 0.0078` is SPM default. |
| `smoothing_fwhm` | `float \| None` | `None` | Spatial smoothing FWHM in mm. |
| `noise_model` | `str` | `'ar1'` | `'ar1'` or `'ols'`. |
| `mask_img` | `str \| NiftiImage \| None` | `None` | Brain mask. `None` computes one. |
| `drift_model` | `str` | `'cosine'` | `'cosine'` (DCT) or `'polynomial'`. |

**Example (standard first-level analysis):**

```python
from nilearn.glm.first_level import FirstLevelModel
import pandas as pd

# Load events
events = pd.read_csv("sub-01/func/sub-01_task-localizer_events.tsv", sep="\t")
print(events.columns.tolist())  # ['onset', 'duration', 'trial_type']

# Paper: "6 mm FWHM smoothing, 128 s high-pass filter, AR(1) noise model"
glm = FirstLevelModel(
    t_r=2.0,                    # from paper or NIfTI header
    hrf_model="spm",            # match paper's software (SPM → 'spm', FSL → 'glover')
    high_pass=1/128,            # "128 s high-pass" = 0.0078 Hz
    smoothing_fwhm=6.0,         # "6 mm FWHM Gaussian kernel"
    noise_model="ar1",
    drift_model="cosine",
)

# Fit
glm.fit(
    run_imgs="sub-01/func/sub-01_task-localizer_bold.nii.gz",
    events=events,
    confounds=confounds,  # from fMRIPrep if available
)
```

**Pitfalls:**
- `hrf_model='spm'` and `'glover'` produce slightly different results. Match the paper's software.
- SPM papers use `high_pass=1/128`. FSL uses `high_pass=1/100` by default.
- Papers may smooth before or after masking. Nilearn smooths during fitting.

---

## Contrasts

```python
# Paper: "Contrast: faces > houses"
contrast_map = glm.compute_contrast("face - house", output_type="z_score")

# Paper: "Contrast: task > rest" (single condition vs implicit baseline)
contrast_map = glm.compute_contrast("task", output_type="z_score")

# Paper: "F-test for main effect of category"
# Use an array: one row per condition being tested
import numpy as np
contrast_matrix = np.eye(4)[:3]  # test first 3 regressors jointly
contrast_map = glm.compute_contrast(contrast_matrix, stat_type="F", output_type="z_score")
```

### `FirstLevelModel.compute_contrast(...)`

**Signature:**
```text
FirstLevelModel.compute_contrast(
    contrast_def, stat_type=None, output_type='z_score'
)
# Returns: Nifti1Image
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `contrast_def` | `str \| ndarray` | — | Contrast expression (e.g., `"face - house"`) or weight array. |
| `stat_type` | `str \| None` | `None` | `'t'` or `'F'`. Inferred from contrast if `None`. |
| `output_type` | `str` | `'z_score'` | `'z_score'`, `'stat'`, `'p_value'`, `'effect_size'`, `'effect_variance'`. |

---

## Second-Level (Group) Analysis

### `nilearn.glm.second_level.SecondLevelModel(...)`

**Signature:**
```text
nilearn.glm.second_level.SecondLevelModel(
    mask_img=None, target_affine=None, target_shape=None,
    smoothing_fwhm=None, memory=None, memory_level=1,
    verbose=0, n_jobs=1, minimize_memory=True
)
```

**Example (one-sample t-test across subjects):**

```python
from nilearn.glm.second_level import SecondLevelModel
import pandas as pd

# Collect all subjects' first-level contrast maps
contrast_imgs = [f"sub-{s:02d}_face_vs_house_z.nii.gz" for s in range(1, 21)]

# Design matrix for one-sample t-test
design_matrix = pd.DataFrame({"intercept": [1] * len(contrast_imgs)})

second_level = SecondLevelModel(smoothing_fwhm=None)  # already smoothed at first level
second_level.fit(contrast_imgs, design_matrix=design_matrix)

group_z = second_level.compute_contrast(output_type="z_score")
```

---

## Thresholding Statistical Maps

### `nilearn.glm.threshold_stats_img(...)`

**Signature:**
```text
nilearn.glm.threshold_stats_img(
    stat_img, alpha=0.001, height_control='fpr',
    cluster_threshold=0, two_sided=True, mask_img=None
)
# Returns: (thresholded_img, threshold_value)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `stat_img` | `Nifti1Image` | — | Statistical map (z or t). |
| `alpha` | `float` | `0.001` | Significance threshold. |
| `height_control` | `str` | `'fpr'` | `'fpr'` (uncorrected), `'fdr'`, `'bonferroni'`. |
| `cluster_threshold` | `int` | `0` | Minimum cluster size in voxels. |

```python
from nilearn.glm import threshold_stats_img

# Paper: "voxel-wise FDR q < 0.05, cluster size > 10"
thresholded, threshold = threshold_stats_img(
    group_z,
    alpha=0.05,
    height_control="fdr",
    cluster_threshold=10,
)
print(f"Threshold: z > {threshold:.2f}")
```

---

## Maskers for ROI Analysis

### `nilearn.maskers.NiftiMasker(...)`

**Signature:**
```text
nilearn.maskers.NiftiMasker(
    mask_img=None, runs=None, smoothing_fwhm=None,
    standardize=False, standardize_confounds=True,
    detrend=False, high_variance_confounds=False,
    t_r=None, low_pass=None, high_pass=None,
    memory=None, memory_level=1, verbose=0,
    target_affine=None, target_shape=None,
    mask_strategy='background', mask_args=None,
    dtype=None, clean_kwargs=None
)
# Source: nilearn/maskers/nifti_masker.py
```

```python
from nilearn.maskers import NiftiMasker

# Whole-brain masker
masker = NiftiMasker(
    standardize=True,
    high_pass=0.01,
    t_r=2.0,
    smoothing_fwhm=6.0,
)
X = masker.fit_transform(func_img, confounds=confounds)
# X shape: (n_timepoints, n_voxels)
```

### `nilearn.maskers.NiftiLabelsMasker(...)`

For atlas-based ROI extraction:

```python
from nilearn.maskers import NiftiLabelsMasker
from nilearn import datasets

# Fetch atlas
atlas = datasets.fetch_atlas_schaefer_2018(n_rois=100)

masker = NiftiLabelsMasker(
    labels_img=atlas.maps,
    labels=atlas.labels,
    standardize=True,
    t_r=2.0,
)
roi_signals = masker.fit_transform(func_img, confounds=confounds)
# roi_signals shape: (n_timepoints, 100)
```

---

## Brain Atlases & Templates

Papers reference specific atlases for ROI definition. All major atlases are in `nilearn.datasets`.

### AAL (Automated Anatomical Labeling)

The most commonly cited atlas in fMRI papers.

### `nilearn.datasets.fetch_atlas_aal(...)`

**Signature:**
```text
nilearn.datasets.fetch_atlas_aal(
    version='SPM12', data_dir=None, url=None, resume=True, verbose=1
)
# Returns: Bunch(maps, indices, labels, description)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `version` | `str` | `'SPM12'` | `'SPM12'` (116 regions), `'3v2'` (AAL3, 166 regions). |

```python
from nilearn import datasets
from nilearn.maskers import NiftiLabelsMasker

# Fetch and use AAL atlas
aal = datasets.fetch_atlas_aal(version="SPM12")
print(f"Regions: {len(aal.labels)}")  # 116
print(f"Sample labels: {aal.labels[:5]}")  # ['Precentral_L', 'Precentral_R', ...]

masker = NiftiLabelsMasker(
    labels_img=aal.maps,
    labels=aal.labels,
    standardize=True,
    t_r=2.0,
)
roi_signals = masker.fit_transform(func_img, confounds=confounds)
# Shape: (n_timepoints, 116)
```

**Common AAL region names referenced in papers:**

| Paper Region | AAL Label | Index |
|-------------|-----------|-------|
| Left amygdala | `Amygdala_L` | 41 |
| Right amygdala | `Amygdala_R` | 42 |
| Left hippocampus | `Hippocampus_L` | 37 |
| Right hippocampus | `Hippocampus_R` | 38 |
| Left fusiform | `Fusiform_L` | 55 |
| Right fusiform | `Fusiform_R` | 56 |
| Left inferior frontal (triangularis) | `Frontal_Inf_Tri_L` | 11 |
| Left superior temporal | `Temporal_Sup_L` | 81 |
| Precuneus (left) | `Precuneus_L` | 67 |
| Anterior cingulate | `Cingulate_Ant_L` | 31 |
| Left insula | `Insula_L` | 29 |
| Left caudate | `Caudate_L` | 71 |
| Left thalamus | `Thalamus_L` | 77 |

### Harvard-Oxford Atlas

```python
# Cortical (48 regions, probability-based)
ho_cort = datasets.fetch_atlas_harvard_oxford("cort-maxprob-thr25-2mm")
# Subcortical (21 regions)
ho_sub = datasets.fetch_atlas_harvard_oxford("sub-maxprob-thr25-2mm")
# Probabilistic (for weighted extraction)
ho_prob = datasets.fetch_atlas_harvard_oxford("cort-prob-2mm")
```

### Schaefer 2018 (Functional Parcellation)

```python
# Modern functional parcellation — 100 to 1000 parcels
atlas = datasets.fetch_atlas_schaefer_2018(
    n_rois=200,       # 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000
    yeo_networks=7,   # 7 or 17 network assignment
    resolution_mm=2,
)
# Labels include network: '7Networks_LH_Vis_1', '7Networks_LH_Default_1', etc.
# Networks: Vis, SomMot, DorsAttn, SalVentAttn, Limbic, Cont, Default
```

### Other Commonly Referenced Atlases

```python
# Destrieux (148 FreeSurfer surface regions)
destrieux = datasets.fetch_atlas_destrieux_2009()

# Yeo networks (7 or 17 resting-state networks)
yeo = datasets.fetch_atlas_yeo_2011()

# Talairach (Brodmann areas)
talairach = datasets.fetch_atlas_talairach("ba")

# DiFuMo (data-driven functional modes)
difumo = datasets.fetch_atlas_difumo(dimension=64)

# Pauli subcortical (12 high-resolution subcortical regions)
pauli = datasets.fetch_atlas_pauli_2017()
```

### MNI152 Template

```python
# Standard templates for underlay / normalization
mni_template = datasets.load_mni152_template(resolution=2)
mni_mask = datasets.load_mni152_brain_mask(resolution=2)
mni_gm = datasets.load_mni152_gm_template(resolution=2)  # gray matter
mni_wm = datasets.load_mni152_wm_template(resolution=2)  # white matter
```

### Coordinate-Based ROIs (Sphere at MNI Coordinate)

When papers define ROIs by center coordinate + radius:

### `nilearn.maskers.NiftiSpheresMasker(...)`

**Signature:**
```text
nilearn.maskers.NiftiSpheresMasker(
    seeds, radius=None, mask_img=None, allow_overlap=False,
    standardize=False, standardize_confounds=True,
    detrend=False, high_variance_confounds=False,
    t_r=None, low_pass=None, high_pass=None,
    memory=None, memory_level=1, verbose=0,
    dtype=None, clean_kwargs=None
)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `seeds` | `list of tuples` | — | MNI coordinates, e.g., `[(-42, -52, -18)]`. |
| `radius` | `float \| None` | `None` | Sphere radius in mm. `None` = single voxel. |
| `allow_overlap` | `bool` | `False` | Allow overlapping spheres. |

```python
from nilearn.maskers import NiftiSpheresMasker

# Paper: "8mm sphere ROIs centered on FFA (-42, -52, -18) and PPA (-28, -40, -12)"
masker = NiftiSpheresMasker(
    seeds=[(-42, -52, -18), (-28, -40, -12), (42, -52, -18), (28, -40, -12)],
    radius=8.0,
    standardize=True,
    t_r=2.0,
)
roi_signals = masker.fit_transform(func_img, confounds=confounds)
# Shape: (n_timepoints, 4) — one column per seed
```

**Pitfalls:**
- Coordinates must be in MNI space (same as data).
- Papers sometimes report Talairach coordinates — convert using `nilearn.datasets.fetch_atlas_talairach()` or online converters.
- If radius is too large, spheres may overlap. Set `allow_overlap=True` if needed.

---

## MVPA / Decoding

### `nilearn.decoding.Decoder(...)`

**Signature:**
```text
nilearn.decoding.Decoder(
    estimator='svc', mask=None, cv=5, param_grid=None,
    screening_percentile=20, scoring='accuracy',
    smoothing_fwhm=None, standardize=True,
    target_affine=None, target_shape=None,
    high_pass=None, t_r=None, verbose=0
)
```

```python
from nilearn.decoding import Decoder

# Paper: "SVM classification of face vs house activation patterns"
decoder = Decoder(
    estimator="svc",
    mask=mask_img,
    cv=5,                       # "5-fold cross-validation"
    screening_percentile=20,    # feature selection
    scoring="accuracy",
    smoothing_fwhm=None,        # if already smoothed
)

# conditions and session_label for leave-one-run-out
decoder.fit(func_imgs, conditions, groups=run_labels)
print(f"Accuracy: {decoder.cv_scores_['face'].mean():.1%}")
```

### Searchlight Analysis

```python
from nilearn.decoding import SearchLight
from sklearn.svm import LinearSVC

searchlight = SearchLight(
    mask_img=mask_img,
    radius=5.6,                 # "searchlight with 5.6 mm radius"
    estimator=LinearSVC(),
    cv=5,
    n_jobs=-1,
)
searchlight.fit(func_imgs, conditions)
accuracy_map = searchlight.scores_  # Nifti1Image
```

---

## Connectivity Analysis

### `nilearn.connectome.ConnectivityMeasure(...)`

```python
from nilearn.connectome import ConnectivityMeasure

# "Functional connectivity was computed using Pearson correlation"
conn = ConnectivityMeasure(kind="correlation")
matrices = conn.fit_transform([roi_signals])  # list of (n_timepoints, n_rois) arrays
# matrices[0] shape: (n_rois, n_rois)
```

---

## Visualization

### `nilearn.plotting.plot_stat_map(...)`

**Signature:**
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
| `bg_img` | `Nifti1Image \| str \| None` | `None` | Background image (`None` = MNI template). |
| `cut_coords` | `int \| tuple \| None` | `None` | Number of slices (int) or coordinates (tuple). |
| `display_mode` | `str` | `'ortho'` | `'ortho'`, `'x'`, `'y'`, `'z'`, `'xz'`, `'yz'`, `'tiled'`, `'mosaic'`. |
| `threshold` | `float \| None` | `1e-6` | Values below this are transparent. |
| `cmap` | `str` | `None` | Colormap: `'cold_hot'`, `'RdBu_r'`, `'viridis'`, etc. |
| `output_file` | `str \| None` | `None` | Save to file (`.png`, `.pdf`, `.svg`). |
| `radiological` | `bool` | `False` | Radiological convention (left=right). |

```python
from nilearn import plotting

# Standard ortho view (most common in papers)
plotting.plot_stat_map(
    contrast_map,
    threshold=3.0,
    display_mode="ortho",
    cut_coords=(0, -52, 18),    # FFA region
    cmap="cold_hot",
    colorbar=True,
    title="Face > House (z > 3.0)",
    output_file="figures/activation_ortho.png",
)

# Multi-slice axial (common in methods papers)
plotting.plot_stat_map(
    contrast_map,
    threshold=3.0,
    display_mode="z",
    cut_coords=[-20, -10, 0, 10, 20, 30, 40, 50],
    cmap="cold_hot",
    output_file="figures/activation_axial.png",
)

# Glass brain (three projections)
plotting.plot_glass_brain(
    contrast_map,
    threshold=3.0,
    display_mode="lyrz",
    colorbar=True,
    plot_abs=False,              # show both positive and negative
    title="Face > House",
    output_file="figures/glass_brain.png",
)
```

### ROI Overlay

```python
# Show atlas ROI on anatomy
from nilearn import datasets
aal = datasets.fetch_atlas_aal()

plotting.plot_roi(
    aal.maps,
    display_mode="ortho",
    cut_coords=(0, 0, 0),
    title="AAL Atlas Parcellation",
    output_file="figures/aal_overlay.png",
)
```

### Surface Visualization

```python
from nilearn import plotting, datasets, surface

fsaverage = datasets.fetch_surf_fsaverage()

# Project volume to surface
texture = surface.vol_to_surf(contrast_map, fsaverage["pial_left"])

# Render on inflated surface
fig = plotting.plot_surf_stat_map(
    fsaverage["infl_left"],
    texture,
    hemi="left",
    view="lateral",
    threshold=3.0,
    cmap="cold_hot",
    colorbar=True,
    bg_map=fsaverage["sulc_left"],
    title="Face > House (left hemisphere)",
)
fig.savefig("figures/surface_left.png", dpi=300)
```

### Connectivity Visualization

```python
# Connectivity matrix
plotting.plot_matrix(
    connectivity_matrix,
    labels=roi_labels,
    tri="lower",
    vmin=-1, vmax=1,
    title="Functional Connectivity",
)

# Brain network graph
coords = plotting.find_parcellation_cut_coords(atlas.maps)
plotting.plot_connectome(
    connectivity_matrix,
    coords,
    edge_threshold="95%",
    node_size=20,
    display_mode="lzr",
    title="Top 5% Connections",
    output_file="figures/connectome.png",
)
```

### Interactive HTML Viewers

```python
# Volume viewer (click to navigate)
view = plotting.view_img(contrast_map, threshold=3.0)
view.save_as_html("results/activation_viewer.html")

# Surface viewer
view = plotting.view_surf(fsaverage["infl_left"], texture, threshold=3.0)
view.save_as_html("results/surface_viewer.html")

# Connectome viewer
view = plotting.view_connectome(connectivity_matrix, coords, edge_threshold="95%")
view.save_as_html("results/connectome_viewer.html")
```

---

## Preprocessing Order (Standard fMRI Replication Template)

```python
import nibabel as nib
from nilearn.glm.first_level import FirstLevelModel
from nilearn.glm.second_level import SecondLevelModel
from nilearn.glm import threshold_stats_img
import pandas as pd

# 1. Load data
func_img = "sub-01/func/sub-01_task-localizer_bold.nii.gz"
events = pd.read_csv("sub-01/func/sub-01_task-localizer_events.tsv", sep="\t")

# 2. First-level GLM (match paper's parameters)
glm = FirstLevelModel(t_r=2.0, hrf_model="spm", high_pass=1/128,
                       smoothing_fwhm=6.0, noise_model="ar1")
glm.fit(func_img, events=events)

# 3. Compute contrast
z_map = glm.compute_contrast("face - house", output_type="z_score")

# 4. Second-level (after all subjects)
# second_level = SecondLevelModel()
# second_level.fit(all_z_maps, design_matrix=dm)

# 5. Threshold and report
thresholded, thr = threshold_stats_img(z_map, alpha=0.001, height_control="fpr",
                                        cluster_threshold=10)
```
