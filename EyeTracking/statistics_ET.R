# ===========================
# Blablacara ET Analysis - Optimized
# ===========================

# ---- 1. Load Libraries ----
library(eyetrackingR)
library(eyelinker)
library(Matrix)
library(lme4)
library(lmerTest)
library(emmeans)
library(pbkrtest)
library(tidyverse)
library(writexl)
library(readxl)
library(ggplot2)
library(png)
library(grid)
library(stringr)

# ---- 2. Paths ----
base_path <- "/Users/irenearrietasagredo/Documents/GitHub/Blablacara_thesis_git/analysis1_outcome_ET"
data_path <- "/Users/irenearrietasagredo/Desktop/BCBL/Thesis-blablacara/Blablacara-data/data_analysis"

# ---- 3. Import Data ----
data1 <- read.table(file.path(data_path, "dataset_all_ET_blablacara.csv"), header = TRUE)
data2 <- read.table(file.path(data_path, "dataset_all_ET_blablacara_PTLT_diff.csv"), header = TRUE)

# ---- 4. Compute Mean per Subject x Condition ----
mean_PTLT <- data1 %>% group_by(participant_column, cond, group) %>%
  summarise(mean_PT_LT = mean(PTLT), .groups = "drop")
data1 <- data1 %>% left_join(mean_PTLT, by = c("participant_column","cond","group")) %>%
  rename(mean_cond = mean_PT_LT)

mean_PTLT_diff <- data2 %>% group_by(participant_column, cond, group) %>%
  summarise(mean_PT_LT_diff = mean(PTLT_diff), .groups = "drop")
data2 <- data2 %>% left_join(mean_PTLT_diff, by = c("participant_column","cond","group")) %>%
  rename(mean_cond = mean_PT_LT_diff)

# ---- 5. Standardize Factors ----
data1 <- data1 %>%
  mutate(
    cond = factor(cond, levels = c("AV", "AVdeg", "V")),
    group = factor(group, levels = c("1", "2"))
  )

data2 <- data2 %>%
  mutate(
    cond = factor(cond, levels = c("AV", "AVdeg", "V")),
    group = factor(group, levels = c("1", "2"))
  )

# ---- 6. Define Colors ----
color_group <- c("1" = rgb(0.67, 0.71, 0.60), # Infants
                 "2" = "darkgrey")           # Toddlers
color_conditions <- c("AV" = "skyblue", "AVdeg" = "darkgrey", "V" = "lightpink")

# ---- 7. Helper Function: Plot PTLT ----
plot_PT_LT <- function(df, yvar, filename, add_points = TRUE, facet_var = "group") {
  p <- ggplot(df, aes(x = cond, y = !!sym(yvar), fill = group)) +
    geom_boxplot(position = position_dodge(width = 0.75), width = 0.6, outlier.shape = NA)
  
  if (add_points) {
    p <- p + geom_jitter(
      aes(group = group),
      position = position_jitterdodge(dodge.width = 0.75, jitter.width = 0.2),
      size = 1.5, color = "black", alpha = 0.8
    )
  }
  
  p <- p + facet_wrap(as.formula(paste("~", facet_var))) +
    labs(x = "", y = "Proportion of looking to the mouth over the eyes") +
    scale_fill_manual(values = color_group, labels = c("Infants","Toddlers")) +
    theme_classic(base_size = 14) +
    theme(legend.position = "right")
  
  ggsave(filename, plot = p, width = 12, height = 6, dpi = 300, units = "in", device = "png")
}

# Example plots
plot_PT_LT(data1, "PTLT", file.path(base_path, "PTLT_grouped.png"))
plot_PT_LT(data2, "PTLT_diff", file.path(base_path, "PTLT_diff_grouped.png"))

# ---- 8. Helper Function: Run LMER & Post-Hoc ----
run_lmer <- function(df, formula, outpath){
  model <- lmer(formula, data = df)
  summ <- summary(model)
  anova_res <- anova(model)
  
  write_xlsx(list(summary = summ, anova = anova_res), outpath)
  
  post_hoc <- emmeans(model, specs = pairwise ~ cond, adjust = "tukey")
  return(list(model = model, post_hoc = post_hoc))
}

# Run models
res1 <- run_lmer(data1, PTLT ~ group*cond + (1|participant_column),
                 file.path(base_path,"ET_model_group_PTLT.xlsx"))
res2 <- run_lmer(data2, PTLT_diff ~ group*cond + (1|participant_column),
                 file.path(base_path,"ET_model_group_PTLT_diff.xlsx"))

# ---- 9. Percentage of Trials ----
trial_summary <- data2 %>%
  group_by(group) %>%
  summarise(
    n_subjects = n_distinct(participant_column),
    total_trials = n(),
    ideal_trials = n_subjects * 18,
    perc_trials = total_trials / ideal_trials * 100
  )

print(trial_summary)

# ---- 10. Save Processed Data ----
write.table(data1, file.path(base_path,"dataset_all_ET_blablacara_group.csv"), row.names = FALSE)
write.table(data2, file.path(base_path,"dataset_all_ET_blablacara_group_PTLT_diff.csv"), row.names = FALSE)
