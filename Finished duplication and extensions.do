/***************************************************************
display "Author: u7759119 Liangya Zhu"
* Integrated Analysis: Real Wages, Productivity & Inflation in Australia (1970–2023)
* Combines Manufacturing & All Industries Analysis | Single Log File
***************************************************************/

clear all
capture log close
set more off

*** Global Log Settings (Only Once) ***
log using "D:\8002 Assignment\Combined_Analysis.log", text replace

***************************************************************
***************Part 1  Replication*****************************

* Real Wages, Productivity and Inflation in Australia (1970–2007)
* Unified Base Year: 2000=100 | Enhanced Version with Moving Averages
***************************************************************

* STEP 0: Import the prepared dataset
import excel "D:\8002 Assignment\datasets.xlsx", sheet("replication") firstrow clear

	
* STEP 1: Set time series
tsset year

* STEP 2: Annualize wage, compute real wage & productivity
gen annual_wage = wages_weekly_earningsbase2000 * 52
gen real_wage = annual_wage / cpibase2000
gen productivity = industrialproductionbaseyear / manufactureemploymentbaseyear


* STEP 3: Inflation as % change (not log diff)
gen inflation = 100 * (cpibase2000 - L.cpibase2000) / L.cpibase2000

* STEP 4: Growth rates
gen real_wage_growth = 100 * (real_wage - L.real_wage) / L.real_wage
gen productivity_growth = 100 * (productivity - L.productivity) / L.productivity

* Clean for plotting: remove unrealistic spikes
local upper = 20
local lower = -20

gen rwg_clean = real_wage_growth
replace rwg_clean = . if rwg_clean > `upper' | rwg_clean < `lower'

gen pg_clean = productivity_growth
replace pg_clean = . if pg_clean > `upper' | pg_clean < `lower'

gen infl_clean = inflation
replace infl_clean = . if infl_clean > `upper' | infl_clean < `lower'

* Time series line plot
twoway ///
    (connected pg_clean year, lcolor(blue) lwidth(medthick) msymbol(diamond)) ///
    (connected rwg_clean year, lcolor(red) lwidth(medthick) msymbol(square)) ///
    (connected infl_clean year, lcolor(green) lwidth(medthick) msymbol(triangle)), ///
    legend(position(6) ring(0) cols(3) ///
        label(1 "Productivity Growth") ///
        label(2 "Real Wage Growth") ///
        label(3 "Inflation Rate")) ///
    title("Growth in Wage, Productivity & Inflation (Australia, 1970–2007)", size(medsmall)) ///
    ytitle("Annual % Change", size(small)) ///
    xtitle("Year", size(small)) ///
    xlabel(1970(2)2007, angle(90) labsize(vsmall)) ///
    graphregion(color(white)) plotregion(margin(zero))

* Export
graph export "D:\8002 Assignment\growth_trends_1970_2007.png", width(3000) height(2200) replace

* ===========================
*Main Test
* STEP 1: Clean environment to avoid variable conflicts
* ===========================
capture drop log_real_wage log_productivity
capture drop d_log_real_wage d_log_productivity d_inflation

* STEP 2: Log-transform variables
* ===========================
gen log_real_wage = log(real_wage)
gen log_productivity = log(productivity)

* ===========================
* STEP 2.5: Determine optimal lag length using VAR lag order selection
* ===========================
varsoc log_real_wage
varsoc log_productivity
varsoc inflation

* ===========================
* STEP 3: ADF Unit Root Tests on original variables (level form)
* ===========================
dfuller real_wage, lags(1) trend
dfuller productivity, lags(2) trend
dfuller inflation, lags(1) trend

* ===========================
* STEP 3.5: PP Unit Root Tests on original variables (level form)
* ===========================
pperron real_wage, lags(1) trend
pperron productivity, lags(2) trend
pperron inflation, lags(1) trend

* ===========================
* STEP 4: ADF Unit Root Tests on log-transformed variables
* ===========================
dfuller log_real_wage, lags(1) trend
dfuller log_productivity, lags(2) trend

* ===========================
* STEP 4.1: PP Unit Root Tests on log-transformed variables
* ===========================
pperron log_real_wage, lags(1) trend
pperron log_productivity, lags(2) trend

* ===========================
* STEP 5: First-difference if non-stationary
* ===========================
gen d_log_real_wage = D.log_real_wage
gen d_log_productivity = D.log_productivity
gen d_inflation = D.inflation

* ===========================
* STEP 6: ADF Unit Root Tests on first-differenced variables
* ===========================
dfuller d_log_real_wage, lags(1) trend
dfuller d_log_productivity, lags(2) trend
dfuller d_inflation, lags(1) trend

* ===========================
* STEP 6.1: PP Unit Root Tests on first-differenced variables
* ===========================
pperron d_log_real_wage, lags(1) trend
pperron d_log_productivity, lags(2) trend
pperron d_inflation, lags(1) trend

* ===========================
* STEP 7: Johansen Cointegration Test (Trace and Max Eigenvalue)
* ===========================
* Note: Ensure all variables are I(1) before this step

* Johansen test - Trace statistic
vecrank log_productivity log_real_wage  inflation, lags(2) trace

vec log_productivity log_real_wage inflation, lags(2) rank(1)

* Johansen test - Max eigenvalue statistic
vecrank log_productivity log_real_wage  inflation, lags(2) max


* ===========================
* STEP 7.1: Gregory-Hansen Tests for Structural Break in Cointegration
* ===========================

* Install GH package if not already installed
cap which ghansen
if _rc ssc install ghansen

* Model (1): Level shift only
ghansen log_productivity log_real_wage inflation, break(level) lagmethod(aic)

* Model (2): Trend shift only
ghansen log_productivity log_real_wage inflation, break(trend) lagmethod(aic)

* Model (3): Regime shift (intercept + slope)
ghansen log_productivity log_real_wage inflation, break(regime) lagmethod(aic)

* Model (4): Regime + trend shift
ghansen log_productivity log_real_wage inflation, break(regimetrend) lagmethod(aic)

* STEP 8: Estimate Vector Error Correction Model (VECM)
* ===========================

vec log_productivity log_real_wage inflation, lags(2) rank(1) 

* ===========================
* STEP 9: View Cointegration & ECT Results (already shown after vec)
* ===========================
* Long-run cointegrating relationship and short-run error correction
* terms are printed automatically after the vec command.
* No additional estat commands are required.

* ===========================
* STEP 10: Granger Causality Tests (within VECM)
* ===========================

* Re-estimate VECM and store results (if needed again)
vec log_productivity log_real_wage inflation, lags(2) rank(1) 
* ===========================
* Short-run Granger Causality via Wald Tests (within VECM)
* ===========================


* 1. Does log_productivity Granger-cause log_real_wage?
test (_b[D_log_real_wage:LD.log_productivity] = 0)

* 2. Does log_real_wage Granger-cause log_productivity?
test (_b[D_log_productivity:LD.log_real_wage] = 0)

* 3. Does inflation Granger-cause log_real_wage?
test (_b[D_log_real_wage:LD.inflation] = 0)

* 4. Does inflation Granger-cause log_productivity?
test (_b[D_log_productivity:LD.inflation] = 0)

* 5. Does real wages Granger-cause inflation?
test (_b[D_inflation:LD.log_real_wage] = 0)

* 6. Does productivity Granger-cause inflation?
test (_b[D_inflation:LD.log_productivity] = 0)

* 7. Joint test: Do real wages and productivity Granger-cause inflation?
test (_b[D_inflation:LD.log_real_wage] = 0) (_b[D_inflation:LD.log_productivity] = 0)

* ===========================
* STEP 11: Alternative Long-Run Estimates (Replicating Table 3)
* ===========================

* --- 1. Engle-Granger Two-Step Method ---
* Estimate static long-run relationship
reg log_productivity log_real_wage inflation

* Save residuals and test for stationarity
predict eg_resid, resid
dfuller eg_resid, lags(1)

* --- 2. ARDL Model with EC (Error Correction) representation ---
* Estimate ARDL(p,q1,q2) and retrieve long-run coefficients
* Replace with best lags after testing if needed

ardl log_productivity log_real_wage inflation, lags(1 1 1) ec

* --- 3. GETS (General-to-Specific) Model ---
* Use existing differenced variable
* Ensure lagged variables are created (if not already)
gen L_log_productivity = L.log_productivity
gen L_log_real_wage   = L.log_real_wage
gen L_inflation       = L.inflation

* Estimate unrestricted dynamic model
reg d_log_productivity L_log_productivity L_log_real_wage L_inflation

* Optional: automatic variable selection
stepwise, pr(0.05): reg d_log_productivity L_log_productivity L_log_real_wage L_inflation


* --- 4. FMOLS Approximation via Newey-West Robust OLS ---
* Note: This is an approximate long-run estimator
newey log_productivity log_real_wage inflation, lag(1)


* -----------------------------------------------
* GH Method: Gregory-Hansen Cointegration Test + Post-Break Regression
* -----------------------------------------------

* Step 1: Install ghansen package (if not installed)
capture ssc install ghansen

* Step 2: Run GH test (regime + trend shift specification)
ghansen log_productivity log_real_wage inflation, break(regimetrend) lagmethod(aic)

* Step 3: Extract break year (manually set based on GH test output)
local break_year = 1982  // Set break year based on GH test results

* Step 4: Create post-break dummy variable
gen post_break = (year >= `break_year')

* Step 5: Estimate long-run relationship on post-break subsample
reg log_productivity log_real_wage inflation if post_break == 1

* Step 6: Store results for reporting
estimates store GH_post_break

* Skip not run this code: Step 7: Generate formatted table (adjust path as needed)
ssc install estout
esttab GH_post_break using "GH_results.rtf", ///
  b(3) se(3) star(* 0.05 ** 0.01) ///
  keep(log_real_wage inflation _cons) ///
  mtitles("GH Post-Break Estimates") replace


* ===========================
* END: All core replication steps now completed.

***************************************************************
* STEP 13: Rolling Regression with 20-Year Window
***************************************************************
rolling b_wage = _b[log_real_wage] b_infl = _b[inflation] b_cons = _b[_cons], ///
    window(20) step(1) saving(rolling_prod_coeffs, replace): ///
    regress log_productivity log_real_wage inflation

use rolling_prod_coeffs, clear
gen year = start + 10

twoway (line b_wage year, lcolor(red)) ///
       (line b_infl year, lcolor(green)), ///
       legend(order(1 "ln(Wage)" 2 "Inflation")) ///
       title("Rolling Coefficients: ln(Productivity) as Dependent", size(small)) ///
       ytitle("Elasticity") xtitle("Year") graphregion(color(white))

graph export "D:\8002 Assignment\1970_2007_Rolling_Coefficients.png", ///
    width(3200) height(2400) replace

***************************************************************
* STEP 14: Export Final Data
***************************************************************
export delimited using "D:\8002 Assignment\replication_1970_2007_wage_productivity_inflation.csv", replace


***************************************************************

***************Part 2  Manufacture*****************************
***************************************************************
* Real Wages, Productivity and Inflation in Australian Manufacturing (1990-2022)
* Time series analysis following academic replication logic
* Author: [Liangya Zhu]
***************************************************************

* STEP 0: Load dataset
import excel "D:\8002 Assignment\datasets.xlsx", sheet("extension1") firstrow clear

* STEP 1:
destring real_wage productivity inflation, replace ignore(",") force

* STEP 1.5: Set time series structure
tsset year

* STEP 2: Create growth rate variables
gen productivity_growth = 100 * (D.productivity / L.productivity)
gen real_wage_growth = 100 * (D.real_wage / L.real_wage)
* STEP 4: Unit Root Tests (ADF) with various specifications
display "=== ADF Unit Root Tests: real_wage ==="
dfuller real_wage, lags(1)             // No constant, no trend
dfuller real_wage, lags(1) drift       // Constant only
dfuller real_wage, lags(1) trend       // Constant + trend

display "=== ADF Unit Root Tests: productivity ==="
dfuller productivity, lags(1) 
dfuller productivity, lags(1) drift
dfuller productivity, lags(1) trend

display "=== ADF Unit Root Tests: inflation ==="
dfuller inflation, lags(1) 
dfuller inflation, lags(1) drift
dfuller inflation, lags(1) trend

* STEP 4.1: Create log-transformed variables
gen log_productivity = log(productivity)
gen log_real_wage = log(real_wage)
*tsline
tsline log_real_wage, title("Log of Real Wage Over Time") ylabel(, angle(0))
tsline log_productivity, title("Log of Productivity Over Time") ylabel(, angle(0))

* STEP 4.2: ADF Unit Root Tests on log-transformed variables
display "=== ADF Unit Root Tests on Log-Transformed Variables ==="
dfuller log_productivity, lags(1) trend
dfuller log_real_wage, lags(1) trend

* STEP 4.3: Test stationarity of first difference 
gen d_log_real_wage = D.log_real_wage
gen d_log_productivity = D.log_productivity

display "=== ADF Unit Root Test on First Difference of log(real_wage) ==="
dfuller d_log_real_wage, lags(1) drift
dfuller d_log_productivity, lags(1) drift

* STEP 5: ARDL Model
display "=== ARDL Model with Error Correction: log_productivity ~ log_real_wage + inflation ==="
ardl log_productivity log_real_wage inflation, lags(1) ec1

* STEP 6: Bounds Test for Cointegration
estat ectest

* STEP 8: Diagnostic Tests
estat bgodfrey
estat hettest
predict resid_ardl, resid
sktest resid_ardl

* STEP 9: Generate fitted values from the ARDL model
reg D.log_productivity L.log_productivity L.log_real_wage L.inflation D.log_real_wage D.inflation
predict fitted_reg
tsline D.log_productivity fitted_reg, ///
    legend(label(1 "Actual Growth (Δlog Productivity)") label(2 "Fitted Growth")) ///
    title("Actual vs Fitted Productivity Growth in Manufacture (ARDL Model)", size(small)) ///
    ytitle("Annual % Change") ///
    xtitle("Year") ///
    xlabel(1990(2)2022, angle(90))

graph export "D:\8002 Assignment\manufacture_productivity_growth_fitted_vs_actual.png", width(3200) height(2400) replace

* STEP 10: Granger Causality Test using VAR
gen d_inflation = D.inflation
varsoc d_log_productivity d_log_real_wage d_inflation
var d_log_productivity d_log_real_wage d_inflation, lags(1)
vargranger

* STEP 11: Time Series Plot
twoway (connected productivity_growth year, lcolor(blue) lwidth(medium) msymbol(D) msize(vsmall)) ///
       (connected real_wage_growth year, lcolor(red) lwidth(medium) msymbol(square) msize(vsmall)) ///
       (connected inflation year, lcolor(green) lwidth(medium) msymbol(triangle) msize(vsmall)), ///
       legend(position(6) ring(0) cols(3) ///
              label(1 "Productivity Growth") ///
              label(2 "Real Wage Growth") ///
              label(3 "Inflation Rate")) ///
       title("Growth in Wage, Productivity & Inflation in Australian Manufacturing (1990–2022)", size(small)) ///
       ytitle("Annual % Change", size(small)) ///
       xtitle("Year", size(small)) ///
       xlabel(1990(2)2022, angle(90) labsize(small)) ///
       graphregion(color(white)) ///
       plotregion(margin(zero))

graph export "D:\8002 Assignment\manufacture_growth_trends_final_export.png", width(3200) height(2400) replace


****************************************************************
* STEP 12: Rolling Regression with Productivity as the Dependent Variable
* STEP 12.1: Set time series structure
tsset year

* Run rolling regression with a 12-year window
rolling ///
    b_wage = _b[log_real_wage] ///
    b_infl = _b[inflation] ///
    b_cons = _b[_cons], ///
    window(12) step(1) saving(rolling_prod_coeffs, replace): ///
    regress log_productivity log_real_wage inflation

* Load saved coefficients
use rolling_prod_coeffs, clear

* Generate midpoint year to anchor each regression
gen year = (start + end) / 2

* Plot the coefficients
twoway ///
    (line b_wage year, lcolor(red) lwidth(medium)) ///
    (line b_infl year, lcolor(green) lwidth(medium)), ///
    legend(order(1 "ln(Wage)" 2 "Inflation")) ///
    title("Structural Breaks in Manufacturing Sector (1990–2022)", size(medium)) ///
    ytitle("Coefficient Value") ///
    xtitle("Year") ///
    xscale(range(1990 2022)) ///
    ylabel(, grid) ///
    graphregion(color(white))

graph export "D:\8002 Assignment\1990_2022_rolling_productivity_coeffs.png", replace width(3200) height(2400)

***************************************************************
* STEP 13: Export Clean Data for External Analysis
***************************************************************
export delimited ///
    using "D:\8002 Assignment\1990_2022_manufacture_wage_productivity_inflation.csv", ///
    replace

***************************************************************


***************Part 3  All industries***************************

***************************************************************
* Real Wages, Productivity and Inflation in Australia (1990–2022)
* Fixed ARDL/ECM + Bounds + Diagnostics + Rolling Regression
***************************************************************

* STEP 0:  Import
import excel "D:\8002 Assignment\datasets.xlsx", sheet("extension2") firstrow clear

* STEP 1:  Rename & tsset
rename real_annual_wage_aud_constant_p real_wage
rename laborproductivityconstant_pric productivity
rename inflation_rate inflation

* STEP 1.5: Set time series structure
tsset year

* STEP 2: Create growth rate variables
gen productivity_growth = 100 * (D.productivity / L.productivity)
gen real_wage_growth = 100 * (D.real_wage / L.real_wage)


* STEP 4: Unit Root Tests (ADF)
display "=== ADF Unit Root Tests ==="
dfuller real_wage, lags(1) trend 
dfuller productivity, lags(1) trend 
dfuller inflation, lags(1) trend 

* STEP 4.1: Create log-transformed variables
gen log_productivity = log(productivity)
gen log_real_wage = log(real_wage)

* STEP 4.2: ADF Unit Root Tests on log-transformed variables
display "=== ADF Unit Root Tests on Log-Transformed Variables ==="
dfuller log_productivity, lags(1) trend 
dfuller log_real_wage, lags(1) trend 

* STEP 4.3: Test stationarity of first difference of log(real_wage)
gen d_log_real_wage = D.log_real_wage

display "=== ADF Unit Root Test on First Difference of log(real_wage) ==="
dfuller d_log_real_wage, lags(1) trend

* Generate first difference of log productivity
gen d_log_productivity = D.log_productivity

* ADF unit root test on differenced variable with 1 lag and trend
dfuller d_log_productivity, lags(1) trend  // Test stationarity after differencing


* STEP 5 (revised): ARDL Model with I(1) and I(0) variables
* --------------------------------------------------------------
* Using level variables: log_productivity (I(1)), log_real_wage (I(1)), inflation (I(0))
* Allows testing for long-run relationship (cointegration)

display "=== ARDL Model with Error Correction: log_productivity ~ log_real_wage + inflation ==="


* Estimate ARDL model (remove ec option since variables are stationary)
ardl log_productivity log_real_wage inflation, lags(1) ec1

* STEP 6: Bounds Test for Cointegration
estat ectest


* STEP 8: Diagnostic Tests
* --------------------------------------------------------------
* 8.1 Serial Correlation Test (Breusch-Godfrey)
estat bgodfrey, lags(1)  // Test for 1st-order autocorrelation

* 8.2 Heteroskedasticity Test (Breusch-Pagan)
estat hettest, iid      // Assume i.i.d. errors

* 8.3 Residual Normality Test (Jarque-Bera)
predict resid_ardl, resid  // Generate residuals
sktest resid_ardl         // Test for normality

* Skip not run STEP 9: Generate fitted values from the ARDL model

* Run the ARDL regression model
reg D.log_productivity L.log_productivity L.log_real_wage L.inflation D.log_real_wage D.inflation

* Generate fitted values for the dependent variable (D.log_productivity)
predict fitted_reg

* Plot the actual vs fitted growth rates
tsline D.log_productivity fitted_reg, ///
    legend(label(1 "Actual Growth (Δlog Productivity)") label(2 "Fitted Growth")) ///
    title("Actual vs Fitted Productivity Growth in All Industries(ARDL Model)",size(small)) ///
    ytitle("Annual % Change") ///
    xtitle("Year") ///
    xlabel(1990(2)2022, angle(90))

* Export the figure
graph export "D:\8002 Assignment\all_industries_productivity_growth_fitted_vs_actual.png", width(3200) height(2400) replace


* STEP 10: Granger Causality Test using VAR
* 10.1 Create first difference variables (if not already created)
gen d_inflation = D.inflation
* STEP 10.2: Check optimal lag length
varsoc d_log_productivity d_log_real_wage d_inflation

* STEP 10.3: Estimate VAR model (e.g., with lag 1)
var d_log_productivity d_log_real_wage d_inflation, lags(1)

* STEP 10.4: Granger causality test
vargranger


* STEP 11: Final Time Series Plot with markers (correct way)
twoway (connected productivity_growth year, lcolor(blue) lwidth(medium) msymbol(D) msize(vsmall)) ///
       (connected real_wage_growth year, lcolor(red) lwidth(medium) msymbol(square) msize(vsmall)) ///
       (connected inflation year, lcolor(green) lwidth(medium) msymbol(triangle) msize(vsmall)), ///
       legend(position(6) ring(0) cols(3) ///
              label(1 "Productivity Growth") ///
              label(2 "Real Wage Growth") ///
              label(3 "Inflation Rate")) ///
       title("Growth in Wage, Productivity & Inflation (All Industries, Australia) ", size(small)) ///
       ytitle("Annual % Change", size(small)) ///
       xtitle("Year", size(small)) ///
       xlabel(1990(2)2022, angle(90) labsize(small)) ///
       graphregion(color(white)) ///
       plotregion(margin(zero))

* Export high-resolution figure
graph export "D:\8002 Assignment\growth_trends_final_export.png", ///
    width(3200) height(2400) replace

	
***************************************************************
* STEP 12: Rolling Regression with Productivity as the Dependent Variable
***************************************************************

* Set the time series structure
tsset year

* Perform the rolling regression using correct variables (no log on inflation)
rolling b_wage = _b[log_real_wage] b_infl = _b[inflation] b_cons = _b[_cons], /// 
    window(12) step(1) saving(rolling_prod_coeffs, replace): /// 
    regress log_productivity log_real_wage inflation

* Load the rolling results and adjust the year
use rolling_prod_coeffs, clear
gen year = start + 5   // Midpoint of rolling window (because window=12)

* Plot the rolling coefficients
twoway /// 
    (line b_wage year, lcolor(red)) /// 
    (line b_infl year, lcolor(green)) /// 
    , /// 
    legend(order(1 "ln(Wage)" 2 "Inflation")) /// 
    title("Rolling Coefficients in All Industries in Australia (Dep: ln(Productivity))", size(small)) /// 
    ytitle("Elasticity") /// 
    xtitle("Year") /// 
    graphregion(color(white))

* Export the graph
graph export "D:\8002 Assignment\rolling_productivity_coeffs_in_All_Industries_in_Australia.png", width(3200) height(2400) replace

***************************************************************
* STEP 13: Export Clean Data for External Analysis (R / Python)
***************************************************************
export delimited using "D:\8002 Assignment\all_industries_wage_productivity_inflation.csv", replace

***************************************************************
* STEP 14: Close the log file
***************************************************************
log close