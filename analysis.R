# --- 0. Load Libraries ---
library(dynlm)
library(ggplot2)
library(mFilter)
library(lmtest)
library(car)
library(lubridate)
library(zoo)
library(patchwork) # Optional
library(sandwich)

# --- 1. Load and Prepare Data ---

# Define the filename
data <- filename.csv


# --- Ensure 'Date' column is in Date format ---
# You might need to adjust the format string if your CSV stores dates differently
# Common formats: "%Y-%m-%d", "%m/%d/%Y", "%d-%m-%Y"
if ("Date" %in% colnames(data) && !inherits(data$Date, "Date")) {
  print("Converting 'Date' column to Date objects...")
  data$Date <- as.Date(data$Date) # Assumes standard R date format or YYYY-MM-DD
} else if (!"Date" %in% colnames(data)) {
  stop("Error: 'Date' column not found in the CSV file.")
}


# Order data by date (essential for time series)
data <- data[order(data$Date), ]

# Convert relevant columns to a zoo time series object for dynlm
data_zoo <- zoo(data[, c("monthly_exc_rate", "CPI", "Actual_IIP")], order.by = data$Date)

# --- 2. Generate HP Filter Components ---
hp_filtered <- hpfilter(data_zoo$Actual_IIP, freq = 14400)
data_zoo$Potential_IIP <- hp_filtered$trend
data_zoo$Output_Gap    <- hp_filtered$cycle

# --- 3. Run Regression Models ---
# Model 1 (Preferred)
igd_model <- dynlm(formula = monthly_exc_rate ~ CPI + Output_Gap, data = data_zoo)
print("--- Summary: Model 1 (Output Gap) ---")
summary(igd_model)

# Model 2
model2 <- dynlm(formula = monthly_exc_rate ~ CPI + Actual_IIP, data = data_zoo)
print("--- Summary: Model 2 (Actual IIP) ---")
summary(model2)
print("Durbin-Watson Test (Model 2):")
print(dwtest(model2))

# Model 3
model3 <- dynlm(formula = monthly_exc_rate ~ CPI + Potential_IIP, data = data_zoo)
print("--- Summary: Model 3 (Potential IIP) ---")
summary(model3)
print("Durbin-Watson Test (Model 3):")
print(dwtest(model3))

# --- 4. Generate Plots ---
plot_data <- fortify.zoo(data_zoo)

# Plot 4.1: CPI
p_cpi <- ggplot(plot_data, aes(x = Index, y = CPI)) +
  geom_line(color = "blue") +
  labs(title = "Time Series of CPI", x = "Date", y = "CPI") +
  theme_minimal()
print(p_cpi)

# Plot 4.2: Monthly Exchange Rate
p_exr <- ggplot(plot_data, aes(x = Index, y = monthly_exc_rate)) +
  geom_line(color = "green") +
  labs(title = "Time Series of Monthly Exchange Rate", x = "Date", y = "Exchange Rate") +
  theme_minimal()
print(p_exr)

# Plot 4.3: Output Gap
p_og <- ggplot(plot_data, aes(x = Index, y = Output_Gap)) +
  geom_line(color = "purple") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  labs(title = "Time Series of Output Gap", x = "Date", y = "Output Gap") +
  theme_minimal()
print(p_og)
# ggsave("time_series_output_gap.png", p_og)

# Plot 4.4: Combined Time Series
p_comb <- ggplot(plot_data, aes(x = Index)) +
  geom_line(aes(y = CPI, color = "CPI")) +
  geom_line(aes(y = monthly_exc_rate, color = "Exchange Rate")) +
  geom_line(aes(y = Output_Gap, color = "Output Gap")) +
  labs(title = "Time Series of CPI, Output Gap, Monthly Exchange Rate", x = "Date", y = "Values") +
  scale_color_manual(name = "Legend", values = c("CPI" = "blue", "Exchange Rate" = "green", "Output Gap" = "purple")) +
  theme_minimal()
print(p_comb)
# ggsave("time_series_combined.png", p_comb)

# Plot 4.5: HP Filter Decomposition
p_hp <- ggplot(plot_data, aes(x = Index)) +
  geom_line(aes(y = Actual_IIP, color = "Actual IIP")) +
  geom_line(aes(y = Potential_IIP, color = "Potential IIP (HP Trend)"), linetype = "dashed") +
  labs(title = "HP Filter Decomposition of IIP", x = "Date", y = "IIP Index") +
  scale_color_manual(name = "Series", values = c("Actual IIP" = "black", "Potential IIP (HP Trend)" = "red")) +
  theme_minimal()
print(p_hp)
# ggsave("hp_filter_decomposition.png", p_hp)

# Plot 4.6: Scatter Plot of Predictors (CPI vs Output Gap)
p_scatter_preds <- ggplot(plot_data, aes(x = CPI, y = Output_Gap)) +
  geom_point(alpha = 0.6) +
  labs(title = "Scatter Plot of Predictors (Model 1)", x = "CPI", y = "Output Gap") +
  theme_minimal()
print(p_scatter_preds)
# ggsave("scatter_predictors.png", p_scatter_preds)

# Plot 4.7: Scatter Plot for Report
p_report_scatter <- ggplot(plot_data, aes(x = CPI, y = monthly_exc_rate)) +
  geom_point(aes(color = Output_Gap), alpha = 0.7) +
  geom_smooth(method = "lm", se = FALSE, color = "blue") +
  scale_color_gradient2(low = "darkblue", mid = "grey", high = "lightblue", midpoint = 0) +
  labs(title = "Linear Model: monthly_exc_rate ~ CPI + Output_Gap",
       x = "CPI", y = "Monthly Exchange Rate", color = "Output_Gap") +
  theme_minimal()
print(p_report_scatter)
# ggsave("report_scatter_color.png", p_report_scatter)


# --- 5. Diagnostic Tests and Plots for Model 1 (igd_model) ---
print("--- Diagnostic Tests for Model 1 ---")

# 5.1 VIF Test (Multicollinearity)
if (length(coef(igd_model)) > 2) {
  vif_values <- vif(igd_model)
  print("VIF Values:")
  print(vif_values)
} else {
  print("VIF test requires at least two predictors.")
}

# 5.2 Breusch-Pagan Test (Heteroskedasticity)
bp_test <- bptest(igd_model)
print("Breusch-Pagan Test (Homoskedasticity):")
print(bp_test)

# 5.3 Durbin-Watson Test for Model 1
dw_test_model1 <- dwtest(igd_model)
print("Durbin-Watson Test (Model 1 Autocorrelation):")
print(dw_test_model1)

# 5.4 Standard Regression Diagnostic Plots (using base R plot)
print("Generating Base R Diagnostic Plots...")
par(mfrow = c(2, 2))
plot(igd_model, which = 1) # Residuals vs Fitted
plot(igd_model, which = 2) # Normal Q-Q
plot(igd_model, which = 3) # Scale-Location
plot(igd_model, which = 5) # Residuals vs Leverage
par(mfrow = c(1, 1))

# 5.5 Autocorrelation Plots of Residuals
print("Generating ACF/PACF Plots of Residuals...")
model_residuals <- residuals(igd_model)

residuals_complete_ts_structure <- na.omit(model_residuals)
if (inherits(residuals_complete_ts_structure, "zoo")) {
  residuals_numeric <- as.numeric(coredata(residuals_complete_ts_structure))
} else {
  residuals_numeric <- as.numeric(residuals_complete_ts_structure)
}

if (length(residuals_numeric) > 1 && all(is.finite(residuals_numeric))) {
  print("Sufficient finite numeric residuals found. Attempting to plot ACF/PACF...")
  par(mfrow = c(1, 2))
  acf(residuals_numeric, main = "ACF of Residuals (Model 1, NAs removed)")
  pacf(residuals_numeric, main = "PACF of Residuals (Model 1, NAs removed)")
  par(mfrow = c(1, 1))
} else if (length(residuals_numeric) <= 1) {
  print("Not enough non-NA residuals to generate ACF/PACF plots after na.omit.")
} else {
  print("Residuals contain non-finite values. Cannot plot ACF/PACF.")
}

# --- 6. Newey-West HAC Standard Errors for Model 1 ---
hac_se <- NeweyWest(igd_model, prewhite = FALSE, adjust = TRUE)

print("--- Summary: Model 1 with Newey-West HAC Standard Errors ---")
print(coeftest(igd_model, vcov. = hac_se))

print("--- Original OLS Summary (for comparison) ---")
summary(igd_model)

print("--- Code Execution Complete ---")

