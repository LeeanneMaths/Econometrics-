****************************************************
* Markov Chain Matrix
* Author: Leeanne
****************************************************
clear all
log using "Markov_Simple.log", replace text

* 1. Import Data
import excel "D:\Marko Chain Computation.xlsx", sheet("Sheet1") firstrow
encode Gender, gen(gid)
xtset gid Year

* 2. Calculate Transition Probabilities
by gid (Year): gen L1_prev = L.Level1Students
by gid (Year): gen L2_prev = L.Level2Students

gen p12   = Level2Students / L1_prev if L1_prev > 0
gen p23c  = Level3Calculus / L2_prev if L2_prev > 0  
gen p23o  = Level3NonCalculus / L2_prev if L2_prev > 0
gen p11   = 1 - p12
gen p24   = 1 - (p23c + p23o)

drop if missing(p12)

* 3. Calculate Average Transition Probabilities by Gender
collapse (mean) p11 p12 p23c p23o p24, by(Gender)

* 4. Display results
display "=== Final Results ==="
list
summarize p11 p12 p23c p23o p24

* 5. Build Markov Transition Matrix - NO MATA
forvalues i = 1/2 {
    display "======== Processing Row `i' ========"
    
    * Get values from current row
    scalar s11 = p11[`i']
    scalar s12 = p12[`i']
    scalar s23c = p23c[`i']
    scalar s23o = p23o[`i']
    scalar s24 = p24[`i']
    local g = Gender[`i']
    
    display "Gender: `g'"
    display "Transition probabilities:"
    display "p11 = " s11
    display "p12 = " s12
    display "p23c = " s23c
    display "p23o = " s23o
    display "p24 = " s24
    
    * Build transition matrix
    matrix P = ( ///
        s11, s12, 0,    0,    0 \ ///
        0,   0,    s23c, s23o, s24 \ ///
        0,   0,    1,    0,    0 \ ///
        0,   0,    0,    1,    0 \ ///
        0,   0,    0,    0,    1 )
    
    display "Transition Matrix P for `g':"
    matrix list P, format(%6.4f)
    display ""
}

log close