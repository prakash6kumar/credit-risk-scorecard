library(tidyverse)

loan_data <- readRDS("data/processed/loan_data_clean.rds")

# Default percentages by grade
loan_data %>%
  group_by(grade) %>%
  summarise(
    total_loans = n(),
    default_rate = mean(is_bad)
  ) %>%
  ggplot(aes(x = grade, y = default_rate)) +
  geom_col(fill = "darkred") +
  scale_y_continuous(labels = scales::percent) +
  theme_minimal() +
  labs(title = "Default Rate by Loan Grade", y = "Bad Rate", x = "Grade")

# Density plot of interest rates of good and bad loans
ggplot(loan_data, aes(x = int_rate, fill = as.factor(is_bad))) +
  geom_density(alpha = 0.4) +
  scale_fill_manual(values = c("steelblue", "darkred"), 
                    labels = c("Good", "Bad"), 
                    name = "Loan Status") +
  theme_minimal() +
  labs(title = "Interest Rate Distribution by Outcome",
       x = "Interest Rate",
       y = "Density")

# Density plot of Debt-to-Interest Ratios for good and bad loans
# DTI had to be capped at the 99th percentile to prevent tailing
dti_cap <- quantile(loan_data$dti, 0.99, na.rm = TRUE)
print(dti_cap)

loan_data <- loan_data %>%
  mutate(
    dti_capped = if_else(dti > dti_cap, dti_cap, dti)
  )

ggplot(loan_data, aes(x = dti_capped, fill = as.factor(is_bad))) +
  geom_density(alpha = 0.4) +
  scale_fill_manual(values = c("steelblue", "darkred"), 
                    labels = c("Good", "Bad"), 
                    name = "Loan Status") +
  theme_minimal() +
  labs(title = "Debt-to-Income Distribution by Outcome",
       x = "Debt-to-Income",
       y = "Density")

# Default rates per Loan Purpose
loan_data %>%
  group_by(purpose) %>%
  summarise(bad_rate = mean(is_bad)) %>%
  ggplot(aes(x = reorder(purpose, bad_rate), y = bad_rate)) +
  geom_col(fill = "forestgreen") +
  coord_flip() + # Makes long labels easier to read
  theme_minimal() +
  labs(title = "Default Rate by Loan Purpose",
       x = "Purpose",
       y = "Default Rate")

# Comparison of interest, annual income, and DTI between good and bad loans
loan_data %>%
  group_by(is_bad) %>%
  summarise(
    avg_int_rate = mean(int_rate, na.rm = TRUE),
    avg_annual_inc = mean(annual_inc, na.rm = TRUE),
    avg_dti = mean(dti, na.rm = TRUE),
    loan_count = n()
  )

# Boxplot of the spread of interest rates between good and bad loans
ggplot(loan_data, aes(x = as.factor(is_bad), y = int_rate, fill = as.factor(is_bad))) +
  geom_boxplot() +
  scale_x_discrete(labels = c("Good (0)", "Bad (1)")) +
  theme_minimal() +
  labs(title = "Interest Rate Spread: Good vs Bad Loans",
       x = "Loan Status",
       y = "Interest Rate (%)") +
  guides(fill = "none")

