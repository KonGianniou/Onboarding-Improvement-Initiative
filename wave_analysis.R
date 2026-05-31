# =============================================================================
# New Hire Onboarding Quiz — Pre/Post Intervention Analysis
#
# Study design:
#   Wave 7  →  Baseline cohort. Questions asked by new hires were recorded
#               and categorised by topic. No quiz existed yet.
#   Intervention  →  A quiz was built covering the topics most asked about
#               in Wave 7 (identified via chi-squared significance testing).
#   Wave 9  →  Post-intervention cohort. New hires completed the quiz
#               before their onboarding period. Questions asked were recorded
#               using the same topic taxonomy.
#
# Hypothesis: Topics covered in the quiz will show a statistically significant
#             reduction in question volume in Wave 9 vs Wave 7.
#
# Dataset: Fully synthetic — generated to mirror real study structure.
# Author:  Portfolio Project
# =============================================================================


# ── 1. SETUP & LIBRARIES ─────────────────────────────────────────────────────

required_pkgs <- c("ggplot2", "dplyr", "tidyr", "viridis",
                   "RColorBrewer", "scales", "patchwork", "hrbrthemes")

installed   <- rownames(installed.packages())
to_install  <- required_pkgs[!required_pkgs %in% installed]
if (length(to_install)) install.packages(to_install)

library(ggplot2)
library(dplyr)
library(tidyr)
library(viridis)
library(RColorBrewer)
library(scales)
library(patchwork)
library(hrbrthemes)


# ── 2. LOAD DATA ─────────────────────────────────────────────────────────────

# Wave 7 baseline: topic-level question counts + weighted counts
# (Wave 7 weighted = counts adjusted for cohort size differences)
datachi <- read.csv("DataChi.csv", header = TRUE)

# Main pre/post dataset: topic counts for Wave 7 and Wave 9, with quiz flag
datax <- read.csv("DATA.csv", header = TRUE)

# Individual-level data: questions asked per new hire in each wave (n=50 each)
datachi2 <- read.csv("DataChi2.csv", header = TRUE)

# Matched topic-level paired data (same 20 topics, Wave 7 vs Wave 9 counts)
datapaired <- read.csv("Pairedt_test.csv", header = TRUE)

# Daily question volume time series for the three highest-volume topics
dataviz <- read.csv("Timeseries.csv", header = TRUE)
dataviz$Date <- as.Date(dataviz$Date)

# Wave 7 topic totals used to decide which topics entered the quiz
databar <- read.csv("DATA_Total.csv", header = TRUE)

cat("=== Data loaded ===\n")
cat("Topics tracked:", nrow(datax), "\n")
cat("Quiz topics:   ", sum(datax$In_Quiz), "\n")
cat("Non-quiz topics:", sum(!datax$In_Quiz), "\n\n")


# ── 3. STEP 1 — IDENTIFY QUIZ TOPICS (Chi-squared on Wave 7 baseline) ────────
#
# Before the quiz existed, Wave 7 question counts were compared against a
# population-weighted version of those same counts. Topics where the raw count
# differed significantly from the weighted expectation were flagged as the
# highest-priority knowledge gaps — these became the quiz topics.

cat("=== STEP 1: Chi-squared — Wave 7 raw vs Wave 7 weighted (quiz selection) ===\n")

datachi_counts <- datachi[, c("Wave_7", "Wave_7_Weighted")]

chisq_baseline <- apply(datachi_counts, 1, function(row) {
  chisq.test(as.numeric(row))
})

pvals_baseline <- sapply(chisq_baseline, function(x) x$p.value)

chi_baseline_table <- data.frame(
  Topic         = datachi$Topic,
  Wave_7_Raw    = datachi$Wave_7,
  Wave_7_Wtd    = datachi$Wave_7_Weighted,
  Chi_X2        = round(sapply(chisq_baseline, function(x) x$statistic), 4),
  p_value       = round(pvals_baseline, 4),
  Selected_for_Quiz = ifelse(pvals_baseline < 0.05, "YES — included in quiz", "No")
)

print(chi_baseline_table)
cat("\n→ Topics with p < 0.05 were included in the quiz.\n\n")


# ── 4. STEP 2 — PRE/POST COMPARISON (Chi-squared: Wave 7 vs Wave 9) ──────────
#
# After Wave 9 new hires completed the quiz and went through onboarding,
# their question counts were compared to the Wave 7 baseline topic-by-topic.
# A significant result means the quiz had a measurable effect on that topic.

cat("=== STEP 2: Chi-squared — Wave 7 vs Wave 9 (quiz effect by topic) ===\n")

datax_counts <- datax[, c("Wave_7", "Wave_9")]

chisq_prepost <- apply(datax_counts, 1, function(row) {
  chisq.test(as.numeric(row))
})

pvals_prepost <- sapply(chisq_prepost, function(x) x$p.value)

chi_prepost_table <- data.frame(
  Topic         = datax$Topic,
  In_Quiz       = datax$In_Quiz,
  Wave_7        = datax$Wave_7,
  Wave_9        = datax$Wave_9,
  Reduction_Pct = round((datax$Wave_7 - datax$Wave_9) / datax$Wave_7 * 100, 1),
  Chi_X2        = round(sapply(chisq_prepost, function(x) x$statistic), 4),
  p_value       = round(pvals_prepost, 4),
  Significant   = ifelse(pvals_prepost < 0.05, "YES *", "no")
)

print(chi_prepost_table)

# Summary by quiz status
cat("\n→ Average question reduction:\n")
cat("  Quiz topics:    ",
    round(mean(chi_prepost_table$Reduction_Pct[datax$In_Quiz]), 1), "%\n")
cat("  Non-quiz topics:",
    round(mean(chi_prepost_table$Reduction_Pct[!datax$In_Quiz]), 1), "%\n\n")


# ── 5. STEP 3 — INDIVIDUAL-LEVEL Chi-squared (Wave 7 vs Wave 9 per hire) ─────
#
# Cross-checks the topic-level finding at the individual level.
# Tests whether each new hire's total question count shifted between waves.

cat("=== STEP 3: Chi-squared — per new hire question counts (Wave 7 vs Wave 9) ===\n")

datachi2_counts <- datachi2[, c("Wave_7_Questions", "Wave_9_Questions")]

chisq_individual <- apply(datachi2_counts, 1, function(row) {
  chisq.test(as.numeric(row))
})

pvals_ind <- sapply(chisq_individual, function(x) x$p.value)

chi_individual_table <- data.frame(
  NewHireID     = datachi2$NewHireID,
  Wave_7_Qs     = datachi2$Wave_7_Questions,
  Wave_9_Qs     = datachi2$Wave_9_Questions,
  Chi_X2        = round(sapply(chisq_individual, function(x) x$statistic), 4),
  p_value       = round(pvals_ind, 4),
  Significant   = ifelse(pvals_ind < 0.05, "YES *", "no")
)

print(chi_individual_table)
cat("\n→ New hires with significantly fewer questions in Wave 9:",
    sum(pvals_ind < 0.05 & datachi2$Wave_9_Questions < datachi2$Wave_7_Questions),
    "of", nrow(datachi2), "\n\n")


# ── 6. STEP 4 — PAIRED t-TEST (topic-level and individual-level) ─────────────
#
# The paired t-test treats each topic (or new hire) as its own matched pair,
# asking: was the mean reduction from Wave 7 to Wave 9 significantly different
# from zero across all 20 topics?

cat("=== STEP 4a: Paired t-test — topic-level counts (Wave 7 vs Wave 9) ===\n")
res_paired_topics <- t.test(
  datapaired$Wave_7_Count,
  datapaired$Wave_9_Count,
  paired = TRUE
)
print(res_paired_topics)

cat("\n=== STEP 4b: Independent t-test — per new hire question totals ===\n")
res_indep <- t.test(datachi2$Wave_7_Questions, datachi2$Wave_9_Questions)
print(res_indep)

cat("\n=== STEP 4c: Directional check — quiz vs non-quiz topic reduction ===\n")
res_quiz_vs_nonquiz <- t.test(
  chi_prepost_table$Reduction_Pct[datax$In_Quiz],
  chi_prepost_table$Reduction_Pct[!datax$In_Quiz]
)
print(res_quiz_vs_nonquiz)
cat("\n→ p-value:", round(res_quiz_vs_nonquiz$p.value, 4),
    " — quiz topics reduced more than non-quiz topics?",
    ifelse(res_quiz_vs_nonquiz$p.value < 0.05, "YES (significant)", "Not significantly different"), "\n\n")


# ── 7. COLOUR PALETTE & THEME ────────────────────────────────────────────────

quiz_colours <- c(
  "Quiz topic"      = "#1F77B4",
  "Non-quiz topic"  = "#AAAAAA",
  "Significant"     = "#D62728",
  "Not significant" = "#AEC6CF"
)

topic_colours <- c(
  "Property details" = "#1F77B4",
  "Finance"          = "#FF7F0E",
  "Availability"     = "#2CA02C"
)

theme_wave <- function() {
  theme_minimal(base_size = 12) +
    theme(
      plot.title       = element_text(face = "bold", size = 14, margin = margin(b = 6)),
      plot.subtitle    = element_text(size = 10, colour = "grey40", margin = margin(b = 10)),
      plot.caption     = element_text(size = 8, colour = "grey55", hjust = 0),
      axis.title       = element_text(size = 10),
      panel.grid.minor = element_blank(),
      legend.position  = "bottom",
      legend.title     = element_blank()
    )
}


# ── 8. FIGURE 1 — Wave 7 Baseline: Which topics drove the quiz? ──────────────

coul <- colorRampPalette(brewer.pal(9, "Spectral"))(nrow(databar))

fig1 <- databar %>%
  mutate(
    Topic    = reorder(Topic, n),
    Category = ifelse(In_Quiz, "Quiz topic", "Non-quiz topic")
  ) %>%
  ggplot(aes(x = Topic, y = n, fill = Category)) +
  geom_col(width = 0.75) +
  geom_text(aes(label = n), hjust = -0.2, size = 3.2) +
  scale_fill_manual(values = c("Quiz topic" = "#1F77B4", "Non-quiz topic" = "#AAAAAA")) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  coord_flip() +
  labs(
    title    = "Figure 1 — Wave 7 Baseline: Questions Asked by Topic",
    subtitle = "Blue = topics included in the onboarding quiz (highest-need knowledge gaps)",
    x = NULL, y = "Number of Questions (Wave 7)",
    caption  = "Source: Synthetic onboarding data"
  ) +
  theme_wave()

ggsave("fig1_wave7_baseline.png", fig1, width = 11, height = 7, dpi = 150)
cat("✔ Saved fig1_wave7_baseline.png\n")


# ── 9. FIGURE 2 — Time Series: Daily Questions Before and After Quiz ──────────

don7 <- dataviz %>%
  filter(Wave == 7, Topic %in% c("Property details", "Finance", "Availability"))

don9 <- dataviz %>%
  filter(Wave == 9, Topic %in% c("Property details", "Finance", "Availability"))

p_ts7 <- don7 %>%
  ggplot(aes(x = Date, y = n, group = Topic, colour = Topic)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2, alpha = 0.7) +
  scale_colour_manual(values = topic_colours) +
  scale_y_continuous(limits = c(0, 30)) +
  labs(title    = "Wave 7 — Before Quiz (Baseline)",
       subtitle = "Daily questions during onboarding — no quiz yet",
       x = NULL, y = "Questions per day") +
  theme_wave()

p_ts9 <- don9 %>%
  ggplot(aes(x = Date, y = n, group = Topic, colour = Topic)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2, alpha = 0.7) +
  scale_colour_manual(values = topic_colours) +
  scale_y_continuous(limits = c(0, 30)) +
  labs(title    = "Wave 9 — After Quiz (Post-intervention)",
       subtitle = "Daily questions during onboarding — quiz completed pre-arrival",
       x = NULL, y = "Questions per day") +
  theme_wave()

fig2 <- p_ts7 / p_ts9 +
  plot_annotation(
    title    = "Figure 2 — Daily Question Volume: Wave 7 vs Wave 9",
    subtitle = "All three topics were covered by the quiz — volume visibly lower post-intervention",
    caption  = "Source: Synthetic onboarding data"
  )

ggsave("fig2_timeseries.png", fig2, width = 12, height = 8, dpi = 150)
cat("✔ Saved fig2_timeseries.png\n")


# ── 10. FIGURE 3 — Pre/Post Reduction by Topic (quiz vs non-quiz) ─────────────

fig3 <- chi_prepost_table %>%
  mutate(
    Category = ifelse(In_Quiz, "Quiz topic", "Non-quiz topic"),
    Topic     = reorder(Topic, Reduction_Pct)
  ) %>%
  ggplot(aes(x = Topic, y = Reduction_Pct, fill = Category)) +
  geom_col(width = 0.75) +
  geom_text(aes(label = paste0(Reduction_Pct, "%")), hjust = -0.15, size = 3.2) +
  scale_fill_manual(values = c("Quiz topic" = "#1F77B4", "Non-quiz topic" = "#AAAAAA")) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.18)),
                     labels = label_percent(scale = 1)) +
  coord_flip() +
  labs(
    title    = "Figure 3 — Question Reduction: Wave 7 → Wave 9",
    subtitle = "Blue = quiz-covered topics | Grey = topics not in the quiz",
    x = NULL, y = "Reduction in questions (%)",
    caption  = "Source: Synthetic onboarding data"
  ) +
  theme_wave()

ggsave("fig3_reduction_by_topic.png", fig3, width = 11, height = 7, dpi = 150)
cat("✔ Saved fig3_reduction_by_topic.png\n")


# ── 11. FIGURE 4 — Chi-Squared Significance: Which reductions are real? ───────

fig4 <- chi_prepost_table %>%
  mutate(
    neg_log_p = -log10(p_value),
    Sig_label  = ifelse(Significant == "YES *", "Significant (p<0.05)", "Not significant"),
    Topic      = reorder(Topic, neg_log_p)
  ) %>%
  ggplot(aes(x = Topic, y = neg_log_p, fill = Sig_label)) +
  geom_col(width = 0.75) +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed",
             colour = "#D62728", linewidth = 0.8) +
  annotate("text", x = 2, y = -log10(0.05) + 0.06,
           label = "α = 0.05 threshold", hjust = 0,
           colour = "#D62728", size = 3.2) +
  scale_fill_manual(values = c("Significant (p<0.05)" = "#D62728",
                               "Not significant"       = "#AEC6CF")) +
  coord_flip() +
  labs(
    title    = "Figure 4 — Chi-Squared Test: Statistical Significance of Wave 7 → Wave 9 Shifts",
    subtitle = "Red bars = significant reduction; taller = stronger evidence",
    x = NULL, y = "-log₁₀(p-value)",
    caption  = "Source: Synthetic onboarding data | Dashed line = α = 0.05"
  ) +
  theme_wave()

ggsave("fig4_chisq_significance.png", fig4, width = 11, height = 7, dpi = 150)
cat("✔ Saved fig4_chisq_significance.png\n")


# ── 12. FIGURE 5 — Scatter: Wave 7 vs Wave 9 with quiz labelling ─────────────

fig5 <- chi_prepost_table %>%
  mutate(
    Category  = ifelse(In_Quiz, "Quiz topic", "Non-quiz topic"),
    sig_label = ifelse(Significant == "YES *" & In_Quiz, Topic, NA)
  ) %>%
  ggplot(aes(x = Wave_7, y = Wave_9, colour = Category, label = sig_label)) +
  geom_abline(slope = 0.5, intercept = 0, linetype = "dotted",
              colour = "grey50", linewidth = 0.7) +
  annotate("text", x = 80, y = 43, label = "50% reduction line",
           size = 3, colour = "grey50", angle = 25) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed",
              colour = "grey70", linewidth = 0.7) +
  annotate("text", x = 80, y = 83, label = "No change",
           size = 3, colour = "grey70", angle = 25) +
  geom_point(size = 4, alpha = 0.85) +
  geom_text(vjust = -0.9, size = 3, na.rm = TRUE, show.legend = FALSE) +
  scale_colour_manual(values = c("Quiz topic" = "#1F77B4",
                                 "Non-quiz topic" = "#AAAAAA")) +
  labs(
    title    = "Figure 5 — Wave 7 vs Wave 9 Question Volume per Topic",
    subtitle = "Points below the 'no change' line = fewer questions in Wave 9",
    x = "Wave 7 questions (pre-quiz baseline)",
    y = "Wave 9 questions (post-intervention)",
    caption  = "Source: Synthetic onboarding data | Quiz topics labelled where significant"
  ) +
  theme_wave()

ggsave("fig5_scatter_prepost.png", fig5, width = 10, height = 7, dpi = 150)
cat("✔ Saved fig5_scatter_prepost.png\n")


# ── 13. EXPORT RESULTS TABLES ────────────────────────────────────────────────

write.csv(chi_prepost_table,  "results_wave7_vs_wave9.csv",  row.names = FALSE)
write.csv(chi_baseline_table, "results_wave7_baseline.csv",  row.names = FALSE)

cat("\n✔ Saved results_wave7_vs_wave9.csv\n")
cat("✔ Saved results_wave7_baseline.csv\n")
cat("\n✅ Analysis complete. All outputs saved.\n")
