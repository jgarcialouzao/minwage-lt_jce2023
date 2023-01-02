

foreach y in 2012 2010 {
use "${path}\data\sodra`y'.dta" , clear
*Generate job IDs and count working days, if work less than 30 days re-compute income
egen idjob = group(pid fid)
gen monthly = mofd(mdy(month,1,year))
format monthly %tm

gen emp_end_date1 = emp_end_date
replace emp_end_date = mdy(12,31,2020) if emp_end_date > mdy(12,31,2020)
format emp_end_date1  %td

gen first=dofm(monthly)
gen last=dofm(monthly + 1) - 1
gen 	days = .
replace days = emp_end_date1 - first + 1 if emp_start_date<=first & emp_end_date1<last
replace days = last - emp_start_date + 1  if emp_start_date>first & emp_end_date1>=last
replace days = emp_end_date1 - emp_start_date  + 1  if emp_start_date>first & emp_end_date1<last
replace days = 30 if emp_start_date<=first & emp_end_date>=last
drop first last

*Multiple jobs with same employer in a month, collapse
bys idjob monthly: egen total_inc = total(income)
bys idjob monthly: egen total_days = total(days)
bys idjob monthly (emp_start_date): keep if _n == _N

replace income = total_inc
replace days   = total_days 
drop total_inc total_days
drop emp_start_date emp_end_date

*Adjust income to account for sickness benefits (recover using replacement rates) and re-scaled working less than 30 days to 30days jobs
replace income = income + sickness/0.6 if sickness!=0
replace income = round(income,1 )
drop sickness incapacity

drop if nace_1>19
drop if fid_municipality==-1
drop if pid_location==-1
keep if month==12
keep if age<60
keep if employment==1 
keep if status==.
keep if fsize>=2
egen tmp = rsum(*benefits *pension)
drop if tmp>0
drop tmp
drop if nace_1==8

**Employment observations
keep if days==30
drop if income<159
keep if endspell_code==.

drop endspell*  status unemp_benefits retirement_pension severance  other_benefits other_pension

bys pid (income): keep if _n == _N


rename income incomeDEC`y'
rename age ageDEC`y'
rename female femaleDEC`y'
rename fid_municipality fid_municipalityDEC`y'
rename nace_1 nace_1DEC`y'
rename fsize fsizeDEC`y'
gen double fidDEC`y' = fid
format fidDEC`y' %12.0f

*Create income bins
gen inc_289 = incomeDEC`y'<317	
forvalues n =317(28)989 {
gen inc_`n' = incomeDEC`y'>=`n' & incomeDEC`y'<`n'+28
}

keep pid inc_* *DEC`y'

tempfile dta`y'
save `dta`y''

local yF = `y' + 1
foreach i in 1 6 12 18 {  
disp in red "`i'"
if `i' == 18 {
local yF1 = `y' + 2
use "${path}\data\sodra`yF1'.dta" , clear
*Generate job IDs and count working days, if work less than 30 days re-compute income
egen idjob = group(pid fid)
gen monthly = mofd(mdy(month,1,year))
format monthly %tm

gen emp_end_date1 = emp_end_date
replace emp_end_date = mdy(12,31,2020) if emp_end_date > mdy(12,31,2020)
format emp_end_date1  %td

gen first=dofm(monthly)
gen last=dofm(monthly + 1) - 1
gen 	days = .
replace days = emp_end_date1 - first + 1 if emp_start_date<=first & emp_end_date1<last
replace days = last - emp_start_date + 1  if emp_start_date>first & emp_end_date1>=last
replace days = emp_end_date1 - emp_start_date  + 1  if emp_start_date>first & emp_end_date1<last
replace days = 30 if emp_start_date<=first & emp_end_date>=last
drop first last

*Multiple jobs with same employer in a month, collapse
bys idjob monthly: egen total_inc = total(income)
bys idjob monthly: egen total_days = total(days)
bys idjob monthly (emp_start_date): keep if _n == _N

replace income = total_inc
replace days   = total_days 
drop total_inc total_days
drop emp_start_date emp_end_date

*Adjust income to account for sickness benefits (recover using replacement rates) and re-scaled working less than 30 days to 30days jobs
replace income = income + sickness/0.6 if sickness!=0
replace income = round(income,1 )
drop sickness incapacity

drop if nace_1>19
drop if fid_municipality==-1
drop if pid_location==-1
keep if month==6
keep if age<60
keep if employment==1 
keep if status==.
keep if fsize>=2
egen tmp = rsum(*benefits *pension)
drop if tmp>0
drop tmp
drop if nace_1==8

**Employment observations
keep if days==30
drop if income<159
keep if endspell_code==.

drop endspell*  status unemp_benefits retirement_pension severance nace_full other_benefits other_pension

bys pid (income): keep if _n == _N

qui merge 1:1 pid using `dta`y'', keep(2 3)
	
qui  gen De_m`i'`yF' =  _merge!=2 // stayed employed

qui  gen Dw_m`i'`yF' = (income - incomeDEC`y')/incomeDEC`y' if De_m`i'`yF'==1

drop if  Dw_m`i'`yF'>=2 &  Dw_m`i'`yF'<.

keep pid fid De* Dw* inc* *DEC`y' 

tempfile temp`y'_m`i'
save `temp`y'_m`i''

foreach v in e w {
	
qui  gen beta_`v'_m`i'`yF' = . 
qui  gen cilow_`v'_m`i'`yF' = . 
qui  gen cihigh_`v'_m`i'`yF' = . 

qui reghdfe D`v'_m`i'`yF' inc_* ageDEC`y' femaleDEC`y',  absorb(fid_municipalityDEC`y' nace_1DEC`y')  cluster(fid_municipalityDEC`y') keepsing nocons

forvalues n = 317(28)989 {
qui replace beta_`v'_m`i'`yF'   = _b[inc_`n'] if inc_`n'==1
qui replace cilow_`v'_m`i'`yF'  = _b[inc_`n'] - 1.96*_se[inc_`n'] if inc_`n'==1
qui replace cihigh_`v'_m`i'`yF' = _b[inc_`n'] + 1.96*_se[inc_`n'] if inc_`n'==1	
}	

qui replace beta_`v'   = _b[inc_289] if inc_289==1
qui replace cilow_`v'  = _b[inc_289] - 1.96*_se[inc_289] if inc_289==1
qui replace cihigh_`v' = _b[inc_289] + 1.96*_se[inc_289] if inc_289==1	
}	


gen wbin = 289 if inc_289==1
forvalues n=317(28)989 {
qui 	replace wbin = `n' if inc_`n'==1
}

*Plot estimates in figures
keep beta_* ci* wbin
bys wbin: keep if _n == 1

tempfile estimates_`y'_m`i'
save `estimates_`y'_m`i''	
	
}	

if `i'!=18 {
use "${path}\data\sodra`yF'.dta" , clear
*Generate job IDs and count working days, if work less than 30 days re-compute income
egen idjob = group(pid fid)
gen monthly = mofd(mdy(month,1,year))
format monthly %tm

gen emp_end_date1 = emp_end_date
replace emp_end_date = mdy(12,31,2020) if emp_end_date > mdy(12,31,2020)
format emp_end_date1  %td

gen first=dofm(monthly)
gen last=dofm(monthly + 1) - 1
gen 	days = .
replace days = emp_end_date1 - first + 1 if emp_start_date<=first & emp_end_date1<last
replace days = last - emp_start_date + 1  if emp_start_date>first & emp_end_date1>=last
replace days = emp_end_date1 - emp_start_date  + 1  if emp_start_date>first & emp_end_date1<last
replace days = 30 if emp_start_date<=first & emp_end_date>=last
drop first last

*Multiple jobs with same employer in a month, collapse
bys idjob monthly: egen total_inc = total(income)
bys idjob monthly: egen total_days = total(days)
bys idjob monthly (emp_start_date): keep if _n == _N

replace income = total_inc
replace days   = total_days 
drop total_inc total_days
drop emp_start_date emp_end_date

*Adjust income to account for sickness benefits (recover using replacement rates) and re-scaled working less than 30 days to 30days jobs
replace income = income + sickness/0.6 if sickness!=0
replace income = round(income,1 )
drop sickness incapacity

drop if nace_1>19
drop if fid_municipality==-1
drop if pid_location==-1
keep if month==`i'
keep if age<60
keep if employment==1 
keep if status==.
keep if fsize>=2
egen tmp = rsum(*benefits *pension)
drop if tmp>0
drop tmp
drop if nace_1==8

**Employment observations
keep if days==30
drop if income<159
keep if endspell_code==.

drop endspell*  status unemp_benefits retirement_pension severance nace_full other_benefits other_pension

bys pid (income): keep if _n == _N

qui merge 1:1 pid using `dta`y'', keep(2 3)
	
qui  gen De_m`i'`yF' =  _merge!=2 // stayed employed

qui  gen Dw_m`i'`yF' = (income - incomeDEC`y')/incomeDEC`y' if De_m`i'`yF'==1

drop if  Dw_m`i'`yF'>=2 &  Dw_m`i'`yF'<.

keep pid fid De* Dw* inc* *DEC`y' 

tempfile temp`y'_m`i'
save `temp`y'_m`i''



foreach v in e w {
	
qui  gen beta_`v'_m`i'`yF' = . 
qui  gen cilow_`v'_m`i'`yF' = . 
qui  gen cihigh_`v'_m`i'`yF' = . 

qui reghdfe D`v'_m`i'`yF' inc_* ageDEC`y' femaleDEC`y',  absorb(fid_municipalityDEC`y' nace_1DEC`y')  cluster(fid_municipalityDEC`y') keepsing nocons

forvalues n = 317(28)989 {
qui replace beta_`v'_m`i'`yF'   = _b[inc_`n'] if inc_`n'==1
qui replace cilow_`v'_m`i'`yF'  = _b[inc_`n'] - 1.96*_se[inc_`n'] if inc_`n'==1
qui replace cihigh_`v'_m`i'`yF' = _b[inc_`n'] + 1.96*_se[inc_`n'] if inc_`n'==1	
}	

qui replace beta_`v'   = _b[inc_289] if inc_289==1
qui replace cilow_`v'  = _b[inc_289] - 1.96*_se[inc_289] if inc_289==1
qui replace cihigh_`v' = _b[inc_289] + 1.96*_se[inc_289] if inc_289==1	
}	


gen wbin = 289 if inc_289==1
forvalues n=317(28)989 {
qui 	replace wbin = `n' if inc_`n'==1
}

*Plot estimates in figures
keep beta_* ci* wbin
bys wbin: keep if _n == 1

tempfile estimates_`y'_m`i'
save `estimates_`y'_m`i''
}
}
}



foreach i in 1 6 12 18 {
use `temp2012_m`i'', clear

gen wbin = 289 if inc_289==1
forvalues n=317(28)989 {
qui 	replace wbin = `n' if inc_`n'==1
}
merge m:1 wbin using `estimates_2012_m`i'', keepusing(beta* ci*) nogen
merge m:1 wbin using `estimates_2010_m`i'', keepusing(beta*) nogen

qui  gen De_corr_m`i' = De_m`i' - beta_e_m`i'2011 
qui replace De_corr_m`i' = De_m`i' if wbin==.

qui  gen Dw_corr_m`i' = Dw_m`i' - beta_w_m`i'2011
qui replace Dw_corr_m`i' = Dw_m`i' if wbin==.


foreach v in e_corr_m`i' w_corr_m`i' {
	

qui gen beta_`v' = . 
qui gen cilow_`v' = . 
qui gen cihigh_`v' = . 

reghdfe D`v' inc_* ageDEC`y' femaleDEC`y',  absorb(fid_municipalityDEC`y' nace_1DEC`y')  cluster(fid_municipalityDEC`y') keepsing nocons

forvalues n =317(28)989 {
qui replace beta_`v'   = _b[inc_`n'] if inc_`n'==1
qui replace cilow_`v'  = _b[inc_`n'] - 1.96*_se[inc_`n'] if inc_`n'==1
qui replace cihigh_`v' = _b[inc_`n'] + 1.96*_se[inc_`n'] if inc_`n'==1	
}	

qui replace beta_`v'   = _b[inc_289] if inc_289==1
qui replace cilow_`v'  = _b[inc_289] - 1.96*_se[inc_289] if inc_289==1
qui replace cihigh_`v' = _b[inc_289] + 1.96*_se[inc_289] if inc_289==1	
}	
keep wbin beta* ci*
bys wbin: keep if _n == 1
keep wbin beta* ci*

tempfile final2012m`i'
save `final2012m`i''

}

use `final2012m1'
merge 1:1 wbin using `final2012m6', nogen
merge 1:1 wbin using `final2012m12', nogen
merge 1:1 wbin using `final2012m18', nogen


qui grstyle init
qui grstyle set plain, compact grid dotted /*no grid*/
qui grstyle color major_grid gs13
qui grstyle set symbol
qui grstyle set lpattern
qui grstyle set color blue, n(4)   
qui grstyle set color blue, n(4)   opacity(34): p#markfill


replace wbin = wbin+14

tw (connect beta_w_corr_m18 wbin, lpattern(solid) lcolor("gray") mcolor("gray %34")) (rcap cilow_w_corr_m18 cihigh_w_corr_m18 wbin, lpattern(solid) lcolor("gray") ) (connect beta_w_corr_m12 wbin, lpattern(solid) lcolor("32 178 170") mcolor("32 178 170 %34")) (rcap cilow_w_corr_m12 cihigh_w_corr_m12 wbin, lpattern(solid) lcolor("32 178 170") ) (connect beta_w_corr_m6 wbin, lpattern(solid) lcolor("104 59 101") mcolor("104 59 101 %34") ) (rcap cilow_w_corr_m6 cihigh_w_corr_m6 wbin, lpattern(solid) lcolor("104 59 101")) (connect beta_w_corr_m1 wbin, lpattern(solid) msymbol(T) lcolor("251 162 127") mcolor("251 162 127 %34") msymbol(T) ) (rcap cilow_w_corr_m1 cihigh_w_corr_m1 wbin, lpattern(solid) lcolor("251 162 127")), xline(373, lcolor(red%85)) yline(0, lcolor(black%25)) xtitle("Monthly Income Bins") ytitle("Income Growth")  ylabel(-0.05(0.05)0.25)  xlabel(289(28)1017, alternate)  legend(order( 7 "January-2013" 5 "June-2013" 3 "December-2013" 1 "June-2014") row(1) symysize(5) symxsize(5))  


tw (connect beta_e_corr_m18 wbin, lpattern(solid) lcolor("gray") mcolor("gray %34")) (rcap cilow_e_corr_m18 cihigh_e_corr_m18 wbin, lpattern(solid) lcolor("gray") ) (connect beta_e_corr_m12 wbin, lpattern(solid) lcolor("32 178 170") mcolor("32 178 170 %34")) (rcap cilow_e_corr_m12 cihigh_e_corr_m12 wbin, lpattern(solid) lcolor("32 178 170") ) (connect beta_e_corr_m6 wbin, lpattern(solid) lcolor("104 59 101") mcolor("104 59 101 %34") ) (rcap cilow_e_corr_m6 cihigh_e_corr_m6 wbin, lpattern(solid) lcolor("104 59 101")) (connect beta_e_corr_m1 wbin, lpattern(solid) msymbol(T) lcolor("251 162 127") mcolor("251 162 127 %34") msymbol(T) ) (rcap cilow_e_corr_m1 cihigh_e_corr_m1 wbin, lpattern(solid) lcolor("251 162 127")), xline(373, lcolor(red%85)) yline(0, lcolor(black%25)) xtitle("Monthly Income Bins") ytitle("Stay in Employment")  ylabel(-0.08(0.02)0.04)  xlabel(289(28)1017, alternate)  legend(order( 7 "January-2013" 5 "June-2013" 3 "December-2013" 1 "June-2014") row(1) symysize(5) symxsize(5)) 












