************* EMET 8002 Problem Set 6********

// ====================================================
clear all               // clear memory
capture log close       // close any open log files
set more off            // don't pause when screen fills



// create a new log-file to save code and output
log using problem_set_6.log, replace    

/************************************************/
/* Q1.a: Import and prepare date variable       */
/************************************************/

clear all
cd "D:\EMET 8002 Problem set 6"   
import delimited "D:\EMET 8002 Problem set 6\49_Industry_Portfolios_Daily.CSV", ///
    rowrange(10:24547) varnames(10) delimiters(",") clear
compress

// Convert the first column (v1) to readable date format
rename v1 raw_date
tostring raw_date, gen(date_str)
gen date = daily(date_str, "YMD")
format date %td
order date, first

/************************************************/
/* Q1.b1: Select and rename target variables    */
/************************************************/

rename agric        returns_agric
rename food         returns_food
rename books        returns_books
rename autos        returns_autos

/************************************************/
/* Q1.b2: Generate dummy variables for 3 events */
/************************************************/

gen gfc = inrange(date, td(15sep2008), td(31mar2009))
gen ww2 = inrange(date, td(01sep1939), td(02sep1945))
gen greatdep = inrange(date, td(24oct1929), td(31mar1933))

/************************************************/
/* Q1.b3: Keep relevant variables               */
/************************************************/

keep date returns_agric returns_food returns_books returns_autos gfc ww2 greatdep

/************************************************/
/* Q1.b4: Reshape data from wide to long format */
/************************************************/

gen obs_id = _n   // use obs number as unique ID for reshaping
reshape long returns_, i(obs_id) j(industry) string
sort industry date

/************************************************/
/* Q1.c: Declare panel structure using xtset    */
/************************************************/

egen industry_id = group(industry)   // convert string to numeric
xtset industry_id date, daily

/************************************************/
/* Q1.d: Run pooled regression                  */
/************************************************/

reg returns_ greatdep ww2 gfc, vce(robust)
//In the pooled regression, the coefficient on greatdep is –0.142 and statistically significant at the 1% level (p = 0.002). This indicates that stock returns were significantly lower during the Great Depression.
//The gfc dummy is negative (–0.353) and marginally significant at the 5% level (p = 0.051), suggesting a possible decline in returns during the Global Financial Crisis, although the evidence is less conclusive.
//For ww2, the coefficient is positive (0.021) but statistically insignificant (p = 0.220), implying that returns during World War II were not significantly different from normal periods.
//Overall, the results suggest that the Great Depression had the most pronounced and robust effect on returns, followed by weaker evidence for the GFC and no clear impact during WW2.


/************************************************/
/* Q1.e: Add industry fixed effects             */
/************************************************/

xtreg returns_ greatdep ww2 gfc, fe vce(robust)
//Adding fixed effects via xtreg allows us to control for unobserved heterogeneity across industries. The coefficient for greatdep remains –0.142, still significant (p = 0.013), reinforcing that the Depression led to a significant drop in stock returns even after controlling for industry-specific effects.
//The gfc effect becomes more statistically significant (p = 0.033), with a similar coefficient (–0.353), indicating stronger support for a negative return effect during the crisis when accounting for industry-level variation.
//The ww2 dummy remains statistically insignificant (p = 0.405), suggesting little evidence of a return shift during wartime, consistent with the pooled results.
//The high F-statistic and strong joint significance (Prob > F = 0.0000) confirm that the dummy variables explain a meaningful share of variation across industries.



/***************************************************/
/* Question 2: Panel Data Techniques               */
/***************************************************/

/* Q2.a: Set panel structure using xtset */
use "D:\EMET 8002 Problem set 6\wagepan.dta", clear
xtset nr year

/* Q2.b: Visual comparison using histograms */

* Save first histogram
hist lwage if year == 1980, percent width(0.2) ///
    title("Log Wage: 1980") xtitle("") saving(hist1980, replace)

* Save second histogram
hist lwage if year == 1987, percent width(0.2) ///
    title("Log Wage: 1987") xtitle("") saving(hist1987, replace)

* Combine both into one graph
graph combine hist1980.gph hist1987.gph, ycommon xcommon ///
    title("Distribution of Log Wages: 1980 vs 1987")
//In the period between 1980 and 1987, the average log wage (lwage) increased notably from 1.3935 to 1.8665, indicating a substantial rise in real wages. This trend is also reflected in the distribution of log wages: the histogram for 1980 shows a wider spread with a concentration around lower wage levels, whereas the 1987 distribution shifts to the right, becoming more centered around higher values. This rightward shift suggests not only general wage growth but also a possible reduction in wage inequality at the lower end of the distribution. Overall, the descriptive statistics and visual comparison both point to significant improvements in earnings over the seven-year period.

/* Q2.c: Tabulate education */
tab educ
tab educ, summarize(lwage)

/* Q2.d: Panel regression and Hausman test */
* Estimate fixed effects
xtreg lwage exper expersq married, fe
estimates store fe_model

* Estimate random effects
xtreg lwage exper expersq married, re
estimates store re_model

* Perform Hausman test
hausman fe_model re_model
//We estimated both fixed and random effects models for lwage on exper, expersq, and married. The Hausman test strongly rejects the null (p < 0.001), indicating that the random effects assumptions are invalid. Therefore, the fixed effects model is preferred. It shows significant positive effects of experience and being married on wages, with diminishing returns to experience.

/* Q2.e: Add time fixed effects and test joint significance */
xtreg lwage exper expersq married i.year, fe
testparm i.year
//Based on the testparm output for time fixed effects, the joint test of the year dummies yields an F-statistic of 2.11 with a p-value of 0.0487. Since this is below the 5% significance level, we reject the null hypothesis that all year dummies are jointly equal to zero. This means the time fixed effects are statistically significant and should be included, as they help capture time-specific variation in log wages not explained by individual characteristics.

/* Q2.f: Include educ and reassess model */
* Add education to FE model (note: dropped if time-invariant)
xtreg lwage exper expersq married educ i.year, fe
estimates store fe_educ

* RE model with education
xtreg lwage exper expersq married educ i.year, re
estimates store re_educ

* Hausman test again
hausman fe_educ re_educ

* Breusch-Pagan LM test for RE vs OLS
xttest0

/* Optional: Advanced diagnostics */
ssc install xtcsd, replace
xtreg lwage exper expersq married i.year, fe
xtcsd, pesaran abs

ssc install xtscc, replace
xtscc lwage exper expersq married educ i.year, fe

ssc install xttest3, replace
xtreg lwage exper expersq married i.year, fe
xttest3

xtreg lwage exper expersq married i.year, fe robust

//After including "educ" in the panel regression, it was dropped from the fixed effects model due to time-invariance. The Hausman test comparing the fixed and random effects models was insignificant (p = 0.0998), implying no systematic difference between the two and favoring the random effects model. However, the Breusch-Pagan LM test (p = 0.0000) confirmed the presence of panel effects, supporting RE over OLS. Additional tests (xtcsd and xttest3) revealed cross-sectional dependence and heteroskedasticity, making Driscoll-Kraay standard errors in the FE model more robust. Thus, despite the Hausman result, the FE model with Driscoll-Kraay errors is preferred as it better handles the data's heteroskedasticity and dependence, and retains interpretability for policy-relevant variables like education via the RE model.

/* End of script */
log close

 