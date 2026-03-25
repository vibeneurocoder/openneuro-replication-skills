<!-- openneuro-replication-skills | domain: Statistics and Replication Comparison -->
<!-- target libraries: pingouin>=0.5.3, scipy>=1.11, statsmodels>=0.14 -->

# Domain: Statistics and Replication Comparison

Replication requires matching the original paper's statistical tests exactly, then
comparing effect sizes and patterns to assess replication success.

---

## Repeated-Measures ANOVA with `pingouin`

The most common test in ERP papers. Pingouin provides the cleanest interface.

### `pingouin.rm_anova(...)`

**Signature:**
```text
pingouin.rm_anova(
    data=None, dv=None, within=None, subject=None,
    correction='auto', detailed=False, effsize='ng2'
)
# Returns: pandas.DataFrame
# Source: pingouin/parametric.py
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `data` | `DataFrame` | — | Long-format data. |
| `dv` | `str` | — | Column name of the dependent variable (e.g., `'amplitude'`). |
| `within` | `str \| list` | — | Within-subject factor(s). |
| `subject` | `str` | — | Column name for subject identifier. |
| `correction` | `str \| bool` | `'auto'` | `'auto'`, `True` (Greenhouse-Geisser), `False`. |
| `detailed` | `bool` | `False` | Include SS, MS columns. |
| `effsize` | `str` | `'ng2'` | `'ng2'` (generalized eta²), `'np2'` (partial eta²). |

**Example (one-way RM-ANOVA):**

```python
import pingouin as pg

# Data must be long-format: subject | condition | amplitude
results = pg.rm_anova(
    data=df,
    dv="amplitude",
    within="condition",
    subject="subject",
    detailed=True,
    effsize="np2",  # partial eta-squared, most commonly reported
)
print(results[["Source", "ddof1", "ddof2", "F", "p-unc", "p-GG-corr", "np2", "eps"]])
```

**Output columns:**
| Column | Description |
|--------|-------------|
| `F` | F-statistic |
| `ddof1` | Numerator degrees of freedom |
| `ddof2` | Denominator degrees of freedom |
| `p-unc` | Uncorrected p-value |
| `p-GG-corr` | Greenhouse-Geisser corrected p-value |
| `np2` | Partial eta-squared effect size |
| `eps` | Epsilon (sphericity estimate) |

### Two-Way RM-ANOVA

```python
# Paper: "2 × 3 RM-ANOVA with factors Emotion (happy, neutral) and Region (frontal, central, parietal)"
results = pg.rm_anova(
    data=df,
    dv="amplitude",
    within=["emotion", "region"],
    subject="subject",
    effsize="np2",
)
print(results.round(4))
```

**Pitfalls:**
- Pingouin expects **long-format** data. One row per subject × condition combination.
- For partial eta-squared (`np2`), pingouin computes `SSeffect / (SSeffect + SSerror)`. Some papers use generalized eta-squared (`ng2`) which uses total SS in the denominator.
- Papers that say "Greenhouse-Geisser corrected" → use the `p-GG-corr` column.
- Papers that say "Huynh-Feldt corrected" → pingouin doesn't compute this directly. Use `statsmodels` AnovaRM instead.

---

## Pairwise Comparisons (Post-Hoc Tests)

### `pingouin.pairwise_tests(...)`

**Signature:**
```text
pingouin.pairwise_tests(
    data=None, dv=None, within=None, between=None,
    subject=None, parametric=True, marginal=True,
    alpha=0.05, alternative='two-sided', padjust='bonf',
    effsize='hedges', correction='auto', nan_policy='listwise',
    return_desc=False, interaction=True, within_first=True
)
# Returns: pandas.DataFrame
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `padjust` | `str` | `'bonf'` | Correction method: `'bonf'`, `'holm'`, `'fdr_bh'`, `'none'`. |
| `effsize` | `str` | `'hedges'` | `'hedges'` (corrected d), `'cohen'`, `'eta-square'`, `'none'`. |
| `parametric` | `bool` | `True` | Paired t-tests (`True`) or Wilcoxon (`False`). |
| `return_desc` | `bool` | `False` | Include mean/std per group. |

**Example:**

```python
# Post-hoc pairwise comparisons after significant ANOVA
posthoc = pg.pairwise_tests(
    data=df,
    dv="amplitude",
    within="condition",
    subject="subject",
    padjust="bonf",  # match paper's correction method
    effsize="hedges",
    return_desc=True,
)
print(posthoc[["Contrast", "A", "B", "mean(A)", "mean(B)", "T", "dof", "p-unc", "p-corr", "hedges"]])
```

---

## Paired t-Test

### `pingouin.ttest(...)`

**Signature:**
```text
pingouin.ttest(
    x, y, paired=False, alternative='two-sided',
    correction='auto', r=0.707, confidence=0.95
)
# Returns: pandas.DataFrame
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `x` | `array-like` | — | First sample. |
| `y` | `array-like` | — | Second sample. |
| `paired` | `bool` | `False` | Paired t-test if `True`. |
| `alternative` | `str` | `'two-sided'` | `'two-sided'`, `'greater'`, `'less'`. |
| `r` | `float` | `0.707` | Cauchy prior for Bayesian factor. |

**Example:**

```python
# Paper: "Paired t-test comparing N170 amplitude for faces vs. cars"
face_amps = df[df["condition"] == "face"]["amplitude"]
car_amps = df[df["condition"] == "car"]["amplitude"]

result = pg.ttest(face_amps, car_amps, paired=True)
print(result[["T", "dof", "alternative", "p-val", "cohen-d", "BF10", "power"]])
```

**Output columns:**
| Column | Description |
|--------|-------------|
| `T` | t-statistic |
| `dof` | Degrees of freedom |
| `p-val` | p-value |
| `cohen-d` | Cohen's d effect size |
| `BF10` | Bayes Factor (evidence for H1 vs H0) |
| `power` | Achieved power |

---

## Non-Parametric Alternatives

When papers report non-parametric tests:

```python
# Wilcoxon signed-rank (paired, non-parametric t-test alternative)
result = pg.wilcoxon(face_amps, car_amps, alternative="two-sided")
print(result[["W-val", "p-val", "RBC", "CLES"]])

# Friedman test (non-parametric RM-ANOVA alternative)
result = pg.friedman(data=df, dv="amplitude", within="condition", subject="subject")
print(result[["Q", "dof", "p-unc"]])

# Mann-Whitney U (independent, non-parametric)
result = pg.mwu(group1_amps, group2_amps, alternative="two-sided")
```

---

## Cluster-Based Permutation Tests with MNE

Papers citing "Maris & Oostenveld (2007)" use cluster permutation.

### `mne.stats.permutation_cluster_test(...)`

**Signature:**
```text
mne.stats.permutation_cluster_test(
    X, threshold=None, n_permutations=1024, tail=0,
    stat_fun=None, adjacency=None, n_jobs=None,
    seed=None, max_step=1, exclude=None, step_down_p=0,
    t_power=1, out_type='indices', check_disjoint=False,
    buffer_size=None, verbose=None
)
# Returns: (T_obs, clusters, cluster_p_values, H0)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `X` | `list of ndarray` | — | List of arrays, one per condition. Shape: `(n_subjects, n_times)` or `(n_subjects, n_times, n_channels)`. |
| `threshold` | `float \| dict \| None` | `None` | Cluster-forming threshold. `None` uses `p=0.05` F/t threshold. |
| `n_permutations` | `int` | `1024` | Number of permutations. Papers typically use 1000–10000. |
| `tail` | `int` | `0` | `0` (two-tailed), `1` (greater), `-1` (less). |
| `adjacency` | `sparse matrix \| None` | `None` | Spatial adjacency for spatio-temporal clusters. |

**Example (temporal cluster test):**

```python
import numpy as np
from mne.stats import permutation_cluster_test

# X: list of 2 arrays, each (n_subjects, n_times)
X = [
    np.array([epochs["face"].average().get_data().mean(axis=0) for epochs in all_subject_epochs]),
    np.array([epochs["car"].average().get_data().mean(axis=0) for epochs in all_subject_epochs]),
]

T_obs, clusters, cluster_pv, H0 = permutation_cluster_test(
    X,
    n_permutations=5000,
    tail=0,
    seed=42,
)
sig_clusters = [c for c, p in zip(clusters, cluster_pv) if p < 0.05]
print(f"Found {len(sig_clusters)} significant clusters")
```

### `mne.stats.permutation_cluster_1samp_test(...)`

For testing a single condition against zero (e.g., difference waves):

```python
from mne.stats import permutation_cluster_1samp_test

# Test difference wave against zero
diff_data = face_data - car_data  # shape: (n_subjects, n_times)

T_obs, clusters, cluster_pv, H0 = permutation_cluster_1samp_test(
    diff_data,
    n_permutations=5000,
    tail=0,
    seed=42,
)
```

### Spatio-Temporal Cluster Test

```python
from mne.channels import find_ch_adjacency

# Get channel adjacency for spatial clustering
adjacency, ch_names = find_ch_adjacency(epochs.info, ch_type="eeg")

# Data shape: (n_subjects, n_times, n_channels) — note the transpose
X_st = [data.transpose(0, 2, 1) for data in X]  # reshape if needed

T_obs, clusters, cluster_pv, H0 = permutation_cluster_test(
    X_st,
    n_permutations=5000,
    adjacency=adjacency,
    tail=0,
    seed=42,
)
```

---

## Effect Sizes

### Cohen's d (Paired)

```python
# Pingouin computes automatically in ttest:
result = pg.ttest(face_amps, car_amps, paired=True)
d = result["cohen-d"].values[0]

# Manual computation:
def cohens_d_paired(x, y):
    diff = np.array(x) - np.array(y)
    return diff.mean() / diff.std(ddof=1)
```

### Partial Eta-Squared

```python
# From RM-ANOVA output:
np2 = results["np2"].values[0]

# Manual: η²p = SS_effect / (SS_effect + SS_error)
```

### Confidence Intervals

```python
# 95% CI for mean difference
from scipy import stats

diff = face_amps.values - car_amps.values
mean_diff = diff.mean()
se = stats.sem(diff)
ci = stats.t.interval(0.95, df=len(diff)-1, loc=mean_diff, scale=se)
print(f"Mean difference: {mean_diff:.2f} µV, 95% CI: [{ci[0]:.2f}, {ci[1]:.2f}]")
```

---

## Comparing Replication Results with Original Paper

### Quantitative Comparison Framework

```python
def compare_with_paper(our_value, paper_value, paper_ci=None, metric_name=""):
    """Compare replication result against paper's reported value."""
    diff = our_value - paper_value
    pct_diff = (diff / abs(paper_value)) * 100 if paper_value != 0 else float('inf')

    status = "CLOSE"
    if abs(pct_diff) > 50:
        status = "DIVERGENT"
    elif abs(pct_diff) > 20:
        status = "MODERATE_DIFF"

    result = {
        "metric": metric_name,
        "ours": our_value,
        "paper": paper_value,
        "difference": diff,
        "pct_difference": pct_diff,
        "status": status,
    }

    if paper_ci is not None:
        result["within_paper_ci"] = paper_ci[0] <= our_value <= paper_ci[1]

    return result

# Example usage:
comparisons = [
    compare_with_paper(-5.2, -4.8, metric_name="N170 face amplitude (µV)"),
    compare_with_paper(164, 168, metric_name="N170 peak latency (ms)"),
    compare_with_paper(0.82, 0.78, metric_name="Partial eta-squared"),
    compare_with_paper(0.003, 0.001, metric_name="p-value (ANOVA)"),
]

import pandas as pd
comparison_df = pd.DataFrame(comparisons)
print(comparison_df.to_string(index=False))
```

### Replication Success Criteria

```python
def assess_replication(comparisons, alpha=0.05):
    """Assess overall replication success."""
    report = []

    for comp in comparisons:
        # Check 1: Same direction of effect
        same_direction = (comp["ours"] > 0) == (comp["paper"] > 0)

        # Check 2: Within reasonable range (< 30% difference)
        within_range = abs(comp["pct_difference"]) < 30

        report.append({
            **comp,
            "same_direction": same_direction,
            "within_range": within_range,
        })

    # Overall assessment
    n_same_dir = sum(r["same_direction"] for r in report)
    n_in_range = sum(r["within_range"] for r in report)

    print(f"\n=== Replication Assessment ===")
    print(f"Same direction: {n_same_dir}/{len(report)}")
    print(f"Within 30% range: {n_in_range}/{len(report)}")

    return report
```

---

## Mixed Models with `statsmodels`

When papers use linear mixed-effects models:

### `statsmodels.formula.api.mixedlm(...)`

```python
import statsmodels.formula.api as smf

# "Linear mixed model with condition as fixed effect and subject as random intercept"
model = smf.mixedlm(
    "amplitude ~ condition",
    data=df,
    groups=df["subject"],
    re_formula="~1",  # random intercept only
)
result = model.fit()
print(result.summary())
```

### `statsmodels.stats.anova.AnovaRM(...)`

Alternative to pingouin for Huynh-Feldt correction:

```python
from statsmodels.stats.anova import AnovaRM

aov = AnovaRM(data=df, depvar="amplitude", subject="subject", within=["condition"])
result = aov.fit()
print(result.anova_table)
```

---

## Multiple Comparisons Correction

```python
from statsmodels.stats.multitest import multipletests

p_values = [0.01, 0.04, 0.03, 0.08, 0.001]

# Bonferroni (most conservative)
reject_bonf, p_bonf, _, _ = multipletests(p_values, method="bonferroni")

# FDR Benjamini-Hochberg (common in neuroimaging)
reject_fdr, p_fdr, _, _ = multipletests(p_values, method="fdr_bh")

# Holm-Bonferroni (step-down, less conservative than Bonferroni)
reject_holm, p_holm, _, _ = multipletests(p_values, method="holm")

print(f"Bonferroni rejects: {reject_bonf}")
print(f"FDR rejects: {reject_fdr}")
```

---

## Bayesian Analysis

When papers report Bayes factors:

```python
# Pingouin includes BF10 in t-test output automatically
result = pg.ttest(face_amps, car_amps, paired=True)
bf10 = result["BF10"].values[0]

# Interpretation:
# BF10 > 100: Extreme evidence for H1
# BF10 > 30:  Very strong evidence for H1
# BF10 > 10:  Strong evidence for H1
# BF10 > 3:   Moderate evidence for H1
# BF10 1–3:   Anecdotal evidence for H1
# BF10 < 1/3: Moderate evidence for H0
# BF10 < 1/10: Strong evidence for H0

# For ANOVA Bayes factors:
result = pg.rm_anova(data=df, dv="amplitude", within="condition", subject="subject")
# Then use pg.bayesfactor_ttest for pairwise
```

---

## Output Template for Replication Reports

```python
def print_replication_stats(results_dict, paper_dict):
    """Print formatted comparison table."""
    print("\n" + "="*70)
    print("REPLICATION RESULTS vs ORIGINAL PAPER")
    print("="*70)

    for key in results_dict:
        ours = results_dict[key]
        paper = paper_dict.get(key, "not reported")
        match = "✓" if isinstance(paper, (int, float)) and abs(ours - paper) / max(abs(paper), 1e-10) < 0.3 else "?"
        print(f"  {key:40s} Ours: {ours:>10.3f}  Paper: {str(paper):>10s}  {match}")

    print("="*70)
```
