* Stata Tutorial 1: Working with Data
* Code from the ECO446 Quercus page of the same name.
* Generated from tutorial1.md by md2do.py; edit the page, not this file.

import delimited "https://raw.githubusercontent.com/smarteconomics/Econ446/main/tutorial/cpi-tutorial.csv", clear

describe
list in 1/10

browse

tabulate prov
tabulate category
summarize cpi
summarize cpi if prov == "NB" & category == "All-items"

gen month = monthly(ref_date, "YM")
format month %tm
list ref_date month in 1/3

list prov category cpi if month == tm(2016m7) & prov == "NB"

keep if category == "All-items"
count

gen lcpi = 100 * log(cpi)
label variable lcpi "100 x log CPI"

twoway line cpi month if prov == "NB", ///
    xline(`=tm(2016m7)') title("CPI, New Brunswick") ytitle("CPI (2002 = 100)")

twoway (line lcpi month if prov == "NB") (line lcpi month if prov == "NS") ///
    if inrange(month, tm(2014m1), tm(2018m12)), ///
    xline(`=tm(2016m7)') legend(order(1 "New Brunswick" 2 "Nova Scotia")) ///
    ytitle("100 x log CPI")

twoway line lcpi month if inrange(month, tm(2014m1), tm(2018m12)), ///
    by(prov) xline(`=tm(2016m7)')

bysort prov: egen base = max(cond(month == tm(2016m6), lcpi, .))
gen rel_lcpi = lcpi - base

preserve
keep if inrange(month, tm(2014m1), tm(2018m12)) & !inlist(prov, "NU", "YT", "NT")
gen nb = (prov == "NB")
collapse (mean) rel_lcpi, by(nb month)
twoway (line rel_lcpi month if nb == 1) (line rel_lcpi month if nb == 0), ///
    xline(`=tm(2016m7)') yline(0) legend(order(1 "New Brunswick" 2 "Other provinces")) ///
    ytitle("Percent change since June 2016")
graph export nb-vs-others.png, replace
restore

save cpi-allitems, replace
