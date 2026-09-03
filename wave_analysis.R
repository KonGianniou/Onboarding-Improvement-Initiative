# =============================================================================#
# Dataset: Synthetic data, generated to mirror real study structure.
# Author:  Konstantina Gianniou
# =============================================================================

### Packages ###

install.packages(c("tidyverse","scales","broom","patchwork","ggrepel"))

library(tidyverse)
library(scales)
library(broom)
library(patchwork)
library(ggrepel)

### Data ###

data=read.csv("DATA.csv",stringsAsFactors = FALSE,check.names = FALSE)

raw_total=read.csv("DATA_Total.csv",stringsAsFactors = FALSE)

names(data)=make.names(names(data))

n7=sum(data$Wave_7_n, na.rm = TRUE)
n9=sum(data$Wave_9_n, na.rm = TRUE)

wave7_weight=n9 / n7

data=data %>%
  mutate(
    Wave_7_weight = wave7_weight,
    Wave_7_weighted_n = Wave_7_n * Wave_7_weight,
    Wave_9_weight = 1,
    Wave_9_weighted_n = Wave_9_n,
    
    Wave_7_share = Wave_7_n / n7,
    Wave_9_share = Wave_9_n / n9,
    
    share_change_pp =
      100 * (Wave_9_share - Wave_7_share),
    
    share_ratio =
      Wave_9_share / Wave_7_share,
    
    log2_share_ratio =
      log2(share_ratio)
  )

cat("\nObserved sample sizes\n")
cat("Wave 7:", n7, "\n")
cat("Wave 9:", n9, "\n")
cat("Wave 7 standardisation weight:", wave7_weight, "\n")

cat("\nWeighted totals\n")
cat("Wave 7 weighted:",
    sum(data$Wave_7_weighted_n), "\n")
cat("Wave 9 weighted:",
    sum(data$Wave_9_weighted_n), "\n")

### Desctiptive ###
results=data %>%
  select(
    Topic,
    Wave_7_n,
    Wave_9_n,
    Wave_7_weighted_n,
    Wave_9_weighted_n,
    Wave_7_share,
    Wave_9_share,
    share_change_pp,
    share_ratio,
    log2_share_ratio
  ) %>%
  arrange(desc(abs(share_change_pp)));print(results)

write.csv(results,"Wave7_Wave9_topic_descriptive_results.csv",row.names = FALSE)


### Tests ###

# Perason's Xsq

data_clean=data[, c("Topic", "Wave_7_n", "Wave_9_n")]

data_clean$Wave_7_n=as.numeric(data_clean$Wave_7_n)
data_clean$Wave_9_n=as.numeric(data_clean$Wave_9_n)

data_clean=data_clean[
  is.finite(data_clean$Wave_7_n) &
    is.finite(data_clean$Wave_9_n) &
    data_clean$Wave_7_n >= 0 &
    data_clean$Wave_9_n >= 0,
]


count_matrix=rbind(
  data_clean$Wave_7_n,
  data_clean$Wave_9_n
)


rownames(count_matrix)=c("Wave 7", "Wave 9")
colnames(count_matrix)=data_clean$Topic

print(count_matrix)

overall_chisq=chisq.test(count_matrix, correct = FALSE)

print(overall_chisq)

expected=overall_chisq$expected

residuals=overall_chisq$stdres

residual_table=data.frame(
  Topic = data_clean$Topic,
  Expected_Wave7 = expected[1, ],
  Expected_Wave9 = expected[2, ],
  StdResid_Wave7 = residuals[1, ],
  StdResid_Wave9 = residuals[2, ]
)

print(residual_table)

# Cramer's V for a 2 x 20 table
cramers_v=sqrt(
  as.numeric(overall_chisq$statistic) /
    (sum(count_matrix) *
       min(nrow(count_matrix) - 1,
           ncol(count_matrix) - 1))
)

cat("\nCramer's V:", cramers_v, "\n")

### Topics test ###

topic_tests=data %>%
  rowwise() %>%
  mutate(
    prop_test = list(
      prop.test(
        x = c(Wave_7_n, Wave_9_n),
        n = c(n7, n9),
        correct = FALSE
      )
    ),
    p_value = prop_test$p.value,
    conf_low = prop_test$conf.int[1],
    conf_high = prop_test$conf.int[2]
  ) %>%
  ungroup() %>%
  mutate(
    # conf.int is for Wave7 - Wave9, so convert to percentage points
    conf_low_pp = 100 * conf_low,
    conf_high_pp = 100 * conf_high,
    
    p_adjusted_BH = p.adjust(
      p_value,
      method = "BH"
    ),
    
    significant_BH = p_adjusted_BH < 0.05
  ) %>%
  select(
    Topic,
    Wave_7_n,
    Wave_9_n,
    Wave_7_share,
    Wave_9_share,
    share_change_pp,
    share_ratio,
    log2_share_ratio,
    p_value,
    p_adjusted_BH,
    significant_BH
  ) %>%
  arrange(p_adjusted_BH)

print(topic_tests)

write.csv(topic_tests,"Wave7_Wave9_topic_tests.csv",row.names = FALSE)

### Change ###

ci_results=data %>%
  mutate(
    diff = Wave_9_share - Wave_7_share,
    se = sqrt(
      Wave_7_share * (1 - Wave_7_share) / n7 +
        Wave_9_share * (1 - Wave_9_share) / n9
    ),
    ci_low = diff - 1.96 * se,
    ci_high = diff + 1.96 * se,
    ci_low_pp = ci_low * 100,
    ci_high_pp = ci_high * 100
  )

write.csv(ci_results,"Wave7_Wave9_change_confidence_intervals.csv",row.names = FALSE)

### Descriptive weighted ###

weighted_long=data %>%
  select(
    Topic,
    Wave_7_weighted_n,
    Wave_9_weighted_n
  ) %>%
  pivot_longer(
    cols = c(Wave_7_weighted_n, Wave_9_weighted_n),
    names_to = "Wave",
    values_to = "Weighted_Count"
  ) %>%
  mutate(
    Wave = recode(
      Wave,
      Wave_7_weighted_n = "Wave 7 (pre)",
      Wave_9_weighted_n = "Wave 9 (post)"
    )
  )

### Graphs ###

raw_long=data %>%
  select(Topic, Wave_7_n, Wave_9_n) %>%
  pivot_longer(
    cols = c(Wave_7_n, Wave_9_n),
    names_to = "Wave",
    values_to = "Count"
  ) %>%
  mutate(
    Wave = recode(
      Wave,
      Wave_7_n = "Wave 7 (pre)",
      Wave_9_n = "Wave 9 (post)"
    )
  )

p_raw=ggplot(
  raw_long,
  aes(
    x = reorder(Topic, Count),
    y = Count,
    fill = Wave
  )
) +
  geom_col(position = "dodge") +
  coord_flip() +
  labs(
    title = "Raw number of contacts/questions by topic",
    subtitle = "Wave 7 vs Wave 9",
    x = NULL,
    y = "Number of contacts"
  ) +
  theme_minimal() +
  theme(legend.position = "top");print(p_raw)

p_weighted=ggplot(
  weighted_long,
  aes(
    x = reorder(Topic, Weighted_Count),
    y = Weighted_Count,
    fill = Wave
  )
) +
  geom_col(position = "dodge") +
  coord_flip() +
  labs(
    title = "Sample-size-standardised topic counts",
    subtitle = paste0(
      "Wave 7 standardised to Wave 9; weight = ",
      round(wave7_weight, 4)
    ),
    x = NULL,
    y = "Standardised count"
  ) +
  theme_minimal() +
  theme(legend.position = "top");print(p_weighted)


share_long=data %>%
  select(Topic, Wave_7_share, Wave_9_share) %>%
  pivot_longer(
    cols = c(Wave_7_share, Wave_9_share),
    names_to = "Wave",
    values_to = "Share"
  ) %>%
  mutate(
    Wave = recode(
      Wave,
      Wave_7_share = "Wave 7 (pre)",
      Wave_9_share = "Wave 9 (post)"
    )
  )

p_composition=ggplot(
  share_long,
  aes(
    x = Wave,
    y = Share,
    fill = Topic
  )
) +
  geom_col(width = 0.7) +
  scale_y_continuous(labels = percent_format()) +
  labs(
    title = "Composition of contacts by topic",
    subtitle = "Each wave sums to 100%",
    x = NULL,
    y = "Share of contacts"
  ) +
  theme_minimal() +
  theme(legend.position = "right");print(p_composition)


p_change=ggplot(
  ci_results,
  aes(
    x = reorder(Topic, share_change_pp),
    y = share_change_pp
  )
) +
  geom_hline(yintercept = 0, linewidth = 0.7) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Change in topic share",
    subtitle = "Wave 9 minus Wave 7, percentage points",
    x = NULL,
    y = "Change in share (percentage points)"
  ) +
  theme_minimal();print(p_change)


p_ci=ggplot(
  ci_results,
  aes(
    x = reorder(Topic, diff),
    y = diff
  )
) +
  geom_hline(yintercept = 0, linewidth = 0.7) +
  geom_errorbar(
    aes(
      ymin = ci_low,
      ymax = ci_high
    ),
    width = 0.2
  ) +
  geom_point(size = 2.5) +
  coord_flip() +
  scale_y_continuous(labels = percent_format()) +
  labs(
    title = "Change in topic share with 95% confidence intervals",
    subtitle = "Wave 9 minus Wave 7",
    x = NULL,
    y = "Difference in share"
  ) +
  theme_minimal();print(p_ci)

dumbbell=data %>%
  arrange(Wave_7_share) %>%
  mutate(Topic = factor(Topic, levels = Topic))

p_dumbbell=ggplot(dumbbell) +
  geom_segment(
    aes(
      x = Wave_7_share,
      xend = Wave_9_share,
      y = Topic,
      yend = Topic
    ),
    linewidth = 1
  ) +
  geom_point(
    aes(x = Wave_7_share, y = Topic),
    size = 3
  ) +
  geom_point(
    aes(x = Wave_9_share, y = Topic),
    size = 3
  ) +
  scale_x_continuous(labels = percent_format()) +
  labs(
    title = "Topic share before and after intervention",
    x = "Share of contacts",
    y = NULL
  ) +
  theme_minimal()

print(p_dumbbell)


ratio_data=data %>%
  filter(
    is.finite(share_ratio),
    share_ratio > 0
  )

p_ratio=ggplot(
  ratio_data,
  aes(
    x = reorder(Topic, share_ratio),
    y = share_ratio
  )
) +
  geom_hline(yintercept = 1, linewidth = 0.7) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Relative change in topic share",
    subtitle = "Wave 9 share / Wave 7 share",
    x = NULL,
    y = "Share ratio"
  ) +
  theme_minimal()

print(p_ratio)


p_logratio=ggplot(
  ratio_data,
  aes(
    x = reorder(Topic, log2_share_ratio),
    y = log2_share_ratio
  )
) +
  geom_hline(yintercept = 0, linewidth = 0.7) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Relative change in topic share",
    subtitle = "Log2(Wave 9 share / Wave 7 share)",
    x = NULL,
    y = "Log2 share ratio"
  ) +
  theme_minimal()

print(p_logratio)


resid_long=residual_table %>%
  select(
    Topic,
    StdResid_Wave7,
    StdResid_Wave9
  ) %>%
  pivot_longer(
    cols = starts_with("StdResid"),
    names_to = "Wave",
    values_to = "Standardised_Residual"
  ) %>%
  mutate(
    Wave = recode(
      Wave,
      StdResid_Wave7 = "Wave 7",
      StdResid_Wave9 = "Wave 9"
    )
  )

p_resid=ggplot(
  resid_long,
  aes(
    x = Wave,
    y = reorder(Topic, Standardised_Residual),
    fill = Standardised_Residual
  )
) +
  geom_tile() +
  geom_text(
    aes(label = round(Standardised_Residual, 2)),
    size = 3
  ) +
  labs(
    title = "Chi-square standardised residuals",
    subtitle = "Large positive/negative values identify topics driving the overall difference",
    x = NULL,
    y = NULL,
    fill = "Standardised\nresidual"
  ) +
  theme_minimal()

print(p_resid)


rank_data=data %>%
  mutate(
    rank_wave7 = min_rank(desc(Wave_7_share)),
    rank_wave9 = min_rank(desc(Wave_9_share)),
    rank_change = rank_wave7 - rank_wave9
  )

p_rank=ggplot(
  rank_data,
  aes(
    x = rank_wave7,
    y = rank_wave9,
    label = Topic
  )
) +
  geom_abline(
    slope = 1,
    intercept = 0,
    linetype = "dashed"
  ) +
  geom_point(size = 3) +
  ggrepel::geom_text_repel() +
  scale_x_reverse() +
  scale_y_reverse() +
  labs(
    title = "Change in topic ranking",
    subtitle = "Rank 1 = largest share",
    x = "Wave 7 rank",
    y = "Wave 9 rank"
  ) +
  theme_minimal()

print(p_rank)

p_scatter=ggplot(
  data,
  aes(
    x = Wave_7_share,
    y = Wave_9_share,
    label = Topic
  )
) +
  geom_abline(
    slope = 1,
    intercept = 0,
    linetype = "dashed"
  ) +
  geom_point(size = 3) +
  ggrepel::geom_text_repel() +
  scale_x_continuous(labels = percent_format()) +
  scale_y_continuous(labels = percent_format()) +
  labs(
    title = "Topic shares: Wave 7 vs Wave 9",
    x = "Wave 7 share",
    y = "Wave 9 share"
  ) +
  theme_minimal()

print(p_scatter)


top_changes=bind_rows(
  data %>%
    slice_max(share_change_pp, n = 5) %>%
    mutate(Direction = "Increase"),
  data %>%
    slice_min(share_change_pp, n = 5) %>%
    mutate(Direction = "Decrease")
)

p_top_changes=ggplot(
  top_changes,
  aes(
    x = reorder(Topic, share_change_pp),
    y = share_change_pp
  )
) +
  geom_hline(yintercept = 0) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Largest changes in topic share",
    x = NULL,
    y = "Change in share (percentage points)"
  ) +
  theme_minimal()

print(p_top_changes)


sensitivity=data.frame(
  Analysis = c(
    "Raw counts / proportions",
    "Wave 7 standardised to Wave 9"
  ),
  Wave7_total = c(
    n7,
    sum(data$Wave_7_weighted_n)
  ),
  Wave9_total = c(
    n9,
    sum(data$Wave_9_weighted_n)
  ),
  Weight_applied_to_Wave7 = c(
    1,
    wave7_weight
  )
)

print(sensitivity)


topic_frequency <- raw_total %>%
  count(Topic, sort = TRUE)

print(topic_frequency)

