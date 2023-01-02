
*quietly{
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
merge m:1 fid_municipality using "${path}\aux_data\locationwages`y'.dta", keep(1 3) keepusing(highbite)
drop _m
merge m:1 nace_full fid_municipality year using "${path}\aux_data\market_hhi.dta", keep(1 3) keepusing(hhi)
drop _m 
rename fid_municipality fid_municipalityDEC`y'
rename highbite highbiteDEC`y'
rename nace_1 nace_1DEC`y'
rename fsize fsizeDEC`y'
gen double fidDEC`y' = fid
format fidDEC`y' %12.0f

*Create income groups
gen treat = incomeDEC<373
gen partially_treat = incomeDEC>=373 & incomeDEC<569
gen control = incomeDEC>=569 & incomeDEC<1017

**HETEROGENEITY GROUPS

*Age
gen youngDEC`y' = age<25
gen oldDEC`y'   = age>45 

*Trade based on openess to trade and refine with Mian and Sufi (2014)
g nace_2 = int(nace_full/10000)
merge m:1 nace_2 using "${path}\aux_data\nace2_trade_hhi.dta", keep(1 3) keepusing(openness)
gen tradeDEC`y' = openness>0.1 & openness<. | nace_1==3 | nace_full>=580000 & nace_full<590000
gen nontradeDEC`y' = openness<=0.10 | (nace_full>=470000 & nace_full<479000) | int(nace_full/10000)==56 | nace_full == 451000 | nace_full==451100 | nace_full==451900 

*Concentration 
gen concDEC`y' = 0 if hhi<0.25 
replace concDEC`y' = 1 if  hhi>=0.25 &  hhi<. 

*Big city
gen bigcityDEC`y' = fid_municipalityDEC`y'==13 | fid_municipalityDEC`y'==19 | fid_municipalityDEC`y'==21

*Firm size
gen smeDEC`y' = fsize<50

*Ownership
gen fpublicDEC`y' = inrange(fid_type, 10,13) | inrange(fid_type, 35, 38) | inrange(fid_type,50,55)

*Envelope wages
gen envelopeDEC`y' = fsize<20 & (nace_1==6 | nace_1==9 | int(nace_full/10000)==47 | int(nace_full/10000)==96)  

 
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

qui drop if  (Dw_`yF'>=2 &  Dw_`yF'<.)

keep pid fid De* Dw* treat partially_treat control *DEC`y'
tempfile temp`y'
save `temp`y''

if  `y' == 2010 {
	foreach g of var female young old fpublic sme bigcity highbite nontrade conc envelope {
foreach var in treat partially_treat control {
gen `var'_`g' = `var'*`g'
}
}
foreach v in e w  {
	
qui  gen beta_`v'_`yF' = . 
qui reghdfe D`v'_`yF' treat partially_treat control ageDEC`y' femaleDEC`y',  absorb(fid_municipalityDEC`y' nace_1DEC`y')  keepsing nocons
foreach var in treat partially_treat control {
qui replace beta_`v'_`yF' = _b[`var']   if `var'==1 
}

foreach g in female young old fpublic sme bigcity highbite nontrade conc envelope {
qui  gen beta_`v'_`yF'_`g'0 = . 
qui  gen beta_`v'_`yF'_`g'1 = . 
disp in red "`g' "
qui reghdfe D`v'_`yF' treat treat_`g' partially_treat partially_treat_`g' control control_`g' ageDEC`y' femaleDEC`y',  absorb(fid_municipalityDEC`y' nace_1DEC`y')  keepsing nocons
foreach var in treat partially_treat control {
qui replace beta_`v'_`yF'_`g'0 = _b[`var']   if `var'==1 
qui replace beta_`v'_`yF'_`g'1 = _b[`var'] +  _b[`var'_`g']  if `var'==1
}
}
}

gen wbin = .
replace wbin = 1 if treat==1
replace wbin = 2 if partially_treat==1
replace wbin = 3 if control==1

*Plot estimates in figures
keep beta_* wbin 
bys wbin: keep if _n == 1

tempfile estimates_`y'
save `estimates_`y''    
}
}	

use `temp2012'
foreach v in female young old fpublic sme bigcity highbite nontrade conc envelope {
    rename `v'DEC`y' `v'
}
gen wbin = .
replace wbin = 1 if treat==1
replace wbin = 2 if partially_treat==1
replace wbin = 3 if control==1
merge m:1 wbin using `estimates_2010', keepusing(beta*) nogen

foreach g of var female young old fpublic sme bigcity highbite nontrade conc envelope {
foreach var in treat partially_treat control {
gen `var'_`g' = `var'*`g'
}
}

foreach v in w e {
*matrix `v' = J(10,3,.)
*matrix coln `v'   = beta ci_lb ci_ub
*matrix rown `v'   = "Benchmark" "Women" "Young Workers" "Senior Workers"  "Public Admin. or State-Owned" "Micro; Small; Medium-Sized" "Vilnius; Kaunas; Klaipeda" "High-Exposure Municipality" "Non-Tradable Industries" "Highly-Concentrated Markets"

matrix `v' = J(10,3,.)
matrix coln `v'   = beta ci_lb ci_ub
matrix rown `v'   = "Benchmark" "Women" "Young Workers" "Public Admin. or State-Owned" "Micro; Small; Medium-Sized" "Vilnius; Kaunas; Klaipeda" "High-Exposure Municipality" "Non-Tradable Industries" "Highly-Concentrated Markets" "Envelope Wages"


disp in red "Benchmark"
qui gen D`v'_corr = D`v'_2013 - beta_`v'_2011
qui replace D`v'_corr = D`v'_2013 if wbin==.
qui reghdfe D`v'_corr treat partially_treat control age female,  absorb(fid_municipalityDEC2012 nace_1DEC2012) cluster(fid_municipalityDEC2012) keepsing nocons
mat `v'[1,1] = _b[treat]    
mat `v'[1,2] = _b[treat]    - 1.96*_se[treat]  
mat `v'[1,3] = _b[treat]    + 1.96*_se[treat] 
drop D`v'_corr

local i 1
foreach g of var female young fpublic sme bigcity highbite nontrade conc envelope {
disp in red "`g'"
qui  gen D`v'_corr = D`v'_2013 - beta_`v'_2011_`g'0 if `g' == 0
qui replace D`v'_corr = D`v'_2013 - beta_`v'_2011_`g'1 if `g' == 1
qui replace D`v'_corr = D`v'_2013 if wbin==.

local ++ i 
qui reghdfe D`v'_corr treat treat_`g' partially_treat partially_treat_`g' control control_`g' `g' age female,  absorb(fid_municipalityDEC2012 nace_1DEC2012) cluster(fid_municipalityDEC2012) keepsing nocons
qui lincom  _b[treat] +  _b[treat_`g']
mat `v'[`i',1] = `r(estimate)'    
mat `v'[`i',2] = `r(estimate)'   - 1.96*`r(se)'  
mat `v'[`i',3] = `r(estimate)'   + 1.96*`r(se)'  
drop D`v'_corr

}
}


qui grstyle init
qui grstyle set plain, compact grid dotted /*no grid*/
qui grstyle color major_grid gs13 
qui grstyle set symbol
qui grstyle set lpattern


coefplot matrix(w[.,1]), ci((w[.,2] w[.,3])) msymbol(O) lpattern(solid)  ciopts(lcolor("64 105 166")) mcolor("32 178 170 %34") xlabel(0.04(0.04)0.20) xline(0.1115, lcolor("251 162 127 %50")) xtitle("Point Estimates", size(small))

coefplot matrix(e[.,1]), ci((e[.,2] e[.,3])) msymbol(O) lpattern(solid) ciopts(lcolor("64 105 166")) mcolor("32 178 170 %34")  xlabel(-0.06(0.03)0.06) xline(-0.0037,lcolor("251 162 127 %50")) xtitle("Point Estimates", size(small))
