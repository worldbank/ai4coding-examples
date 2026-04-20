mex-subsample is prepared using actual HH survey data for Mexico. 
It is a combination of variables and a random subsample of a half of the original data.
The raw data is taken from: 
2016: https://en.www.inegi.org.mx/programas/enigh/nc/2016/
2018: https://en.www.inegi.org.mx/programas/enigh/nc/2018/


The code:

* ============================================================
* ENIGH 2016 + 2018 — Earner Subsample
*
* Load individual income (ingresos) and characteristics
* (poblacion) for 2016 and 2018. Merge with main-job info
* (trabajos) and HH-level variables (concentradohogar).
* Keep only individuals with positive income, draw a 50%
* random subsample per year, select ~19 key variables,
* and save as mex-subsample.dta.
*
* Monetary variables converted to 2021 PPP international $
* using the same deflators as analysis_2016_2018.do.
* ============================================================

clear all
set more off

* ---- Paths (same as analysis_2016_2018.do) -----------------
global base_data "C:\Users\wb532966\OneDrive - WBG\AI\AI-course-2026-April\ai4coding-data\mex"
global script_dir "C:\Users\wb532966\eb-local\ai4coding-examples\ex01-old-stata-code"

* ---- PPP parameters (2021 base) ----------------------------
local ppp_2021 = 11.2990
local cpi_2016 = 74.9
local cpi_2018 = 84.5
local cpi_2021 = 100.0
local defl_16  = (`cpi_2021' / `cpi_2016') / `ppp_2021'
local defl_18  = (`cpi_2021' / `cpi_2018') / `ppp_2021'

* ---- Reproducible random seed ------------------------------
set seed 20260417

tempfile year2016 year2018

foreach year in 2016 2018 {

    local year_path "$base_data\\`year'"

    if `year' == 2016 local defl = `defl_16'
    else               local defl = `defl_18'

    display _n "========================================================"
    display    " Processing `year'"
    display    "========================================================"

    * ----------------------------------------------------------
    * 1. Individual characteristics (poblacion)
    * ----------------------------------------------------------
    use folioviv foliohog numren edad sexo nivelaprob gradoaprob ///
        trabajo_mp segsoc ///
        using "`year_path'\\poblacion.dta", clear

    * Gender
    gen hombre = (sexo == "1") if !missing(sexo)
    label var hombre "Male (1=yes)"

    * Years of education (same logic as analysis script)
    destring gradoaprob, gen(grado_n) force
    gen anios_educ = .
    replace anios_educ = 0             if nivelaprob == "0"
    replace anios_educ = grado_n       if inlist(nivelaprob, "1", "2")
    replace anios_educ = 6 + grado_n   if nivelaprob == "3"
    replace anios_educ = 9 + grado_n   if inlist(nivelaprob, "4", "5", "6")
    replace anios_educ = 12 + grado_n  if nivelaprob == "7"
    replace anios_educ = 16 + grado_n  if nivelaprob == "8"
    replace anios_educ = 18 + grado_n  if nivelaprob == "9"
    label var anios_educ "Years of formal education (estimated)"

    * Education category
    gen educ_cat = .
    replace educ_cat = 1 if inlist(nivelaprob, "0", "1")
    replace educ_cat = 2 if nivelaprob == "2"
    replace educ_cat = 3 if nivelaprob == "3"
    replace educ_cat = 4 if inlist(nivelaprob, "4", "5", "6")
    replace educ_cat = 5 if inlist(nivelaprob, "7", "8", "9")
    label define ec 1 "None/Preschool" 2 "Primary" 3 "Secondary" ///
                    4 "Post-secondary" 5 "Tertiary", replace
    label values educ_cat ec

    * Formality
    gen formal = (segsoc == "1") if !missing(segsoc)
    label var formal "Has social security (1=yes)"

    drop sexo nivelaprob gradoaprob grado_n trabajo_mp segsoc

    tempfile pobl
    save `pobl'

    * ----------------------------------------------------------
    * 2. Individual income (ingresos) — collapse to person level
    * ----------------------------------------------------------
    use folioviv foliohog numren ing_tri ///
        using "`year_path'\\ingresos.dta", clear

    * PPP-convert before collapsing
    quietly replace ing_tri = ing_tri * `defl'

    collapse (sum)   ing_tri_total = ing_tri ///
             (count) n_income_sources = ing_tri, ///
             by(folioviv foliohog numren)
    label var ing_tri_total    "Total quarterly indiv. income (2021 PPP intl $)"
    label var n_income_sources "Number of income sources"

    tempfile inc
    save `inc'

    * ----------------------------------------------------------
    * 3. Main job characteristics (trabajos)
    * ----------------------------------------------------------
    use folioviv foliohog numren id_trabajo scian sinco htrab ///
        using "`year_path'\\trabajos.dta", clear
    keep if id_trabajo == "1"

    * Industry sector (SCIAN)
    destring scian, gen(scian_n) force
    gen sector = .
    replace sector = 1 if scian_n >= 1100 & scian_n < 1200 & !missing(scian_n)
    replace sector = 2 if scian_n >= 3100 & scian_n < 3400 & !missing(scian_n)
    replace sector = 3 if scian_n >= 4300 & scian_n < 4900 & !missing(scian_n)
    replace sector = 4 if ((scian_n >= 4900 & !missing(scian_n)) | ///
                           (scian_n >= 2000 & scian_n < 3100))
    label define sec_lbl 1 "Agriculture" 2 "Manufacturing" ///
                         3 "Commerce" 4 "Services/Other", replace
    label values sector sec_lbl

    * Occupation category (SINCO)
    destring sinco, gen(sinco_n) force
    gen ocup_cat = .
    replace ocup_cat = 1 if sinco_n >= 1000 & sinco_n < 2000 & !missing(sinco_n)
    replace ocup_cat = 2 if sinco_n >= 2000 & sinco_n < 4000 & !missing(sinco_n)
    replace ocup_cat = 3 if sinco_n >= 4000 & sinco_n < 7000 & !missing(sinco_n)
    replace ocup_cat = 4 if sinco_n >= 7000 & sinco_n < 9000 & !missing(sinco_n)
    replace ocup_cat = 5 if sinco_n >= 9000 & !missing(sinco_n)
    label define oc_lbl 1 "Managers" 2 "Professionals" 3 "Skilled" ///
                        4 "Operators" 5 "Unskilled", replace
    label values ocup_cat oc_lbl

    label var htrab "Hours worked per week (main job)"
    drop id_trabajo scian sinco scian_n sinco_n

    tempfile jobs
    save `jobs'

    * ----------------------------------------------------------
    * 4. Household-level variables (concentradohogar)
    * ----------------------------------------------------------
    use folioviv foliohog factor ubica_geo tam_loc ing_cor tot_integ ///
        using "`year_path'\\concentradohogar.dta", clear

    rename factor fac_exp
    label var fac_exp "Expansion factor (survey weight)"

    * PPP-convert HH income
    quietly replace ing_cor = ing_cor * `defl'
    label var ing_cor "Quarterly HH corriente income (2021 PPP intl $)"

    * Monthly per capita HH income (quarterly ÷ 3 ÷ HH size)
    gen ingreso_pc = ing_cor / tot_integ / 3
    label var ingreso_pc "Monthly per capita HH income (2021 PPP intl $)"

    * State code
    gen str2 edo = substr(ubica_geo, 1, 2)
    label var edo "State code (2-digit)"

    * Rural/urban (tam_loc "4" = <2,500 inhabitants)
    gen rural = (tam_loc == "4") if !missing(tam_loc)
    label var rural "Rural locality (tam_loc=4, <2500 inhab)"

    * Macro-region
    gen region = .
    replace region = 1 if inlist(edo, "02","03","05","08","10","19","25","26","28")
    replace region = 2 if inlist(edo, "01","06","11","14","18","22","24","32")
    replace region = 3 if inlist(edo, "09","12","13","15","16","17","21")
    replace region = 4 if inlist(edo, "04","07","20","23","27","29","30","31")
    label define reg_lbl 1 "Norte" 2 "Centro-Norte" ///
                         3 "Centro" 4 "Sur-Sureste", replace
    label values region reg_lbl

    drop ubica_geo tam_loc ing_cor

    tempfile hh
    save `hh'

    * ----------------------------------------------------------
    * 5. Merge all modules
    * ----------------------------------------------------------
    use `pobl', clear

    * Individual income
    merge 1:1 folioviv foliohog numren using `inc', ///
        keep(master match) nogenerate

    * Main job
    merge 1:1 folioviv foliohog numren using `jobs', ///
        keep(master match) nogenerate

    * HH-level (weight, location, HH income)
    merge m:1 folioviv foliohog using `hh', ///
        keep(match) nogenerate

    * Year identifier
    gen int survey_year = `year'
    label var survey_year "Survey year (ENIGH)"

    * ----------------------------------------------------------
    * 6. Keep only individuals who earn something
    * ----------------------------------------------------------
    keep if ing_tri_total > 0 & !missing(ing_tri_total)
    display "  Earners retained: " _N

    * ----------------------------------------------------------
    * 7. Draw 50% random subsample
    * ----------------------------------------------------------
    gen double _rand = runiform()
    sort _rand
    local half = ceil(_N / 2)
    keep in 1/`half'
    drop _rand
    display "  50% subsample: " _N

    * ----------------------------------------------------------
    * 8. Keep selected variables (19 total)
    * ----------------------------------------------------------
    keep survey_year folioviv foliohog numren fac_exp ///
         edad hombre anios_educ educ_cat formal ///
         ing_tri_total ingreso_pc tot_integ ///
         sector ocup_cat htrab ///
         edo rural region

    order survey_year folioviv foliohog numren fac_exp ///
          edad hombre anios_educ educ_cat formal ///
          ing_tri_total ingreso_pc tot_integ ///
          sector ocup_cat htrab ///
          edo rural region

    if `year' == 2016 save `year2016', replace
    else               save `year2018', replace
}

* ==============================================================
* 9. Append both years and save
* ==============================================================
use `year2016', clear
append using `year2018'

label data "ENIGH 2016+2018 subsample — earners only, 50% random, 2021 PPP $"
note: Created from ENIGH poblacion + ingresos + trabajos + concentradohogar
note: Only individuals with positive quarterly income retained
note: 50% random subsample per year (seed=20260417)
note: Monetary variables in 2021 PPP international dollars

compress
save "$script_dir\\data\\03-clean\\mex-subsample.dta", replace

display _n "========================================================"
display    " Subsample saved → $script_dir\data\03-clean\mex-subsample.dta"
display    " Observations: " _N
display    " Variables:    " c(k)
display    "========================================================"

describe, short
tab survey_year
