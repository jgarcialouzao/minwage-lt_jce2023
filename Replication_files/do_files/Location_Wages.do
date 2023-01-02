

use "${path}\data\sodra2010.dta", clear
append using  "${path}\data\sodra2011.dta"
append using  "${path}\data\sodra2012.dta"
*Generate job IDs and count working days, if work less than 30 days re-compute income
egen idjob = group(pid fid)
gen monthly = mofd(mdy(month,1,year))
format monthly %tm

gen emp_end_date1 = emp_end_date
replace emp_end_date = mdy(12,31,2020) if emp_end_date > mdy(12,31,2020)
format emp_end_date1  %td

gen first=dofm(monthly
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

foreach y in 2012 2011 2010 {
preserve
keep if year==`y'
gen LT = nationality=="LTU"
gen lnw = ln(income)
qui reg lnw age female nb_children marital_status LT fsize i.nace_1
predict residual_w, res
bys fid_municipality: egen averagew_loc = mean(income)
bys fid_municipality: egen averageresw_loc = mean(residual_w)
gen diff = 373 - income
replace diff = 0 if diff<0
bys fid_municipality: egen sumdiff = sum(diff)
bys fid_municipality: egen sumincome = sum(income)
gen exposure =  sumdiff/sumincome 

keep fid_municipality average* exposure
bys fid_municipality: keep if _n == 1

*Minimum wage exposure
qui sum exposure, d
qui gen highbite = exposure > `r(p50)'
save "${path}\aux_data\locationwages`y'.dta", replace
restore
}