* Stata Tutorial 3: Staggered Adoption and Synthetic Control
* Code from the ECO446 Quercus page of the same name.
* Generated from tutorial3.md by md2do.py; edit the page, not this file.

ssc install estout, replace
ssc install synth, replace
net install ddplot, from("https://raw.githubusercontent.com/smarteconomics/Econ446/main/") replace

import delimited "https://raw.githubusercontent.com/smarteconomics/Econ446/main/tutorial/staggered-sim.csv", clear
describe

summarize effect if post
reg y post i.id i.year

reg y post i.id i.year if year < 2014
reg y post i.id i.year if year >= 2006

gen early = (cohort == 2006)
reg y i.early##ib2005.year i.id if year < 2014
ddplot, treat(early) year(year) ytitle("Estimated effect") title("Early cohort vs. not-yet-treated late cohort")

clear
input str2 prov str7 change
NS 2010-07
ON 2010-07
BC 2010-07
QC 2011-01
QC 2012-01
QC 2013-01
BC 2013-04
PE 2013-04
MB 2013-07
NB 2016-07
NL 2016-07
PE 2016-10
SK 2017-04
MB 2019-07
end
gen change_month = monthly(change, "YM")
format change_month %tm
save taxchanges, replace

import delimited "https://raw.githubusercontent.com/smarteconomics/Econ446/main/tutorial/cpi-tutorial.csv", clear
keep if category == "All-items"
gen month = monthly(ref_date, "YM")
format month %tm
drop if inlist(prov, "YT", "NT", "NU")
encode prov, gen(id)
save cpi-allitems, replace

local k = 12
tempfile stacked
clear
save `stacked', emptyok
local e = 0
foreach ev in NS:2010-07 NB:2016-07 NL:2016-07 PE:2016-10 {
    local ++e
    local p = substr("`ev'", 1, 2)
    local r = monthly(substr("`ev'", 4, 7), "YM")

    * provinces with a sales tax change in the window are not clean controls
    use taxchanges, clear
    keep if inrange(change_month, `r' - `k', `r' + `k')
    levelsof prov, local(notclean) clean

    use cpi-allitems, clear
    keep if inrange(month, `r' - `k', `r' + `k' - 1)
    foreach c of local notclean {
        drop if prov == "`c'" & prov != "`p'"
    }
    gen event = `e'
    gen treat = (prov == "`p'")
    gen rel = month - `r' + `k'
    append using `stacked'
    save `stacked', replace
}

forvalues j = 0/`=2*`k'-1' {
    label define rel `j' "`=`j'-`k''", add
}
label values rel rel
tabulate prov event

reg cpi i.treat##ib11.rel i.id#i.event i.month#i.event
ddplot, treat(treat) year(rel) xtitle("Months relative to HST increase") ytitle("Effect on CPI (index points)") title("Stacked DD: four HST increases") xlabel(0(3)21, valuelabel)
graph export stacked-hst.png, replace

import delimited "https://raw.githubusercontent.com/smarteconomics/Econ446/main/tutorial/cpi-tutorial.csv", clear
keep if category == "Household"
gen month = monthly(ref_date, "YM")
format month %tm
keep if inrange(month, tm(2004m11), tm(2008m10))
drop if inlist(prov, "YT", "NT", "NU")
separate cpi, by(prov) veryshortlabel
twoway line cpi1-cpi10 month, xline(`=tm(2006m11)') legend(pos(6) cols(5)) ytitle("CPI (2002 = 100)")

gen treat = (prov == "SK")
gen post = (month >= tm(2006m11))
foreach c in AB BC MB ON {
    quietly reg cpi i.treat##i.post if inlist(prov, "SK", "`c'") & inrange(month, tm(2005m11), tm(2007m10))
    display "Control group `c':" _col(25) %6.2f _b[1.treat#1.post]
}
quietly reg cpi i.treat##i.post if inrange(month, tm(2005m11), tm(2007m10))
display "All other provinces:" _col(25) %6.2f _b[1.treat#1.post]

encode prov, gen(id)
tsset id month
summarize id if prov == "SK", meanonly
local sk = r(min)
synth cpi cpi(`=tm(2005m1)') cpi(`=tm(2005m7)') cpi(`=tm(2006m1)') cpi(`=tm(2006m4)') cpi(`=tm(2006m7)') cpi(`=tm(2006m10)'), trunit(`sk') trperiod(`=tm(2006m11)') keep(synth-sk) replace

preserve
use synth-sk, clear
format _time %tm
twoway (line _Y_treated _time) (line _Y_synthetic _time, lpattern(dash)), xline(`=tm(2006m11)') legend(order(1 "Saskatchewan" 2 "Synthetic Saskatchewan") pos(6)) ytitle("CPI (2002 = 100)") xtitle("")
restore
