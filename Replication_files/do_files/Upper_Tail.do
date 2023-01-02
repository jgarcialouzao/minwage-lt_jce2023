


foreach y in 2012 2010 /*2011*/ {
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

*Select upper tail to test model validity
rename income incomeDEC`y'
drop if incomeDEC`y'<1017

rename age ageDEC`y'
rename female femaleDEC`y'
rename fid_municipality fid_municipalityDEC`y'
rename nace_1 nace_1DEC`y'
rename fsize fsizeDEC`y'
gen double fidDEC`y' = fid
format fidDEC`y' %12.0f


*Create income bins
forvalues n =1017(28)1717{
gen inc_`n' = incomeDEC`y'>=`n' & incomeDEC`y'<`n'+28
}

keep pid inc_* *DEC`y'

tempfile dta`y'
save `dta`y''

local yF = `y' + 1
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

drop endspell*  status unemp_benefits retirement_pension severance nace_full other_benefits other_pension

bys pid (income): keep if _n == _N

merge 1:1 pid using `dta`y'', keep(2 3)

gen De_`yF' =  _merge!=2 // stayed employed

gen Dw_`yF' = (income - incomeDEC`y')/incomeDEC`y' if De_`yF'==1

qui sum  Dw_`yF', d
drop if  (Dw_`yF'>=2 &  Dw_`yF'<.)
keep pid fid De* Dw* inc* *DEC`y' 

tempfile temp`y'
save `temp`y''


foreach v in e w  {
	

gen beta_`v'_`yF' = . 
gen cilow_`v'_`yF' = . 
gen cihigh_`v'_`yF' = . 

reghdfe D`v'_`yF' inc_* ageDEC femaleDEC,   absorb(fid_municipalityDEC nace_1DEC)  cluster(fid_municipalityDEC) keepsing nocons

forvalues n =1017(28)1717 {
qui replace beta_`v'_`yF'   = _b[inc_`n'] if inc_`n'==1
replace cilow_`v'_`yF'  = _b[inc_`n'] - 1.96*_se[inc_`n'] if inc_`n'==1
replace cihigh_`v'_`yF' = _b[inc_`n'] + 1.96*_se[inc_`n'] if inc_`n'==1	
}	

}	


gen wbin = . 
forvalues n=1017(28)1717 {
	replace wbin = `n' if inc_`n'==1
}

*Plot estimates in figures
keep beta_* ci* wbin
bys wbin: keep if _n == 1

tempfile estimates_`y'
save `estimates_`y''

}

use `temp2012'
gen wbin = . 
forvalues n=1017(28)1717 {
	replace wbin = `n' if inc_`n'==1
}
merge m:1 wbin using `estimates_2012', keepusing(beta* ci*) nogen
*merge m:1 wbin using `estimates_2011', keepusing(beta*) nogen
merge m:1 wbin using `estimates_2010', keepusing(beta*) nogen

gen corr_e = beta_e_2011
replace corr_e = 0 if wbin==.

gen corr_w = beta_w_2011
replace corr_w = 0 if wbin==.

gen De_corr = De_2013 - corr_e
gen Dw_corr = Dw_2013 - corr_w



foreach v in e_corr w_corr  {
	

qui gen beta_`v' = . 
qui gen cilow_`v' = . 
qui gen cihigh_`v' = . 

reghdfe D`v' inc_* ageDEC femaleDEC, absorb(fid_municipalityDEC nace_1DEC)  cluster(fid_municipalityDEC) keepsing nocons

forvalues n =1017(28)1717 {
qui replace beta_`v'   = _b[inc_`n'] if inc_`n'==1
qui replace cilow_`v'  = _b[inc_`n'] - 1.96*_se[inc_`n'] if inc_`n'==1
qui replace cihigh_`v' = _b[inc_`n'] + 1.96*_se[inc_`n'] if inc_`n'==1	
}	

}	


keep wbin *2013 *corr
bys wbin: keep if _n == 1
keep wbin beta* ci*

qui grstyle init
qui grstyle set plain, compact grid dotted /*no grid*/
qui grstyle color major_grid gs13
qui grstyle set symbol
qui grstyle set lpattern
qui grstyle set color blue, n(2)   
qui grstyle set color blue, n(2)   opacity(34): p#markfill

replace wbin = wbin + 14

tw  (connect beta_w_2013  wbin, lpattern(solid) lcolor("217 83 79") mcolor("217 83 79 %34") ) (rcap cilow_w_2013 cihigh_w_2013 wbin, lpattern(solid) lcolor("217 83 79") )  (connect beta_w_corr wbin, lpattern(solid) lcolor("32 178 170") mcolor("32 178 170 %34")) (rcap cilow_w_corr cihigh_w_corr wbin, lpattern(solid) lcolor("32 178 170")) , yline(0, lcolor(black%25)) xtitle("Monthly Income Bins") ytitle("Income Growth")  ylabel(-0.09(0.03)0.12)  xlabel(1017(28)1745, alt)  legend(order( 1 "Unadjusted" 3 "Adjusted")) 


tw (connect beta_e_2013 wbin, lpattern(solid) lcolor("217 83 79") mcolor("217 83 79 %34") ) (rcap cilow_e_2013 cihigh_e_2013 wbin, lpattern(solid) lcolor("217 83 79") ) (connect beta_e_corr wbin, lpattern(solid) lcolor("32 178 170") mcolor("32 178 170 %34")) (rcap cilow_e_corr cihigh_e_corr wbin, lpattern(solid) lcolor("32 178 170")), yline(0, lcolor(black%25)) xtitle("Monthly Income Bins") ytitle("Stay in Employment")  ylabel(-0.06(0.02)0.06) xlabel(1017(28)1745, alt)  legend(order( 1 "Unadjusted" 3 "Adjusted")) 









