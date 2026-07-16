#this is for the fullest pre and post datasets with no consideration for matching
#


library(dplyr)
library(tidyr)
library(readxl)
library(writexl)
library(ggplot2)
library(mirt)
library(GDINA)
library(networkD3)
library(patchwork)
library(htmlwidgets)
library(webshot2)   # works without PhantomJS
library(cowplot)
library(magick)
library(lmerTest)
set.seed(1234)

#this is the data prep script used as of 10/23/2025

#let's set a vector of columns we would like to select right away to make this a bit easier. 
#we'll need two because of differences between LASSO v1 and v2

cols_v1 <- c("course_id", "course_name", "assessment_code", "institution_name", "term", "year", "discipline", "instructor", "student_id", "institution_id","course_use_las",
             "gender_text", "ethnicity_text", "race_text", "year_in_school", "parent_degree", "transgender", "male", "female", "transman", "transwoman", "gender_noanswer", "genderqueer_nonconforming",
             "pre_duration","pre_score","pre_num_correct", "pre_1", "pre_2", "pre_3", "pre_4", "pre_5", "pre_6", "pre_7", "pre_8", "pre_9", "pre_10", "pre_11", "pre_12", "pre_13", "pre_14", "pre_15", "pre_16", "pre_17", "pre_18", "pre_19", "pre_20", "pre_21", "pre_22", "pre_23", "pre_24", "pre_25", "pre_26", "pre_27", "pre_28", "pre_29", "pre_30", "pre_31", "pre_32", "pre_33", "pre_34", "pre_35", "pre_36", "pre_37", "pre_38", "pre_39", "pre_40", "pre_41", "pre_42", "pre_43", "pre_44", "pre_45", "pre_46", "pre_47", "pre_48", "pre_49", "pre_50", "pre_51", "pre_52", 
             "post_duration", "post_score", "post_num_correct", "post_1", "post_2", "post_3", "post_4", "post_5", "post_6", "post_7", "post_8", "post_9", "post_10", "post_11", "post_12", "post_13", "post_14", "post_15", "post_16", "post_17", "post_18", "post_19", "post_20", "post_21", "post_22", "post_23", "post_24", "post_25", "post_26", "post_27", "post_28", "post_29", "post_30", "post_31", "post_32", "post_33", "post_34", "post_35", "post_36", "post_37", "post_38", "post_39", "post_40", "post_41", "post_42", "post_43", "post_44", "post_45", "post_46", "post_47", "post_48", "post_49", "post_50", "post_51", "post_52" 
)

#####################################
#                                   #
#  Importing CCI, CCA and PCA data  #
#                                   #
#####################################

#Import LASSO v1
data <- read.csv("../Jayson-Kevin-LASSO-Data-Aug-2024/LASSO_1.0_for_upload_9_24.csv")

#If a student consented on the pre or post then that score was retained.
#If a student consented on both the pre and post then those scores were retained
#If a student consented on niether the pre or post then the line after this one removes those
data <- data %>% mutate(pre_score = if_else(pre_agree_to_participate %in% c("I agree to share","I agree to participate" ),pre_score,NA_real_),
                        post_score = if_else(post_agree_to_participate %in% c("I agree to share","I agree to participate" ), post_score, NA_real_))


data <- data %>% filter(!(is.na(pre_score) & is.na(post_score)))

#selects 133 columns, I might edit this later.  Trying to shrink the size of these things
data <- data %>% select(all_of(cols_v1))



#################
#               #
#     CCI       #
#               #
#################

#The CCI, in LASSO version 1 is listed as CalcCI
data_cci <- data %>% filter(assessment_code == "CalcCI")

#filter out any course that has fewer than 10 students
data_cci <- data_cci %>% group_by(course_id) %>% filter(n() >= 10) %>% ungroup()


#There are two courses that are labeled as administering the CCI but have more responses than the CCI has questions
#emailed JN on 9/29
#filter these out
data_cci2 <- data_cci %>% filter(!(course_id %in% c(2657, 3239)))


#now that we've removed the wonky courses we'll select only the pertinent columns for the CCI
columns_to_keep <- c("student_id",  "course_id",  "pre_score", "pre_duration",  "post_score", "post_duration",  "institution_id",  "year",  "term",  "instructor",  "male",  "female",  
                     "parent_degree",  "course_use_las",  "pre_1", "pre_2", "pre_3", "pre_4", "pre_5", "pre_6", "pre_7", "pre_8", "pre_9", "pre_10",
                     "pre_11", "pre_12", "pre_13", "pre_14", "pre_15", "pre_16", "pre_17", "pre_18", "pre_19", "pre_20", "pre_21", "pre_22", "pre_23",
                     "pre_24", "post_1", "post_2", "post_3", "post_4", "post_5", "post_6", "post_7", "post_8", "post_9", "post_10", "post_11", "post_12", 
                     "post_13", "post_14", "post_15", "post_16", "post_17", "post_18", "post_19", "post_20", "post_21", "post_22", "post_23", "post_24")

data_cci2 <- data_cci2 %>% select(all_of(columns_to_keep))


#add an 'attempted' column, this will allow filtering on the number attempted.
data_cci2 <- data_cci2 %>% mutate(pre_attempted = rowSums(!is.na(select(., matches("^pre_\\d{1,2}$")))),
                                  post_attempted = rowSums(!is.na(select(., matches("^post_\\d{1,2}$")))))


#for those who did not spend enough time we replace their score with NA_real_
data_cci2 <- data_cci2 %>%   mutate(pre_score = if_else(is.na(pre_duration) | pre_duration < 300, NA_real_, pre_score),
                                    post_score = if_else(is.na(post_duration) | post_duration <300, NA_real_, post_score))

#for those who did not attempt at least 80% of the questions we replace their score with NA_real_
data_cci2 <- data_cci2 %>% mutate(pre_score = if_else(pre_attempted < .8*24, NA_real_,pre_score),
                                  post_score = if_else(post_attempted < .8*24, NA_real_, post_score ))

#This is the CCI data set with pre/post responses and information for modeling.
cci_data <- data_cci2 %>% select(student_id, course_id, pre_score, post_score,institution_id, year, term,instructor, male, female, parent_degree, course_use_las,
                                                  matches("^pre_\\d{1,2}$"), matches("post_\\d{1,2}$"))


#The CCI has two questions that are not content related (and have quite a few inconsistent responses across pre/post)
#let's remove them now
cci_data <- cci_data %>% select(-pre_1, -pre_2, -post_1, -post_2)

cci_nonNA_pre <- sum(!is.na(cci_data$pre_score))
cci_nonNA_post <- sum(!is.na(cci_data$post_score))
cci_nonNA_both <- sum(!is.na(cci_data$pre_score) & !is.na(cci_data$post_score))
cci_nonNA_pre
cci_nonNA_post
cci_nonNA_both

cci_course_sizes <- cci_data %>% count(course_id)
cci_course_sizes

#################
#               #
#     CCA       #
#               #
#################

data_cca <- data %>% filter(assessment_code == "CCA")

#removing courses with fewer than 10 students
data_cca <- data_cca %>% group_by(course_id) %>% filter(n() >= 10) %>% ungroup()

#now  we'll select only the pertinent columns
columns_to_keep <- c("student_id",  "course_id",  "pre_score", "pre_duration",  "post_score", "post_duration",  "institution_id",  "year",  "term",  "instructor",  "male",  "female",  
                     "parent_degree",  "course_use_las",  "pre_1", "pre_2", "pre_3", "pre_4", "pre_5", "pre_6", "pre_7", "pre_8", "pre_9", "pre_10",
                     "pre_11", "pre_12", "pre_13", "pre_14", "pre_15", "pre_16", "pre_17", "pre_18", "post_1", "post_2", "post_3", "post_4", "post_5", "post_6", "post_7", "post_8", "post_9", "post_10", "post_11", "post_12", 
                     "post_13", "post_14", "post_15", "post_16", "post_17", "post_18")

data_cca <- data_cca %>% select(all_of(columns_to_keep))


#add an 'attempted' column, this will allow filtering on the number attempted.
data_cca <- data_cca %>% mutate(pre_attempted = rowSums(!is.na(select(., matches("^pre_\\d{1,2}$")))),
                                  post_attempted = rowSums(!is.na(select(., matches("^post_\\d{1,2}$")))))

#change scores to NA_real_ if students failed to correctly answer the filter question
data_cca <- data_cca %>% mutate(pre_score = if_else(is.na(pre_12) | !(pre_12 == "f"), NA_real_, pre_score),
                                post_score = if_else(is.na(post_12) | !(post_12 == "f"), NA_real_, post_score))

cca_pre_12_correct <-sum(data_cca$pre_12 == "f", na.rm = TRUE)
cca_post_12_correct <-sum(data_cca$post_12 == "f", na.rm = TRUE)
cca_pre_12_correct
cca_post_12_correct

#now we do not need that column and it will just mess with IRT and DINA so let's remove it
data_cca <- data_cca %>% select(-pre_12, -post_12)


#for those who did not spend enough time we replace their score with NA_real_
data_cca <- data_cca %>%   mutate(pre_score = if_else(is.na(pre_duration) | pre_duration < 300, NA_real_, pre_score),
                                    post_score = if_else(is.na(post_duration) | post_duration <300, NA_real_, post_score))

#for those who did not attempt at least 80% of the questions we replace their score with NA_real_
data_cca <- data_cca %>% mutate(pre_score = if_else(pre_attempted < .8*18, NA_real_,pre_score),
                                  post_score = if_else(post_attempted < .8*18, NA_real_, post_score ))

#This is the CCI data set with pre/post responses and information for modeling.
cca_data <- data_cca %>% select(student_id, course_id, pre_score, post_score,institution_id, year, term,instructor, male, female, parent_degree, course_use_las,
                                 matches("^pre_\\d{1,2}$"), matches("post_\\d{1,2}$"))

cca_nonNA_pre <- sum(!is.na(cca_data$pre_score))
cca_nonNA_post <- sum(!is.na(cca_data$post_score))
cca_nonNA_both <- sum(!is.na(cca_data$pre_score) & !is.na(cca_data$post_score))
cca_nonNA_pre
cca_nonNA_post
cca_nonNA_both

cca_course_sizes <- cca_data %>% count(course_id)
cca_course_sizes

#################
#               #
#     PCA       #
#               #
#################

pca <- read.csv("pca_8_23_df.csv")

#import PCA data which already has binary graded columns so no need for a key
#pca <- read.csv("pca_8_23_df_post.csv")
#pca <- pca %>% filter(pre_agree_to_participate %in% c("I agree to share","I agree to participate" ), post_agree_to_participate %in% c("I agree to share","I agree to participate" ) )

#I had missed that I was imposing the condition that both pre and post needed consent, found this on October 20th, 2025

pca <- pca %>% mutate(pre_score = if_else(pre_agree_to_participate %in% c("I agree to share","I agree to participate" ),pre_score,NA_real_),
       post_score = if_else(post_agree_to_participate %in% c("I agree to share","I agree to participate" ), post_score, NA_real_))
pca <- pca %>% filter(!(is.na(pre_score) & is.na(post_score)))


#filter for small courses
data_pca <- pca %>% group_by(course_id) %>% filter(n() >= 10) %>% ungroup()

#add an 'attempted' column, this will allow filtering on the number attempted.
data_pca <- data_pca %>% mutate(pre_attempted = rowSums(!is.na(select(., matches("^pre_\\d{1,2}_C$")))),
                                post_attempted = rowSums(!is.na(select(., matches("^post_\\d{1,2}_C$")))))

#filter for time just like above with the CCI and CCA
data_pca <- data_pca %>%   mutate(pre_score = if_else(is.na(pre_duration) | pre_duration < 300, NA_real_, pre_score),
                             post_score = if_else(is.na(post_duration) | post_duration <300, NA_real_, post_score))

#for those who did not attempt at least 80% of the questions we replace their score with NA_real_
data_pca <- data_pca %>% mutate(pre_score = if_else(pre_attempted < .8*25, NA_real_,pre_score),
                                post_score = if_else(post_attempted < .8*25, NA_real_, post_score ))

#select the columns we're interested in
pca_data <- data_pca %>%   select(student_id, course_id, pre_score, post_score, institution_id, year, term, male, female, parent_degree, course_use_las,
                                  matches("^pre_\\d{1,2}_C$"), matches("post_\\d{1,2}_C$"))

pca_nonNA_pre <- sum(!is.na(pca_data$pre_score))
pca_nonNA_post <- sum(!is.na(pca_data$post_score))
pca_nonNA_both <- sum(!is.na(pca_data$pre_score) & !is.na(pca_data$post_score))
pca_nonNA_pre
pca_nonNA_post
pca_nonNA_both

pca_course_sizes <- pca_data %>% count(course_id)
pca_course_sizes



####################################
#                                  #
#         LASSO V2                 #
#                                  #
####################################

v2colnames <- c("organization_id", "organization_name", "course_id", "course_name", "term", "year", "is_test_course", "instructors", 
                "use_near_peer", "assessment_internal_code", "minimum_duration", "course_student_id", "student_id", "gender", "ethnicity", 
                "race", "admin_1_no_of_questions", "admin_1_participate", "admin_1_duration_in_mins", "admin_1_score", "admin_1_1_answer", 
                "admin_1_2_answer", "admin_1_3_answer", "admin_1_4_answer", "admin_1_5_answer", "admin_1_6_answer", "admin_1_7_answer", 
                "admin_1_8_answer", "admin_1_9_answer", "admin_1_10_answer", "admin_1_11_answer", "admin_1_12_answer", "admin_1_13_answer", 
                "admin_1_14_answer", "admin_1_15_answer", "admin_1_16_answer", "admin_1_17_answer", "admin_1_18_answer", "admin_1_19_answer", 
                "admin_1_20_answer", "admin_1_21_answer", "admin_1_22_answer", "admin_1_23_answer", "admin_1_24_answer", "admin_2_no_of_questions",
                "admin_2_participate", "admin_2_duration_in_mins", "admin_2_score", "admin_2_1_answer", "admin_2_2_answer", "admin_2_3_answer", 
                "admin_2_4_answer", "admin_2_5_answer", "admin_2_6_answer", "admin_2_7_answer", "admin_2_8_answer", "admin_2_9_answer", 
                "admin_2_10_answer", "admin_2_11_answer", "admin_2_12_answer", "admin_2_13_answer", "admin_2_14_answer", "admin_2_15_answer", 
                "admin_2_16_answer", "admin_2_17_answer", "admin_2_18_answer", "admin_2_19_answer", "admin_2_20_answer", "admin_2_21_answer", 
                "admin_2_22_answer", "admin_2_23_answer", "admin_2_24_answer")


#This is data from LASSO version 2 and there are different columns
datav2 <- read.csv("postman_cci_cca_regular_download_sept_2025.csv")

datav2 <- datav2 %>% select(all_of(v2colnames))

#cleaning up names a bit so they are similar to LASSO version1
names(datav2) <- sub("^admin_1", "pre", names(datav2))
names(datav2) <- sub("^admin_2", "post", names(datav2))
names(datav2) <- sub("_answer$", "", names(datav2))

#assign NA_real_ to those scores on assessments without consent.  Just as above we'll filter out 
#any student who did not consent on either the pre or post but will retain information for those
#assessments where there is consent to use the data
datav2 <- datav2 %>% mutate(pre_score = if_else(pre_participate %in% c("I agree to share"),pre_score,NA_real_),
                            post_score = if_else(post_participate %in% c("I agree to share"), post_score, NA_real_))

#filtering out students who did not consent on pre and  post
datav2 <- datav2 %>% filter(!(is.na(pre_score) & is.na(post_score)))


#filter by course size
datav2 <- datav2 %>% group_by(course_id) %>% filter(n() >= 10) %>% ungroup()

#this looks like an error I didn't use 11/26
#cci_v2 <- datav2 %>% filter(assessment_internal_code == "CCA")


#replace pre and post scores with NA_real_ if there was not enough time spent on the assessment
datav2 <- datav2 %>% mutate(pre_score = ifelse(is.na(pre_duration_in_mins) | pre_duration_in_mins <5, NA_real_, pre_score),
                            post_score = ifelse(is.na(post_duration_in_mins) | post_duration_in_mins <5, NA_real_, post_score))


#rename a few columns to fit with LASSO v1
datav2 <- datav2 %>% rename(institution_id = "organization_id", instructor = "instructors", course_use_las = "use_near_peer", assessment_code = "assessment_internal_code")
#add a male/female column
datav2 <- datav2 %>% mutate(male = ifelse(gender == "Man", 1, 0), female = ifelse(gender=="Woman", 1, 0), parent_degree = NA)

v2colnames2 <- c("student_id", "course_id", "pre_score", "post_score", "institution_id", "year", "term","instructor", "male", "female", "parent_degree", "course_use_las",
                 "pre_1", "pre_2", "pre_3", "pre_4", "pre_5", "pre_6", "pre_7", "pre_8", "pre_9", "pre_10", "pre_11", "pre_12", "pre_13", "pre_14", "pre_15", 
                 "pre_16", "pre_17", "pre_18", "pre_19", "pre_20", "pre_21", "pre_22", "pre_23", "pre_24", "post_1", "post_2", "post_3", "post_4", "post_5",
                 "post_6", "post_7", "post_8", "post_9", "post_10", "post_11", "post_12", "post_13", "post_14", "post_15", "post_16", "post_17", "post_18", 
                 "post_19", "post_20", "post_21", "post_22", "post_23", "post_24", "assessment_code") 

datav2 <- datav2 %>% select(all_of(v2colnames2))


#######
#     #
# CCI #
#     #
#######

#there is no overlap between version 2 CCI and version 1 CCI
datav2_cci <- datav2 %>% filter(assessment_code == "CaCI" & year == 2025) %>% select(-assessment_code)



#creating a column in order to discern who attempted at least 80% of the problems
datav2_cci <- datav2_cci %>% mutate(pre_attempted = rowSums(!is.na(select(., matches("^pre_\\d{1,2}$")))),
                                post_attempted = rowSums(!is.na(select(., matches("^post_\\d{1,2}$")))))

#for those who did not attempt at least 80% of the questions we replace their score with NA_real_
#these scores are raw and not percentiles.  For the CCI we divide by 

datav2_cci <- datav2_cci %>% mutate(pre_score = if_else(pre_attempted < .8*24, NA_real_,100*pre_score/24),
                                post_score = if_else(post_attempted < .8*24, NA_real_, 100*post_score/24 ))

#The CCI has two questions that are not content related (and have quite a few inconsistent responses across pre/post)
#let's remove them now
datav2_cci <- datav2_cci %>% select(-pre_1, -pre_2, -post_1, -post_2, -pre_attempted, -post_attempted)


cciv2_nonNA_pre <- sum(!is.na(datav2_cci$pre_score))
cciv2_nonNA_post <- sum(!is.na(datav2_cci$post_score))
cciv2_nonNA_both <- sum(!is.na(datav2_cci$pre_score) & !is.na(datav2_cci$post_score))
cciv2_nonNA_pre
cciv2_nonNA_post
cciv2_nonNA_both

cciv2_course_sizes <- datav2_cci %>% count(course_id)
cciv2_course_sizes


#######
#     #
# CCA #
#     #
#######

#I think there is overlap between version 2 CCA and version 1 CCA
#so I'm going to filter version 2 to include only 2024 and 2025.  
#it's not much data but...
v2colnames2_cca <- c("student_id", "course_id", "pre_score", "post_score", "institution_id", "year", "term","instructor", "male", "female", "parent_degree", "course_use_las",
                     "pre_1", "pre_2", "pre_3", "pre_4", "pre_5", "pre_6", "pre_7", "pre_8", "pre_9", "pre_10", "pre_11", "pre_12", "pre_13", "pre_14", "pre_15", 
                     "pre_16", "pre_17", "pre_18", "post_1", "post_2", "post_3", "post_4", "post_5",
                     "post_6", "post_7", "post_8", "post_9", "post_10", "post_11", "post_12", "post_13", "post_14", "post_15", "post_16", "post_17", "post_18") 

datav2_cca <- datav2 %>% filter(assessment_code == "CCA") %>% select(all_of(v2colnames2_cca))
#filtering for years that are not present in the above v1 data for CCA
datav2_cca <- datav2_cca %>% filter(year %in% c("2024", "2025"))

#creating a column in order to discern who attempted at least 80% of the problems
datav2_cca <- datav2_cca %>% mutate(pre_attempted = rowSums(!is.na(select(., matches("^pre_\\d{1,2}$")))),
                                    post_attempted = rowSums(!is.na(select(., matches("^post_\\d{1,2}$")))))

#for those who did not attempt at least 80% of the questions we replace their score with NA_real_
datav2_cca <- datav2_cca %>% mutate(pre_score = if_else(pre_attempted < .8*18, NA_real_,pre_score),
                                    post_score = if_else(post_attempted < .8*18, NA_real_, post_score ))


#change scores to NA_real_ if students failed to correctly answer the filter question
datav2_cca <- datav2_cca %>% mutate(pre_score = if_else(is.na(pre_12) | !(pre_12 == "F"), NA_real_, 100*pre_score/18),
                                post_score = if_else(is.na(post_12) | !(post_12 == "F"), NA_real_, 100*post_score/18))

cca_pre_12_correctv2 <-sum(datav2_cca$pre_12 == "F", na.rm = TRUE)
cca_post_12_correctv2 <-sum(datav2_cca$post_12 == "F", na.rm = TRUE)
cca_pre_12_correctv2
cca_post_12_correctv2

#now we do not need that column and it will just mess with IRT and DINA so let's remove it
datav2_cca <- datav2_cca %>% select(-pre_12, -post_12, -pre_attempted, -post_attempted)


ccav2_nonNA_pre <- sum(!is.na(datav2_cca$pre_score))
ccav2_nonNA_post <- sum(!is.na(datav2_cca$post_score))
ccav2_nonNA_both <- sum(!is.na(datav2_cca$pre_score) & !is.na(datav2_cca$post_score))
ccav2_nonNA_pre
ccav2_nonNA_post
ccav2_nonNA_both

ccav2_course_sizes <- datav2_cca %>% count(course_id)
ccav2_course_sizes

###########
#         #
# Binding #
#         #
###########

#bringing it altogether and writing those files for analysis
#reminder: these files are pre/post, already filtered for consent, time, etc
cci_data_v12 <- rbind(cci_data, datav2_cci)
cca_data_v12 <- rbind(cca_data, datav2_cca)

#write data files for use in the analysis script: IJRUME_analysis.R
write.csv(cci_data_v12, "cci_data_v12.csv")
write.csv(cca_data_v12, "cca_data_v12.csv")
write.csv(pca_data, "pca_data.csv")



