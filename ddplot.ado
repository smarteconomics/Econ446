cap prog drop ddplot
prog ddplot, rclass

version 15
	
	syntax [, treat(varname) year(varname) frame(string) replace noLABel rspike XTItle(passthru) YTItle(passthru) TItle(passthru) SUBTItle(passthru) YLABel(passthru) XLABel(string asis) XLABELOPTS(string asis) YSCale(passthru) XSCale(passthru) note(passthru)]

	// set default names of treat and year variables
	if "`treat'" == "" local treat treat
	if "`year'"  == "" local year year

	// optionally use rspike instead of rarea for CIs
	local rarea rarea
	local cicolor color(gs12)
	if "`rspike'"!="" {
		local rarea rspike
		local cicolor color(gs4)
		}
	
	// save coefficients and CIs as new variables _dd_*
	qui for any year b se ub lb : cap drop _dd_X
	qui for any year b se ub lb : gen _dd_X=.
	local i = 1

	quietly levelsof `year' if e(sample), local(years)
	quietly foreach y of local years {
		capture local b = _b[1.`treat'#`y'.`year']
		if !_rc {
			di `i',`y',_b[1.`treat'#`y'.`year']
			// find the base period as that with a coefficient of zero
			if `b'==0 {
				di "Found the base year: `y'"
				local baseline=`y'+0.5
				}
			qui replace _dd_year = `y' in `i'
			qui replace _dd_b  = _b[1.`treat'#`y'.`year'] in `i'
			qui replace _dd_se = _se[1.`treat'#`y'.`year'] in `i'
			qui replace _dd_lb = _dd_b - invnormal(.975) * _dd_se in `i'
			qui replace _dd_ub = _dd_b + invnormal(.975) * _dd_se in `i'
			local ++i
			}
		else {
			di as error "Coefficient _b[1.`treat'#`y'.`year'] not found."
			di as error "Type 'help ddplot' for syntax help." 
			exit 111
			}
		}

	// preserve year value labels if they exist
	if "`label'"!="nolabel" {
		label values _dd_year `: value label `year''
		}

	// if xtitle not specified, suppress it entirely
	if "`xtitle'"=="" local xtitle xtitle("")

	// optionally save data in a frame
	if "`frame'"!="" {
		cap confirm new frame `frame'
		if _rc & "`replace'"!="replace" {
			di as error "Frame `frame' already exists; specify replace option also"
		}
		else {
			cap frame drop `frame'
			frame put _dd* if _dd_year!=., into(`frame')
			}
		}	
	
	
	local cmd ///
	  twoway ///
	  `rarea' _dd_ub _dd_lb _dd_year , `cicolor' || ///
	  conn  _dd_b _dd_year, color(black) lwidth(medthick) || ///
	  , xlab(`xlabel', `xlabelopts' valuelabel) xline(`baseline', lpattern(dash) lcolor(gs8)) ///
	  yline(0, lpattern(solid) lcolor(gs4)) legend(off) ///
	  `xtitle' `ytitle' `title' `subtitle' `ylabel' `yscale' `xscale' `note'

	di "`cmd'"
	`cmd'
	return local cmd=`"`cmd'"'
	
	
end

	

