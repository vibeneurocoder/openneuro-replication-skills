<!-- openneuro-replication-skills | domain: Neuroscience Method Vocabulary -->

# Neuroscience Method Vocabulary → Python Implementation

When extracting methods from papers, these terms map to specific implementations.
Use this as a lookup when the paper describes a technique by name.

---

## Preprocessing Terms

| Paper Says | Means | Python Implementation |
|------------|-------|----------------------|
| "bandpass filtered X–Y Hz" | FIR or IIR filter between X and Y Hz | `raw.filter(l_freq=X, h_freq=Y)` |
| "highpass filtered at X Hz" | Remove frequencies below X Hz | `raw.filter(l_freq=X, h_freq=None)` |
| "lowpass filtered at X Hz" | Remove frequencies above X Hz | `raw.filter(l_freq=None, h_freq=X)` |
| "notch filter at 50/60 Hz" | Remove line noise | `raw.notch_filter(freqs=50)` |
| "zero-phase filter" | Non-causal, no phase distortion | `raw.filter(..., phase='zero')` (default) |
| "Butterworth Nth-order" | IIR filter, specific design | `raw.filter(..., method='iir', iir_params=dict(order=N, ftype='butter'))` |
| "FIR filter" | Finite impulse response | `raw.filter(..., method='fir')` (default) |
| "Hamming window" | FIR window function | `raw.filter(..., fir_window='hamming')` (default) |
| "pop_eegfiltnew" (EEGLAB) | EEGLAB's default FIR filter | `raw.filter(..., method='fir', fir_design='firwin')` |
| "average reference" | Re-reference to mean of all electrodes | `raw.set_eeg_reference('average', projection=False)` |
| "linked mastoids" | Re-reference to average of M1/M2 | `raw.set_eeg_reference(['M1', 'M2'], projection=False)` |
| "REST reference" | Infinity reference | `raw.set_eeg_reference('REST', projection=False)` |
| "downsampled to N Hz" | Reduce sampling rate | `raw.resample(sfreq=N)` |

## Artifact Rejection Terms

| Paper Says | Means | Python Implementation |
|------------|-------|----------------------|
| "epochs exceeding ±100 µV rejected" | Peak-to-peak amplitude threshold | `reject=dict(eeg=100e-6)` in `mne.Epochs()` |
| "ICA" / "Independent Component Analysis" | Decompose signals to remove artifacts | `mne.preprocessing.ICA()` — see `preprocessing-pipeline.md` |
| "runica" (EEGLAB) | Infomax ICA algorithm | `ICA(method='infomax', fit_params=dict(extended=True))` |
| "fastica" | FastICA algorithm | `ICA(method='fastica')` |
| "ADJUST" (EEGLAB plugin) | Automatic ICA component classification | `ica.find_bads_eog()` + `ica.find_bads_ecg()` (approximate) |
| "ICLabel" (EEGLAB plugin) | Deep learning ICA component labeling | `mne.preprocessing.ICA` + `mne_icalabel.label_components()` |
| "RANSAC" | Robust bad channel detection | `autoreject.Ransac()` |
| "autoreject" | Automated epoch rejection/interpolation | `autoreject.AutoReject()` |
| "interpolated bad channels" | Spherical spline interpolation | `epochs.interpolate_bads()` |
| "muscle artifact rejection" | Remove EMG contamination | High-frequency power thresholding or ICA |
| "EOG regression" | Remove eye artifact via regression | `mne.preprocessing.EOGRegression()` |

## Epoching Terms

| Paper Says | Means | Python Implementation |
|------------|-------|----------------------|
| "epochs –200 to 800 ms" | Time-locked segments around events | `mne.Epochs(raw, events, tmin=-0.2, tmax=0.8)` |
| "baseline corrected –200 to 0 ms" | Subtract mean of pre-stimulus period | `baseline=(-0.2, 0)` in `mne.Epochs()` |
| "prestimulus baseline" | Baseline from epoch start to stimulus | `baseline=(None, 0)` |
| "no baseline correction" | Raw amplitude preserved | `baseline=None` |
| "detrended" | Linear detrend before baseline | `detrend=1` in `mne.Epochs()` |

## ERP Analysis Terms

| Paper Says | Means | Python Implementation |
|------------|-------|----------------------|
| "mean amplitude" | Average voltage in time window | `evoked.get_data()[:, mask].mean() * 1e6` |
| "peak amplitude" | Maximum/minimum in time window | `evoked.get_peak(tmin, tmax, mode='neg')` |
| "peak latency" | Time of maximum/minimum | `evoked.get_peak(tmin, tmax, return_amplitude=True)` |
| "50% fractional area latency" | Time at which 50% of area under curve is reached | Custom: cumulative sum threshold |
| "adaptive mean" | Mean amplitude around individual peak | Find peak per subject, then extract ±N ms window |
| "difference wave" | Subtraction of two conditions | `mne.combine_evoked([a, b], weights=[1, -1])` |
| "grand average" | Average across subjects | `mne.grand_average(list_of_evoked)` |
| "GFP" / "Global Field Power" | Spatial standard deviation across channels | `evoked.get_data().std(axis=0)` |
| "RMS" | Root mean square across channels | `np.sqrt((evoked.get_data()**2).mean(axis=0))` |

## ERP Component Reference

| Name | Polarity | Window | Sites | Paradigm |
|------|----------|--------|-------|----------|
| C1 | Pos/Neg | 50–90 ms | Oz | Striate visual cortex |
| P1 / P100 | Positive | 80–130 ms | O1, O2 | Visual onset |
| N1 / N100 | Negative | 80–150 ms | Cz, Fz | Auditory onset |
| N170 | Negative | 140–200 ms | P7, P8 | Face/object perception |
| VPP | Positive | 140–200 ms | Fz, FCz | Face (vertex counterpart of N170) |
| MMN | Negative | 150–250 ms | Fz, FCz | Auditory deviant detection |
| N2 / N200 | Negative | 200–350 ms | Fz, FCz | Conflict, inhibition |
| N2pc | Negative | 200–300 ms | PO7/PO8 | Visual search (contralateral) |
| P2 / P200 | Positive | 150–250 ms | Cz, Fz | Attention, repetition |
| P3a | Positive | 250–350 ms | Fz, FCz | Novelty, distraction |
| P3b / P300 | Positive | 300–600 ms | Pz, CPz | Oddball target detection |
| N400 | Negative | 300–500 ms | Cz, CPz | Semantic violation |
| P600 / LPC | Positive | 500–800 ms | Pz, CPz | Syntactic/memory |
| ERN / Ne | Negative | 0–100 ms post-resp | FCz, Cz | Error monitoring |
| Pe | Positive | 200–400 ms post-resp | Pz, CPz | Error awareness |
| LRP | Lateralized | –500 to 0 ms pre-resp | C3, C4 | Motor preparation |
| CNV | Negative | –1000 to 0 ms | Cz, FCz | Anticipation |
| SSVEP | Oscillatory | Steady-state | Oz | Frequency tagging |

## Statistical Terms

| Paper Says | Means | Python Implementation |
|------------|-------|----------------------|
| "repeated-measures ANOVA" | Within-subject ANOVA | `pingouin.rm_anova()` |
| "mixed ANOVA" | Between + within factors | `pingouin.mixed_anova()` |
| "Greenhouse-Geisser correction" | Sphericity correction | `p-GG-corr` column from `rm_anova()` |
| "Huynh-Feldt correction" | Less conservative sphericity | `statsmodels.stats.anova.AnovaRM()` |
| "Bonferroni correction" | Divide alpha by N comparisons | `padjust='bonf'` in `pairwise_tests()` |
| "FDR correction" | False discovery rate | `padjust='fdr_bh'` or `multipletests(method='fdr_bh')` |
| "Holm-Bonferroni" | Step-down Bonferroni | `padjust='holm'` |
| "cluster-based permutation" | Maris & Oostenveld 2007 | `mne.stats.permutation_cluster_test()` |
| "paired t-test" | Within-subject comparison | `pingouin.ttest(x, y, paired=True)` |
| "Wilcoxon signed-rank" | Non-parametric paired test | `pingouin.wilcoxon(x, y)` |
| "Bayes factor" | Evidence ratio H1 vs H0 | `BF10` column from `pingouin.ttest()` |
| "Cohen's d" | Standardized mean difference | `cohen-d` column from `pingouin.ttest()` |
| "partial eta-squared" | ANOVA effect size | `np2` column from `pingouin.rm_anova(effsize='np2')` |
| "generalized eta-squared" | ANOVA effect size (alternative) | `ng2` from `pingouin.rm_anova(effsize='ng2')` |
| "Hedges' g" | Bias-corrected Cohen's d | `hedges` from `pingouin.pairwise_tests(effsize='hedges')` |

## fMRI Analysis Terms

| Paper Says | Means | Python Implementation |
|------------|-------|----------------------|
| "GLM" / "general linear model" | Voxel-wise regression | `nilearn.glm.first_level.FirstLevelModel()` |
| "first-level analysis" | Per-subject GLM | `FirstLevelModel().fit()` |
| "second-level analysis" | Group-level inference | `SecondLevelModel().fit()` |
| "contrast: A > B" | Subtraction of conditions | `glm.compute_contrast("A - B")` |
| "6 mm FWHM smoothing" | Gaussian spatial smoothing | `smoothing_fwhm=6.0` in `FirstLevelModel` |
| "128 s high-pass filter" | DCT-based drift removal | `high_pass=1/128` in `FirstLevelModel` |
| "FWE corrected" | Family-wise error correction | `height_control='bonferroni'` in `threshold_stats_img()` |
| "FDR q < 0.05" | False discovery rate | `height_control='fdr'` in `threshold_stats_img()` |
| "uncorrected p < 0.001" | No multiple comparison correction | `height_control='fpr'` in `threshold_stats_img()` |
| "MVPA" / "decoding" | Multi-voxel pattern analysis | `nilearn.decoding.Decoder()` |
| "searchlight" | Local pattern classification | `nilearn.decoding.SearchLight()` |
| "ROI analysis" | Region-based signal extraction | `NiftiLabelsMasker()` or `NiftiMasker(mask_img=roi)` |
| "functional connectivity" | Correlation between ROIs | `nilearn.connectome.ConnectivityMeasure(kind='correlation')` |

## Time-Frequency Terms

| Paper Says | Means | Python Implementation |
|------------|-------|----------------------|
| "Morlet wavelet" | Complex wavelet decomposition | `mne.time_frequency.tfr_morlet()` |
| "multitaper" | Spectral estimation method | `mne.time_frequency.tfr_multitaper()` |
| "Welch PSD" | Power spectral density | `mne.time_frequency.psd_array_welch()` |
| "ERSP" | Event-related spectral perturbation | `tfr.plot(baseline=(-0.2, 0), mode='logratio')` |
| "ITC" / "PLV" | Inter-trial coherence / phase-locking | `return_itc=True` in `tfr_morlet()` |
| "alpha band" | 8–13 Hz oscillation | `freqs=np.arange(8, 14)` |
| "theta band" | 4–8 Hz oscillation | `freqs=np.arange(4, 9)` |
| "beta band" | 13–30 Hz oscillation | `freqs=np.arange(13, 31)` |
| "gamma band" | 30–100 Hz oscillation | `freqs=np.arange(30, 101)` |
| "delta band" | 0.5–4 Hz oscillation | `freqs=np.arange(1, 5)` |

## Source Localization Terms

| Paper Says | Means | Python Implementation |
|------------|-------|----------------------|
| "dSPM" | Dynamic statistical parametric mapping | `mne.minimum_norm.apply_inverse(..., method='dSPM')` |
| "sLORETA" | Standardized LORETA | `mne.minimum_norm.apply_inverse(..., method='sLORETA')` |
| "eLORETA" | Exact LORETA | `mne.minimum_norm.apply_inverse(..., method='eLORETA')` |
| "MNE" | Minimum norm estimate | `mne.minimum_norm.apply_inverse(..., method='MNE')` |
| "beamformer" / "LCMV" | Linearly constrained minimum variance | `mne.beamformer.make_lcmv()` |
| "DICS" | Dynamic imaging of coherent sources | `mne.beamformer.make_dics()` |
| "dipole fitting" | Equivalent current dipole model | `mne.fit_dipole()` |
| "BEM" | Boundary element model (head model) | `mne.make_bem_model()` |
| "forward model" | Source-to-sensor mapping | `mne.make_forward_solution()` |
| "inverse solution" | Sensor-to-source mapping | `mne.minimum_norm.make_inverse_operator()` |
