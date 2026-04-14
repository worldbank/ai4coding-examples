# test-r.R
# Verify R is working: package management, palmerpenguins data, 
# visualisations (scatter, histogram, box, facets), and regression.

# -------------------------------------------------------
# 1. Package check + install
# -------------------------------------------------------
required_pkgs <- c("tidyverse", "ggplot2", "palmerpenguins")

missing_pkgs <- required_pkgs[!sapply(required_pkgs, requireNamespace, quietly = TRUE)]

if (length(missing_pkgs) > 0) {
  message("Installing missing packages: ", paste(missing_pkgs, collapse = ", "))
  install.packages(missing_pkgs, repos = "https://cloud.r-project.org")
} else {
  message("All required packages are already installed.")
}

library(tidyverse)
library(palmerpenguins)

# -------------------------------------------------------
# 2. Data overview
# -------------------------------------------------------
glimpse(penguins)

penguins_clean <- penguins |> drop_na()
cat(sprintf("\nRows after dropping NAs: %d (removed %d)\n",
            nrow(penguins_clean), nrow(penguins) - nrow(penguins_clean)))

# -------------------------------------------------------
# 3. Figure 1 — Scatter: bill dimensions coloured by species
# -------------------------------------------------------
fig_scatter <- ggplot(
  penguins_clean,
  aes(x = bill_length_mm, y = bill_depth_mm, colour = species, shape = species)
) +
  geom_point(alpha = 0.7, size = 2.5) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 0.9) +
  scale_colour_manual(values = c("darkorange", "purple", "cyan4")) +
  scale_shape_manual(values = c(16, 17, 15)) +
  labs(
    title    = "Bill length vs. bill depth",
    subtitle = "Linear fit per species",
    x        = "Bill length (mm)",
    y        = "Bill depth (mm)",
    colour   = "Species", shape = "Species"
  ) +
  theme_minimal(base_size = 13)

print(fig_scatter)

# -------------------------------------------------------
# 4. Figure 2 — Histogram: flipper length by species (overlaid)
# -------------------------------------------------------
fig_hist <- ggplot(
  penguins_clean,
  aes(x = flipper_length_mm, fill = species)
) +
  geom_histogram(alpha = 0.6, binwidth = 5, position = "identity", colour = "white") +
  scale_fill_manual(values = c("darkorange", "purple", "cyan4")) +
  labs(
    title = "Flipper length distribution",
    x     = "Flipper length (mm)",
    y     = "Count",
    fill  = "Species"
  ) +
  theme_minimal(base_size = 13)

print(fig_hist)

# -------------------------------------------------------
# 5. Figure 3 — Box plots: body mass by species and sex
# -------------------------------------------------------
fig_box <- ggplot(
  penguins_clean,
  aes(x = species, y = body_mass_g, fill = sex)
) +
  geom_boxplot(alpha = 0.7, outlier.shape = 21, outlier.size = 2) +
  scale_fill_manual(values = c("steelblue", "tomato")) +
  labs(
    title = "Body mass by species and sex",
    x     = "Species",
    y     = "Body mass (g)",
    fill  = "Sex"
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "top")

print(fig_box)

# -------------------------------------------------------
# 6. Figure 4 — Faceted scatter: bill dimensions faceted by island
# -------------------------------------------------------
fig_facet <- ggplot(
  penguins_clean,
  aes(x = bill_length_mm, y = bill_depth_mm, colour = species, shape = species)
) +
  geom_point(alpha = 0.7, size = 2) +
  facet_wrap(~island, nrow = 1) +
  scale_colour_manual(values = c("darkorange", "purple", "cyan4")) +
  scale_shape_manual(values = c(16, 17, 15)) +
  labs(
    title    = "Bill dimensions by island",
    subtitle = "Faceted by island of observation",
    x        = "Bill length (mm)",
    y        = "Bill depth (mm)",
    colour   = "Species", shape = "Species"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    panel.spacing  = unit(1, "lines"),
    strip.text     = element_text(face = "bold")
  )

print(fig_facet)

# -------------------------------------------------------
# 7. Regression: body mass ~ flipper length + bill length + species
# -------------------------------------------------------
model <- lm(
  body_mass_g ~ flipper_length_mm + bill_length_mm + bill_depth_mm + species,
  data = penguins_clean
)

cat("\n---- OLS Regression: Body mass ----\n")
print(summary(model))

# Tidy coefficient table
cat("\n---- Tidy coefficients ----\n")
coef_tbl <- broom::tidy(model, conf.int = TRUE) |>
  mutate(across(where(is.numeric), \(x) round(x, 3)))
print(coef_tbl)

cat(sprintf(
  "\nAdjusted R²: %.4f | Residual std. error: %.1f g\n",
  summary(model)$adj.r.squared,
  summary(model)$sigma
))
