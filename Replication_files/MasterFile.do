*** Stata 17
*** Master file to replicate "Wage and Employment Impact of Minimum Wage: Evidence from Lithuania" by Jose Garcia-Louzao and Linas Tarasonis
*** January 2023


clear all
capture log close
capture program drop _all
macro drop _all
set more 1
set seed 13
set cformat %5.4f

** Set main directory 
*  It is important to place each file within each specific sub-folder for the smooth process of the routines, i.e., do_files, data, aux_data
global path "{Replication_files}" 
cd ${path}

** Installation of external programs required for estimation or saving results

* ftools (remove program if it existed previously)
ssc install ftools, replace
ssc install gtools, all replace

* reghdfe 
ssc install reghdfe, replace


** Routines to obtain regression results
*  See README for data access

** Main results
* Income and employment responses to MW
do ${path}\do_files\Benchmark_Results.do

* Implied elasticities 
do ${path}\do_files\Elasticities.do

* Heterogeneous respones
* Requires data on locationwages, sector openness to trade (with auxiliary firm-level data), and hhi 
do ${path}\do_files\Location_Wages.do
do ${path}\do_files\Market_Concentration.do
do ${path}\do_files\Open_Trade.do
do ${path}\do_files\Heterogeneity.do 


** Additional regression results 

* Reallocation: wage spillovers and employment retention by movers and stayers status
do ${path}\do_files\Reallocation.do 

* Respones in the upper tail
do ${path}\do_files\Upper_Tail.do 

* Respones at different time horizons
do ${path}\do_files\Time_Horizon.do

* Using jobs instead of workers
do ${path}\do_files\Jobs.do

* Using main job based on lowest income instead of highest
do ${path}\do_files\Lowest_Income.do

* Using income based on average income Q4 instead of December
do ${path}\do_files\Income_Q4.do

* Using September income instead of December
do ${path}\do_files\September_Income.do

* Including transportation industry
do ${path}\do_files\Transportation.do


