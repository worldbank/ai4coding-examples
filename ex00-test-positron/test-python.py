# test-python.py
# Verify Python is working: package management, palmerpenguins data,
# visualisations (violin, pairplot, bar + CI, KDE heatmap), and regression.

# -------------------------------------------------------
# 1. Package check + install
# -------------------------------------------------------
import importlib
import subprocess
import sys

required = ["palmerpenguins", "pandas", "matplotlib", "seaborn", "statsmodels", "scikit-learn"]

missing = [pkg for pkg in required if importlib.util.find_spec(pkg) is None]
if missing:
    print(f"Installing missing packages: {', '.join(missing)}")
    subprocess.check_call([sys.executable, "-m", "pip", "install", *missing])
else:
    print("All required packages are already installed.")

# -------------------------------------------------------
# 2. Imports and data loading
# -------------------------------------------------------
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from palmerpenguins import load_penguins
import statsmodels.formula.api as smf
from sklearn.preprocessing import LabelEncoder

sns.set_theme(style="whitegrid", palette="colorblind")
SPECIES_PALETTE = {"Adelie": "#FF8C00", "Chinstrap": "#9400D3", "Gentoo": "#008B8B"}

# -------------------------------------------------------
# 3. Data loading
# -------------------------------------------------------
penguins = load_penguins()
penguins_clean = penguins.dropna().copy()

print(f"Total rows: {len(penguins)} | After dropping NAs: {len(penguins_clean)}")
print(penguins_clean.describe().round(2))

# -------------------------------------------------------
# 4. Figure 1 — Violin plots: body mass by species and sex
# -------------------------------------------------------
fig, ax = plt.subplots(figsize=(9, 5))
sns.violinplot(
    data=penguins_clean,
    x="species", y="body_mass_g",
    hue="sex", split=True,
    palette={"male": "steelblue", "female": "tomato"},
    inner="quartile", linewidth=1.2,
    ax=ax,
)
ax.set_title("Body mass distribution by species and sex", fontsize=14)
ax.set_xlabel("Species")
ax.set_ylabel("Body mass (g)")
plt.tight_layout()
plt.show()

# -------------------------------------------------------
# 5. Figure 2 — Pair plot of all numeric morphometrics
# -------------------------------------------------------
numeric_cols = ["bill_length_mm", "bill_depth_mm", "flipper_length_mm", "body_mass_g"]
pair_data = penguins_clean[numeric_cols + ["species"]]

pg = sns.pairplot(
    pair_data,
    hue="species",
    palette=SPECIES_PALETTE,
    diag_kind="kde",
    plot_kws={"alpha": 0.6, "s": 30},
)
pg.figure.suptitle("Pairwise relationships — all morphometric variables", y=1.02, fontsize=13)
plt.show()

# -------------------------------------------------------
# 5. Figure 3 — Mean flipper length per species × island (bar + CI)
# -------------------------------------------------------
summary = (
    penguins_clean
    .groupby(["island", "species"])["flipper_length_mm"]
    .agg(["mean", "sem"])
    .reset_index()
    .rename(columns={"mean": "mean_flipper", "sem": "se_flipper"})
)

fig, ax = plt.subplots(figsize=(9, 5))
sns.barplot(
    data=penguins_clean,
    x="island", y="flipper_length_mm",
    hue="species",
    palette=SPECIES_PALETTE,
    errorbar="se", capsize=0.08,
    ax=ax,
)
ax.set_title("Mean flipper length by island and species (±SE)", fontsize=14)
ax.set_xlabel("Island")
ax.set_ylabel("Flipper length (mm)")
ax.legend(title="Species", loc="lower right")
plt.tight_layout()
plt.show()

# -------------------------------------------------------
# 6. Figure 4 — KDE + rug: bill length by species
# -------------------------------------------------------
fig, ax = plt.subplots(figsize=(9, 5))
for species, colour in SPECIES_PALETTE.items():
    subset = penguins_clean.loc[penguins_clean["species"] == species, "bill_length_mm"]
    sns.kdeplot(subset, ax=ax, label=species, color=colour, linewidth=2, fill=True, alpha=0.15)
    ax.plot(subset, [-0.002] * len(subset), "|", color=colour, alpha=0.5, markersize=8)

ax.set_title("Kernel density of bill length by species (with rug)", fontsize=14)
ax.set_xlabel("Bill length (mm)")
ax.set_ylabel("Density")
ax.legend(title="Species")
plt.tight_layout()
plt.show()

# -------------------------------------------------------
# 7. OLS regression: body mass ~ morphometrics + species
# -------------------------------------------------------
formula = "body_mass_g ~ flipper_length_mm + bill_length_mm + bill_depth_mm + C(species)"
model = smf.ols(formula, data=penguins_clean).fit()

print("\n" + "=" * 60)
print("OLS Regression: body mass ~ morphometrics + species")
print("=" * 60)
print(model.summary())
print(f"\nN = {int(model.nobs)}  |  Adj. R² = {model.rsquared_adj:.4f}  |  RMSE = {model.mse_resid**0.5:.1f} g")
