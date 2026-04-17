* ============================================================
* ENIGH 2016-2018 — Income, Poverty, and Welfare Analysis
*   Revised pipeline: 2021 PPP conversion throughout,
*   intermediary saves to data/, multiple explicit merges.
*
* PPP SOURCE: World Bank PA.NUS.PPP (LCU per international $)
*   https://data.worldbank.org/indicator/NY.GDP.MKTP.PP.KD?locations=MX
*
* ALL monetary figures converted to 2021 PPP international $
*   Formula: value_PPP = value_MXN * (cpi_2021/cpi_year) / ppp_2021
* ============================================================

clear all
set more off
set matsize 800

* ---- Global paths ----------------------------------------
global base_data "C:\Users\wb532966\OneDrive - WBG\AI\AI-course-2026-April\ai4coding-data\mex"
global out_dir   "C:\Users\wb532966\eb-local\ai4coding-examples\ex01-old-stata-code"
global data_dir  "$out_dir\data"
global outfile   "$out_dir\ENIGH_output.xlsx"

* ============================================================
* PPP CONVERSION PARAMETERS — Mexico, 2021 base
*   ppp_2021 = 11.2990 MXN per 2021 int'l $   (PA.NUS.PPP World Bank)
*   cpi_2016 = 74.9   (INPC Banco de Mexico, 2021=100)
*   cpi_2018 = 84.5
*   cpi_2021 = 100.0
* ============================================================
local ppp_2021  = 11.2990
local cpi_2016  = 74.9
local cpi_2018  = 84.5
local cpi_2021  = 100.0

* Deflators: multiply nominal MXN -> 2021 PPP international $
local defl_16   = (`cpi_2021' / `cpi_2016') / `ppp_2021'
local defl_18   = (`cpi_2021' / `cpi_2018') / `ppp_2021'

* ---- CONEVAL Poverty Lines — 2016 (nominal MXN + 2021 PPP converted) ----
global lbm_urb_16   1136
global lbm_rur_16    812
global lcap_urb_16  1356
global lcap_rur_16   992
global lpat_urb_16  2143
global lpat_rur_16  1545

* 2016 lines in 2021 PPP international $
global lbm_urb_16_ppp  = $lbm_urb_16  * `defl_16'
global lbm_rur_16_ppp  = $lbm_rur_16  * `defl_16'
global lcap_urb_16_ppp = $lcap_urb_16 * `defl_16'
global lcap_rur_16_ppp = $lcap_rur_16 * `defl_16'
global lpat_urb_16_ppp = $lpat_urb_16 * `defl_16'
global lpat_rur_16_ppp = $lpat_rur_16 * `defl_16'

* ---- World Bank IPL 2016 (nominal MXN + 2021 PPP converted) ----
global l215_16   556
global l365_16   942
global l685_16  1768
global l215_16_ppp = $l215_16 * `defl_16'
global l365_16_ppp = $l365_16 * `defl_16'
global l685_16_ppp = $l685_16 * `defl_16'

* ---- 2018 CONEVAL lines (nominal MXN + 2021 PPP converted) ----
global lbm_urb_18   1248
global lbm_rur_18    895
global lpat_urb_18  2335
global lpat_rur_18  1700
global lbm_urb_18_ppp  = $lbm_urb_18  * `defl_18'
global lbm_rur_18_ppp  = $lbm_rur_18  * `defl_18'
global lpat_urb_18_ppp = $lpat_urb_18 * `defl_18'
global lpat_rur_18_ppp = $lpat_rur_18 * `defl_18'
global l215_18   1803
global l365_18   3059
global l685_18   5736
global l215_18_ppp = $l215_18 * `defl_18'
global l365_18_ppp = $l365_18 * `defl_18'
global l685_18_ppp = $l685_18 * `defl_18'

* ============================================================
* HELPER: _ppp_convert
*   Applies 2021 PPP deflation to known ENIGH monetary stubs.
*   Call immediately after loading any raw file.
*   Args: deflator  year_label
* ============================================================
capture program drop _ppp_convert
program define _ppp_convert
    args defl yr
    foreach v in ing_cor gasto_mon gasto_nm gasto_tot ///
                 gas_corr gas_no_co gasmon gasnomon ///
                 ing_tri ing_men {
        capture confirm numeric variable `v'
        if !_rc {
            quietly replace `v' = `v' * `defl'
            quietly label variable `v' "`v' (2021 PPP intl $, from `yr' MXN)"
        }
    }
    note: Monetary vars converted to 2021 PPP int'l $, ///
          deflator=`defl', year `yr'. Source: PA.NUS.PPP World Bank.
end


* ===========================================================
* SECTION I.A — LOAD 2016 HOUSEHOLD DATA
*   → MERGE 1: concentrado 1:1 viviendas (dwelling info)
*   → MERGE 2: result 1:1 hogares (HH expenses)
*   → PPP convert all monetary vars to 2021 int'l $
*   → compute poverty flags with PPP-converted lines
*   → save data/hh16_base.dta
* ===========================================================

use "$base_data\2016\concentradohogar.dta", clear
rename factor fac_exp
gen str2 edo = substr(ubica_geo, 1, 2)
gen rural = (tam_loc == "5")
label var rural "Localidad rural (tam_loc = 5)"
gen region = .
replace region = 1 if inlist(edo,"02","03","05","08","10","19","25","26","28")
replace region = 2 if inlist(edo,"01","06","11","14","18","22","24","32")
replace region = 3 if inlist(edo,"09","12","13","15","16","17","21")
replace region = 4 if inlist(edo,"04","07","20","23","27","29","30","31")
label define reg_lbl 1 "Norte" 2 "Centro-Norte" 3 "Centro" 4 "Sur-Sureste"
label values region reg_lbl
gen jefe_hombre = (sexo_jefe == "1") if !missing(sexo_jefe)

* SAVE 1: raw concentrado before any merges
save "$data_dir\hh16_concentrado_raw.dta", replace
display "[data/] saved → hh16_concentrado_raw.dta"

* MERGE 1: join dwelling characteristics (viviendas m:1 on folioviv)
merge m:1 folioviv using "$base_data\2016\viviendas.dta", ///
    keep(match master) nogenerate
display "[merge 1] concentrado m:1 viviendas"
save "$data_dir\hh16_with_vivienda.dta", replace
display "[data/] saved → hh16_with_vivienda.dta"

* MERGE 2: join HH expenses (hogares 1:1 on folioviv+foliohog)
merge 1:1 folioviv foliohog using "$base_data\2016\hogares.dta", ///
    keep(match master) nogenerate
display "[merge 2] + hogares (HH expenses)"
save "$data_dir\hh16_with_hogares.dta", replace
display "[data/] saved → hh16_with_hogares.dta"

* PPP-convert all monetary variables to 2021 international $
_ppp_convert `defl_16' 2016

* Per-capita income in 2021 PPP $ (derived AFTER deflation of ing_cor)
gen ingreso_pc = ing_cor / tot_integ / 3
label var ingreso_pc "Ingreso mensual per capita (2021 PPP intl $)"
gen log_ingreso_pc = log(ingreso_pc + 1)
label var log_ingreso_pc "Log ingreso mensual per capita (2021 PPP intl $)"

* Poverty flags using PPP-converted lines
gen pov_ali = .
replace pov_ali = 1 if rural==0 & ingreso_pc < $lbm_urb_16_ppp
replace pov_ali = 1 if rural==1 & ingreso_pc < $lbm_rur_16_ppp
replace pov_ali = 0 if missing(pov_ali) & !missing(ingreso_pc)
label var pov_ali "Pobreza alimentaria CONEVAL 2016 (2021 PPP $)"
gen pov_cap = .
replace pov_cap = 1 if rural==0 & ingreso_pc < $lcap_urb_16_ppp
replace pov_cap = 1 if rural==1 & ingreso_pc < $lcap_rur_16_ppp
replace pov_cap = 0 if missing(pov_cap) & !missing(ingreso_pc)
gen pov_pat = .
replace pov_pat = 1 if rural==0 & ingreso_pc < $lpat_urb_16_ppp
replace pov_pat = 1 if rural==1 & ingreso_pc < $lpat_rur_16_ppp
replace pov_pat = 0 if missing(pov_pat) & !missing(ingreso_pc)
gen pov_215 = (ingreso_pc < $l215_16_ppp) if !missing(ingreso_pc)
gen pov_365 = (ingreso_pc < $l365_16_ppp) if !missing(ingreso_pc)
gen pov_685 = (ingreso_pc < $l685_16_ppp) if !missing(ingreso_pc)

* SAVE 2: fully processed HH base (PPP, all merges done)
save "$data_dir\hh16_base.dta", replace
display "[data/] saved → hh16_base.dta (N=" c(N) ")"


* ===========================================================
* SECTION I.B — LOAD 2016 INDIVIDUAL DATA
*   → MERGE 3: collapse ingresos → person totals → 1:1 merge
*   → MERGE 4: poblacion with individual income totals
*   → MERGE 5: individuals m:1 with hh16_base
*   → save data/ind16_merged.dta
* ===========================================================

use "$base_data\2016\poblacion.dta", clear

gen grupo_edad = .
replace grupo_edad = 1 if edad >= 0  & edad <= 11
replace grupo_edad = 2 if edad >= 12 & edad <= 24
replace grupo_edad = 3 if edad >= 25 & edad <= 44
replace grupo_edad = 4 if edad >= 45 & edad <= 64
replace grupo_edad = 5 if edad >= 65
label define ge 1 "0-11" 2 "12-24" 3 "25-44" 4 "45-64" 5 "65+"
label values grupo_edad ge
gen hombre = (sexo == "1") if !missing(sexo)
label var hombre "Hombre (1=si)"
destring gradoaprob, generate(grado_n) force
gen anios_educ = .
replace anios_educ = 0             if nivelaprob == "0"
replace anios_educ = grado_n       if nivelaprob == "1"
replace anios_educ = grado_n       if nivelaprob == "2"
replace anios_educ = 6 + grado_n   if nivelaprob == "3"
replace anios_educ = 9 + grado_n   if nivelaprob == "4"
replace anios_educ = 9 + grado_n   if nivelaprob == "5"
replace anios_educ = 9 + grado_n   if nivelaprob == "6"
replace anios_educ = 12 + grado_n  if nivelaprob == "7"
replace anios_educ = 16 + grado_n  if nivelaprob == "8"
replace anios_educ = 18 + grado_n  if nivelaprob == "9"
replace anios_educ = 0             if missing(anios_educ) & edad < 5
label var anios_educ "Anyos de educacion formal (estimado)"
gen educ_cat = .
replace educ_cat = 1 if inlist(nivelaprob,"0","1")
replace educ_cat = 2 if nivelaprob == "2"
replace educ_cat = 3 if nivelaprob == "3"
replace educ_cat = 4 if inlist(nivelaprob,"4","5","6")
replace educ_cat = 5 if inlist(nivelaprob,"7","8","9")
label define ec 1 "None/Preschool" 2 "Primary" 3 "Secondary" 4 "Post-sec" 5 "Tertiary"
label values educ_cat ec
gen trabaja   = (trabajo_mp == "1") if edad >= 25 & edad <= 60 & !missing(trabajo_mp)
gen inactivo  = (trabaja == 0 & inlist(act_pnea1,"1","2","3","4","5")) ///
    if edad >= 25 & edad <= 60 & !missing(trabajo_mp)
gen desemplea = (trabaja == 0 & inactivo == 0) ///
    if edad >= 25 & edad <= 60 & !missing(trabajo_mp)
gen formal    = (segsoc == "1") if !missing(segsoc) & edad >= 25 & edad <= 60

* SAVE 3: raw poblacion (pre-merge)
save "$data_dir\ind16_poblacion_raw.dta", replace
display "[data/] saved → ind16_poblacion_raw.dta"

* MERGE 3: collapse individual income sources (ingresos) to person totals
preserve
    use "$base_data\2016\ingresos.dta", clear
    capture confirm numeric variable ing_tri
    if !_rc {
        quietly replace ing_tri = ing_tri * `defl_16'
        quietly label variable ing_tri "Ingreso trim individual (2021 PPP intl $)"
    }
    collapse (sum) ing_tri_total = ing_tri ///
             (count) n_income_sources = ing_tri, ///
             by(folioviv foliohog numren)
    label var ing_tri_total "Total ingreso trim individual (2021 PPP intl $)"
    save "$data_dir\ingresos16_collapsed.dta", replace
    display "[data/] saved → ingresos16_collapsed.dta"
restore

* MERGE 4: join individual income totals (1:1 on person key)
merge 1:1 folioviv foliohog numren using "$data_dir\ingresos16_collapsed.dta", ///
    keep(match master) nogenerate
display "[merge 4] poblacion 1:1 ingresos16_collapsed"
save "$data_dir\ind16_with_income.dta", replace
display "[data/] saved → ind16_with_income.dta"

* MERGE 5: individuals m:1 with HH base (ing_pc, poverty flags, dwelling)
merge m:1 folioviv foliohog using "$data_dir\hh16_base.dta", ///
    keep(match master) nogenerate
display "[merge 5] poblacion m:1 hh16_base"

* SAVE 4: fully merged individual file 2016
save "$data_dir\ind16_merged.dta", replace
display "[data/] saved → ind16_merged.dta (N=" c(N) ")"


* ===========================================================
* SECTION I.C — SHEET 1: DEMOGRAPHICS (2016)
*   Uses ind16_merged.dta (individual + HH, 2021 PPP $)
* ===========================================================

use "$data_dir\ind16_merged.dta", clear

putexcel set "$outfile", sheet("Sheet1_Demographics") modify

putexcel A1 = "SHEET 1 — POPULATION & DEMOGRAPHIC OVERVIEW (ENIGH 2016, 2021 PPP $)", bold
putexcel A2 = "Survey weights applied. Income in 2021 PPP int'l $. Source: ENIGH 2016, INEGI."

* --- Sub-table 1.1: National Summary ---
putexcel A4 = "1.1 National Summary", bold
putexcel A5 = "Indicator"
putexcel B5 = "Value"

quietly sum fac_exp
local tot_pop_16 = r(sum)
quietly count
local n_obs_16 = r(N)
quietly sum fac_exp if hombre == 1
local pop_hom_16 = r(sum)
quietly sum fac_exp if hombre == 0
local pop_muj_16 = r(sum)

putexcel A6 = "Population total (weighted)"
putexcel B6 = `tot_pop_16'
putexcel A7 = "Observations (unweighted)"
putexcel B7 = `n_obs_16'
putexcel A8 = "  Male (weighted)"
putexcel B8 = `pop_hom_16'
putexcel A9 = "  Female (weighted)"
putexcel B9 = `pop_muj_16'

* --- Sub-table 1.2: Age Groups ---
putexcel A12 = "1.2 Population by Age Group", bold
putexcel A13 = "Age Group"
putexcel B13 = "Pop (weighted)"
putexcel C13 = "% Total"
putexcel D13 = "Male (wtd)"
putexcel E13 = "Female (wtd)"

local row = 14
forvalues g = 1/5 {
    quietly sum fac_exp if grupo_edad == `g'
    local n_g   = r(sum)
    local pct_g = `n_g' / `tot_pop_16' * 100
    quietly sum fac_exp if grupo_edad == `g' & hombre == 1
    local n_hom = r(sum)
    quietly sum fac_exp if grupo_edad == `g' & hombre == 0
    local n_muj = r(sum)
    local lbl : label ge `g'
    putexcel A`row' = "`lbl'"
    putexcel B`row' = `n_g'
    putexcel C`row' = `pct_g'
    putexcel D`row' = `n_hom'
    putexcel E`row' = `n_muj'
    local ++row
}
putexcel A`row' = "TOTAL"
putexcel B`row' = `tot_pop_16', bold

* --- Sub-table 1.3: By Macro-Region ---
putexcel A22 = "1.3 Population by Macro-Region", bold
putexcel A23 = "Region"
putexcel B23 = "Pop (weighted)"
putexcel C23 = "Male (wtd)"
putexcel D23 = "Female (wtd)"
putexcel E23 = "% National"

local row = 24
forvalues r = 1/4 {
    quietly sum fac_exp if region == `r'
    local np    = r(sum)
    local pct_r = `np' / `tot_pop_16' * 100
    quietly sum fac_exp if region == `r' & hombre == 1
    local nm = r(sum)
    quietly sum fac_exp if region == `r' & hombre == 0
    local nf = r(sum)
    local lbl : label reg_lbl `r'
    putexcel A`row' = "`lbl'"
    putexcel B`row' = `np'
    putexcel C`row' = `nm'
    putexcel D`row' = `nf'
    putexcel E`row' = `pct_r'
    local ++row
}
putexcel A`row' = "TOTAL"
putexcel B`row' = `tot_pop_16', bold

* --- Sub-table 1.4: Employment Status (prime-age 25-60) ---
putexcel A32 = "1.4 Employment Status — Prime-Age Adults (25-60)", bold
putexcel A33 = "Status"
putexcel B33 = "National"
putexcel C33 = "Norte"
putexcel D33 = "Centro-Norte"
putexcel E33 = "Centro"
putexcel F33 = "Sur-Sureste"

quietly sum fac_exp if trabaja == 1
local emp_n_16 = r(sum)
quietly sum fac_exp if edad >= 25 & edad <= 60 & !missing(trabaja)
local pa_n_16  = r(sum)
local emp_rate_16 = `emp_n_16' / `pa_n_16' * 100

putexcel A34 = "Employed (%)"
putexcel B34 = `emp_rate_16'

* NOTE: regional employment columns — added in loop, only national was in director briefing version
forvalues r = 1/4 {
    quietly sum fac_exp if trabaja==1 & region==`r'
    local emp_r = r(sum)
    quietly sum fac_exp if edad>=25 & edad<=60 & region==`r' & !missing(trabaja)
    local pa_r  = r(sum)
    local col : word `r' of C D E F
    putexcel `col'34 = `emp_r'/`pa_r'*100
}

quietly sum fac_exp if desemplea == 1
local desemp_n = r(sum)
putexcel A35 = "Unemployed (%)"
putexcel B35 = `desemp_n'/`pa_n_16'*100

quietly sum fac_exp if inactivo == 1
local inact_n  = r(sum)
putexcel A36 = "Inactive (%)"
putexcel B36 = `inact_n'/`pa_n_16'*100

display "Sheet 1 written."


* ===========================================================
* SECTION I.D — LOAD HH BASE FROM DATA/ (replaces redundant reload)
*   hh16_base.dta already has: PPP-converted income, poverty flags,
*   viviendas + hogares merged, log_ingreso_pc
* ===========================================================

use "$data_dir\hh16_base.dta", clear
display "[data/] loaded hh16_base.dta for Sheets 2+3"


* ===========================================================
* SECTION II — SHEET 2: INCOME DISTRIBUTION & POVERTY (2016)
* ===========================================================

putexcel set "$outfile", sheet("Sheet2_Poverty") modify

putexcel A1 = "SHEET 2 — INCOME DISTRIBUTION & POVERTY (ENIGH 2016)", bold
putexcel A2 = "CONEVAL 2016 lines and WB IPLs converted to 2021 PPP int'l $/month/capita."

* --- Sub-table 2.1: Poverty Headcounts ---
putexcel A4 = "2.1 Poverty Headcount by Line (% of households)", bold
putexcel A5 = "Poverty Line"
putexcel B5 = "National"
putexcel C5 = "Norte"
putexcel D5 = "Centro-Norte"
putexcel E5 = "Centro"
putexcel F5 = "Sur-Sureste"

local row = 6
foreach pline in pov_215 pov_365 pov_685 pov_ali pov_cap pov_pat {
    local lbl_str = "`pline'"
    if "`pline'" == "pov_215" local lbl_str "IPL 2.15/day (2021 PPP $)"
    if "`pline'" == "pov_365" local lbl_str "IPL 3.65/day (2021 PPP $)"
    if "`pline'" == "pov_685" local lbl_str "IPL 6.85/day (2021 PPP $)"
    if "`pline'" == "pov_ali" local lbl_str "Alimentaria CONEVAL (2021 PPP $)"
    if "`pline'" == "pov_cap" local lbl_str "Capacidades CONEVAL (2021 PPP $)"
    if "`pline'" == "pov_pat" local lbl_str "Patrimonio CONEVAL (2021 PPP $)"

    quietly sum `pline' [aw=fac_exp]
    local nat_r = r(mean)*100
    putexcel A`row' = "`lbl_str'"
    putexcel B`row' = `nat_r'

    forvalues r = 1/4 {
        quietly sum `pline' [aw=fac_exp] if region == `r'
        local rv = r(mean)*100
        local col : word `r' of C D E F
        putexcel `col'`row' = `rv'
    }
    local ++row
}

* --- Sub-table 2.2: Poverty by HH Head Characteristics ---
putexcel A14 = "2.2 Extreme Poverty (Alimentaria) by HH Head Characteristics", bold
putexcel A15 = "Group"
putexcel B15 = "Rate (%)"
putexcel C15 = "Poor pop (wtd)"

local row = 16
foreach g in 1 0 {
    if `g' == 1 putexcel A`row' = "Male-headed HH"
    else        putexcel A`row' = "Female-headed HH"
    quietly sum pov_ali [aw=fac_exp] if jefe_hombre == `g'
    local rv = r(mean)*100
    putexcel B`row' = `rv'
    quietly sum fac_exp if pov_ali == 1 & jefe_hombre == `g'
    local sv = r(sum)
    putexcel C`row' = `sv'
    local ++row
}

* Age-group headcounts by head age
local ++row
putexcel A`row' = "By age group of head:", bold
local ++row
foreach ag_lbl in "Head age < 30" "Head age 30-44" "Head age 45-64" "Head age 65+" {
    local ag_cond = ""
    if `"`ag_lbl'"' == "Head age < 30"    local ag_cond "edad_jefe < 30"
    if `"`ag_lbl'"' == "Head age 30-44"   local ag_cond "edad_jefe >= 30 & edad_jefe < 45"
    if `"`ag_lbl'"' == "Head age 45-64"   local ag_cond "edad_jefe >= 45 & edad_jefe < 65"
    if `"`ag_lbl'"' == "Head age 65+"     local ag_cond "edad_jefe >= 65"

    quietly sum pov_ali [aw=fac_exp] if `ag_cond'
    local rv = r(mean)*100
    quietly sum fac_exp if pov_ali==1 & `ag_cond'
    local sv = r(sum)
    putexcel A`row' = "  `ag_lbl'"
    putexcel B`row' = `rv'
    putexcel C`row' = `sv'
    local ++row
}

* --- Sub-table 2.3: Income Distribution Statistics ---
putexcel A28 = "2.3 Income Distribution (MXN/month/capita)", bold
putexcel A29 = "Statistic"
putexcel B29 = "National"
putexcel C29 = "Norte"
putexcel D29 = "Centro-Norte"
putexcel E29 = "Centro"
putexcel F29 = "Sur-Sureste"

quietly sum ingreso_pc [aw=fac_exp]
local mean_16 = r(mean)
putexcel A30 = "Mean"
putexcel B30 = `mean_16'

forvalues r = 1/4 {
    quietly sum ingreso_pc [aw=fac_exp] if region == `r'
    local mean_r = r(mean)
    local col : word `r' of C D E F
    putexcel `col'30 = `mean_r'
}

* Percentiles — national (2021 PPP intl $)
quietly _pctile ingreso_pc [aw=fac_exp], percentiles(10 25 50 75 90)
local p10_16 = r(r1)
local p25_16 = r(r2)
local med_16 = r(r3)
local p75_16 = r(r4)
local p90_16 = r(r5)

putexcel A31 = "P10"
putexcel B31 = `p10_16'
putexcel A32 = "P25"
putexcel B32 = `p25_16'
putexcel A33 = "Median"
putexcel B33 = `med_16'
putexcel A34 = "P75"
putexcel B34 = `p75_16'
putexcel A35 = "P90"
putexcel B35 = `p90_16'

* --- Figure 2.1: Income Density Curves ---
twoway (kdensity log_ingreso_pc [aw=fac_exp] if jefe_hombre==1, ///
           lcolor(navy) lwidth(medthick) legend(label(1 "Male-headed HH"))) ///
       (kdensity log_ingreso_pc [aw=fac_exp] if jefe_hombre==0, ///
           lcolor(cranberry) lpattern(dash) legend(label(2 "Female-headed HH"))), ///
    title("Log Income Distribution by HH Head Gender (ENIGH 2016, 2021 PPP $)") ///
    xtitle("Log monthly per capita income (2021 PPP intl $)") ytitle("Density") ///
    legend(rows(1)) graphregion(color(white))
graph export "$out_dir\fig21_income_density_2016.png", replace width(1200)

twoway (kdensity log_ingreso_pc [aw=fac_exp] if region==1, lcolor(navy)   legend(label(1 "Norte"))) ///
       (kdensity log_ingreso_pc [aw=fac_exp] if region==2, lcolor(green)  legend(label(2 "C-Norte"))) ///
       (kdensity log_ingreso_pc [aw=fac_exp] if region==3, lcolor(orange) legend(label(3 "Centro"))) ///
       (kdensity log_ingreso_pc [aw=fac_exp] if region==4, lcolor(maroon) legend(label(4 "Sur-SE"))), ///
    title("Log Income Distribution by Macro-Region (ENIGH 2016, 2021 PPP $)") ///
    xtitle("Log income (2021 PPP intl $)") ytitle("Density") legend(rows(1)) graphregion(color(white))
graph export "$out_dir\fig21b_income_region_2016.png", replace width(1200)

display "Sheet 2 written."


* ===========================================================
* SECTION III — SHEET 3: INEQUALITY (2016)
* ===========================================================

putexcel set "$outfile", sheet("Sheet3_Inequality") modify
putexcel A1 = "SHEET 3 — INEQUALITY (ENIGH 2016, 2021 PPP $)", bold

* --- Sub-table 3.1: Gini Coefficients ---
* Using fastgini (SSC). Must be installed: ssc install fastgini
/*
* Alternative: ineqdeco (also SSC)
* quietly ineqdeco ingreso_pc [pw=fac_exp]
* Tried ineqdeco first but it hit matsize limits on the 2016 sample.
*/

putexcel A3 = "3.1 Gini Coefficients", bold
putexcel A4 = "Geography"
putexcel B4 = "Gini"

fastgini ingreso_pc [pw=fac_exp]
local gini_16 = r(gini)
putexcel A5 = "National"
putexcel B5 = `gini_16'

local row = 6
forvalues r = 1/4 {
    fastgini ingreso_pc [pw=fac_exp] if region == `r'
    local gini_r = r(gini)
    local lbl : label reg_lbl `r'
    putexcel A`row' = "`lbl'"
    putexcel B`row' = `gini_r'
    local ++row
}

* --- Sub-table 3.2: Income Shares by Quintile ---
putexcel A14 = "3.2 Income Share by Quintile (% of total income)", bold
putexcel A15 = "Quintile"
putexcel B15 = "National"

xtile quintil = ingreso_pc [aw=fac_exp], nq(5)
quietly sum ingreso_pc [aw=fac_exp]
local tot_inc_16 = r(sum)

local row = 16
forvalues q = 1/5 {
    quietly sum ingreso_pc [aw=fac_exp] if quintil == `q'
    local sh = r(sum)/`tot_inc_16'*100
    putexcel A`row' = "Q`q'"
    putexcel B`row' = `sh'
    local ++row
}

* --- Figure 3.1: Distribution by region ---
* NOTE: originally planned box plots by state (32 states), too crowded.
* Using macro-region instead.
graph box ingreso_pc [aw=fac_exp], over(region, label(angle(45))) ///
    title("Income Distribution by Macro-Region (ENIGH 2016, 2021 PPP $)") ///
    ytitle("Monthly per capita income (2021 PPP intl $)") ///
    graphregion(color(white)) nooutsides
graph export "$out_dir\fig31_income_region_box_2016.png", replace width(1200)

display "Sheet 3 written."


* ===========================================================
* SECTION IV — BUILD REGRESSION DATASET
*   Load ind16_with_income (pre-saved)
*   MERGE 6: 1:m trabajos -> keep main job
*   MERGE 7: m:1 hh16_base
*   SAVE 6: data/reg16.dta
* ===========================================================

use "$data_dir\ind16_with_income.dta", clear
gen edad2 = edad^2

* MERGE 6: join jobs dataset 1:m (multiple jobs per person)
merge 1:m folioviv foliohog numren ///
    using "$base_data\2016\trabajos.dta", nogenerate
display "[merge 6] ind16 1:m trabajos"
keep if id_trabajo == "1" | missing(id_trabajo)

* Sector (SCIAN) + occupation (SINCO)
destring scian, generate(scian_n) force
gen sector = .
replace sector = 1 if scian_n >= 1100 & scian_n < 1200
replace sector = 2 if scian_n >= 3100 & scian_n < 3400
replace sector = 3 if (scian_n >= 4300 & scian_n < 4900)
replace sector = 4 if scian_n >= 4900 | (scian_n >= 2000 & scian_n < 3100)
label define sec_lbl 1 "Agropecuario" 2 "Manufactura" 3 "Comercio" 4 "Servicios/Otro", replace
label values sector sec_lbl
destring sinco, generate(sinco_n) force
gen ocup_cat = .
replace ocup_cat = 1 if sinco_n >= 1000 & sinco_n < 2000
replace ocup_cat = 2 if sinco_n >= 2000 & sinco_n < 4000
replace ocup_cat = 3 if sinco_n >= 4000 & sinco_n < 7000
replace ocup_cat = 4 if sinco_n >= 7000 & sinco_n < 9000
replace ocup_cat = 5 if sinco_n >= 9000
label define oc_lbl 1 "Directivos" 2 "Prof/Tec" 3 "Calific" 4 "Operadores" 5 "No calific", replace
label values ocup_cat oc_lbl
label var htrab "Horas trabajadas por semana (primer trabajo)"

* SAVE 5: individuals + trabajos (pre-HH merge)
save "$data_dir\ind16_with_trabajos.dta", replace
display "[data/] saved -> ind16_with_trabajos.dta"

* MERGE 7: join HH-level vars
merge m:1 folioviv foliohog using "$data_dir\hh16_base.dta", ///
    keep(match master) nogenerate
display "[merge 7] ind16_with_trabajos m:1 hh16_base"
capture rename menores n_menores
capture rename p65mas  n_mayores
gen log_inc_pc = log(ingreso_pc) if ingreso_pc > 0 & !missing(ingreso_pc)
label var log_inc_pc "Log monthly per capita income (2021 PPP intl $)"

* SAVE 6: full regression dataset 2016
save "$data_dir\reg16.dta", replace
display "[data/] saved -> reg16.dta (N=" c(N) ")"


* ===========================================================
* SECTION IV-B — SHEET 4: REGRESSIONS (2016)
* ===========================================================

putexcel set "$outfile", sheet("Sheet4_Regs") modify

use "$data_dir\reg16.dta", clear

putexcel A1 = "SHEET 4 — REGRESSIONS: LOG PER CAPITA INCOME (ENIGH 2016, 2021 PPP $)", bold
putexcel A2 = "OLS survey-weighted. Dep. var: log(monthly per capita HH income, 2021 PPP intl $)."
putexcel A3 = "(1) All 25-60  (2) Males  (3) Females  (4) Young 20-44  (5) Older 45-60  (6) Seniors 60-65"
putexcel A4 = "Income in 2021 PPP int'l $. Source: PA.NUS.PPP World Bank (ppp_2021=11.299, cpi_2016=74.9)."

putexcel A5  = "Variable"
putexcel B5  = "(1) All"
putexcel C5  = "(2) Males"
putexcel D5  = "(3) Females"
putexcel E5  = "(4) Young"
putexcel F5  = "(5) Older"
putexcel G5  = "(6) Seniors"

putexcel A6  = "Age"
putexcel A7  = "Age squared"
putexcel A8  = "Male"
putexcel A9  = "Years educ"
putexcel A10 = "HH size"
putexcel A11 = "N children (HH)"
putexcel A12 = "N elderly (HH)"
putexcel A13 = "Hours worked"
putexcel A14 = "N"
putexcel A15 = "R-squared"
putexcel A16 = "Mean dep. var"

local conditions `" "edad>=25 & edad<=60" "edad>=25 & edad<=60 & hombre==1" "edad>=25 & edad<=60 & hombre==0" "edad>=20 & edad<=44" "edad>=45 & edad<=60" "edad>=60 & edad<=65" "'
local col_list B C D E F G
local scol = 1

foreach cond of local conditions {
    local cn : word `scol' of `col_list'

    quietly reg log_inc_pc edad edad2 hombre anios_educ i.sector i.ocup_cat ///
        tot_integ n_menores n_mayores htrab [aw=fac_exp] ///
        if `cond' & !missing(log_inc_pc)

    local b_edad   = _b[edad]
    local b_edad2  = _b[edad2]
    local b_hom    = _b[hombre]
    local b_educ   = _b[anios_educ]
    local b_hhsz   = _b[tot_integ]
    local b_nmen   = _b[n_menores]
    local b_nmay   = _b[n_mayores]
    local b_htrab  = _b[htrab]
    local N_reg    = e(N)
    local r2_reg   = e(r2)

    putexcel `cn'6  = `b_edad'
    putexcel `cn'7  = `b_edad2'
    putexcel `cn'8  = `b_hom'
    putexcel `cn'9  = `b_educ'
    putexcel `cn'10 = `b_hhsz'
    putexcel `cn'11 = `b_nmen'
    putexcel `cn'12 = `b_nmay'
    putexcel `cn'13 = `b_htrab'
    putexcel `cn'14 = `N_reg'
    putexcel `cn'15 = `r2_reg'

    quietly sum log_inc_pc [aw=fac_exp] if e(sample)
    local mu_dep = r(mean)
    putexcel `cn'16 = `mu_dep'

    local ++scol
}

display "Sheet 4 written."


* ===========================================================
* SECTION V — LOAD AND PROCESS 2018 DATA
*   → MERGE 8: 2018 concentrado 1:1 viviendas
*   → MERGE 9: result 1:1 hogares
*   → PPP convert to 2021 int'l $
*   → MERGE 10: collapse ingresos18 → 1:1 merge with poblacion
*   → MERGE 11: individuals m:1 hh18_base
*   → save data/hh18_base.dta, data/ind18_merged.dta
* ===========================================================

* --- 2018 HH base ---
use "$base_data\2018\concentradohogar.dta", clear
rename factor fac_exp
gen str2 edo = substr(ubica_geo, 1, 2)
gen rural = (tam_loc == "5")
gen region = .
replace region = 1 if inlist(edo,"02","03","05","08","10","19","25","26","28")
replace region = 2 if inlist(edo,"01","06","11","14","18","22","24","32")
replace region = 3 if inlist(edo,"09","12","13","15","16","17","21")
replace region = 4 if inlist(edo,"04","07","20","23","27","29","30","31")
label define reg_lbl 1 "Norte" 2 "Centro-Norte" 3 "Centro" 4 "Sur-Sureste", replace
label values region reg_lbl
gen jefe_hombre = (sexo_jefe == "1") if !missing(sexo_jefe)

* SAVE 7: 2018 raw concentrado
save "$data_dir\hh18_concentrado_raw.dta", replace
display "[data/] saved → hh18_concentrado_raw.dta"

* MERGE 8: 2018 concentrado m:1 viviendas
merge m:1 folioviv using "$base_data\2018\viviendas.dta", ///
    keep(match master) nogenerate
display "[merge 8] 2018 concentrado m:1 viviendas"
save "$data_dir\hh18_with_vivienda.dta", replace
display "[data/] saved → hh18_with_vivienda.dta"

* MERGE 9: 2018 concentrado 1:1 hogares
merge 1:1 folioviv foliohog using "$base_data\2018\hogares.dta", ///
    keep(match master) nogenerate
display "[merge 9] 2018 + hogares"

* PPP-convert monetary variables to 2021 international $
_ppp_convert `defl_18' 2018

gen ingreso_pc = ing_cor / tot_integ / 3
label var ingreso_pc "Ingreso mensual per capita (2021 PPP intl $)"

* Poverty flags using 2018 CONEVAL lines converted to 2021 PPP $
gen pov_ali_18 = .
replace pov_ali_18 = 1 if rural==0 & ingreso_pc < $lbm_urb_18_ppp
replace pov_ali_18 = 1 if rural==1 & ingreso_pc < $lbm_rur_18_ppp
replace pov_ali_18 = 0 if missing(pov_ali_18) & !missing(ingreso_pc)
gen pov_pat_18 = .
replace pov_pat_18 = 1 if rural==0 & ingreso_pc < $lpat_urb_18_ppp
replace pov_pat_18 = 1 if rural==1 & ingreso_pc < $lpat_rur_18_ppp
replace pov_pat_18 = 0 if missing(pov_pat_18) & !missing(ingreso_pc)
gen pov_215_18 = (ingreso_pc < $l215_18_ppp) if !missing(ingreso_pc)
gen pov_365_18 = (ingreso_pc < $l365_18_ppp) if !missing(ingreso_pc)
gen pov_685_18 = (ingreso_pc < $l685_18_ppp) if !missing(ingreso_pc)

* SAVE 8: 2018 HH base (PPP-converted, all merges done)
save "$data_dir\hh18_base.dta", replace
display "[data/] saved → hh18_base.dta (N=" c(N) ")"

* --- 2018 Individual file ---
use "$base_data\2018\poblacion.dta", clear
gen grupo_edad = .
replace grupo_edad = 1 if edad >= 0  & edad <= 11
replace grupo_edad = 2 if edad >= 12 & edad <= 24
replace grupo_edad = 3 if edad >= 25 & edad <= 44
replace grupo_edad = 4 if edad >= 45 & edad <= 64
replace grupo_edad = 5 if edad >= 65
label define ge 1 "0-11" 2 "12-24" 3 "25-44" 4 "45-64" 5 "65+", replace
label values grupo_edad ge
gen hombre     = (sexo == "1") if !missing(sexo)
gen trabaja_18 = (trabajo_mp == "1") if edad >= 25 & edad <= 60 & !missing(trabajo_mp)
gen formal_18  = (segsoc == "1")     if !missing(segsoc) & edad >= 25 & edad <= 60
gen informal_18 = (formal_18 == 0)  if !missing(formal_18) & trabaja_18 == 1

* SAVE 9: raw 2018 poblacion
save "$data_dir\ind18_poblacion_raw.dta", replace
display "[data/] saved → ind18_poblacion_raw.dta"

* MERGE 10: collapse 2018 individual income sources
preserve
    use "$base_data\2018\ingresos.dta", clear
    capture confirm numeric variable ing_tri
    if !_rc {
        quietly replace ing_tri = ing_tri * `defl_18'
        quietly label variable ing_tri "Ingreso trim (2021 PPP intl $)"
    }
    collapse (sum) ing_tri_total = ing_tri ///
             (count) n_income_sources = ing_tri, ///
             by(folioviv foliohog numren)
    save "$data_dir\ingresos18_collapsed.dta", replace
    display "[data/] saved → ingresos18_collapsed.dta"
restore
merge 1:1 folioviv foliohog numren using "$data_dir\ingresos18_collapsed.dta", ///
    keep(match master) nogenerate
display "[merge 10] 2018 poblacion 1:1 ingresos18_collapsed"
save "$data_dir\ind18_with_income.dta", replace
display "[data/] saved → ind18_with_income.dta"

* MERGE 11: 2018 individuals m:1 hh18_base
merge m:1 folioviv foliohog using "$data_dir\hh18_base.dta", ///
    keep(match master) nogenerate
display "[merge 11] 2018 poblacion m:1 hh18_base"

* SAVE 10: 2018 fully merged individual file
save "$data_dir\ind18_merged.dta", replace
display "[data/] saved → ind18_merged.dta (N=" c(N) ")"


* ===========================================================
* SECTION VI — SHEET 5: DEMOGRAPHICS & POVERTY (2018, 2021 PPP $)
* ===========================================================

putexcel set "$outfile", sheet("Sheet5_2018") modify
putexcel A1 = "SHEET 5 — DEMOGRAPHICS & POVERTY (ENIGH 2018, 2021 PPP $)", bold
putexcel A2 = "2018 CONEVAL lines converted to 2021 PPP int'l $. Same base as 2016 sheets."

use "$data_dir\ind18_merged.dta", clear

putexcel A4 = "5.1 National Summary (2018)", bold
quietly sum fac_exp
local tot_pop_18 = r(sum)
quietly count
local n_obs_18   = r(N)
putexcel A5 = "Population total (weighted)"
putexcel B5 = `tot_pop_18'
putexcel A6 = "Observations (unweighted)"
putexcel B6 = `n_obs_18'

quietly sum fac_exp if hombre == 1
local ph18 = r(sum)
quietly sum fac_exp if hombre == 0
local pf18 = r(sum)
putexcel A7 = "  Male (weighted)"
putexcel B7 = `ph18'
putexcel A8 = "  Female (weighted)"
putexcel B8 = `pf18'

putexcel A10 = "5.2 Population by Age Group (2018)", bold
putexcel A11 = "Age Group"
putexcel B11 = "Pop (weighted)"
putexcel C11 = "% Total"

local row = 12
forvalues g = 1/5 {
    quietly sum fac_exp if grupo_edad == `g'
    local n_g   = r(sum)
    local pct_g = `n_g' / `tot_pop_18' * 100
    local lbl : label ge `g'
    putexcel A`row' = "`lbl'"
    putexcel B`row' = `n_g'
    putexcel C`row' = `pct_g'
    local ++row
}

putexcel A20 = "5.3 Poverty Headcount 2018 (% of households)", bold
putexcel A21 = "Poverty Line"
putexcel B21 = "National"
putexcel C21 = "Norte"
putexcel D21 = "Centro-Norte"
putexcel E21 = "Centro"
putexcel F21 = "Sur-Sureste"

use "$data_dir\hh18_base.dta", clear

local row = 22
foreach pline in pov_215_18 pov_365_18 pov_685_18 pov_ali_18 pov_pat_18 {
    local lbl_str = "`pline'"
    if "`pline'" == "pov_215_18" local lbl_str "IPL 2.15/day (2021 PPP $)"
    if "`pline'" == "pov_365_18" local lbl_str "IPL 3.65/day (2021 PPP $)"
    if "`pline'" == "pov_685_18" local lbl_str "IPL 6.85/day (2021 PPP $)"
    if "`pline'" == "pov_ali_18" local lbl_str "Alimentaria CONEVAL 2018 (2021 PPP $)"
    if "`pline'" == "pov_pat_18" local lbl_str "Patrimonio CONEVAL 2018 (2021 PPP $)"

    quietly sum `pline' [aw=fac_exp]
    local nat_r18 = r(mean)*100
    putexcel A`row' = "`lbl_str'"
    putexcel B`row' = `nat_r18'

    forvalues r = 1/4 {
        quietly sum `pline' [aw=fac_exp] if region == `r'
        local rv18 = r(mean)*100
        local col : word `r' of C D E F
        putexcel `col'`row' = `rv18'
    }
    local ++row
}

putexcel A30 = "5.4 Employment & Informality 2018 (prime-age 25-60)", bold
use "$data_dir\ind18_merged.dta", clear

quietly sum fac_exp if trabaja_18 == 1
local emp_n_18 = r(sum)
quietly sum fac_exp if edad >= 25 & edad <= 60 & !missing(trabaja_18)
local pa_n_18  = r(sum)
local emp_rate_18 = `emp_n_18' / `pa_n_18' * 100
putexcel A31 = "Employment rate (%)"
putexcel B31 = `emp_rate_18'

quietly sum fac_exp if informal_18 == 1
local inf_n_18  = r(sum)
local inf_rate_18 = `inf_n_18' / `emp_n_18' * 100
putexcel A32 = "Informality rate (% of employed)"
putexcel B32 = `inf_rate_18'

display "Sheet 5 written."


* ===========================================================
* SECTION VII — POOLED DATASET + SHEET 6: CROSS-SECTION
*   Both years already in 2021 PPP → directly comparable
*   MERGE 12 (append): hh18_base + hh16_base
*   → save data/hh16_forpool.dta, data/hh18_forpool.dta
*   → save data/pooled_1618.dta
* ===========================================================

putexcel set "$outfile", sheet("Sheet6_Comparison") modify
putexcel A1 = "SHEET 6 — CROSS-SECTION COMPARISON: ENIGH 2016 vs 2018", bold
putexcel A2 = "Both years in 2021 PPP int'l $/month/capita (directly comparable). Source: PA.NUS.PPP World Bank."

* Build 2016 for pooling
use "$data_dir\hh16_base.dta", clear
gen year = 2016
rename ingreso_pc income_percap
save "$data_dir\hh16_forpool.dta", replace
display "[data/] saved → hh16_forpool.dta"

* Build 2018 for pooling
use "$data_dir\hh18_base.dta", clear
gen year = 2018
rename ingreso_pc income_percap
save "$data_dir\hh18_forpool.dta", replace
display "[data/] saved → hh18_forpool.dta"

* MERGE 12: append 2018 + 2016 into pooled cross-section
use "$data_dir\hh18_forpool.dta", clear
append using "$data_dir\hh16_forpool.dta"
label var income_percap "Monthly per capita income (2021 PPP intl $)"
note: Pooled ENIGH 2016+2018 in 2021 PPP int'l $. PA.NUS.PPP World Bank.
save "$data_dir\pooled_1618.dta", replace
display "[data/] saved → pooled_1618.dta (N=" c(N) ")"

* 6.1 Poverty comparison
putexcel A4 = "6.1 Poverty Headcount Comparison (%)", bold
putexcel A5 = "Poverty Line"
putexcel B5 = "2016"
putexcel C5 = "2018"
putexcel D5 = "Change (pp)"

local row = 6
foreach pline in pov_215 pov_365 pov_685 {
    local pline18 = "`pline'_18"
    quietly sum `pline'   [aw=fac_exp] if year == 2016
    local r16 = r(mean)*100
    quietly sum `pline18' [aw=fac_exp] if year == 2018
    local r18_v = r(mean)*100
    local chg   = `r18_v' - `r16'
    if "`pline'" == "pov_215" putexcel A`row' = "IPL 2.15/day (2021 PPP $)"
    if "`pline'" == "pov_365" putexcel A`row' = "IPL 3.65/day (2021 PPP $)"
    if "`pline'" == "pov_685" putexcel A`row' = "IPL 6.85/day (2021 PPP $)"
    putexcel B`row' = `r16'
    putexcel C`row' = `r18_v'
    putexcel D`row' = `chg'
    local ++row
}

quietly sum pov_ali    [aw=fac_exp] if year == 2016
local ali_16 = r(mean)*100
quietly sum pov_ali_18 [aw=fac_exp] if year == 2018
local ali_18 = r(mean)*100
putexcel A`row' = "Alimentaria (CONEVAL, year-specific thresholds)"
putexcel B`row' = `ali_16'
putexcel C`row' = `ali_18'
local chg_ali = `ali_18' - `ali_16'
putexcel D`row' = `chg_ali'

* 6.2 Income distribution comparison
putexcel A14 = "6.2 Income Distribution Comparison (2021 PPP intl $)", bold
putexcel A15 = "Statistic"
putexcel B15 = "2016"
putexcel C15 = "2018"
putexcel D15 = "% Change"

quietly sum income_percap [aw=fac_exp] if year == 2016
local mean_16b = r(mean)
quietly sum income_percap [aw=fac_exp] if year == 2018
local mean_18  = r(mean)
putexcel A16 = "Mean per capita income"
putexcel B16 = `mean_16b'
putexcel C16 = `mean_18'
putexcel D16 = ((`mean_18' - `mean_16b') / `mean_16b' * 100)

quietly _pctile income_percap [aw=fac_exp] if year == 2016, p(50)
local med_16b = r(r1)
quietly _pctile income_percap [aw=fac_exp] if year == 2018, p(50)
local med_18 = r(r1)
putexcel A17 = "Median per capita income"
putexcel B17 = `med_16b'
putexcel C17 = `med_18'
putexcel D17 = ((`med_18' - `med_16b') / `med_16b' * 100)

fastgini income_percap [pw=fac_exp] if year == 2016
local gini_16b = r(gini)
fastgini income_percap [pw=fac_exp] if year == 2018
local gini_18  = r(gini)
putexcel A18 = "Gini coefficient"
putexcel B18 = `gini_16b'
putexcel C18 = `gini_18'
local gini_chg = `gini_18' - `gini_16b'
putexcel D18 = `gini_chg'

* 6.3 Employment comparison
putexcel A21 = "6.3 Employment Rate (prime-age 25-60, %)", bold
putexcel A22 = "Gender"
putexcel B22 = "2016"
putexcel C22 = "2018"

use "$data_dir\ind16_merged.dta", clear
quietly sum fac_exp if trabaja==1 & hombre==1
local emp_m_16 = r(sum)
quietly sum fac_exp if edad>=25 & edad<=60 & hombre==1 & !missing(trabaja)
local pa_m_16  = r(sum)
quietly sum fac_exp if trabaja==1 & hombre==0
local emp_f_16 = r(sum)
quietly sum fac_exp if edad>=25 & edad<=60 & hombre==0 & !missing(trabaja)
local pa_f_16  = r(sum)
putexcel A23 = "Male"
local er_m16 = `emp_m_16'/`pa_m_16'*100
putexcel B23 = `er_m16'
putexcel A24 = "Female"
local er_f16 = `emp_f_16'/`pa_f_16'*100
putexcel B24 = `er_f16'

use "$data_dir\ind18_merged.dta", clear
quietly sum fac_exp if trabaja_18==1 & hombre==1
local emp_m_18 = r(sum)
quietly sum fac_exp if edad>=25 & edad<=60 & hombre==1 & !missing(trabaja_18)
local pa_m_18  = r(sum)
quietly sum fac_exp if trabaja_18==1 & hombre==0
local emp_f_18 = r(sum)
quietly sum fac_exp if edad>=25 & edad<=60 & hombre==0 & !missing(trabaja_18)
local pa_f_18  = r(sum)
local er_m18 = `emp_m_18'/`pa_m_18'*100
putexcel C23 = `er_m18'
local er_f18 = `emp_f_18'/`pa_f_18'*100
putexcel C24 = `er_f18'

* Figure 6.1 — overlapping density curves 2016 vs 2018
use "$data_dir\pooled_1618.dta", clear
gen log_inc = log(income_percap + 1)

twoway (kdensity log_inc [aw=fac_exp] if year==2016, ///
           lcolor(navy) lwidth(medthick) legend(label(1 "2016"))) ///
       (kdensity log_inc [aw=fac_exp] if year==2018, ///
           lcolor(orange) lpattern(dash) legend(label(2 "2018"))), ///
    title("Income Distribution: 2016 vs 2018 (ENIGH, 2021 PPP $)") ///
    xtitle("Log monthly per capita income (2021 PPP intl $)") ///
    ytitle("Density") legend(rows(1)) graphregion(color(white))
graph export "$out_dir\fig61_density_comparison.png", replace width(1200)

display "Sheet 6 written."


* ===========================================================
* SECTION VIII — SUBNATIONAL POVERTY CSV
*   Load hh16_base → collapse → SAVE 11: subnational_2016.dta
*   Load hh18_base → collapse → SAVE 12: subnational_2018.dta
*   MERGE 13: state-level 2018 1:1 state-level 2016
*   → SAVE 13: subnational_merged.dta → export CSV
*   All income/poverty in 2021 PPP int'l $
* ===========================================================

use "$data_dir\hh16_base.dta", clear

collapse (mean)   poverty_rate_2016 = pov_ali  ///
         (mean)   extreme_pov_2016  = pov_pat  ///
         (rawsum) pop_weighted_2016 = fac_exp  ///
         (count)  n_obs_2016        = ingreso_pc ///
         [aw=fac_exp], by(edo)

save "$data_dir\subnational_2016.dta", replace
display "[data/] saved → subnational_2016.dta"

use "$data_dir\hh18_base.dta", clear

collapse (mean)   poverty_rate_2018 = pov_ali_18 ///
         (mean)   extreme_pov_2018  = pov_pat_18 ///
         (rawsum) pop_weighted_2018 = fac_exp    ///
         (count)  n_obs_2018        = ingreso_pc ///
         [aw=fac_exp], by(edo)

save "$data_dir\subnational_2018.dta", replace
display "[data/] saved → subnational_2018.dta"

* MERGE 13: state-level 2018 1:1 state-level 2016
merge 1:1 edo using "$data_dir\subnational_2016.dta"
tab _merge   // checking but not acting

rename edo adm1_code
gen adm1_name = ""
replace adm1_name = "Aguascalientes"      if adm1_code == "01"
replace adm1_name = "Baja California"     if adm1_code == "02"
replace adm1_name = "Baja California Sur" if adm1_code == "03"
replace adm1_name = "Campeche"            if adm1_code == "04"
replace adm1_name = "Coahuila"            if adm1_code == "05"
replace adm1_name = "Colima"              if adm1_code == "06"
replace adm1_name = "Chiapas"             if adm1_code == "07"
replace adm1_name = "Chihuahua"           if adm1_code == "08"
replace adm1_name = "Ciudad de Mexico"    if adm1_code == "09"
replace adm1_name = "Durango"             if adm1_code == "10"
replace adm1_name = "Guanajuato"          if adm1_code == "11"
replace adm1_name = "Guerrero"            if adm1_code == "12"
replace adm1_name = "Hidalgo"             if adm1_code == "13"
replace adm1_name = "Jalisco"             if adm1_code == "14"
replace adm1_name = "Estado de Mexico"    if adm1_code == "15"
replace adm1_name = "Michoacan"           if adm1_code == "16"
replace adm1_name = "Morelos"             if adm1_code == "17"
replace adm1_name = "Nayarit"             if adm1_code == "18"
replace adm1_name = "Nuevo Leon"          if adm1_code == "19"
replace adm1_name = "Oaxaca"              if adm1_code == "20"
replace adm1_name = "Puebla"              if adm1_code == "21"
replace adm1_name = "Queretaro"           if adm1_code == "22"
replace adm1_name = "Quintana Roo"        if adm1_code == "23"
replace adm1_name = "San Luis Potosi"     if adm1_code == "24"
replace adm1_name = "Sinaloa"             if adm1_code == "25"
replace adm1_name = "Sonora"              if adm1_code == "26"
replace adm1_name = "Tabasco"             if adm1_code == "27"
replace adm1_name = "Tamaulipas"          if adm1_code == "28"
replace adm1_name = "Tlaxcala"            if adm1_code == "29"
replace adm1_name = "Veracruz"            if adm1_code == "30"
replace adm1_name = "Yucatan"             if adm1_code == "31"
replace adm1_name = "Zacatecas"           if adm1_code == "32"

gen small_sample_flag = (n_obs_2016 < 100 | n_obs_2018 < 100) if !missing(n_obs_2016)
note: All poverty rates use 2021 PPP income vs PPP-converted CONEVAL lines.

drop _merge

* SAVE 14: merged subnational dataset
save "$data_dir\subnational_merged.dta", replace
display "[data/] saved → subnational_merged.dta"

order adm1_code adm1_name ///
      poverty_rate_2016 poverty_rate_2018 ///
      extreme_pov_2016  extreme_pov_2018  ///
      n_obs_2016 n_obs_2018               ///
      pop_weighted_2016 pop_weighted_2018  ///
      small_sample_flag

* hardcoded output path — should use $out_dir but this section was added last
export delimited using ///
    "C:\Users\wb532966\eb-local\ai4coding-examples\ex01-old-stata-code\subnational_poverty.csv", ///
    replace

display "Subnational CSV exported."


* ===========================================================
* SECTION II.F — SHEET 0: DASHBOARD
* (written last in code; should be placed first in workbook —
*  Excel sheet ordering is by creation time so this ends up last.
*  Would need to manually reorder tabs in Excel. Known issue.)
* ===========================================================
* Added per director's request at October 2018 meeting.
* "Just a quick one-pager, two columns, so we can compare at a glance."
* Uses locals from earlier in this script.
* IMPORTANT: if run in isolation, local macros will be undefined
* and the dashboard will be blank.

putexcel set "$outfile", sheet("Sheet0_Dashboard") modify

putexcel A1 = "DASHBOARD — MEXICO HOUSEHOLD WELFARE: ENIGH 2016 vs 2018 (2021 PPP $)", bold
putexcel A2 = "All monetary indicators in 2021 PPP int'l $/month/capita. Sheets 1-6 for details."
putexcel B3 = "2016"
putexcel C3 = "2018"

putexcel A4 = "National population (weighted)"
putexcel B4 = `tot_pop_16'
putexcel C4 = `tot_pop_18'

putexcel A5 = "Poverty rate — Alimentaria CONEVAL (%)"
putexcel B5 = `ali_16'
putexcel C5 = `ali_18'

putexcel A6 = "Median per capita income (MXN, real 2016)"
putexcel B6 = `med_16b'
putexcel C6 = `med_18'

putexcel A7 = "Gini coefficient"
putexcel B7 = `gini_16b'
putexcel C7 = `gini_18'

putexcel A8 = "Employment rate, prime-age 25-60 (%)"
putexcel B8 = `emp_rate_16'
putexcel C8 = `emp_rate_18'

putexcel A10 = "Notes:"
putexcel A11 = "- PPP source: World Bank PA.NUS.PPP (ppp_2021=11.299 MXN/intl$)"
putexcel A12 = "- CPI source: Banco de Mexico INPC (2021=100; 2016=74.9, 2018=84.5)"
putexcel A13 = "- CONEVAL lines converted: nominal MXN × (100/CPI_year)/11.299 → 2021 PPP $"
putexcel A14 = "- All intermediary .dta files saved in: $out_dir\data\"

* List all saved intermediary files
local saved_files : dir "$data_dir" files "*.dta", respectcase
display _n "[data/] Intermediary files:"
display `"`saved_files'"`

display _n "=============================================="
display "Pipeline complete. Output: $outfile"
display "Figures:     $out_dir"
display "CSV:         $out_dir\subnational_poverty.csv"
display "Data files:  $out_dir\data\"
display "=============================================="
