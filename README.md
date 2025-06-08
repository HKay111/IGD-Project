# Analysis of Indian Rupee Exchange Rate: Impact of CPI and Output Gap

## 1. Introduction

### 1.1 Background and Motivation
As India strives for economic growth and development, managing key economic indicators is crucial. The exchange rate, representing the value of the Rupee internationally, is vital for trade competitiveness and attracting investment. Domestically, policymakers closely monitor inflation (Consumer Price Index - CPI) and the overall pace of economic activity relative to the economy's potential (Output Gap). This study investigates the link between these domestic factors and movements in the monthly Indian Rupee (INR) exchange rate. This analysis is pertinent to macroeconomic policy and its impact.

### 1.2 Research Problem/Question
How do domestic inflation, as measured by the Consumer Price Index (CPI), and the cyclical position of the industrial economy, proxied by an Output Gap derived from the Index of Industrial Production (IIP), influence the monthly Indian Rupee (INR) exchange rate?

### 1.3 Objectives of the Study
1.  To empirically estimate the relationship between the monthly INR exchange rate and the CPI.
2.  To estimate the relationship between the monthly INR exchange rate and the Output Gap (derived from IIP using the Hodrick-Prescott filter).
3.  To compare the explanatory power of Output Gap versus Actual IIP and Potential IIP.
4.  To interpret findings within relevant economic theories (e.g., Purchasing Power Parity).
5.  To ensure robust statistical inference by diagnosing model assumptions and applying corrections like Heteroskedasticity and Autocorrelation Consistent (HAC) standard errors.

### 1.4 Scope and Limitations
This study focuses on the monthly INR/USD exchange rate, CPI, and an Output Gap from IIP (using HP filter) for India, with data from **January 2014 to July 2024**. The primary methodology is Ordinary Least Squares (OLS) in a dynamic linear model framework, with diagnostics (VIF, Breusch-Pagan, Durbin-Watson) and Newey-West HAC standard errors.

**Limitations:**
*   Omits some determinants (interest rate differentials, capital flows, global factors).
*   HP filter has known limitations (end-point sensitivity, smoothing parameter choice).
*   IIP as a proxy for Output Gap doesn't fully capture the large service sector.
*   Assumes linear relationships; serial correlation, though corrected, might suggest more complex models.
*   Findings are specific to the chosen data period.

## 2. Theoretical Framework (Brief Overview)
The study draws upon:
*   **Purchasing Power Parity (PPP):** Links price levels (CPI) to exchange rates. Relative PPP suggests `%ΔS ≈ π - π*`, implying higher domestic inflation leads to currency depreciation. This predicts a positive relationship between CPI and the exchange rate (INR/USD).
*   **Output Gap and Exchange Rate Linkages:**
    *   **Interest Rate Channel:** Positive Output Gap can lead to tighter monetary policy, higher interest rates, capital inflows, and currency appreciation (negative relationship between Output Gap and INR/USD).
    *   **Capital Flows/Confidence Channel:** Positive Output Gap signals strong economic performance, attracting investment and leading to currency appreciation (negative relationship).
    *   **Current Account Channel:** Positive Output Gap might increase import demand, potentially leading to currency depreciation (positive relationship), but often dominated by capital account effects.

## 3. Data and Methodology

### 3.1 Data Sources and Description
Monthly time series data for India (January 2014 - July 2024):
1.  **Monthly Exchange Rate (monthly_exc_rate):** Monthly average INR/USD spot rate (INR per USD). Source: RBI DBIE.
2.  **Consumer Price Index (CPI):** All India CPI (Combined: Rural + Urban). Base year: [2012=100]. Source: NSO, MoSPI.
3.  **Index of Industrial Production (Actual_IIP):** Monthly IIP. Base year: [2011-12=100]. Source: NSO, MoSPI.

### 3.2 Variable Construction: HP Filter and Output Gap
The Hodrick-Prescott (HP) filter was applied to `Actual_IIP` to derive:
*   **Potential IIP (Potential_IIP):** Trend component (τt).
*   **Output Gap (Output_Gap):** Cyclical component (ct), calculated as `Actual_IIP - Potential_IIP`.
A smoothing parameter λ = 14400 was used for monthly data.

### 3.3 Time Series Behavior of Key Variables

![Figure 3.1: Time Series of CPI](images/figure_3.1.png)

![Figure 3.2: Time Series of Monthly Exchange Rate](images/figure_3.2.png)

![Figure 3.3: Time Series of Output Gap](images/figure_3.3.png)

![Figure 3.4: Combined Time Series of CPI, Output Gap, and Monthly Exchange Rate](images/figure_3.4.png)

### 3.4 Visualizing the HP Filter Decomposition

![Figure 3.5: HP Filter Decomposition of IIP (Actual vs Potential IIP)](images/figure_3.5.png)

### 3.5 Econometric Model Specification
1.  **Model 1 (Output Gap Model - Preferred):** `monthly_exc_rate_t = β₀ + β₁*CPI_t + β₂*Output_Gap_t + ε₁_t` (Referred to as `igd_model`)
2.  **Model 2 (Actual IIP Model):** `monthly_exc_rate_t = γ₀ + γ₁*CPI_t + γ₂*Actual_IIP_t + ε₂_t`
3.  **Model 3 (Potential IIP Model):** `monthly_exc_rate_t = δ₀ + δ₁*CPI_t + δ₂*Potential_IIP_t + ε₃_t`

### 3.6 Estimation Method and Diagnostics
Models were estimated using OLS via the `dynlm` package in R.
Diagnostic tests on Model 1:
*   Variance Inflation Factor (VIF) for multicollinearity.
*   Breusch-Pagan Test for heteroskedasticity.
*   Durbin-Watson (DW) Test for first-order serial autocorrelation.
Newey-West HAC standard errors were computed to address autocorrelation using `coeftest` (from `lmtest`) and `NeweyWest` (from `sandwich`).

## 4. Empirical Results

### 4.1 Initial OLS Regression Results (Summary)
**Table 4.1: Initial OLS Estimation Results**
*(Dependent Variable: monthly_exc_rate)*

|                     | Model 1 (Output Gap)         | Model 2 (Actual IIP)         | Model 3 (Potential IIP)      |
|---------------------|:----------------------------:|:----------------------------:|:----------------------------:|
| **Variables**       |                              |                              |                              |
| (Intercept)         | 25.600582***                 | 25.594238***                 | 25.609262***                 |
|                     | (1.001463)                   | (1.001698)                   | (1.066650)                   |
| CPI                 | 0.308907***                  | 0.310579***                  | 0.310653***                  |
|                     | (0.006701)                   | (0.006716)                   | (0.007326)                   |
| Output_Gap          | -0.081020***                 |                              |                              |
|                     | (0.019044)                   |                              |                              |
| Actual_IIP          |                              | -0.074965***                 |                              |
|                     |                              | (0.017653)                   |                              |
| Potential_IIP       |                              |                              | -0.083017                    |
|                     |                              |                              | (0.073799)                   |
|                     |                              |                              |                              |
| **Diagnostics**     |                              |                              |                              |
| N                   | 127                          | 127                          | 127                          |
| R-squared           | 0.9453                       | 0.9452                       | 0.9379                       |
| Adjusted R-squared  | 0.9444                       | 0.9444                       | 0.9369                       |
| F-statistic         | 1071                         | 1070                         | 936.7                        |
| *p-value (F-stat)*  | < 2.2e-16                    | < 2.2e-16                    | < 2.2e-16                    |

---
*OLS Standard Errors in parentheses.*
*Significance codes: 0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1*
*(Note: N is inferred from degrees of freedom for residuals (124) + number of parameters (3), so N = 127 for all models.)*

### 4.2 Diagnostic Test Results (Model 1: `igd_model`)
*   **Multicollinearity (VIF):** VIF values for CPI (~1.00) and Output_Gap (~1.00) were extremely low, indicating no multicollinearity.
    ![Figure 4.1: Scatter Plot of Predictors (CPI vs Output Gap)](images/figure_4.1.png)
*   **Heteroskedasticity (Breusch-Pagan Test):** BP statistic = [Insert BP Value from report, e.g., 4.73], p-value = [Insert p-value from report, e.g., 0.094]. Failed to reject null of homoskedasticity (p > 0.05).
*   **Autocorrelation (Durbin-Watson Test):** DW statistic ≈ 0.30 (p-value < 2.2e-16). Strong evidence of severe positive serial correlation in OLS residuals.

### 4.3 Robust Inference Results for Preferred Model (Model 1)
Given significant autocorrelation, Newey-West HAC standard errors were computed for Model 1.
(Refer to Table 4.2 in the full report for detailed HAC results for Model 1)

**Table 4.2: Model 1 Results with HAC Standard Errors**
*(Dependent Variable: monthly_exc_rate)*

| Variable    | Estimate | HAC Std. Error | HAC t value | HAC Pr(>\|t\|) |
|-------------|:--------:|:--------------:|:-----------:|:--------------:|
| (Intercept) | 25.60058 | 1.98630        | 12.889      | < 2e-16 ***    |
| CPI         | 0.30891  | 0.01241        | 24.894      | < 2e-16 ***    |
| Output_Gap  | -0.08102 | 0.01289        | -6.284      | 5.11e-09 ***   |

---
*Significance codes: 0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1*
*Residual standard error: 1.672 on 124 degrees of freedom*
*Multiple R-squared: 0.9453, Adjusted R-squared: 0.9444*
*F-statistic (based on HAC covariance): 327.9 on 2 and 124 DF, p-value: < 2.2e-16*

## 5. Discussion and Interpretation

### 5.1 Interpretation of Preferred Model (Model 1 - Based on HAC Results)
*   **Consumer Price Index (CPI):** Coefficient ≈ +0.309 (p < 0.001 with HAC errors). A one-unit increase in CPI is associated with an approx. 0.31 unit increase in INR/USD (depreciation), consistent with Relative PPP.
*   **Output Gap:** Coefficient ≈ -0.081 (p < 0.001 with HAC errors). A positive Output Gap (economy above potential) is associated with Rupee appreciation, supporting theories of Interest Rate and Capital Flows/Confidence channels.
*   **Intercept:** Statistically significant but primarily serves to adjust the regression line level.

### 5.2 Comparison of Models
The initial OLS comparison (Section 4.1) showed that models with the cyclical component of IIP (Output Gap in Model 1, Actual IIP in Model 2) performed better than the model with only the trend (Potential IIP in Model 3). This suggests the cyclical aspect of industrial activity is key for exchange rate movements in this framework. Model 1 is preferred for its explicit isolation of the cyclical factor.

### 5.3 Discussion of Model Fit and Diagnostics
*   **Overall Fit (Model 1):** Adjusted R² ≈ 0.944 (from initial OLS), indicating CPI and Output Gap explain about 94.4% of the variation in the monthly exchange rate.
*   **Multicollinearity & Heteroskedasticity:** No significant issues detected.
*   **Autocorrelation and HAC Correction:** Severe positive autocorrelation in OLS residuals was found. Newey-West HAC standard errors confirmed the statistical significance of both CPI and Output Gap, making the core conclusions robust to serial correlation.

### 5.4 Residual Analysis (Visual Diagnostics for Model 1 OLS Residuals)

![Figure 5.1: Residuals vs. Fitted Values Plot (Model 1)](images/figure_5.1.png)
*(Supports homoskedasticity, consistent with Breusch-Pagan test)*

![Figure 5.2: Normal Q-Q Plot of Residuals (Model 1)](images/figure_5.2.png)
*(Suggests residuals are approximately normally distributed, with minor tail deviations)*

![Figure 5.3: ACF and PACF Plots of Residuals (Model 1)](images/figure_5.3.png)
*(Confirms strong positive serial autocorrelation, corroborating DW test)*

### 5.5 Visual Evidence of Main Relationships (Model 1)

![Figure 5.4: Monthly Exchange Rate vs. CPI, Colored by Output_Gap](images/figure_5.4.png)
*(Visually confirms the positive relationship between CPI and exchange rate, and the moderating effect of Output Gap)*

## 6. Conclusion and Suggestions

### 6.1 Summary of Findings
1.  **CPI:** Statistically significant positive relationship with the INR/USD exchange rate (depreciation), consistent with Relative PPP.
2.  **Output Gap (IIP-based):** Statistically significant negative relationship with the INR/USD exchange rate (appreciation), supporting theories of economic cycle impacts via interest rate/capital flow channels.
3.  **Cyclical vs. Trend (IIP):** The cyclical component (Output Gap) has significant explanatory power, while the trend component (Potential IIP) does not in this framework.
4.  **Model Fit:** The preferred model (CPI + Output Gap) explains a large proportion (Adj. R² ≈ 0.944) of monthly exchange rate variation.
*All key relationships remain significant after correcting for autocorrelation using HAC standard errors.*

### 6.2 Policy Implications (Tentative)
*   **Inflation Control:** Strong CPI-exchange rate link highlights the importance of price stability for managing exchange rate volatility and external competitiveness.
*   **Cyclical Management:** Output Gap's impact suggests domestic economic cycle management is pertinent to exchange rate outcomes.
*   **Holistic Policy View:** Achieving external sector goals likely requires sound domestic macroeconomic management.

### 6.3 Limitations of the Study
*   Omitted variables (interest rates, capital flows, global factors).
*   HP filter limitations.
*   IIP as an imperfect proxy for the overall economic cycle.
*   Presence of autocorrelation suggesting potential for more complex dynamic models.
*   Linearity assumption.

### 6.4 Scope for Future Research
*   Include additional explanatory variables.
*   Employ alternative Output Gap measures.
*   Utilize advanced dynamic modeling techniques (VAR, VECM, ARMA errors).
*   Conduct sectoral analysis.
*   Analyze relationships over extended or different data periods.

---

