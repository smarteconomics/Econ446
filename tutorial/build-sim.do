* build-sim.do: simulated staggered-adoption data for Stata Tutorial 3
*
* 20 units observed 2000-2019. Units 1-10 are treated in 2006 (early cohort),
* units 11-20 in 2014 (late cohort). No unit is never treated.
* The treatment effect is zero in the year of treatment and grows by 0.5 a year.

clear
set seed 446
set obs 20
gen id = _n
gen cohort = cond(id <= 10, 2006, 2014)
expand 20
bysort id: gen year = 1999 + _n

gen post = (year >= cohort)
gen effect = cond(post, 0.5 * (year - cohort), 0)

* outcome = unit effect + common trend + treatment effect + noise
gen double y = round(id / 5 + 0.2 * (year - 2000) + effect + rnormal(0, 0.1), 0.001)
format y %9.3f

sort id year
export delimited id cohort year post effect y using staggered-sim.csv, replace

* --------------------------------------------------------------------------
* Figure for Tutorial 3: true effects, and the forbidden comparison
* Late cohort (treated 2014) vs early cohort (already treated), 2006-2019:
*   late cohort:  average effect 0 (2006-13) -> 1.25 (2014-19): change +1.25
*   early cohort: average effect 1.75        -> 5.25:           change +3.50
*   forbidden DD = 1.25 - 3.50 = -2.25
* --------------------------------------------------------------------------
preserve
collapse (mean) effect, by(cohort year)
separate effect, by(cohort) veryshortlabel

twoway (scatteri 7.4 2005.5 7.4 2013.5, recast(area) color(gs15)) (scatteri 7.4 2013.5 7.4 2019.5, recast(area) color(gs13)) (line effect2006 year, lcolor(navy) lwidth(thick)) (line effect2014 year, lcolor(maroon) lwidth(thick)) (scatteri 1.75 2006 1.75 2013, recast(line) lcolor(navy) lpattern(dash)) (scatteri 5.25 2014 5.25 2019, recast(line) lcolor(navy) lpattern(dash)) (scatteri 0.08 2006 0.08 2013, recast(line) lcolor(maroon) lpattern(dash)) (scatteri 1.25 2014 1.25 2019, recast(line) lcolor(maroon) lpattern(dash)), xline(2006 2014, lcolor(gs8)) xlabel(2000(2)2018) ylabel(0(1)7) yscale(range(0 7.4)) ytitle("True treatment effect") xtitle("") text(7.1 2009.5 "Before: 2006-2013", size(small)) text(7.1 2016.5 "After: 2014-2019", size(small)) text(2.1 2006.2 "early cohort: 1.75", color(navy) size(small) placement(e)) text(5.9 2014.2 "early cohort: 5.25", color(navy) size(small) placement(e)) text(0.45 2009.5 "late cohort: 0", color(maroon) size(small)) text(1.95 2014.2 "late cohort: 1.25", color(maroon) size(small) placement(e)) legend(order(3 "Early cohort (treated 2006)" 4 "Late cohort (treated 2014)") pos(6) cols(2)) note("Dashed lines: average true effect in each period." "Forbidden DD for the late cohort = (1.25 - 0) - (5.25 - 1.75) = 1.25 - 3.50 = -2.25")
graph export forbidden-comparison.png, width(1400) replace
restore
