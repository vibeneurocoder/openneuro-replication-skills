<!-- openneuro-replication-skills | asset: API Quick Reference -->

# API Quick Reference for Replication

Compact lookup table of the most-used functions in OpenNeuro replication workflows.
For full signatures and parameter tables, see the corresponding `references/*.md` doc.

---

## Data Loading

| Function | Purpose | Reference |
|----------|---------|-----------|
| `mne.io.read_raw_eeglab(fname, preload=True)` | Load EEGLAB `.set/.fdt` files | `eeg-data-loading.md` |
| `mne.io.read_raw_brainvision(vhdr, preload=True)` | Load BrainVision `.vhdr/.vmrk/.eeg` | `eeg-data-loading.md` |
| `mne.io.read_raw_edf(fname, preload=True)` | Load EDF/EDF+ files | `eeg-data-loading.md` |
| `mne.io.read_raw_bdf(fname, preload=True)` | Load BDF (BioSemi) files | `eeg-data-loading.md` |
| `mne.io.read_raw_fif(fname, preload=True)` | Load MNE-native `.fif` files | `eeg-data-loading.md` |
| `mne_bids.read_raw_bids(bids_path)` | Load any BIDS dataset (auto-detect format) | `eeg-data-loading.md` |
| `scipy.io.loadmat(fname)` | Fallback for problematic `.set` files | `eeg-data-loading.md` |
| `nibabel.load(fname)` | Load NIfTI `.nii.gz` for fMRI | `fmri-replication.md` |

## Preprocessing

| Function | Purpose | Reference |
|----------|---------|-----------|
| `raw.filter(l_freq, h_freq)` | Bandpass/highpass/lowpass filter | `preprocessing-pipeline.md` |
| `raw.notch_filter(freqs)` | Remove line noise (50/60 Hz) | `preprocessing-pipeline.md` |
| `raw.set_eeg_reference(ref_channels)` | Re-reference (average, mastoids, etc.) | `preprocessing-pipeline.md` |
| `raw.set_montage(montage)` | Set channel positions | `eeg-data-loading.md` |
| `raw.resample(sfreq)` | Downsample continuous data | `preprocessing-pipeline.md` |
| `mne.add_reference_channels(raw, ch)` | Add back reference electrode | `preprocessing-pipeline.md` |
| `mne.preprocessing.ICA(n_components, method)` | Independent Component Analysis | `preprocessing-pipeline.md` |
| `ica.find_bads_eog(raw)` | Auto-detect EOG components | `preprocessing-pipeline.md` |
| `ica.apply(raw)` | Remove ICA components from data | `preprocessing-pipeline.md` |
| `raw.interpolate_bads()` | Interpolate bad channels | `preprocessing-pipeline.md` |

## Events & Epochs

| Function | Purpose | Reference |
|----------|---------|-----------|
| `mne.events_from_annotations(raw)` | Extract events from annotations | `preprocessing-pipeline.md` |
| `mne.find_events(raw)` | Extract events from STIM channel | `preprocessing-pipeline.md` |
| `mne.Epochs(raw, events, event_id, tmin, tmax)` | Segment into epochs | `preprocessing-pipeline.md` |
| `epochs.drop_bad(reject=dict(eeg=100e-6))` | Artifact rejection by threshold | `preprocessing-pipeline.md` |
| `autoreject.AutoReject()` | Automated artifact rejection | `preprocessing-pipeline.md` |

## ERP Analysis

| Function | Purpose | Reference |
|----------|---------|-----------|
| `epochs["condition"].average()` | Compute condition-specific ERP | `erp-analysis.md` |
| `evoked.get_data()` | Get data array (volts) | `erp-analysis.md` |
| `evoked.get_peak(tmin, tmax, mode)` | Find peak amplitude/latency | `erp-analysis.md` |
| `mne.combine_evoked([a, b], weights=[1,-1])` | Difference wave | `erp-analysis.md` |
| `mne.grand_average(list_of_evoked)` | Grand average across subjects | `erp-analysis.md` |

## Statistics

| Function | Purpose | Reference |
|----------|---------|-----------|
| `pingouin.rm_anova(data, dv, within, subject)` | Repeated-measures ANOVA | `statistics-and-comparison.md` |
| `pingouin.pairwise_tests(data, dv, within, subject)` | Post-hoc pairwise comparisons | `statistics-and-comparison.md` |
| `pingouin.ttest(x, y, paired=True)` | Paired t-test with Cohen's d and BF10 | `statistics-and-comparison.md` |
| `pingouin.wilcoxon(x, y)` | Non-parametric paired test | `statistics-and-comparison.md` |
| `mne.stats.permutation_cluster_test(X)` | Cluster-based permutation | `statistics-and-comparison.md` |
| `statsmodels.stats.multitest.multipletests()` | Multiple comparison correction | `statistics-and-comparison.md` |

## fMRI Analysis

| Function | Purpose | Reference |
|----------|---------|-----------|
| `FirstLevelModel(t_r, hrf_model, high_pass)` | First-level GLM | `fmri-replication.md` |
| `glm.compute_contrast("A - B")` | Compute contrast map | `fmri-replication.md` |
| `SecondLevelModel()` | Group-level analysis | `fmri-replication.md` |
| `threshold_stats_img(img, alpha, height_control)` | Threshold statistical map | `fmri-replication.md` |
| `NiftiMasker()` | Whole-brain signal extraction | `fmri-replication.md` |
| `NiftiLabelsMasker(atlas.maps)` | ROI signal extraction | `fmri-replication.md` |
| `NiftiSpheresMasker(seeds, radius)` | Coordinate-based ROI extraction | `fmri-replication.md` |
| `Decoder(estimator="svc")` | MVPA classification | `fmri-replication.md` |
| `ConnectivityMeasure(kind="correlation")` | Functional connectivity | `fmri-replication.md` |

## EEG Montage Templates

| Function | System | Reference |
|----------|--------|-----------|
| `mne.channels.make_standard_montage("standard_1020")` | Standard 10-20 (94ch) | `eeg-data-loading.md` |
| `mne.channels.make_standard_montage("standard_1005")` | Extended 10-05 (343ch) | `eeg-data-loading.md` |
| `mne.channels.make_standard_montage("GSN-HydroCel-65_1.0")` | EGI 65ch net | `eeg-data-loading.md` |
| `mne.channels.make_standard_montage("GSN-HydroCel-128")` | EGI 128ch net | `eeg-data-loading.md` |
| `mne.channels.make_standard_montage("GSN-HydroCel-256")` | EGI 256ch net | `eeg-data-loading.md` |
| `mne.channels.make_standard_montage("biosemi64")` | BioSemi 64ch | `eeg-data-loading.md` |
| `mne.channels.make_standard_montage("biosemi128")` | BioSemi 128ch | `eeg-data-loading.md` |
| `mne.channels.make_standard_montage("easycap-M1")` | EasyCap M1 (74ch) | `eeg-data-loading.md` |
| `mne.channels.make_dig_montage(ch_pos=dict)` | Custom from coordinates | `eeg-data-loading.md` |
| `mne.channels.get_builtin_montages()` | List all available montages | `eeg-data-loading.md` |

## Brain Atlases & Templates

| Function | Atlas | Reference |
|----------|-------|-----------|
| `datasets.fetch_atlas_aal(version='SPM12')` | AAL (116 regions) | `fmri-replication.md` |
| `datasets.fetch_atlas_aal(version='3v2')` | AAL3 (166 regions) | `fmri-replication.md` |
| `datasets.fetch_atlas_harvard_oxford('cort-maxprob-thr25-2mm')` | Harvard-Oxford cortical (48) | `fmri-replication.md` |
| `datasets.fetch_atlas_harvard_oxford('sub-maxprob-thr25-2mm')` | Harvard-Oxford subcortical (21) | `fmri-replication.md` |
| `datasets.fetch_atlas_schaefer_2018(n_rois=100)` | Schaefer functional (100–1000) | `fmri-replication.md` |
| `datasets.fetch_atlas_destrieux_2009()` | Destrieux / FreeSurfer (148) | `fmri-replication.md` |
| `datasets.fetch_atlas_yeo_2011()` | Yeo resting-state networks (7/17) | `fmri-replication.md` |
| `datasets.fetch_atlas_talairach('ba')` | Talairach Brodmann areas | `fmri-replication.md` |
| `datasets.fetch_atlas_difumo(dimension=64)` | DiFuMo functional modes (64–1024) | `fmri-replication.md` |
| `datasets.fetch_atlas_pauli_2017()` | Pauli subcortical (12) | `fmri-replication.md` |
| `datasets.load_mni152_template(resolution=2)` | MNI152 structural template | `fmri-replication.md` |
| `datasets.load_mni152_brain_mask(resolution=2)` | MNI152 brain mask | `fmri-replication.md` |
| `datasets.fetch_surf_fsaverage()` | FreeSurfer fsaverage surfaces | `fmri-replication.md` |

## Visualization

| Function | Purpose | Reference |
|----------|---------|-----------|
| `mne.viz.plot_compare_evokeds(evokeds, picks)` | ERP waveform comparison | `publication-figures.md` |
| `evoked.plot_topomap(times)` | EEG topographic map | `publication-figures.md` |
| `evoked.plot_joint(times)` | ERP waveforms + topomaps combined | `publication-figures.md` |
| `evoked.plot(spatial_colors=True, gfp=True)` | Butterfly plot with GFP | `publication-figures.md` |
| `epochs.plot_image(picks)` | Single-trial ERP image (heatmap) | `publication-figures.md` |
| `raw.compute_psd().plot()` | Power spectral density | `publication-figures.md` |
| `power.plot(baseline, mode='logratio')` | Time-frequency plot | `publication-figures.md` |
| `power.plot_topomap(tmin, tmax, fmin, fmax)` | TF topographic map | `publication-figures.md` |
| `ica.plot_components(picks)` | ICA component topomaps | `publication-figures.md` |
| `ica.plot_sources(raw, picks)` | ICA time courses | `publication-figures.md` |
| `ica.plot_properties(epochs, picks)` | ICA component properties | `publication-figures.md` |
| `montage.plot(show_names=True)` | Sensor/montage layout | `publication-figures.md` |
| `raw.plot_sensors(show_names=True)` | Data sensor positions | `publication-figures.md` |
| `mne.viz.plot_topomap(data, pos)` | Custom data on scalp | `publication-figures.md` |
| `nilearn.plotting.plot_stat_map(img, threshold)` | fMRI activation on MNI slices | `fmri-replication.md` |
| `nilearn.plotting.plot_glass_brain(img)` | Glass brain projection | `fmri-replication.md` |
| `nilearn.plotting.plot_roi(roi_img)` | Atlas/ROI overlay on anatomy | `publication-figures.md` |
| `nilearn.plotting.plot_surf_stat_map(mesh, data)` | Surface activation map | `publication-figures.md` |
| `nilearn.plotting.plot_connectome(matrix, coords)` | Brain network graph | `publication-figures.md` |
| `nilearn.plotting.plot_matrix(matrix, labels)` | Connectivity/correlation matrix | `publication-figures.md` |
| `nilearn.plotting.view_img(img)` | Interactive HTML volume viewer | `fmri-replication.md` |
| `nilearn.plotting.view_surf(mesh, data)` | Interactive HTML surface viewer | `fmri-replication.md` |
| `nilearn.plotting.view_connectome(matrix, coords)` | Interactive HTML network viewer | `fmri-replication.md` |
| `nilearn.plotting.find_parcellation_cut_coords(atlas)` | Get atlas node coordinates | `fmri-replication.md` |

---

## Unit Conversion Cheat Sheet

| MNE Internal | Paper Reports | Conversion |
|-------------|---------------|------------|
| Volts (V) | Microvolts (µV) | `× 1e6` |
| Seconds (s) | Milliseconds (ms) | `× 1000` |
| Tesla (T) | Femtotesla (fT) | `× 1e15` |
| Hertz (Hz) | Hertz (Hz) | (same) |
