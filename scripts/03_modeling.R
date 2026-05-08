library(tidyverse)
library(tidymodels)

loan_data <- readRDS("data/processed/loan_data_clean.rds")

# Add the capped DTI to the data
dti_cap <- quantile(loan_data$dti, 0.99, na.rm = TRUE)
loan_data <- loan_data %>%
  mutate(
    dti_capped = if_else(dti > dti_cap, dti_cap, dti)
  )

colSums(is.na(loan_data))

# Data Splitting
set.seed(123)
data_split <- initial_split(loan_data, prop = 0.80, strata = is_bad)
train_data <- training(data_split)
test_data  <- testing(data_split)

# Model 1 - Three variables
model_v1 <- glm(is_bad ~ int_rate + dti + annual_inc, 
                data = train_data, 
                family = "binomial")

summary(model_v1)

# Model 2 - 7 Variables
model_v2 <- glm(is_bad ~ int_rate + dti + annual_inc + grade + 
                  acc_open_past_24mths + revol_util + total_acc, 
                data = train_data, 
                family = "binomial")

summary(model_v2)

# Test the model
test_predictions <- test_data %>%
  na.omit() %>%
  mutate(
    # Use '.' to ensure predict() uses the filtered data
    prob_default = predict(model_v2, newdata = ., type = "response")
  )

# Look at the first few predictions
test_predictions %>%
  select(is_bad, prob_default, int_rate, dti, annual_inc, grade) %>%
  head(10)

# Confusion Matrix - turn is_bad into the factor
eval_data <- test_predictions %>%
  mutate(
    truth = as.factor(is_bad),
    # Create the prediction based on a 20% threshold and make it a factor
    estimate = as.factor(if_else(prob_default > 0.20, 1, 0))
  )
# 2. Run the confusion matrix
eval_data %>%
  conf_mat(truth = truth, estimate = estimate)

# ROC Curve and AUC Value
results <- test_predictions %>%
  mutate(
    truth = as.factor(is_bad),
    prob_default = prob_default
  )

# Plot the ROC Curve
results %>%
  roc_curve(truth, prob_default, event_level = "second") %>%
  autoplot()

# Calculate AUC
results %>%
  roc_auc(truth, prob_default, event_level = "second")

# Create an Importance Plot
importance <- as.data.frame(summary(model_v2)$coefficients) %>%
  rownames_to_column("Variable") %>%
  filter(Variable != "(Intercept)") %>%
  mutate(Importance = abs(`z value`))

ggplot(importance, aes(x = reorder(Variable, Importance), y = Importance)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  theme_minimal() +
  labs(title = "Variable Importance (z-score)",
       x = "Variable",
       y = "Absolute z-value")

