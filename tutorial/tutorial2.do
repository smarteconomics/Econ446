* Stata Tutorial 2: Difference-in-Differences
* Code from the ECO446 Quercus page of the same name.
* Generated from tutorial2.md by md2do.py; edit the page, not this file.

ssc install estout, replace
net install ddplot, from("https://raw.githubusercontent.com/smarteconomics/Econ446/main/") replace

import delimited "https://raw.githubusercontent.com/smarteconomics/Econ446/main/tutorial/cpi-tutorial.csv", clear
gen month = monthly(ref_date, "YM")
format month %tm
drop if inlist(prov, "YT", "NT", "NU")
save cpi-categories, replace

keep if category == "All-items"
drop if inlist(prov, "NL", "PE", "SK")
keep if inrange(month, tm(2015m7), tm(2017m6))
tabulate prov

gen treat = (prov == "NB")
gen post  = (month >= tm(2016m7))
encode prov, gen(id)

table treat post, statistic(mean cpi) nformat(%9.2f)

reg cpi i.treat##i.post

gen posttreat = treat * post
reg cpi posttreat i.id i.month

eststo clear
eststo: reg cpi i.treat##i.post
eststo: reg cpi posttreat i.id i.month
esttab, se keep(1.treat#1.post posttreat) label
esttab using dd-table.rtf, se keep(1.treat#1.post posttreat) label replace

reg cpi i.treat##ib`=tm(2016m6)'.month i.id

ddplot, treat(treat) year(month) ytitle("Effect on CPI (index points)") title("New Brunswick HST increase, July 2016")
graph export nb-dynamic.png, replace

use cpi-categories, clear
drop if inlist(prov, "NL", "PE", "SK")
keep if inrange(month, tm(2015m7), tm(2017m6))
gen treat = (prov == "NB")
gen post  = (month >= tm(2016m7))
encode prov, gen(id)

foreach c in "All-items" "Goods" "Services" "Food" "Clothing" "Alcohol and tobacco" {
    quietly reg cpi i.treat##i.post if category == "`c'"
    display "`c'" _col(25) %6.2f _b[1.treat#1.post]
}

reg cpi i.treat##ib`=tm(2016m6)'.month i.id if category == "Alcohol and tobacco"
ddplot, treat(treat) year(month) title("Alcohol and tobacco prices")
