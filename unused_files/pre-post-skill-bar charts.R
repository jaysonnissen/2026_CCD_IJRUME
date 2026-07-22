
#Run this after IJRUME_analysis.R

################################################################################

# CCA

## ---------- POST ----------

pp_post_cca <- post_label_cca_full_long %>%
  filter(post != "Missing") %>%
  mutate(
    A1 = substr(post, 1, 1),
    A2 = substr(post, 2, 2),
    A3 = substr(post, 3, 3),
    A4 = substr(post, 4, 4),
    A5 = substr(post,5,5)
    
  ) %>%
  mutate(across(A1:A5, ~ as.integer(.)))   # "0"/"1" -> 0/1

marginal_pct_post_cca <- pp_post_cca %>%
  select(A1:A5) %>%
  summarise(across(
    everything(),
    ~ mean(. == 1, na.rm = TRUE) * 100   # percent mastered
  )) %>%
  pivot_longer(
    cols = everything(),
    names_to = "attribute",
    values_to = "pct_mastered_post"
  )

## ---------- PRE ----------

pp_pre_cca <- pre_label_cca_full_long %>%
  filter(pre != "Missing") %>%
  mutate(
    A1 = substr(pre, 1, 1),
    A2 = substr(pre, 2, 2),
    A3 = substr(pre, 3, 3),
    A4 = substr(pre, 4, 4),
    A5 = substr(pre, 5, 5)
    
  ) %>%
  mutate(across(A1:A5, ~ as.integer(.)))

marginal_pct_pre_cca <- pp_pre_cca %>%
  select(A1:A5) %>%
  summarise(across(
    everything(),
    ~ mean(. == 1, na.rm = TRUE) * 100
  )) %>%
  pivot_longer(
    cols = everything(),
    names_to = "attribute",
    values_to = "pct_mastered_pre"
  )

## ---------- COMBINE: pre + post columns per attribute ----------

marginal_pct_wide_cca <- marginal_pct_pre_cca %>%
  left_join(marginal_pct_post_cca, by = "attribute")

## ---------- Plot pre vs post side-by-side (colorblind-friendly) ----------

marginal_pct_long_cca <- marginal_pct_wide_cca %>%
  pivot_longer(
    cols = starts_with("pct_mastered_"),
    names_to = "version",
    values_to = "pct_mastered"
  ) %>%
  mutate(
    version = ifelse(version == "pct_mastered_pre", "Pre", "Post")
  )

barplot_cca <- ggplot(marginal_pct_long_cca,
       aes(x = attribute, y = pct_mastered, fill = version)) +
  geom_col(
    position = position_dodge(width = .9),
    width = 0.8,            # narrower bars so there's a clear gap
    color = "black"          # thin outline for extra contrast
  ) +
  scale_fill_manual(
    values = c(
      "Pre"  = "#0072B2",    # blue (Okabe–Ito)
      "Post" = "#D55E00"     # orange (Okabe–Ito)
    )
  ) +
  scale_x_discrete(
    labels = c(
      A1 = "Prerequisites",
      A2 = "Limits",
      A3 = "Derivatives",
      A4 = "Applications of Derivatives",
      A5 = "Integration"
    )
  )+
  labs(
    x = "Skill",
    y = "Percent mastered",
    title = "CCA: Pre vs Post percent proficient by skill",
    fill = "Version"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(hjust = 0.5)
  )
barplot_cca


################################################################################

####  CCI

## ---------- POST ----------

pp_post <- post_label_cci_full_long %>%
  filter(post != "Missing") %>%
  mutate(
    A1 = substr(post, 1, 1),
    A2 = substr(post, 2, 2),
    A3 = substr(post, 3, 3),
    A4 = substr(post, 4, 4),
    A5 = substr(post,5,5)
    
  ) %>%
  mutate(across(A1:A5, ~ as.integer(.)))   # "0"/"1" -> 0/1

marginal_pct_post <- pp_post %>%
  select(A1:A5) %>%
  summarise(across(
    everything(),
    ~ mean(. == 1, na.rm = TRUE) * 100   # percent mastered
  )) %>%
  pivot_longer(
    cols = everything(),
    names_to = "attribute",
    values_to = "pct_mastered_post"
  )

## ---------- PRE ----------

pp_pre <- pre_label_cci_full_long %>%
  filter(pre != "Missing") %>%
  mutate(
    A1 = substr(pre, 1, 1),
    A2 = substr(pre, 2, 2),
    A3 = substr(pre, 3, 3),
    A4 = substr(pre, 4, 4),
    A5 = substr(pre, 5, 5)
    
  ) %>%
  mutate(across(A1:A5, ~ as.integer(.)))

marginal_pct_pre <- pp_pre %>%
  select(A1:A5) %>%
  summarise(across(
    everything(),
    ~ mean(. == 1, na.rm = TRUE) * 100
  )) %>%
  pivot_longer(
    cols = everything(),
    names_to = "attribute",
    values_to = "pct_mastered_pre"
  )

## ---------- COMBINE: pre + post columns per attribute ----------

marginal_pct_wide <- marginal_pct_pre %>%
  left_join(marginal_pct_post, by = "attribute")

## ---------- Plot pre vs post side-by-side (colorblind-friendly) ----------

marginal_pct_long <- marginal_pct_wide %>%
  pivot_longer(
    cols = starts_with("pct_mastered_"),
    names_to = "version",
    values_to = "pct_mastered"
  ) %>%
  mutate(
    version = ifelse(version == "pct_mastered_pre", "Pre", "Post")
  )

ggplot(marginal_pct_long,
       aes(x = attribute, y = pct_mastered, fill = version)) +
  geom_col(
    position = position_dodge(width = .9),
    width = 0.8,            # narrower bars so there's a clear gap
    color = "black"          # thin outline for extra contrast
  ) +
  scale_fill_manual(
    values = c(
      "Pre"  = "#0072B2",    # blue (Okabe–Ito)
      "Post" = "#D55E00"     # orange (Okabe–Ito)
    )
  ) +
  scale_x_discrete(
    labels = c(
      A1 = "Prerequisites",
      A2 = "Limits",
      A3 = "Derivatives",
      A4 = "Applications of Derivatives",
      A5 = "Integration"
    )
  )+
  labs(
    x = "Skill",
    y = "Percent mastered",
    title = "CCI: Pre vs Post percent proficient by skill",
    fill = "Version"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(hjust = 0.5)
  )


################################################################################

# PCA

## ---------- POST ----------

pp_post_pca <- post_label_pca_full_long %>%
  filter(post != "Missing") %>%
  mutate(
    A1 = substr(post, 1, 1),
    A2 = substr(post, 2, 2),
    A3 = substr(post, 3, 3),
    A4 = substr(post, 4, 4)
    
  ) %>%
  mutate(across(A1:A4, ~ as.integer(.)))   # "0"/"1" -> 0/1

marginal_pct_post_pca <- pp_post_pca %>%
  select(A1:A4) %>%
  summarise(across(
    everything(),
    ~ mean(. == 1, na.rm = TRUE) * 100   # percent mastered
  )) %>%
  pivot_longer(
    cols = everything(),
    names_to = "attribute",
    values_to = "pct_mastered_post"
  )

## ---------- PRE ----------

pp_pre_pca <- pre_label_pca_full_long %>%
  filter(pre != "Missing") %>%
  mutate(
    A1 = substr(pre, 1, 1),
    A2 = substr(pre, 2, 2),
    A3 = substr(pre, 3, 3),
    A4 = substr(pre, 4, 4)
    
  ) %>%
  mutate(across(A1:A4, ~ as.integer(.)))

marginal_pct_pre_pca <- pp_pre_pca %>%
  select(A1:A4) %>%
  summarise(across(
    everything(),
    ~ mean(. == 1, na.rm = TRUE) * 100
  )) %>%
  pivot_longer(
    cols = everything(),
    names_to = "attribute",
    values_to = "pct_mastered_pre"
  )

## ---------- COMBINE: pre + post columns per attribute ----------

marginal_pct_wide_pca <- marginal_pct_pre_pca %>%
  left_join(marginal_pct_post_pca, by = "attribute")

## ---------- Plot pre vs post side-by-side (colorblind-friendly) ----------

marginal_pct_long_pca <- marginal_pct_wide_pca %>%
  pivot_longer(
    cols = starts_with("pct_mastered_"),
    names_to = "version",
    values_to = "pct_mastered"
  ) %>%
  mutate(
    version = ifelse(version == "pct_mastered_pre", "Pre", "Post")
  )

barplot_pca <- ggplot(marginal_pct_long_pca,
                      aes(x = attribute, y = pct_mastered, fill = version)) +
  geom_col(
    position = position_dodge(width = .9),
    width = 0.8,            # narrower bars so there's a clear gap
    color = "black"          # thin outline for extra contrast
  ) +
  scale_fill_manual(
    values = c(
      "Pre"  = "#0072B2",    # blue (Okabe–Ito)
      "Post" = "#D55E00"     # orange (Okabe–Ito)
    )
  ) +
  scale_x_discrete(
    labels = c(
      A1 = "Prerequisites",
      A2 = "Limits",
      A3 = "Applications of Derivatives",
      A4 = "Integration"
    )
  )+
  labs(
    x = "Skill",
    y = "Percent mastered",
    title = "PCA: Pre vs Post percent proficient by skill",
    fill = "Version"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(hjust = 0.5)
  )
barplot_pca

