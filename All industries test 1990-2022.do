***************************************************************
* Real Wages, Productivity and Inflation in Australia (1990–2023)
* Fixed ARDL/ECM + Bounds + Diagnostics + Rolling Regression
***************************************************************

clear all
capture log close
set more off

* STEP 0:  Import
import excel "D:\new_EMET 8002 Research Report\all industries data.xlsx", ///
    sheet("Sheet1") firstrow

* STEP 1:  Rename & tsset
rename real_annual_wage_aud_constant_p real_wage
rename laborproductivityconstant_pric productivity
rename inflation_rate inflation

* STEP 1.5: Set time series structure
tsset year

* STEP 2: Create growth rate variables
gen productivity_growth = 100 * (D.productivity / L.productivity)
gen real_wage_growth = 100 * (D.real_wage / L.real_wage)

* STEP 3: Start logging
log using "all_industries_real_wage_productivity_inflation_analysis.log", replace text

* STEP 4: Unit Root Tests (ADF)
display "=== ADF Unit Root Tests ==="
dfuller real_wage, lags(1)
dfuller productivity, lags(1)
dfuller inflation, lags(1)

* STEP 4.1: Create log-transformed variables
gen log_productivity = log(productivity)
gen log_real_wage = log(real_wage)

* STEP 4.2: ADF Unit Root Tests on log-transformed variables
display "=== ADF Unit Root Tests on Log-Transformed Variables ==="
dfuller log_productivity, lags(1)
dfuller log_real_wage, lags(1)

* STEP 4.3: Test stationarity of first difference of log(real_wage)
gen d_log_real_wage = D.log_real_wage

display "=== ADF Unit Root Test on First Difference of log(real_wage) ==="
dfuller d_log_real_wage, lags(1)

* STEP 5 (revised): ARDL Model with log_productivity as dependent variable
display "=== ARDL Model with Error Correction: log_productivity ~ log_real_wage + inflation ==="
ardl log_productivity log_real_wage inflation, lags(1) ec1

* STEP 6: Bounds Test for Cointegration
estat ectest


*STEP 8 ：Diagnostic Tests
*8.1 Serial Correlation (Breusch-Godfrey test), Test for autocorrelation in residuals
estat bgodfrey


*8.2 Heteroskedasticity (Breusch-Pagan/Cook-Weisberg test), Test for heteroskedasticity
estat hettest

*8.3 Normality of Residuals (Jarque-Bera test),Test for normality
predict resid_ardl, resid
sktest resid_ardl

* STEP 9: Generate fitted values from the ARDL model

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
graph export "D:\new_EMET 8002 Research Report\all_industries_productivity_growth_fitted_vs_actual.png", width(3200) height(2400) replace


* STEP 10: Granger Causality Test using VAR
* 10.1 Create first difference variables (if not already created)
gen d_log_productivity = D.log_productivity
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
graph export "D:\new_EMET 8002 Research Report\growth_trends_final_export.png", ///
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
graph export "rolling_productivity_coeffs_in_All_Industries_in_Australia.png", width(3200) height(2400) replace

***************************************************************
* STEP 13: Export Clean Data for External Analysis (R / Python)
***************************************************************
export delimited using "all_industries_wage_productivity_inflation.csv", replace

***************************************************************
* STEP 14: Close the log file
***************************************************************
log close
