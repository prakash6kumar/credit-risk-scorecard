library(tidyverse) 
library(lubridate)
library(janitor)

raw_data <- read.csv("data/raw/loan.csv")

# Define the statuses we want to keep
target_statuses <- c("Fully Paid", 
                     "Does not meet the credit policy. Status:Fully Paid",
                     "Charged Off", 
                     "Default", 
                     "Late (31-120 days)", 
                     "Does not meet the credit policy. Status:Charged Off")

# Filter and Map
loan_data <- raw_data %>%
  # Remove any whitespaces
  mutate(across(where(is.character), str_trim)) %>%
  # Remove any loans that don't have target statuses
  filter(loan_status %in% target_statuses) %>%
  # Use Loan Status to define loans as good or bad
  mutate(is_bad = if_else(str_detect(loan_status, "Paid"), 0, 1)) %>%
  # Turn employment length and loan term into ints
  mutate(
    # Convert emp_length to numeric
    emp_length_num = case_when(
      emp_length == "10+ years" ~ 10,
      emp_length == "9 years"   ~ 9,
      emp_length == "8 years"   ~ 8,
      emp_length == "7 years"   ~ 7,
      emp_length == "6 years"   ~ 6,
      emp_length == "5 years"   ~ 5,
      emp_length == "4 years"   ~ 4,
      emp_length == "3 years"   ~ 3,
      emp_length == "2 years"   ~ 2,
      emp_length == "1 year"    ~ 1,
      emp_length == "< 1 year"  ~ 0,
      TRUE                      ~ NA_real_ 
    ),
    
    # Just extract the digits from term
    term_months = as.numeric(str_extract(term, "\\d+")),
    
  ) %>%
  # Handle the Median Imputation for emp_length
  mutate(
    emp_length_num = replace_na(emp_length_num, median(emp_length_num, na.rm = TRUE))
  ) %>%
  # Cap Income at the 99% percentile
  mutate(
    annual_inc_capped = if_else(annual_inc > income_cap, income_cap, annual_inc)
  )

# Select needed columns for model
loan_data_clean <- loan_data %>%
  select(
    # Target
    is_bad,
    
    # Loan Info
    loan_amnt, term_months, int_rate, installment, grade, sub_grade,
    
    # Borrower Info
    emp_length_num, home_ownership, annual_inc, verification_status, 
    purpose, addr_state, dti,
    
    # Credit History
    delinq_2yrs, earliest_cr_line, inq_last_6mths, open_acc, 
    pub_rec, revol_bal, revol_util, total_acc, mort_acc,
    
    # Financial Health
    tot_cur_bal, total_rev_hi_lim, num_bc_tl, bc_util,
    acc_open_past_24mths, avg_cur_bal,
    
    # Other potential predictors
    pub_rec_bankruptcies, tax_liens, tot_hi_cred_lim
  )

# Save the file
saveRDS(loan_data_clean, "data/processed/loan_data_clean.rds")

