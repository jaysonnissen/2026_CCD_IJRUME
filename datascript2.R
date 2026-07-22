# Prepare the CCI, CCA, and PCA datasets (v13) from a fresh LASSO download.
#
# First run download_lasso_data.Rmd. It creates the combined regular-assessment
# export at LASSO_downloads/lasso_regular_2015_2025.csv.
#
#(Mike 7/22/26) NOTE: IJRUME_analysis.R/.Rmd read cci_data_v12.csv and
#cca_data_v12.csv, NOT the v13 files this script writes -- v12 predates this
#script and retains historic scores the current LASSO export lacks. This
#script is a separate, forward-looking pipeline for extending the dataset
#with more recent LASSO downloads toward the IJRUME manuscript; it is not
#part of reproducing the PERC2025/RUME conference results.
#
#Known issues, left unfixed here (see datascript2.Rmd for the corrected
#version):
#  1. The CCI filter here is `assessment_code %in% c("CCI","CaCI","CalcCI")`.
#     In the full 2015-2025 LASSO export, "CCI" (assessment_name "Chemical
#     Concept Inventory", course_prefix CHEM/CHMG/CH -- 8,853 rows) is a
#     CHEMISTRY instrument, not the Calculus Concept Inventory. Only "CaCI"
#     (assessment_name "Calculus Concept Inventory (CaCI)", course_prefix
#     MATH) is correct here; "CalcCI" matches zero rows in the current
#     export. This script's cci_data_v13.csv is therefore contaminated with
#     Chemical Concept Inventory responses.
#  2. The CCA eligibility rule requires pre_12/post_12 == "F". Zero rows of
#     any assessment type in the full LASSO export have that value, so this
#     rule NAs every CCA score. cca_data_v13.csv ends up with real row
#     counts but entirely NA pre_score/post_score, because there is no
#     subsequent filter to remove them. The actual intended rule is unknown
#     -- needs Kevin/Jayson's input, not a guess.
#  3. The both-scores-NA filter and the per-course n()>=10 minimum are
#     applied once, on the combined multi-assessment dataset, BEFORE each
#     assessment's own item-completion/eligibility rules run. A course can
#     pass the >=10 threshold on unrelated assessment types, or on students
#     who are later invalidated by rule 2 above, and never get re-checked.

library(dplyr)
library(tidyr)

set.seed(1234)

lasso_file <- "LASSO_downloads/lasso_regular_2015_2025.csv"
pca_file <- "pca_8_23_df.csv"
include_blank_participation <- identical(
  Sys.getenv("LASSO_INCLUDE_BLANK_PARTICIPATION"),
  "true"
)

if (!file.exists(lasso_file)) {
  stop(
    "Run download_lasso_data.Rmd first. Expected file: ",
    lasso_file,
    call. = FALSE
  )
}

if (!file.exists(pca_file)) {
  stop("Missing PCA source file: ", pca_file, call. = FALSE)
}

lasso_data <- read.csv(lasso_file, check.names = FALSE)
has_lasso_consent <- function(participation) {
  participation %in% c("I agree to share", "I agree to participate") |
    (include_blank_participation & participation == "")
}

# LASSO regular exports label administrations as admin_1 and admin_2. Renaming
# them permits shared pre/post processing across all downloaded years.
names(lasso_data) <- sub("^admin_1", "pre", names(lasso_data))
names(lasso_data) <- sub("^admin_2", "post", names(lasso_data))
names(lasso_data) <- sub("_answer$", "", names(lasso_data))

required_lasso_columns <- c(
  "organization_id",
  "course_id",
  "term",
  "year",
  "instructors",
  "use_near_peer",
  "assessment_internal_code",
  "student_id",
  "gender",
  "pre_participate",
  "post_participate",
  "pre_duration_in_mins",
  "post_duration_in_mins",
  "pre_score",
  "post_score",
  paste0("pre_", 1:24),
  paste0("post_", 1:24)
)
missing_lasso_columns <- setdiff(required_lasso_columns, names(lasso_data))

if (length(missing_lasso_columns) > 0) {
  stop(
    "The LASSO export is missing required columns: ",
    paste(missing_lasso_columns, collapse = ", "),
    call. = FALSE
  )
}

lasso_data <- lasso_data %>%
  mutate(
    # Preserve the original script's rule: blank participation does not
    # establish consent and therefore cannot retain a score, unless the
    # comparison mode is explicitly enabled through an environment variable.
    pre_score = if_else(
      has_lasso_consent(pre_participate),
      pre_score,
      NA_real_
    ),
    post_score = if_else(
      has_lasso_consent(post_participate),
      post_score,
      NA_real_
    )
  ) %>%
  filter(!(is.na(pre_score) & is.na(post_score))) %>%
  group_by(course_id) %>%
  filter(n() >= 10) %>%
  ungroup() %>%
  mutate(
    pre_score = if_else(
      is.na(pre_duration_in_mins) | pre_duration_in_mins < 5,
      NA_real_,
      pre_score
    ),
    post_score = if_else(
      is.na(post_duration_in_mins) | post_duration_in_mins < 5,
      NA_real_,
      post_score
    ),
    institution_id = organization_id,
    instructor = instructors,
    course_use_las = use_near_peer,
    assessment_code = assessment_internal_code,
    male = if_else(gender == "Man", 1, 0),
    female = if_else(gender == "Woman", 1, 0),
    parent_degree = NA_character_
  )

common_columns <- c(
  "student_id",
  "course_id",
  "pre_score",
  "post_score",
  "institution_id",
  "year",
  "term",
  "instructor",
  "male",
  "female",
  "parent_degree",
  "course_use_las"
)

prepare_cci <- function(data) {
  data %>%
    filter(assessment_code %in% c("CCI", "CaCI", "CalcCI")) %>%
    mutate(
      pre_attempted = rowSums(!is.na(select(., matches("^pre_\\d{1,2}$")))),
      post_attempted = rowSums(!is.na(select(., matches("^post_\\d{1,2}$")))),
      pre_score = if_else(pre_attempted < 0.8 * 24, NA_real_, 100 * pre_score / 24),
      post_score = if_else(post_attempted < 0.8 * 24, NA_real_, 100 * post_score / 24)
    ) %>%
    select(
      all_of(common_columns),
      all_of(paste0("pre_", 1:24)),
      all_of(paste0("post_", 1:24))
    ) %>%
    select(-pre_1, -pre_2, -post_1, -post_2)
}

prepare_cca <- function(data) {
  data %>%
    filter(assessment_code == "CCA") %>%
    mutate(
      pre_attempted = rowSums(!is.na(select(., matches("^pre_\\d{1,2}$")))),
      post_attempted = rowSums(!is.na(select(., matches("^post_\\d{1,2}$")))),
      pre_score = if_else(pre_attempted < 0.8 * 18, NA_real_, pre_score),
      post_score = if_else(post_attempted < 0.8 * 18, NA_real_, post_score),
      pre_score = if_else(
        is.na(pre_12) | pre_12 != "F",
        NA_real_,
        100 * pre_score / 18
      ),
      post_score = if_else(
        is.na(post_12) | post_12 != "F",
        NA_real_,
        100 * post_score / 18
      )
    ) %>%
    select(
      all_of(common_columns),
      all_of(paste0("pre_", 1:18)),
      all_of(paste0("post_", 1:18))
    ) %>%
    select(-pre_12, -post_12)
}

cci_data_v13 <- prepare_cci(lasso_data)
cca_data_v13 <- prepare_cca(lasso_data)

# PCA is maintained separately from LASSO and already includes binary-scored
# item columns, indicated by the _C suffix.
pca <- read.csv(pca_file)

pca <- pca %>%
  mutate(
    pre_score = if_else(
      pre_agree_to_participate %in% c("I agree to share", "I agree to participate"),
      pre_score,
      NA_real_
    ),
    post_score = if_else(
      post_agree_to_participate %in% c("I agree to share", "I agree to participate"),
      post_score,
      NA_real_
    )
  ) %>%
  filter(!(is.na(pre_score) & is.na(post_score))) %>%
  group_by(course_id) %>%
  filter(n() >= 10) %>%
  ungroup() %>%
  mutate(
    pre_attempted = rowSums(!is.na(select(., matches("^pre_\\d{1,2}_C$")))),
    post_attempted = rowSums(!is.na(select(., matches("^post_\\d{1,2}_C$")))),
    pre_score = if_else(
      is.na(pre_duration) | pre_duration < 300 | pre_attempted < 0.8 * 25,
      NA_real_,
      pre_score
    ),
    post_score = if_else(
      is.na(post_duration) | post_duration < 300 | post_attempted < 0.8 * 25,
      NA_real_,
      post_score
    )
  )

pca_data <- pca %>%
  select(
    student_id,
    course_id,
    pre_score,
    post_score,
    institution_id,
    year,
    term,
    male,
    female,
    parent_degree,
    course_use_las,
    matches("^pre_\\d{1,2}_C$"),
    matches("^post_\\d{1,2}_C$")
  )

write.csv(cci_data_v13, "cci_data_v13.csv", row.names = FALSE)
write.csv(cca_data_v13, "cca_data_v13.csv", row.names = FALSE)
write.csv(pca_data, "pca_data.csv", row.names = FALSE)
