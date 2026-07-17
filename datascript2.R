# Prepare the CCI, CCA, and PCA datasets used by IJRUME_analysis.R.
#
# First run download_lasso_data.Rmd. It creates the combined regular-assessment
# export at LASSO_downloads/lasso_regular_2015_2025.csv.

library(dplyr)
library(tidyr)

set.seed(1234)

lasso_file <- "LASSO_downloads/lasso_regular_2015_2025.csv"
pca_file <- "pca_8_23_df.csv"

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
    # establish consent and therefore cannot retain a score.
    pre_score = if_else(
      pre_participate %in% c("I agree to share", "I agree to participate"),
      pre_score,
      NA_real_
    ),
    post_score = if_else(
      post_participate %in% c("I agree to share", "I agree to participate"),
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

cci_data_v12 <- prepare_cci(lasso_data)
cca_data_v12 <- prepare_cca(lasso_data)

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

write.csv(cci_data_v12, "cci_data_v12.csv", row.names = FALSE)
write.csv(cca_data_v12, "cca_data_v12.csv", row.names = FALSE)
write.csv(pca_data, "pca_data.csv", row.names = FALSE)
