

foreach y in 2010 2011 2012 {
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
keep if month>=10
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

bys pid month (income): keep if _n == _N
bys pid fid: gen nobs = _N
drop if nobs!=3
bys pid: egen income_avg= mean(income)
keep if month==12
drop income
rename income_avg income
drop if income==.

*Remove income below previous minium wage and above 3 times that level
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
	
qui  gen De_`yF' =  _merge!=2 // stayed employed

qui  gen Dw_`yF' = (income - incomeDEC`y')/incomeDEC`y' if De_`yF'==1

drop if  (Dw_`yF'>=2 &  Dw_`yF'<.)

keep pid fid De* Dw* inc* *DEC`y' 

tempfile temp`y'
save `temp`y''


foreach v in e w  {
	
qui  gen beta_`v'_`yF' = . 
qui  gen cilow_`v'_`yF' = . 
qui  gen cihigh_`v'_`yF' = . 

reghdfe D`v'_`yF' inc_* ageDEC`y' femaleDEC`y',  absorb(fid_municipalityDEC`y' nace_1DEC`y') cluster(fid_municipalityDEC`y')  keepsing nocons

forvalues n =317(28)989  {
qui replace beta_`v'_`yF'   = _b[inc_`n'] if inc_`n'==1
qui replace cilow_`v'_`yF'  = _b[inc_`n'] - 1.96*_se[inc_`n'] if inc_`n'==1
qui replace cihigh_`v'_`yF' = _b[inc_`n'] + 1.96*_se[inc_`n'] if inc_`n'==1	
}

qui replace beta_`v'_`yF'   = _b[inc_289] if inc_289==1
qui replace cilow_`v'_`yF'  = _b[inc_289] - 1.96*_se[inc_289] if inc_289==1
qui replace cihigh_`v'_`yF' = _b[inc_289] + 1.96*_se[inc_289] if inc_289==1	

}	

gen wbin = 289 if inc_289==1
forvalues n=317(28)989{
qui 	replace wbin = `n' if inc_`n'==1
}

*Plot estimates in figures
keep beta_* ci* wbin
bys wbin: keep if _n == 1

tempfile estimates_`y'
save `estimates_`y''
}

foreach yt in 2011 2012 {
    preserve
use `temp`yt''

local i = `yt' + 1

gen wbin = 289 if inc_289==1
forvalues n=317(28)989  {
qui 	replace wbin = `n' if inc_`n'==1
}
merge m:1 wbin using `estimates_2012', keepusing(beta* ci*) nogen
merge m:1 wbin using `estimates_2011', keepusing(beta* ci*) nogen
merge m:1 wbin using `estimates_2010', keepusing(beta*) nogen

qui  gen De_corr_`i' = De_`i' - beta_e_2011 
qui replace De_corr_`i' = De_`i' if wbin==.

qui  gen Dw_corr_`i' = Dw_`i' - beta_w_2011
qui replace Dw_corr_`i' = Dw_`i' if wbin==.


foreach v in e_corr_`i' w_corr_`i'  {
	

qui gen beta_`v' = . 
qui gen cilow_`v' = . 
qui gen cihigh_`v' = . 

reghdfe D`v' inc_* ageDEC`y' femaleDEC`y',  absorb(fid_municipalityDEC`y' nace_1DEC`y') cluster(fid_municipalityDEC`y') keepsing nocons

forvalues n =317(28)989   {
qui replace beta_`v'   = _b[inc_`n'] if inc_`n'==1
qui replace cilow_`v'  = _b[inc_`n'] - 1.96*_se[inc_`n'] if inc_`n'==1
qui replace cihigh_`v' = _b[inc_`n'] + 1.96*_se[inc_`n'] if inc_`n'==1	
}	

qui replace beta_`v'   = _b[inc_289] if inc_289==1
qui replace cilow_`v'  = _b[inc_289] - 1.96*_se[inc_289] if inc_289==1
qui replace cihigh_`v' = _b[inc_289] + 1.96*_se[inc_289] if inc_289==1	

}	


keep wbin *`i' 
bys wbin: keep if _n == 1
keep wbin beta* ci*

tempfile final`yt'
save `final`yt''
restore
}


use `final2012'
append using `final2011'
append using `estimates_2010'

qui grstyle init
qui grstyle set plain, compact grid dotted /*no grid*/
qui grstyle color major_grid gs13
qui grstyle set symbol
qui grstyle set lpattern
qui grstyle set color blue, n(3)   
qui grstyle set color blue, n(3)   opacity(34): p#markfill


replace wbin = wbin+14


tw (connect beta_e_corr_2013 wbin, lcolor("32 178 170") mcolor("32 178 170 %34")) (rcap cilow_e_corr_2013 cihigh_e_corr_2013 wbin, lpattern(solid) lcolor("32 178 170")) (connect beta_e_corr_2012 wbin, lpattern(solid) lcolor("251 162 127") mcolor("251 162 127 %34")  ) (rcap cilow_e_corr_2012 cihigh_e_corr_2012 wbin, lpattern(solid) lcolor("251 162 127")), xline(373, lcolor(red%85)) yline(0, lcolor(black%25)) xtitle("Monthly Income Bins") ytitle("Stay in Employment")  ylabel(-0.08(0.02)0.04)  xlabel(289(28)1017, alternate)  legend(order( 1 "2012-2013" 3 "2011-2012" )) 


tw (connect beta_w_corr_2013 wbin, lcolor("32 178 170") mcolor("32 178 170 %34")) (rcap cilow_w_corr_2013 cihigh_w_corr_2013 wbin, lpattern(solid) lcolor("32 178 170")) (connect beta_w_corr_2012 wbin, lpattern(solid) lcolor("251 162 127") mcolor("251 162 127 %34")  ) (rcap cilow_w_corr_2012 cihigh_w_corr_2012 wbin, lpattern(solid) lcolor("251 162 127")), xline(373, lcolor(red%85)) yline(0, lcolor(black%25)) xtitle("Monthly Income Bins") ytitle("Income Growth")  ylabel(-0.05(0.05)0.25) xlabel(289(28)1017, alternate) legend(order( 1 "2012-2013" 3 "2011-2012" )) /*leg(off)*/ 




