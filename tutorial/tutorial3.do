* Stata Tutorial 3: Staggered Adoption, Synthetic Control and Synthetic DD
* Code from the ECO446 Quercus page of the same name.
* Generated from tutorial3.md by md2do.py; edit the page, not this file.

ssc install estout, replace
ssc install synth, replace
ssc install sdid, replace
net install ddplot, from("https://raw.githubusercontent.com/smarteconomics/Econ446/main/") replace

clear
set seed 446
set obs 50
gen id = _n
gen cohort = cond(id <= 20, 2006, cond(id <= 40, 2014, .))   // missing = never treated
expand 20
bysort id: gen year = 1999 + _n
gen post = !missing(cohort) & year >= cohort

* true effect: 1 in the first year of treatment, growing by 0.5 each year
gen effect = cond(post, 1 + 0.5 * (year - cohort), 0)
gen y = id / 10 + 0.2 * (year - 2000) + effect + rnormal(0, 0.5)

summarize effect if post
reg y post i.id i.year

local k = 3                                  // window: 3 years before and after
save simulated, replace
tempfile stacked
clear
save `stacked', emptyok

foreach r in 2006 2014 {
    use simulated, clear
    keep if inrange(year, `r' - `k', `r' + `k')
    keep if cohort == `r' | missing(cohort) | cohort > `r' + `k'
    gen event = `r'
    gen treat = (cohort == `r')
    gen rel = year - `r' + `k'               // 0, 1, ..., 2k: Stata factor variables cannot be negative
    append using `stacked'
    save `stacked', replace
}

forvalues j = 0/`=2*`k'' {
    label define rel `j' "`=`j'-`k''", add
}
label values rel rel
tabulate event treat

reg y i.treat##ib`=`k'-1'.rel i.id#i.event i.year#i.event
ddplot, treat(treat) year(rel) xtitle("Years relative to reform") ///
    title("Stacked DD, simulated data")

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
gen lcpi = 100 * log(cpi)
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

reg lcpi i.treat##ib`=`k'-1'.rel i.id#i.event i.month#i.event
ddplot, treat(treat) year(rel) xtitle("Months relative to HST increase") ///
    ytitle("Effect on prices (%)") title("Stacked DD: four HST increases") ///
    xlabel(0(3)21, valuelabel)
graph export stacked-hst.png, replace

use cpi-allitems, clear
drop if inlist(prov, "NS", "BC", "QC")
keep if inrange(month, tm(2008m7), tm(2012m6))
drop id
encode prov, gen(id)
gen treat = (prov == "ON")
gen post = (month >= tm(2010m7))

reg lcpi i.treat##ib`=tm(2010m6)'.month i.id
ddplot, treat(treat) year(month) ytitle("Effect on prices (%)") ///
    title("Ontario HST, dynamic DD")
graph export ontario-dynamic.png, replace

reg lcpi i.treat##i.post

tsset id month
summarize id if prov == "ON", meanonly
local on = r(min)
synth lcpi lcpi(`=tm(2008m7)') lcpi(`=tm(2009m1)') lcpi(`=tm(2009m7)') ///
    lcpi(`=tm(2010m1)') lcpi(`=tm(2010m6)'), ///
    trunit(`on') trperiod(`=tm(2010m7)') fig

gen treated = treat * post
sdid lcpi id month treated, vce(placebo) seed(446) graph

foreach m in did sc sdid {
    quietly sdid lcpi id month treated, vce(noinference) method(`m')
    display "`m'" _col(8) %6.2f e(ATT)
}
