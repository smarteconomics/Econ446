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
drop if inlist(prov, "YT", "NT", "NU")
count

twoway line cpi month if prov == "NB", xline(`=tm(2016m7)') title("CPI, New Brunswick") ytitle("CPI (2002 = 100)")

twoway (line cpi month if prov == "NB") (line cpi month if prov == "NS") if inrange(month, tm(2014m1), tm(2018m12)), xline(`=tm(2016m7)') legend(order(1 "New Brunswick" 2 "Nova Scotia")) ytitle("CPI (2002 = 100)")

separate cpi, by(prov) veryshortlabel
describe cpi*

twoway line cpi1-cpi10 month if inrange(month, tm(2014m1), tm(2018m12)), xline(`=tm(2016m7)') legend(pos(6) cols(5))

bysort prov: egen base = max(cond(month == tm(2016m6), cpi, .))
gen rel_cpi = cpi - base

preserve
keep if inrange(month, tm(2014m1), tm(2018m12))
gen nb = (prov == "NB")
collapse (mean) rel_cpi, by(nb month)
twoway (line rel_cpi month if nb == 1) (line rel_cpi month if nb == 0), xline(`=tm(2016m7)') yline(0) legend(order(1 "New Brunswick" 2 "Other provinces")) ytitle("Change in CPI since June 2016 (index points)")
graph export nb-vs-others.png, replace
restore

save cpi-allitems, replace
