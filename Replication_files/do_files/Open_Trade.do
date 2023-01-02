

use  ${path}\aux_data\firmdata_raw2000_2015.dta, clear 
keep if year>=2010 & year<=2012

*Tradable vs non-tradable sectors: tradability average share of trade of sales > 10% 
tempfile tradable
preserve
keep if empl>0
qui bys NACE2 year: gen nobs = _N
keep if nobs>4
qui bys NACE2 year: egen total_sales = total(rev_sales)
qui bys NACE2 year: egen total_exp= total(EXP)
qui bys NACE2 year: egen total_imp= total(IMP)
qui gen tmp = (total_exp+total_imp) / total_sales
qui bys NACE2 year: keep if _n==1
qui bys NACE2: egen openness = mean(tmp)
qui bys NACE2: keep if _n==1
qui keep NACE2 openness
save `tradable'
restore

merge 1:1 NACE2 using `tradable', nogen

rename NACE2 nace_2
save ${path}\aux_data\nace2_trade_hhi.dta, replace

