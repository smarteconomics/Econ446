* build-cpi.do: monthly CPI by province and major category, from StatCan Table 18-10-0004-01
clear all
set more off

* download the table only if we don't already have it (delete cpi.zip to refresh)
capture confirm file cpi.zip
if _rc {
    copy "https://www150.statcan.gc.ca/n1/tbl/csv/18100004-eng.zip" cpi.zip, replace
}
unzipfile cpi.zip, replace
import delimited 18100004.csv, clear varnames(1) encoding(utf8) stringcols(_all)
describe, short

rename productsandproductgroups product
keep if uom == "2002=100"
keep if substr(ref_date, 1, 4) >= "2005"

* geography: 10 provinces + 3 territorial capitals (no territorial sales tax)
gen prov = ""
replace prov = "NL" if geo == "Newfoundland and Labrador"
replace prov = "PE" if geo == "Prince Edward Island"
replace prov = "NS" if geo == "Nova Scotia"
replace prov = "NB" if geo == "New Brunswick"
replace prov = "QC" if geo == "Quebec"
replace prov = "ON" if geo == "Ontario"
replace prov = "MB" if geo == "Manitoba"
replace prov = "SK" if geo == "Saskatchewan"
replace prov = "AB" if geo == "Alberta"
replace prov = "BC" if geo == "British Columbia"
replace prov = "YT" if geo == "Whitehorse, Yukon"
replace prov = "NT" if geo == "Yellowknife, Northwest Territories"
replace prov = "NU" if geo == "Iqaluit, Nunavut"
keep if prov != ""

* major categories, with short names
gen category = ""
replace category = "All-items"  if product == "All-items"
replace category = "Goods"      if product == "Goods"
replace category = "Services"   if product == "Services"
replace category = "Food"       if product == "Food"
replace category = "Shelter"    if product == "Shelter"
replace category = "Household"  if product == "Household operations, furnishings and equipment"
replace category = "Clothing"   if product == "Clothing and footwear"
replace category = "Transport"  if product == "Transportation"
replace category = "Health"     if product == "Health and personal care"
replace category = "Recreation" if product == "Recreation, education and reading"
replace category = "Alcohol and tobacco" if product == "Alcoholic beverages, tobacco products and recreational cannabis"
keep if category != ""

destring value, gen(cpi)
keep ref_date geo prov category cpi
order ref_date prov geo category cpi
sort prov category ref_date
count
tab prov
tab category
export delimited using cpi-tutorial.csv, replace
