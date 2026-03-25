# Toolbox Capabilities & Known Datasets

Use this to fill in the gap analysis when comparing paper methods against what the replication stack provides.

---

## EEG Preprocessing

### Built-in via MNE-Python (≥1.6)

| Capability | Function | Signature |
|-----------|----------|-----------|
| Load EEGLAB | `mne.io.read_raw_eeglab()` | `(input_fname, eog=(), preload=False)` |
| Load BrainVision | `mne.io.read_raw_brainvision()` | `(vhdr_fname, eog=('HEOG','VEOG'), preload=False)` |
| Load EDF/BDF | `mne.io.read_raw_edf()` / `read_raw_bdf()` | `(input_fname, preload=False)` |
| Load BIDS | `mne_bids.read_raw_bids()` | `(bids_path)` — auto-detects format |
| FIR bandpass | `raw.filter()` | `(l_freq, h_freq, method='fir', fir_design='firwin')` |
| IIR Butterworth | `raw.filter()` | `(l_freq, h_freq, method='iir', iir_params=dict(order=N, ftype='butter'))` |
| Notch filter | `raw.notch_filter()` | `(freqs)` — e.g., `50` or `[50, 100]` |
| Average reference | `raw.set_eeg_reference()` | `(ref_channels='average', projection=False)` |
| Linked mastoids | `raw.set_eeg_reference()` | `(ref_channels=['M1','M2'], projection=False)` |
| Epoching | `mne.Epochs()` | `(raw, events, event_id, tmin, tmax, baseline, reject)` |
| Event extraction | `mne.events_from_annotations()` | `(raw)` → `(events, event_id)` |
| ERP averaging | `epochs.average()` | `(picks=None, method='mean')` |
| Peak finding | `evoked.get_peak()` | `(tmin, tmax, mode='neg', return_amplitude=True)` |
| Grand average | `mne.grand_average()` | `(list_of_evoked)` |
| Difference wave | `mne.combine_evoked()` | `([a, b], weights=[1, -1])` |
| ICA | `mne.preprocessing.ICA()` | `(n_components, method='infomax', random_state=42)` |
| Auto-detect EOG | `ica.find_bads_eog()` | `(raw, ch_name=['VEOG','HEOG'])` |
| Bad channel interp | `epochs.interpolate_bads()` | `(reset_bads=True, mode='accurate')` |
| Resampling | `raw.resample()` | `(sfreq)` |
| Channel montage | `raw.set_montage()` | `('standard_1020', on_missing='warn')` |

### Built-in via scipy (fallback for problematic .set files)

| Capability | Function | Notes |
|-----------|----------|-------|
| Load EEGLAB .set | `scipy.io.loadmat(fname, squeeze_me=True)` | Works when MNE fails |
| SOS filter | `scipy.signal.butter() + sosfiltfilt()` | Butterworth zero-phase |
| Basic stats | `scipy.stats.ttest_rel()` | Paired t-test |

### Via autoreject (≥0.4)

| Capability | Function | Notes |
|-----------|----------|-------|
| Auto rejection | `autoreject.AutoReject(n_jobs=-1)` | Bayesian optimization thresholds |
| RANSAC bad ch | `autoreject.Ransac(n_jobs=-1)` | Robust bad channel detection |

### NOT available (needs custom implementation)

| Capability | Workaround |
|-----------|------------|
| Microsaccade rejection | Custom saccade detection or MNE annotations |
| Random Field Theory correction | Beyond current scope — use cluster permutation instead |
| AMICA (multi-model ICA) | Not available in Python — use standard ICA |

---

## EEG/fMRI Analysis

### Via pingouin (≥0.5.3) — Recommended for replications

| Capability | Function | Key Output Columns |
|-----------|----------|-------------------|
| RM-ANOVA | `pg.rm_anova(data, dv, within, subject, effsize='np2')` | `F`, `p-unc`, `p-GG-corr`, `np2`, `eps` |
| Mixed ANOVA | `pg.mixed_anova(data, dv, within, between, subject)` | `F`, `p-unc`, `np2` |
| Pairwise t-tests | `pg.pairwise_tests(data, dv, within, subject, padjust='bonf')` | `T`, `p-corr`, `hedges`, `BF10` |
| Paired t-test | `pg.ttest(x, y, paired=True)` | `T`, `p-val`, `cohen-d`, `BF10`, `power` |
| Wilcoxon | `pg.wilcoxon(x, y)` | `W-val`, `p-val`, `RBC`, `CLES` |
| Friedman | `pg.friedman(data, dv, within, subject)` | `Q`, `p-unc` |

### Via MNE stats

| Capability | Function | Notes |
|-----------|----------|-------|
| Cluster permutation | `mne.stats.permutation_cluster_test(X, n_permutations=5000)` | Maris & Oostenveld 2007 |
| 1-sample cluster | `mne.stats.permutation_cluster_1samp_test(X)` | Difference wave vs zero |
| Spatio-temporal cluster | Add `adjacency=find_ch_adjacency(info)` | Channels × time |

### Via nilearn (≥0.10) — fMRI

| Capability | Function | Key Parameters |
|-----------|----------|----------------|
| First-level GLM | `FirstLevelModel(t_r, hrf_model, high_pass, smoothing_fwhm)` | SPM: `hrf='spm'`, FSL: `hrf='glover'` |
| Contrasts | `glm.compute_contrast("A - B", output_type='z_score')` | |
| Second-level | `SecondLevelModel().fit(contrast_imgs, design_matrix)` | Group analysis |
| Thresholding | `threshold_stats_img(img, alpha, height_control)` | `'fdr'`, `'bonferroni'`, `'fpr'` |
| MVPA decoding | `Decoder(estimator='svc', cv=5)` | |
| Searchlight | `SearchLight(mask_img, radius=5.6)` | |
| ROI extraction | `NiftiLabelsMasker(atlas.maps)` | Atlas-based |
| Connectivity | `ConnectivityMeasure(kind='correlation')` | |
| Confound loading | `load_confounds(img, strategy=('motion','wm_csf'))` | fMRIPrep outputs |

### Via statsmodels (≥0.14)

| Capability | Function | Notes |
|-----------|----------|-------|
| Mixed model | `smf.mixedlm("dv ~ cond", data, groups="subject")` | Random intercept |
| RM-ANOVA (HF) | `AnovaRM(data, depvar, subject, within)` | Huynh-Feldt correction |
| Multiple comp | `multipletests(p_values, method='fdr_bh')` | Bonferroni, FDR, Holm |

---

## Visualization

### Built-in via MNE + matplotlib

| Capability | Function | Notes |
|-----------|----------|-------|
| ERP comparison | `mne.viz.plot_compare_evokeds(evokeds, picks)` | With CI bands |
| Topographic map | `evoked.plot_topomap(times)` | At specific time points |
| Butterfly plot | `evoked.plot(spatial_colors=True)` | All channels |
| ERP image | `epochs.plot_image(picks)` | Trial × time heatmap |
| Time-frequency | `power.plot(baseline, mode='logratio')` | After `tfr_morlet()` |

### Publication standards

- **Palette**: Okabe-Ito colorblind-safe (`#0072B2`, `#D55E00`, `#009E73`, `#E69F00`)
- **DPI**: 300 minimum, save both PNG and PDF
- **ERP convention**: Negative up (`invert_y=True` or `ax.invert_yaxis()`)
- **Fonts**: Sans-serif (Arial/DejaVu Sans), 7-9pt labels
- **Spines**: Remove top/right
- **Error bars**: SEM with shaded bands for waveforms
- **Panel labels**: Bold uppercase A, B, C in upper-left corner

---

## Data I/O

| Capability | Method | Notes |
|-----------|--------|-------|
| OpenNeuro download | `aws s3 sync --no-sign-request s3://openneuro.org/{id}` | See `references/openneuro-data-access.md` |
| BIDS metadata | `json.load()` for `.json`, `pd.read_csv(sep='\t')` for `.tsv` | |
| Subject discovery | `Path(bids_root).glob("sub-*")` | Exclude `sub-emptyroom` |
| Format detection | Check extensions: `.set`, `.vhdr`, `.edf`, `.nii.gz` | |

---

## Known Datasets Quick Reference

| Dataset | Paper | Modality | Key Analysis | DOI |
|---------|-------|----------|-------------|-----|
| ds003645 | Kappenman et al. 2021 (ERP CORE) | EEG 30ch 1024Hz | N170, P300, N400, MMN, ERN | 10.1016/j.neuroimage.2020.117465 |
| ds003645 | Wakeman & Henson 2015 | EEG 75ch 1100Hz | N170 face perception | 10.1038/sdata.2015.1 |
| ds000105 | Haxby et al. 2001 | fMRI 3T | MVPA object decoding | 10.1126/science.1063736 |
| ds000117 | Wakeman & Henson 2015 | EEG+MEG+fMRI | Face processing (multi-modal) | 10.1038/sdata.2015.1 |
| ds004621 | Dzianok et al. 2022 | EEG 127ch 1000Hz | P300 auditory oddball | 10.1093/gigascience/giac015 |
| ds006480 | Kim et al. 2025 | EEG 65ch 1000Hz | Auditory oddball + arousal | bioRxiv preprint |
| ds003061 | Cahn et al. 2012 | EEG 64ch 256Hz | P300 auditory oddball (TF) | 10.1007/s10339-012-0444-6 |
| ds000246 | Jas et al. 2018 | MEG 306ch | Auditory M100 | 10.3389/fnins.2018.00530 |
| ds000228 | Richardson et al. 2018 | fMRI | Theory of mind | 10.1038/s41467-018-03399-2 |

## Dataset-Specific Notes (from successful replications)

### ds003645 — Wakeman & Henson 2015
- **Format**: EEGLAB .set + .fdt files (use `scipy.io.loadmat()` fallback if MNE fails)
- **Channels**: EEG001-EEG075 (generic labels), EEG061=HEOG, EEG062=VEOG, EEG063=ECG
- **Events**: BIDS TSV with `event_type: show_face/show_face_initial`, `face_type: famous_face/unfamiliar_face/scrambled_face`
- **Key channel**: EEG065 (right parieto-occipital, equivalent to paper's "EEG065")
- **Timing**: 34ms delay between MEG trigger and screen onset (for MEG, not EEG events)
- **Subjects**: 19 total + sub-emptyroom (exclude), paper used 16 of 19
- **Known issues**: Some subjects have high artifact rates (sub-003: 84%, sub-005: 89%)

### ds004621 — Dzianok et al. 2022
- **Format**: BrainVision .vhdr/.vmrk/.eeg
- **Channels**: 127 EEG channels, 1000 Hz
- **Events**: Stimulus codes in .vmrk annotations
- **Key components**: N200 at Fz, P300 at Pz
- **Note**: Paper reports qualitative results only — no exact amplitudes for quantitative comparison

### ds006480 — Kim et al. 2025
- **Format**: EEGLAB .set (EGI HydroCel 65-channel)
- **Channels**: E-numbered (E1, E2, ...) — need EGI montage mapping
- **Events**: 3-stimulus oddball with arousal manipulation (control vs threat-of-shock)
- **Gaps**: Average re-reference (critical), EGI channel mapping (critical), ICA (important)
