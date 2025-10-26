//lunch log file
log using assignment.log, replace

//a
summarize
histogram dfridge, title( "dfridge") bin(40) color(black)
histogram dwlfp , title( "dwlfp ") bin(40) color(black)



//b
regress dfridge dwlfp, vce(robust)
regress dfridge dwlfp xcentroid ycentroid ruggedness pfarm40 pblack40 powoc40 avgedu40, vce(robust)

//c
regress dwlfp z1, vce(robust)
regress dwlfp z1 xcentroid ycentroid ruggedness pfarm40 pblack40 powoc40 avgedu40, vce(robust)

//d
regress dfridge z1, vce(robust)
regress dfridge z1 xcentroid ycentroid ruggedness pfarm40 pblack40 powoc40 avgedu40, vce(robust)


//e
ivregress 2sls dfridge (dwlfp = z1), vce(cluster stateicp)

ivregress 2sls dfridge (dwlfp = z1) xcentroid ycentroid ruggedness pfarm40 pblack40 powoc40 avgedu40, vce(cluster stateicp)
estat first

//f
matrix results = J(5, 7, .)
local controls "xcentroid ycentroid ruggedness pfarm40 pblack40 powoc40 avgedu40"
local i = 1
foreach var of local controls {
    reg `var' z1 i.stateicp if e(sample), vce(cluster stateicp)
    matrix results[1, `i'] = _b[z1]
    matrix results[2, `i'] = _se[z1]
    summarize `var', detail
    matrix results[3, `i'] = r(mean)
    matrix results[4, `i'] = r(sd)
    matrix results[5, `i'] = r(N)
    local i = `i' + 1
}
matrix list results

//g
gen z2 = warfactory * pcasualty
label variable z2 "Instrument: warfactory * pcasualty"

ivregress 2sls dwlfp (dfridge = z2), vce(cluster stateicp)
ivregress 2sls dfridge (dwlfp = z2) xcentroid ycentroid ruggedness pfarm40 pblack40 powoc40 avgedu40, vce(cluster stateicp)

//logfile close
log using logfile.log, replace
