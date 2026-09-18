# Re-analysis of the INR/USD exchange rate project.
#
# The original regression used the exchange rate level, the CPI level and an
# HP-filtered IIP growth cycle. The exchange rate and CPI are both I(1), so
# the levels fit was largely spurious. This version checks stationarity and
# cointegration first, then models monthly depreciation on stationary
# variables.
#
# Data note: "Actual_IIP" is year-on-year IIP growth in percent
# (April 2020 = -57.3), not month-on-month growth.

library(readr)
library(lubridate)
library(dplyr)
library(ggplot2)

library(urca)
library(bootUR)
library(ARDL)
library(mFilter)

library(lmtest)
library(sandwich)
library(modelsummary)
library(sessioninfo)

set.seed(123)
dir.create("tables", showWarnings = FALSE)

# --- 1. Data ----------------------------------------------------------------

data <- read_csv("data/filename.csv", show_col_types = FALSE)
data$Date <- dmy(data$Date)
data <- data[order(data$Date), ]
data$IIP_growth_yoy <- data$Actual_IIP

# Monthly depreciation and inflation in percent
data$dlog_exc <- 100 * c(NA, diff(log(data$monthly_exc_rate)))
data$infl_m   <- 100 * c(NA, diff(log(data$CPI)))
data$infl_yoy <- 100 * (log(data$CPI) - lag(log(data$CPI), 12))
data$l_dlog_exc <- c(NA, head(data$dlog_exc, -1))

# HP trend and cycle of IIP growth, plus two alternative smoothing parameters
data$hp_trend     <- as.numeric(hpfilter(data$IIP_growth_yoy, freq = 14400)$trend)
data$iip_cycle    <- as.numeric(hpfilter(data$IIP_growth_yoy, freq = 14400)$cycle)
data$cycle_1600   <- as.numeric(hpfilter(data$IIP_growth_yoy, freq = 1600)$cycle)
data$cycle_129600 <- as.numeric(hpfilter(data$IIP_growth_yoy, freq = 129600)$cycle)

# --- 2. Plots ---------------------------------------------------------------

p_exc <- ggplot(data, aes(Date, monthly_exc_rate)) +
  geom_line(colour = "#0072B2") +
  labs(title = "Monthly INR/USD exchange rate", x = NULL, y = "INR per USD") +
  theme_minimal(base_size = 11)

p_cpi <- ggplot(data, aes(Date, CPI)) +
  geom_line(colour = "#D55E00") +
  labs(title = "All-India CPI index (2012 = 100)", x = NULL, y = "Index") +
  theme_minimal(base_size = 11)

p_iip <- ggplot(data, aes(Date)) +
  geom_line(aes(y = IIP_growth_yoy, colour = "Year-on-year growth")) +
  geom_line(aes(y = hp_trend, colour = "HP trend (lambda = 14400)"), linewidth = 1) +
  scale_colour_manual(values = c("Year-on-year growth" = "grey30",
                                 "HP trend (lambda = 14400)" = "#D55E00")) +
  labs(title = "IIP year-on-year growth and HP trend", x = NULL,
       y = "Percent", colour = NULL) +
  theme_minimal(base_size = 11)

ggsave("images/fig_exchange_rate.png", p_exc, width = 8, height = 3.2, dpi = 300)
ggsave("images/fig_cpi.png", p_cpi, width = 8, height = 3.2, dpi = 300)
ggsave("images/fig_iip_growth_trend.png", p_iip, width = 8, height = 3.6, dpi = 300)

# --- 3. Unit root tests -----------------------------------------------------
# ADF with up to 6 lags chosen by AIC, and KPSS.

summary(ur.df(data$monthly_exc_rate, type = "drift", lags = 6, selectlags = "AIC"))
summary(ur.kpss(data$monthly_exc_rate, type = "mu", lags = "short"))

summary(ur.df(data$CPI, type = "drift", lags = 6, selectlags = "AIC"))
summary(ur.kpss(data$CPI, type = "mu", lags = "short"))

summary(ur.df(data$IIP_growth_yoy, type = "drift", lags = 6, selectlags = "AIC"))
summary(ur.kpss(data$IIP_growth_yoy, type = "mu", lags = "short"))

summary(ur.df(na.omit(data$dlog_exc), type = "drift", lags = 6, selectlags = "AIC"))
summary(ur.kpss(na.omit(data$dlog_exc), type = "mu", lags = "short"))

summary(ur.df(na.omit(data$infl_m), type = "drift", lags = 6, selectlags = "AIC"))
summary(ur.kpss(na.omit(data$infl_m), type = "mu", lags = "short"))

# Bootstrap versions for the two series that matter most
adf(data$monthly_exc_rate)
boot_adf(data$monthly_exc_rate, B = 999, do_parallel = FALSE, show_progress = FALSE)
adf(data$CPI)
boot_adf(data$CPI, B = 999, do_parallel = FALSE, show_progress = FALSE)

# --- 4. The original levels regression, for reference ------------------------

m_naive <- lm(monthly_exc_rate ~ CPI + iip_cycle, data = data)
summary(m_naive)
dwtest(m_naive)
coeftest(m_naive, vcov. = NeweyWest(m_naive, prewhite = FALSE, adjust = TRUE))

png("images/fig_naive_residual_acf.png", width = 1200, height = 350, res = 150)
acf(as.numeric(na.omit(residuals(m_naive))),
    main = "ACF of residuals: original levels regression", lag.max = 24)
dev.off()

# --- 5. Cointegration: ARDL bounds test --------------------------------------

ardl_aic <- auto_ardl(monthly_exc_rate ~ CPI + iip_cycle, data = as.data.frame(data),
                      max_order = 6, selection = "AIC")
ardl_bic <- auto_ardl(monthly_exc_rate ~ CPI + iip_cycle, data = as.data.frame(data),
                      max_order = 6, selection = "BIC")

bounds_f_test(ardl_aic$best_model, case = 3, exact = TRUE, R = 20000)
bounds_t_test(uecm(ardl_aic$best_model), case = 3, exact = TRUE, R = 20000)
bounds_f_test(ardl_bic$best_model, case = 3, exact = TRUE, R = 20000)
bounds_t_test(uecm(ardl_bic$best_model), case = 3, exact = TRUE, R = 20000)

# --- 6. Corrected model on stationary variables ------------------------------

m1 <- lm(dlog_exc ~ infl_m + iip_cycle, data = data)
m2 <- lm(dlog_exc ~ infl_yoy + iip_cycle, data = data)
m3 <- lm(dlog_exc ~ infl_m + iip_cycle + l_dlog_exc, data = data)

hac <- function(x) NeweyWest(x, prewhite = FALSE, adjust = TRUE)

coeftest(m1, vcov. = hac(m1))

modelsummary(list("Monthly inflation" = m1,
                  "12-month inflation" = m2,
                  "With 1 lag" = m3),
             vcov = hac,
             stars = TRUE,
             gof_map = c("nobs", "r.squared", "adj.r.squared"),
             output = "tables/corrected_models.md")

# Same model with different HP smoothing parameters for the cycle
m_1600 <- lm(dlog_exc ~ infl_m + cycle_1600, data = data)
m_129600 <- lm(dlog_exc ~ infl_m + cycle_129600, data = data)

coeftest(m_1600, vcov. = hac(m_1600))
coeftest(m_129600, vcov. = hac(m_129600))

modelsummary(list("HP 14400" = m1,
                  "HP 1600" = m_1600,
                  "HP 129600" = m_129600),
             vcov = hac,
             stars = TRUE,
             gof_map = c("nobs", "adj.r.squared"),
             output = "tables/cycle_robustness.md")

# Scatter plot of the corrected model
scatter_data <- data[complete.cases(data[, c("infl_m", "dlog_exc")]), ]
p_scatter <- ggplot(scatter_data, aes(infl_m, dlog_exc)) +
  geom_point(alpha = 0.6, colour = "#0072B2") +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "#D55E00") +
  labs(title = "Monthly depreciation vs monthly inflation",
       x = "Monthly inflation (%)", y = "Monthly depreciation (%)") +
  theme_minimal(base_size = 11)

ggsave("images/fig_scatter_depreciation_inflation.png", p_scatter,
       width = 6, height = 4, dpi = 300)

# --- 7. Package versions -----------------------------------------------------

writeLines(capture.output(session_info()), "session_info.txt")
