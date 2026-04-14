* test-stata.do

* A script to test if stata is installed and working correctly.

clear all
set obs 150

* set seed for reproducibility
set seed 12345

* -------------------------------------------------------
* 1. Generate data
* -------------------------------------------------------
gen id = _n

* Three groups with different intercepts
gen group = mod(id - 1, 3) + 1
label define grp 1 "Group A" 2 "Group B" 3 "Group C"
label values group grp

* x varies by group (different means)
gen x = rnormal(8 + 2 * group, 2)

* Quadratic DGP with group-specific intercept shift and interaction
gen group_shift = cond(group == 1, 0, cond(group == 2, 5, 10))
gen y = 2 + 1.5 * x - 0.06 * x^2 + group_shift ///
        + 0.3 * x * (group == 3) + rnormal(0, 1.5)

label variable x "Covariate (x)"
label variable y "Outcome (y)"
label variable group "Group"

* -------------------------------------------------------
* 2. Summary statistics
* -------------------------------------------------------
tabstat x y, by(group) statistics(n mean sd min max) ///
    format(%6.2f) longstub

* -------------------------------------------------------
* 3. Regression: quadratic + group FE + interaction
* -------------------------------------------------------
gen x2 = x^2
label variable x2 "x squared"

regress y c.x##i.group c.x2 , vce(robust)

* Predicted values for scatter overlay
predict yhat, xb

* -------------------------------------------------------
* 4. Figure 1 — Scatter with quadratic fitted lines by group
* -------------------------------------------------------
twoway ///
    (scatter y x if group == 1, mcolor(navy%60)    msymbol(circle)   msize(small)) ///
    (scatter y x if group == 2, mcolor(maroon%60)  msymbol(square)   msize(small)) ///
    (scatter y x if group == 3, mcolor(forest_g%60) msymbol(triangle) msize(small)) ///
    (qfit    y x if group == 1, lcolor(navy)    lwidth(medthick)) ///
    (qfit    y x if group == 2, lcolor(maroon)  lwidth(medthick)) ///
    (qfit    y x if group == 3, lcolor(forest_g) lwidth(medthick)), ///
    legend(order(1 "Group A" 2 "Group B" 3 "Group C") ///
           rows(1) position(6)) ///
    title("Quadratic Fit by Group") ///
    xtitle("x") ytitle("y") ///
    graphregion(color(white)) ///
    name(fig_scatter, replace)

* -------------------------------------------------------
* 5. Figure 2 — Group-wise box plots
* -------------------------------------------------------
graph box y, over(group, label(labsize(small))) ///
    box(1, fcolor(navy%50)    lcolor(navy)) ///
    box(2, fcolor(maroon%50)  lcolor(maroon)) ///
    box(3, fcolor(forest_g%50) lcolor(forest_g)) ///
    medtype(line) medline(lwidth(thick)) ///
    title("Distribution of y by Group") ///
    ytitle("y") ///
    graphregion(color(white)) ///
    name(fig_box, replace)

* -------------------------------------------------------
* 6. Figure 3 — Overlaid kernel density plots by group
* -------------------------------------------------------
twoway ///
    (kdensity y if group == 1, lcolor(navy)    lwidth(medthick) lpattern(solid)) ///
    (kdensity y if group == 2, lcolor(maroon)  lwidth(medthick) lpattern(dash)) ///
    (kdensity y if group == 3, lcolor(forest_g) lwidth(medthick) lpattern(longdash)), ///
    legend(order(1 "Group A" 2 "Group B" 3 "Group C") ///
           rows(1) position(6)) ///
    title("Kernel Density of y by Group") ///
    xtitle("y") ytitle("Density") ///
    graphregion(color(white)) ///
    name(fig_density, replace)
