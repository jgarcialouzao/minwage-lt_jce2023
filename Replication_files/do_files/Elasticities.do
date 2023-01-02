
foreach y in 2012 2011 2010 {
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

*Create income groups
gen treat = incomeDEC<373
gen partially_treat = incomeDEC>=373 & incomeDEC<569
gen control = incomeDEC>=569 & incomeDEC<1017

keep pid treat partially_* control *DEC`y'

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

keep pid fid De* Dw* treat partially_treat control  *DEC`y' 

tempfile temp`y'
save `temp`y''


foreach v in e w  {
	
qui  gen beta_`v'_`yF' = . 
qui reghdfe D`v'_`yF' treat partially_treat control ageDEC`y' femaleDEC`y',  absorb(fid_municipalityDEC`y' nace_1DEC`y') cluster(fid_municipalityDEC`y')  keepsing nocons

foreach var in treat partially_treat control {
qui replace beta_`v'_`yF'   = _b[`var'] if `var'==1

}
}	

gen wbin = .
replace wbin = 1 if treat==1
replace wbin = 2 if partially_treat==1
replace wbin = 3 if control==1


*Plot estimates in figures
keep beta_*  wbin
bys wbin: keep if _n == 1

tempfile estimates_`y'
save `estimates_`y''
}



use `temp2012'
gen wbin = .
replace wbin = 1 if treat==1
replace wbin = 2 if partially_treat==1
replace wbin = 3 if control==1
merge m:1 wbin using `estimates_2010', keepusing(beta*) nogen

qui  gen De_corr = De_2013 - beta_e_2011 
qui replace De_corr = De_2013 if wbin==.

qui  gen Dw_corr = Dw_2013 - beta_w_2011
qui replace Dw_corr = Dw_2013 if wbin==.


*Adjusted results
qui reghdfe Dw_corr treat partially_treat control ageDEC`y' femaleDEC`y',  absorb(fid_municipalityDEC`y' nace_1DEC`y') cluster(fid_municipalityDEC`y') keepsing nocons
outreg2 using reg_grouped2012.tex, replace keep(treat partially_treat control) ctitle(Income Growth)  tex(frag) dec(4)  nonotes label
 
qui reghdfe De_corr treat partially_treat control ageDEC`y' femaleDEC`y',  absorb(fid_municipalityDEC`y' nace_1DEC`y') cluster(fid_municipalityDEC`y') keepsing nocons
outreg2 using reg_grouped2012.tex, append keep(treat partially_treat control) ctitle(Employment Retention)  tex(frag) dec(4)  nonotes label
 
 
*Compute MWE (employment elasticity)
nlcom _b[treat]/0.177

*Compute OWE (own-wage employment elasticity)
qui reg Dw_corr treat partially_treat control ageDEC`y' femaleDEC`y' i.fid_municipalityDEC`y' i.nace_1DEC`y'
estimates store wage_corr
qui reg De_corr treat partially_treat control ageDEC`y' femaleDEC`y'  i.fid_municipalityDEC`y' i.nace_1DEC`y'
estimates store empl_corr
qui suest wage_corr empl_corr , cluster(fid_municipalityDEC`y')
nlcom (_b[empl_corr_mean:treat]/_b[wage_corr_mean:treat])

*Unadjusted but close enough individuals
qui reghdfe Dw_2013 treat  ageDEC`y' femaleDEC`y' if incomeDEC`y'>=317 & incomeDEC`y'<429,  absorb(fid_municipalityDEC`y' nace_1DEC`y') cluster(fid_municipalityDEC`y') keepsing nocons
 
qui reghdfe De_2013 treat  ageDEC`y' femaleDEC`y' if incomeDEC`y'>=317 & incomeDEC`y'<429,  absorb(fid_municipalityDEC`y' nace_1DEC`y') cluster(fid_municipalityDEC`y') keepsing nocons
 
*Compute MWE (employment elasticity)
nlcom _b[treat]/0.177

*Compute OWE (own-wage employment elasticity)
reg Dw_2013 treat  ageDEC`y' femaleDEC`y' i.fid_municipalityDEC`y' i.nace_1DEC`y'  if incomeDEC`y'>=317 & incomeDEC`y'<429
estimates store wage
reg De_2013 treat  ageDEC`y' femaleDEC`y'  i.fid_municipalityDEC`y' i.nace_1DEC`y' if incomeDEC`y'>=317 & incomeDEC`y'<429
estimates store empl
qui  suest wage empl , cluster(fid_municipalityDEC`y')
nlcom (_b[empl_mean:treat]/_b[wage_mean:treat])


