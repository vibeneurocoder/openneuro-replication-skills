# Toolbox Capabilities & Known Datasets

## Toolbox Capability Reference

Use this to fill in the gap analysis when comparing paper methods against what the toolbox provides.

### EEG Preprocessing

**Built-in (toolbox/preprocessing/):**
- `bandpass_filter()`, `highpass_filter()`, `lowpass_filter()` — SOS-based Butterworth filtering (scipy.signal)
- `create_epochs()` — epoch extraction from continuous data
- `baseline_correct()` — pre-stimulus baseline subtraction
- `reject_epochs()` — amplitude-based artifact rejection (with channel selection)

**Available via custom code (proven in replication_test2):**
- Variance-based bad channel detection — log-variance z-score with MAD, threshold z>5, cap at 4 channels
- Average re-referencing — exclude bad channels, recompute mean
- EOG artifact rejection — absolute amplitude threshold on HEOG/VEOG after baseline correction
- Epoch trimming — extract wider epoch, filter, then trim to avoid edge effects

**NOT available (needs external package or custom implementation):**
- ICA artifact removal → use `mne` or `python-picard`
- Channel interpolation → use `mne`
- Microsaccade rejection → custom or `mne`
- Automated bad epoch rejection → use `autoreject`

### EEG Analysis

**Built-in (toolbox/analysis/):**
- `compute_erp()` — average across epochs
- `find_peak()` — peak amplitude/latency in time window (pos or neg mode)
- `compute_mean_amplitude()` — mean amplitude in time window
- `paired_ttest()`, `compute_effect_size()` — basic statistics

**Available via pingouin (recommended for replications):**
- `pg.rm_anova()` — Repeated-measures ANOVA with Greenhouse-Geisser correction, eta-squared
- `pg.pairwise_tests()` — Post-hoc pairwise t-tests with Bonferroni/Holm correction, Hedges' g, BF10
- `pg.sphericity()` — Mauchly's test of sphericity

**Available via scipy.stats:**
- `ttest_rel()` — paired t-test
- `f_oneway()` — one-way ANOVA (between-subjects)

**Available via statsmodels:**
- Mixed-effects models
- Linear regression with contrasts

**NOT available (needs implementation):**
- Time-frequency (Morlet wavelets) → use `mne.time_frequency`
- Cluster-based permutation tests → use `mne.stats`
- Source localization → use `mne`
- Random Field Theory correction → requires SPM-equivalent (beyond current scope)

### Visualization

**Built-in (toolbox/visualization/):**
- `plot_erp()`, `plot_erp_comparison()`, `plot_butterfly()`, `plot_difference_wave()`, `plot_erp_image()`

**Publication-quality figures (proven patterns):**
- Okabe-Ito colorblind-safe palette: `{'Famous': '#D55E00', 'Unfamiliar': '#0072B2', 'Scrambled': '#009E73'}`
- Grand average waveforms with SEM shaded bands
- Multi-panel figures (GridSpec) with bold panel labels
- Bar charts with individual data points and significance markers
- 300 DPI PNG + vector PDF export
- Sans-serif fonts, removed top/right spines, inverted y-axis (EEG convention)

**NOT available:**
- Topographic maps → use `mne.viz.plot_topomap()`
- Brain surface maps → use `nilearn.plotting`
- Time-frequency plots → use `mne.time_frequency` + matplotlib

### fMRI (requires nilearn + nibabel)
- GLM → `nilearn.glm`
- MVPA → `nilearn.decoding`, `scikit-learn`
- ROI definition → `nilearn.masking`
- NIfTI I/O → `nibabel`

### Data I/O

**Built-in:**
- OpenNeuro download via AWS S3 (`aws s3 sync --no-sign-request`)
- BIDS metadata reading (JSON, TSV)

**Custom (proven in replication_test2):**
- EEGLAB .set/.fdt loading via `scipy.io.loadmat()` — works when MNE fails
- BIDS events TSV parsing via `pandas.read_csv(sep='\t')`
- Automatic subject discovery with exclusion patterns (e.g., sub-emptyroom)

---

## Known Datasets Quick Reference

| Dataset | Paper | Modality | Key Analysis |
|---------|-------|----------|-------------|
| ds003645 | Wakeman & Henson 2015 | EEG 75ch 1100Hz | N170 face perception (✓ REPLICATED) |
| ds003645 | Kappenman et al. 2021 (ERP CORE) | EEG 30ch 1024Hz | N170, P300, N400, MMN, ERN |
| ds003061 | Cahn, Delorme & Polich 2012 | EEG 64ch 256Hz | P300 auditory oddball (time-freq) |
| ds000105 | Haxby et al. 2001 | fMRI 3T | MVPA object decoding |
| ds000117 | Wakeman & Henson 2015 | EEG+MEG+fMRI | N170 face processing (multi-modal) |
| ds000246 | Jas et al. 2018 | MEG | Auditory M100 |

## Known Dataset-Paper Mapping

| Dataset | Paper | DOI |
|---------|-------|-----|
| ds003645 | Wakeman & Henson (2015) | 10.1038/sdata.2015.1 |
| ds003645 | Kappenman et al. (2021) ERP CORE | 10.1016/j.neuroimage.2020.117465 |
| ds003061 | Cahn, Delorme & Polich (2012) | 10.1007/s10339-012-0444-6 |
| ds000105 | Haxby et al. (2001) | 10.1126/science.1063736 |
| ds000117 | Wakeman & Henson (2015) | 10.1038/sdata.2015.1 |

## Dataset-Specific Notes (from successful replications)

### ds003645 — Wakeman & Henson 2015
- **Format**: EEGLAB .set + .fdt files (use scipy.io, not MNE)
- **Channels**: EEG001-EEG075 (generic labels), EEG061=HEOG, EEG062=VEOG, EEG063=ECG
- **Events**: BIDS TSV with `event_type: show_face/show_face_initial`, `face_type: famous_face/unfamiliar_face/scrambled_face`
- **Key channel**: EEG065 (right parieto-occipital, equivalent to paper's "EEG065")
- **Timing**: 34ms delay between MEG trigger and screen onset (for MEG, not EEG events)
- **Subjects**: 19 total + sub-emptyroom (exclude), paper used 16 of 19
- **Known issues**: Some subjects have high artifact rates (sub-003: 84%, sub-005: 89%)
