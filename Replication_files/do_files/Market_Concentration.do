

use "${path}\data\sodra2010.dta", clear
append using  "${path}\data\sodra2011.dta"
append using  "${path}\data\sodra2012.dta"

drop if fsize==0 
drop if inrange(fid_type, 10,13) | inrange(fid_type,50,55) // public sector
bys fid nace_full fid_municipality year: keep if _n == 1
qui bys nace_full fid_municipality year: gen nobs = _N
keep if nobs>4
qui bys  nace_full fid_municipality year: egen total_empl = total(fsize)
qui bys  nace_full fid_municipality year: egen hhi = total((fsize/total_empl)^2)
*qui bys  nace_full fid_municipality year: keep if _n==1
*qui bys  nace_full fid_municipality : egen hhi = mean(s2)
qui bys  nace_full fid_municipality year: keep if _n==1

qui keep  nace_full fid_municipality year hhi

save "${path}\aux_data\market_hhi.dta", replace