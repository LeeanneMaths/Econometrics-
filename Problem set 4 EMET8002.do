clear all

//Question 1

//(a)

import delimited "D:\stata\week6_data.csv", clear 

//(b)

tsset year

//(c)

describe

//Plot for the United States
twoway (line pop_us year, yaxis(1) title("Population of the United States")) ///
       (line gdp_us year, yaxis(2) title("GDP of the United States")), ///
       ytitle("Population", axis(1)) ///
       ytitle("GDP", axis(2)) ///
       legend(label(1 "Population") label(2 "GDP"))



//Plot for Australia
twoway (line pop_au year, yaxis(1) title("Population of Australia")) ///
       (line gdp_au year, yaxis(2) title("GDP of Australia")), ///
       ytitle("Population", axis(1)) ///
       ytitle("GDP", axis(2)) ///
       legend(label(1 "Population") label(2 "GDP"))
	   
//From the plots, there seems to be a clear positive relationship between population and GDP in both the United States and Australia.

//(d)

//regression for the United States
reg gdp_us pop_us,robust
//Coefficient: 145413.4 implies that for every additional person in the population, GDP increases by approximately 145,413 USD.The p-value is 0.000, indicating that the population coefficient is statistically significant at conventional levels.
//Spurious Regression Explanation: Given that both GDP and population data are likely non-stationary (trending upwards over time without returning to a mean), the relationship observed in the regression could be spurious. This means that the strong correlation might not solely be due to a direct economic relationship between population growth and GDP but might also reflect the fact that both series are driven upward over time by other factors, such as technological progress, inflation, and increased economic efficiency.

//regression for the Australia
reg gdp_au pop_au,robust
//Coefficient: 108542.2 implies that for every additional person in the population, GDP increases by approximately 108542 AUD.The p-value is 0.000, indicating that the population coefficient is statistically significant at conventional levels.
//Spurious Regression Explanation: As with the U.S., the potential for a spurious relationship exists due to the non-stationary nature of GDP and population data. The positive and significant results may partially be a consequence of both variables sharing a common upward trend across the observed period, which might be influenced by similar broader economic and demographic trends rather than a direct causal relationship.

//(e)
//Persistence, also known as autocorrelation, is a statistical property of time series data where current values in the series are correlated with past values. In simpler terms, it means that future values of a series can be predicted from past values.
//All four time-series data sets exhibit persistence (autocorrelation). This is evident from their gradual and predictable changes over time, rather than random or highly volatile movements. Each data series carries forward its past trends into the future, which is a hallmark of autocorrelated or persistent data.

//(f)
gen D_gdp_us = D.gdp_us
gen D_pop_us = D.pop_us
gen D_gdp_au = D.gdp_au
gen D_pop_au = D.pop_au

*Plot for the United States
twoway (line D_pop_us year, title("First Differences in Population of the United States")) ///
       (line D_gdp_us year, yaxis(2)), ///
       legend(label(1 "Population Change") label(2 "GDP Change")) ///
       ytitle("Population Change", axis(1)) ///
       ytitle("GDP Change", axis(2))

*Plot for Australia
twoway (line D_pop_au year, title("First Differences in Population of Australia")) ///
       (line D_gdp_au year, yaxis(2)), ///
       legend(label(1 "Population Change") label(2 "GDP Change")) ///
       ytitle("Population Change", axis(1)) ///
       ytitle("GDP Change", axis(2))
	   
*Regression for the United States
reg D_gdp_us D_pop_us,robust

*Regression for Australia
reg D_gdp_au D_pop_au,robust

//1. Do the variables still look related?
*United States: The variables appear to still have a relationship, although it is negatively correlated, which might be counterintuitive. The significant negative coefficient suggests that there is a relationship where changes in population are associated with opposite changes in GDP, indicating an inverse relationship in the context of year-to-year changes.

*Australia: In contrast, for Australia, the variables do not appear to be related based on the regression results. The very low R-squared value and the statistically insignificant coefficient for population change indicate that there is no clear or meaningful relationship between year-to-year changes in population and changes in GDP.
//2. Is the `population' coefficient still significant?
*United States: Yes, the population coefficient for the United States is still significant, with a p-value of 0.000. This significance indicates that population changes do have a statistically noticeable impact on GDP changes, even though the direction of this impact is negative.

*Australia: No, the population coefficient for Australia is not significant, with a p-value of 0.903. This lack of significance suggests that changes in the population do not have a detectable impact on GDP changes in the statistical model, at least within the limitations of the yearly data used.

//3. Do you still find evidence of persistence (autocorrelation)?
*United States and Australia: First differencing generally reduces autocorrelation in a time series by focusing on the changes between periods rather than the levels. This can break down any persistent patterns that exist when the data is in levels. Given the fluctuation and variability seen in the plots of the first-differenced data, it is likely that autocorrelation is reduced. However, without formal statistical testing, it's difficult to conclusively say whether evidence of persistence (autocorrelation) remains significant. Observationally, the variability and inconsistency in year-to-year changes suggest less persistence in the differenced series compared to the original levels.

//(g)

* Calculate the natural logarithms
gen ln_gdp_us = log(gdp_us)
gen ln_pop_us = log(pop_us)
gen ln_gdp_au = log(gdp_au)
gen ln_pop_au = log(pop_au)

* Generate first differences of the logged series
gen D_ln_gdp_us = D.ln_gdp_us
gen D_ln_pop_us = D.ln_pop_us
gen D_ln_gdp_au = D.ln_gdp_au
gen D_ln_pop_au = D.ln_pop_au

* Plot for the United States
twoway (line D_ln_pop_us year, title("First Differences of Log Population in the US")) ///
       (line D_ln_gdp_us year, yaxis(2)), ///
       legend(label(1 "Log Population Change") label(2 "Log GDP Change")) ///
       ytitle("Change in Log Population", axis(1)) ///
       ytitle("Change in Log GDP", axis(2))

* Plot for Australia
twoway (line D_ln_pop_au year, title("First Differences of Log Population in Australia")) ///
       (line D_ln_gdp_au year, yaxis(2)), ///
       legend(label(1 "Log Population Change") label(2 "Log GDP Change")) ///
       ytitle("Change in Log Population", axis(1)) ///
       ytitle("Change in Log GDP", axis(2))

// The visual data suggests that there isn't a consistent relationship between the changes in log-transformed population and GDP data for both countries. The variables do not exhibit a clear or predictable pattern that would suggest they are related in the first-differenced log format.

* Regression for the United States
reg D_ln_gdp_us D_ln_pop_us,robust

* Regression for Australia
reg D_ln_gdp_au D_ln_pop_au,robust

//In both countries, the population coefficient is not significant, suggesting that, in the context of year-to-year logarithmic growth rates, population changes do not significantly influence GDP changes. This could indicate that other factors, possibly omitted from this model, play a more crucial role in determining GDP fluctuations.  

//  Based on the transformations applied (first differences of logs) and the nature of the results (low R-squared and non-significant coefficients), it's likely that persistence or autocorrelation has been reduced in these series, aligning with the intended effect of these transformations to mitigate spurious regression issues and autocorrelation in the original data.

//(h)

* Regress population on year
reg pop_us year

* Store the residuals (detrended population)
predict resid_pop_us, resid

* Regress GDP on year
reg gdp_us year

* Store the residuals (detrended GDP)
predict resid_gdp_us, resid

* Plot detrended population
twoway (line resid_pop_us year, title("Detrended Population in the US"))

* Plot detrended GDP
twoway (line resid_gdp_us year, title("Detrended GDP in the US"))

* Regression of detrended GDP on detrended population
reg resid_gdp_us resid_pop_us, robust 

//The coefficient for the detrended population (resid_pop_us) is significantly positive, with a p-value of 0.000. This indicates a strong statistical significance, suggesting that changes in population, after removing the linear trend due to time, have a significant impact on changes in GDP.

//Detrended Relationship: The significant relationship found between the detrended variables suggests that there are dynamics between population and GDP that are not merely due to overall time trends or growth that could be attributed to other factors progressing linearly over time.

// (i) 

gen D_resid_gdp_us = D.resid_gdp_us  // first difference of gdp residuals
gen D_resid_pop_us = D.resid_pop_us  // first difference of population residuals

twoway (line D_resid_gdp_us year, title("Detrended & Differenced GDP (US)"))
twoway (line D_resid_pop_us year, title("Detrended & Differenced Population (US)"))

reg D_resid_gdp_us D_resid_pop_us, robust

//(j)

// Robust regression of US GDP on Australian population
reg gdp_us pop_au, robust
//Regular Regression: In the initial regression of U.S. GDP on Australian population, the 'population' coefficient is highly significant (p-value = 0.000). This might suggest a strong relationship between Australian population and U.S. GDP. However, given the economic independence of these variables, this relationship is likely spurious and may be due to non-stationarity in the time series data.

// Drop existing variables if they exist
capture drop D_gdp_us D_pop_au ln_gdp_us ln_pop_au

// Generate first differences
gen D_gdp_us = D.gdp_us
gen D_pop_au = D.pop_au

// Regression of first differences
reg D_gdp_us D_pop_au,robust
//Regression of First Differences: When the variables are transformed to their first differences, the 'population' coefficient becomes insignificant (p-value = 0.898). This change indicates that the initial significance might have been due to shared trends or other spurious factors, rather than a true causal relationship.

// Drop existing variables if they exist
capture drop ln_gdp_us ln_pop_au Dln_gdp_us Dln_pop_au

// Generate log-transformed variables
gen ln_gdp_us = log(gdp_us)
gen ln_pop_au = log(pop_au)

// Generate first differences of log-transformed variables
gen Dln_gdp_us = D.ln_gdp_us
gen Dln_pop_au = D.ln_pop_au

// Regression using growth rates
reg Dln_gdp_us Dln_pop_au, robust
//Regression using Growth Rates: Similarly, when analyzing the growth rates (logarithmic differences), the 'population' coefficient remains insignificant (p-value = 0.518), further supporting the idea that the initial apparent relationship was spurious.







