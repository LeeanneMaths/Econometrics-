* This do-file converts PISA SPSS data files into Stata data files. It also 
* demonstrates how to merge school to each individual student.

* The PISA 2018 data have been downloaded from the following website:
* https://www.oecd.org/en/data/datasets/pisa-2018-database.html
* The same website also contains the questionnaires and other documentation.

* Import and save student data 
import spss using "CY07_MSU_STU_QQQ.sav", clear
save "PISA 2018 student data", replace

* Import and save school data
import spss using "CY07_MSU_SCH_QQQ.sav", clear
save "PISA 2018 school data", replace

* Merge student and school data
use "PISA 2018 student data", clear
merge m:1 CNTSCHID using "PISA 2018 school data"
save "PISA 2018 student and school data", replace

* Load PISA 2018 data
use "D:\EMET 8002 ONLINE QUIZ\Data for Online Quiz-20250601\PISA 2018 student and school data\PISA 2018 student and school data.dta", clear  // Update with your actual file path

* Open log file to record the session
log using "D:\EMET 8002 ONLINE QUIZ\PISA_Analysis.log", replace text

* Select B-S-J-Z China (QCI) and New Zealand (NZL) samples
keep if inlist(CNT, "QCI", "NZL")

* Verify country distribution
tab CNT

* Create reading time variable (using ST175Q01IA)
gen reading_time = ST175Q01IA
replace reading_time = . if reading_time > 5  // Handle missing values
label var reading_time "Reading time for enjoyment (1=None, 5=More than 2 hours)"

* Create gender variable
gen female = (ST004D01T == 1) if !missing(ST004D01T)
label var female "Female student"

* Verify variable distributions
sum reading_time female
tab reading_time
tab female

* Label parental education variables
label var MISCED "Mother's education (ISCED level)"
label var FISCED "Father's education (ISCED level)"

* Run regression models
eststo clear

// Model for B-S-J-Z China (QCI)
eststo china: reg reading_time MISCED FISCED female c.MISCED#i.female ///
    if CNT == "QCI", vce(robust)
    
// Model for New Zealand (NZL)
eststo nzl: reg reading_time MISCED FISCED female c.MISCED#i.female ///
    if CNT == "NZL", vce(robust)

* Export results to Word document
esttab china nzl using "PISA_Results.rtf", ///
    b(%9.3f) se(%9.3f) star(* 0.05 ** 0.01) ///
    mtitle("B-S-J-Z China" "New Zealand") ///
    coeflabels(MISCED "Mother's Education" ///
               FISCED "Father's Education" ///
               female "Female" ///
               1.female#c.MISCED "Mother Educ × Female" ///
               _cons "Constant") ///
    stats(N r2, fmt(%9.0f %9.3f)) ///
    title("Regression Results: Parental Education and Reading Time") ///
    addnotes(`"Note: B-S-J-Z China represents Beijing, Shanghai, Jiangsu, and Zhejiang"') ///
    replace
    
* Display model diagnostics
di "===== MODEL DIAGNOSTICS ====="

* Restore China model (robust) for regular output
est restore china
di "== Diagnostics for B-S-J-Z China =="

* Run regular OLS version (no robust) just for heteroskedasticity test
reg reading_time MISCED FISCED female c.MISCED#i.female if CNT == "QCI"
estat hettest, rhs

* Restore New Zealand model and run diagnostics
est restore nzl
di "== Diagnostics for New Zealand =="

* Run regular OLS version (no robust) just for heteroskedasticity test
reg reading_time MISCED FISCED female c.MISCED#i.female if CNT == "NZL"
estat hettest, rhs

* Re-run robust model if needed (optional, for vif to match main model)
reg reading_time MISCED FISCED female c.MISCED#i.female if CNT == "NZL", vce(robust)
vif    // Multicollinearity check for NZ

* Save dataset for verification
save "D:\EMET 8002 ONLINE QUIZ\PISA_China_NZ_Analysis.dta", replace

log close