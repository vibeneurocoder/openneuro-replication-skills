# Toolbox Capabilities & Known Datasets

## Toolbox Capability Reference

Use this to fill in the gap analysis when comparing paper methods against what the toolbox provides.

### EEG Preprocessing (toolbox/preprocessing/)
- `bandpass_filter()`, `highpass_filter()`, `lowpass_filter()` — SOS-based filtering
- `create_epochs()` — epoch extraction from continuous data
- `baseline_correct()` — pre-stimulus baseline subtraction
- `reject_epochs()` — amplitude-based artifact rejection (with channel selection)
- NO: ICA, average re-referencing, channel interpolation, microsaccade rejection

### EEG Analysis (toolbox/analysis/)
- `compute_erp()` — average across epochs
- `find_peak()` — peak amplitude/latency in time window (pos or neg mode)
- `compute_mean_amplitude()` — mean amplitude in time window
- `paired_ttest()`, `compute_effect_size()` — basic statistics
- NO: time-frequency (Morlet wavelets), RM-ANOVA, permutation tests, source localization

### fMRI (NOT implemented)
- NO: GLM, MVPA, ROI definition, NIfTI loading — needs nilearn + nibabel

### Visualization (toolbox/visualization/)
- `plot_erp()`, `plot_erp_comparison()`, `plot_butterfly()`, `plot_difference_wave()`, `plot_erp_image()`
- NO: topomaps, brain maps, time-frequency plots

---

## Known Datasets Quick Reference

| Dataset | Paper | Modality | Key Analysis |
|---------|-------|----------|-------------|
| ds003645 | Kappenman et al. 2021 (ERP CORE) | EEG 30ch 1024Hz | N170 face perception |
| ds003061 | Cahn, Delorme & Polich 2012 | EEG 64ch 256Hz | P300 auditory oddball (time-freq) |
| ds000105 | Haxby et al. 2001 | fMRI 3T | MVPA object decoding |
| ds000117 | Wakeman & Henson 2015 | EEG+MEG+fMRI | N170 face processing |
| ds000246 | Jas et al. 2018 | MEG | Auditory M100 |

## Known Dataset-Paper Mapping

| Dataset | Paper | DOI |
|---------|-------|-----|
| ds003645 | Kappenman et al. (2021) ERP CORE | 10.1016/j.neuroimage.2020.117465 |
| ds003061 | Cahn, Delorme & Polich (2012) | 10.1007/s10339-012-0444-6 |
| ds000105 | Haxby et al. (2001) | 10.1126/science.1063736 |
| ds000117 | Wakeman & Henson (2015) | 10.1038/sdata.2015.1 |
