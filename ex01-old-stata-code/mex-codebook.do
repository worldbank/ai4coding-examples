* ============================================================
* Mexico HH Survey (ENIGH) — Full Data Pipeline
*
* Steps per survey year:
*   1. Copy raw .dta files → data/01-raw/
*   2. Apply 2021 PPP conversion to monetary variables
*      → save intermediary → data/02-interm/
*   3. Merge concentrado (HH-level) + poblacion (individual)
*      → save merged → data/02-interm/
*   4. Final clean dataset → data/03-clean/
*   5. Write codebook .txt for each output stage
*
* PPP SOURCE: World Bank PA.NUS.PPP (LCU per international $)
*   and CPI rebased to 2021=100 for Mexico (INPC)
*   Reference: https://data.worldbank.org/indicator/NY.GDP.MKTP.PP.KD?locations=MX
* ============================================================

clear all
set more off

* ---- USER SETTINGS -----------------------------------------
* Root folder containing 2016/, 2018/, 2024/ sub-folders
global base_path "C:\Users\wb532966\OneDrive - WBG\AI\AI-course-2026-April\ai4coding-data\mex"
* Script folder (script lives here; data/ sub-folders are relative to it)
global script_dir "C:\Users\wb532966\eb-local\ai4coding-examples\ex01-old-stata-code"
* Output folder for codebook .txt files
global out_path "`c(pwd)'"
* ============================================================


* ============================================================
* PPP PARAMETERS — Mexico, constant 2021 PPP international $
*
*   Formula applied to each nominal MXN monetary variable:
*     value_2021_PPP = value_MXN * (cpi_2021 / cpi_year) / ppp_2021
*
*   Where:
*     cpi_year  = Mexico CPI index for survey year  (2021 = 100)
*     cpi_2021  = 100  (by definition)
*     ppp_2021  = PPP conversion factor for 2021
*                 (MXN per 2021 international dollar)
*
*   Sources:
*     PA.NUS.PPP  — World Bank, PPP conversion factor (LCU per int$)
*     INPC        — Banco de México, rebased to 2021=100
* ============================================================

* PPP conversion factor: MXN per international $ (current prices)
*   2016: 8.9335   2018: 9.7956   2021: 11.2990   2024: ~13.80
* CPI Mexico (2021 = 100)
*   2016: 74.9     2018: 84.5     2021: 100.0      2024: 128.5

* These are stored in a frame so the processing loop can look them up
frame create ppp_params
frame ppp_params {
    clear
    input int year  double ppp_factor  double cpi_idx
    2016   8.9335    74.9
    2018   9.7956    84.5
    2021  11.2990   100.0
    2024  13.8000   128.5
    end
    label variable year       "Survey year"
    label variable ppp_factor "PPP conv. factor (MXN per int'l $, current)"
    label variable cpi_idx    "Mexico CPI index (2021=100)"
}

* Reference PPP factor and CPI for 2021 (constant base)
local ppp_2021 = 11.2990
local cpi_2021 = 100.0

* ============================================================
* MONETARY VARIABLE PATTERNS IN ENIGH
*   Concentrado: ingcor  gasto_mon  gasto_nm  gasto_tot
*                ing_cor  gas_corr  gas_no_co
*   Hogares:     gasmon  gasnomon
*   Poblacion:   ing_tri  ing_men
*   (script also catches any variable whose label contains
*    "ingreso", "gasto", "monetar", "pesos" case-insensitively)
* ============================================================

global monetary_stubs "ingcor gasto_mon gasto_nm gasto_tot ing_cor gas_corr gas_no_co gasmon gasnomon ing_tri ing_men"


* ============================================================
* HELPER PROGRAMS
* ============================================================

* ------------------------------------------------------------
* 1. _write_codebook_block
*    Write one file's variable metadata to an open file handle
* ------------------------------------------------------------
capture program drop _write_codebook_block
program define _write_codebook_block
    args filepath fhandle

    quietly use "`filepath'", clear

    local nobs = c(N)
    local nvar = c(k)

    local fname = reverse(substr(reverse("`filepath'"), 1, ///
                  strpos(reverse("`filepath'"), "\") - 1))

    file write `fhandle' _n
    file write `fhandle' "  FILE : `fname'" _n
    file write `fhandle' "  Obs  : `nobs'   |   Vars: `nvar'" _n
    file write `fhandle' "  " _dup(80) "-" _n
    file write `fhandle' ///
        "  Variable" _col(30) "Type" _col(46) "Label (original)" _n
    file write `fhandle' "  " _dup(80) "-" _n

    preserve
        quietly describe, replace
        forvalues i = 1/`=_N' {
            local vname = name[`i']
            local vtype = type[`i']
            local vlab  = varlab[`i']
            file write `fhandle' ///
                "  `vname'" _col(30) "`vtype'" _col(46) "`vlab'" _n
        }
    restore

    file write `fhandle' _n
end


* ------------------------------------------------------------
* 2. _save_raw_copy
*    Copy a raw .dta file to data/01-raw/ without modification
* ------------------------------------------------------------
capture program drop _save_raw_copy
program define _save_raw_copy
    args filepath outdir

    quietly use "`filepath'", clear

    * derive output filename: raw_<original>
    local fname = reverse(substr(reverse("`filepath'"), 1, ///
                  strpos(reverse("`filepath'"), "\") - 1))
    local outname = "raw_`fname'"

    quietly save "`outdir'\\`outname'", replace
    display "  [01-raw] saved → `outname'"
end


* ------------------------------------------------------------
* 3. _apply_ppp
*    Convert monetary variables in the current dataset to
*    2021 PPP international dollars and save to 02-interm/
*    Args: year  ppp_factor  cpi_idx  outdir  outname_stem
* ------------------------------------------------------------
capture program drop _apply_ppp
program define _apply_ppp
    args year ppp_factor cpi_idx outdir outname_stem

    local ppp_2021 = 11.2990
    local cpi_2021 = 100.0

    * Multiplier: deflate to 2021 prices then convert to int'l $
    local deflator = (`cpi_2021' / `cpi_idx') / `ppp_2021'

    * --- apply to known monetary stubs ---
    foreach stub of global monetary_stubs {
        capture confirm variable `stub'
        if !_rc {
            quietly replace `stub' = `stub' * `deflator'
            quietly label variable `stub' ///
                "`stub' (2021 PPP intl $, conv. from `year' MXN)"
        }
    }

    * --- also catch vars whose label contains monetary keywords ---
    quietly describe, replace
    local nvars = _N
    restore, preserve   // keep describe results while we scan
    preserve
        quietly describe, replace
        forvalues i = 1/`=_N' {
            local vname = name[`i']
            local vlab  = lower(varlab[`i'])
            if regexm("`vlab'", "ingreso|gasto|monetar|pesos") {
                * only convert if numeric and not already converted
                capture confirm numeric variable `vname'
                if !_rc {
                    * check it hasn't been converted yet (stub loop above)
                    local already = 0
                    foreach stub of global monetary_stubs {
                        if "`vname'" == "`stub'" local already = 1
                    }
                    if `already' == 0 {
                        quietly replace `vname' = `vname' * `deflator'
                        quietly label variable `vname' ///
                            "`vname' (2021 PPP intl $, conv. from `year' MXN)"
                    }
                }
            }
        }
    restore

    * add dataset-level note documenting the conversion
    note: PPP converted — survey year `year', ///
          PPP factor `ppp_factor' MXN/intl$, ///
          CPI deflator `cpi_idx' (2021=100), ///
          reference: PA.NUS.PPP World Bank

    quietly save "`outdir'\\`outname_stem'_ppp.dta", replace
    display "  [02-interm] saved → `outname_stem'_ppp.dta"
end


* ============================================================
* SECTION A  — TEST run on 2016 (metadata only, first 2 files)
* ============================================================
local test_year  "2016"
local test_path  "$base_path\\`test_year'"

display _n "Files in test folder: `test_path'"
local test_files : dir "`test_path'" files "*.dta", respectcase
display `"`test_files'"'

local outfile_test "$out_path\codebook_mex_TEST_`test_year'.txt"
file open fht using "`outfile_test'", write replace text

file write fht "============================================================" _n
file write fht " TEST CODEBOOK: Mexico HH Survey `test_year'" _n
file write fht " Generated: `c(current_date)' `c(current_time)'" _n
file write fht " BASE PATH: `test_path'" _n
file write fht "============================================================" _n

local cnt 0
foreach f of local test_files {
    local ++cnt
    if `cnt' > 2 continue, break
    _write_codebook_block "`test_path'\\`f'" fht
}
if `cnt' == 0 {
    file write fht "  *** No .dta files found — check test_path ***" _n
}
file close fht
display "TEST codebook saved → `outfile_test'"


* ============================================================
* SECTION B  — FULL PIPELINE: raw → interm (PPP) → merge → clean
* ============================================================

foreach year in 2016 2018 2024 {

    display _n "========================================================"
    display    " Processing survey year: `year'"
    display    "========================================================"

    local year_path "$base_path\\`year'"

    * -- folder shortcuts
    local dir_raw   "$script_dir\data\01-raw"
    local dir_interm "$script_dir\data\02-interm"
    local dir_clean  "$script_dir\data\03-clean"

    * -- look up PPP parameters from frame
    frame ppp_params {
        quietly levelsof year, local(yrs)
    }
    local ppp_fac = .
    local cpi_idx = .
    frame ppp_params {
        quietly summarize ppp_factor if year == `year'
        local ppp_fac = r(mean)
        quietly summarize cpi_idx if year == `year'
        local cpi_idx = r(mean)
    }
    if `ppp_fac' == . {
        display "  WARNING: no PPP params for `year', skipping PPP step"
    }

    * -- enumerate .dta files in this year's raw folder
    local filelist : dir "`year_path'" files "*.dta", respectcase

    if "`filelist'" == "" {
        display "  WARNING: no .dta files found in `year_path'"
        continue
    }

    * --------------------------------------------------------
    * STEP 1 — Copy raw files to data/01-raw/
    * --------------------------------------------------------
    display _n "  STEP 1: copying raw files to data/01-raw/"
    foreach f of local filelist {
        _save_raw_copy "`year_path'\\`f'" "`dir_raw'"
    }

    * --------------------------------------------------------
    * STEP 2 — Apply PPP conversion; save to data/02-interm/
    *          Identify concentrado and poblacion modules
    * --------------------------------------------------------
    display _n "  STEP 2: applying 2021 PPP conversion"

    * ENIGH naming: concentrado<year>*.dta  and  poblacion<year>*.dta
    local conc_file   ""
    local pobl_file   ""
    local other_files ""

    foreach f of local filelist {
        local flo = lower("`f'")
        if regexm("`flo'", "concentrado") {
            local conc_file "`f'"
        }
        else if regexm("`flo'", "poblacion") {
            local pobl_file "`f'"
        }
        else {
            local other_files "`other_files' `f'"
        }
    }

    * PPP-convert and save each module
    if "`conc_file'" != "" {
        quietly use "`year_path'\\`conc_file'", clear
        _apply_ppp `year' `ppp_fac' `cpi_idx' "`dir_interm'" "conc`year'"
    }
    if "`pobl_file'" != "" {
        quietly use "`year_path'\\`pobl_file'", clear
        _apply_ppp `year' `ppp_fac' `cpi_idx' "`dir_interm'" "pobl`year'"
    }
    foreach f of local other_files {
        if "`f'" == "" continue
        local stem = substr("`f'", 1, length("`f'") - 4)  // drop .dta
        quietly use "`year_path'\\`f'", clear
        _apply_ppp `year' `ppp_fac' `cpi_idx' "`dir_interm'" "`stem'`year'"
    }

    * --------------------------------------------------------
    * STEP 3 — Merge concentrado (HH-level) with poblacion
    *          (individual-level) on folioviv + foliohog
    *          → save merged intermediary to data/02-interm/
    * --------------------------------------------------------
    display _n "  STEP 3: merging concentrado + poblacion"

    if "`conc_file'" != "" & "`pobl_file'" != "" {

        * Load HH-level (concentrado) — already PPP-converted
        quietly use "`dir_interm'\\conc`year'_ppp.dta", clear

        * Merge 1:m with individual-level (poblacion)
        * Key: folioviv (dwelling ID) + foliohog (HH within dwelling)
        merge 1:m folioviv foliohog using "`dir_interm'\\pobl`year'_ppp.dta", ///
            keep(match master) nogenerate

        * Label the merged dataset
        label data "ENIGH `year' — HH+individual merged, 2021 PPP"
        note: Merged `year': concentrado (1:m) + poblacion on folioviv foliohog
        note: Monetary variables converted to 2021 PPP international dollars

        quietly save "`dir_interm'\\merged`year'_hh_indiv.dta", replace
        display "  [02-interm] saved → merged`year'_hh_indiv.dta  " ///
                "(N=`c(N)', k=`c(k)')"

    }
    else {
        display "  INFO: concentrado or poblacion not found — skipping merge"

        * If only one file exists, save it directly as the merged product
        if "`conc_file'" != "" {
            quietly use "`dir_interm'\\conc`year'_ppp.dta", clear
            quietly save "`dir_interm'\\merged`year'_hh_only.dta", replace
        }
        else if "`pobl_file'" != "" {
            quietly use "`dir_interm'\\pobl`year'_ppp.dta", clear
            quietly save "`dir_interm'\\merged`year'_indiv_only.dta", replace
        }
    }

    * --------------------------------------------------------
    * STEP 4 — Optional: merge in hogares (dwelling expenses)
    *          if present; append to the HH+individual file
    * --------------------------------------------------------
    local hog_file ""
    foreach f of local filelist {
        local flo = lower("`f'")
        if regexm("`flo'", "hogares") local hog_file "`f'"
    }

    if "`hog_file'" != "" {
        display _n "  STEP 4: merging in hogares (dwelling expenses)"

        * Re-use PPP-converted hogares from interm
        local hog_stem = substr("`hog_file'", 1, length("`hog_file'") - 4)
        local hog_interm "`dir_interm'\\`hog_stem'`year'_ppp.dta"

        capture confirm file "`hog_interm'"
        if _rc {
            quietly use "`year_path'\\`hog_file'", clear
            _apply_ppp `year' `ppp_fac' `cpi_idx' "`dir_interm'" "`hog_stem'`year'"
        }

        * Determine which merged file to enrich
        local src_merged ""
        capture confirm file "`dir_interm'\\merged`year'_hh_indiv.dta"
        if !_rc  local src_merged "`dir_interm'\\merged`year'_hh_indiv.dta"
        else {
            capture confirm file "`dir_interm'\\merged`year'_hh_only.dta"
            if !_rc local src_merged "`dir_interm'\\merged`year'_hh_only.dta"
        }

        if "`src_merged'" != "" {
            quietly use "`src_merged'", clear
            merge m:1 folioviv foliohog using "`hog_interm'", ///
                keep(match master) nogenerate

            note: Merged `year': hogares appended (m:1) on folioviv foliohog
            quietly save "`src_merged'", replace
            display "  [02-interm] updated → merged file enriched with hogares"
        }
    }

    * --------------------------------------------------------
    * STEP 5 — Produce clean final dataset → data/03-clean/
    *          Drop merge artifacts, add year key, save
    * --------------------------------------------------------
    display _n "  STEP 5: writing clean dataset to data/03-clean/"

    local clean_src ""
    capture confirm file "`dir_interm'\\merged`year'_hh_indiv.dta"
    if !_rc  local clean_src "`dir_interm'\\merged`year'_hh_indiv.dta"
    else {
        capture confirm file "`dir_interm'\\merged`year'_hh_only.dta"
        if !_rc local clean_src "`dir_interm'\\merged`year'_hh_only.dta"
        else {
            capture confirm file "`dir_interm'\\merged`year'_indiv_only.dta"
            if !_rc local clean_src "`dir_interm'\\merged`year'_indiv_only.dta"
        }
    }

    if "`clean_src'" != "" {
        quietly use "`clean_src'", clear

        * Add survey year identifier
        capture confirm variable survey_year
        if _rc {
            quietly generate int survey_year = `year'
            quietly label variable survey_year "Survey year (ENIGH)"
            quietly order survey_year, first
        }

        quietly save "`dir_clean'\\clean_mex_`year'.dta", replace
        display "  [03-clean] saved → clean_mex_`year'.dta  " ///
                "(N=`c(N)', k=`c(k)')"
    }
    else {
        display "  WARNING: no merged file to promote to clean — skipping"
    }

    * --------------------------------------------------------
    * STEP 6 — Codebook from all raw files (unchanged labels)
    * --------------------------------------------------------
    display _n "  STEP 6: writing raw codebook"
    local outfile "$out_path\codebook_mex_`year'.txt"
    file open fh using "`outfile'", write replace text

    file write fh "============================================================" _n
    file write fh " CODEBOOK: Mexico HH Survey (ENIGH) — `year'" _n
    file write fh " Generated: `c(current_date)' `c(current_time)'" _n
    file write fh " BASE PATH: `year_path'" _n
    file write fh " PPP factor: `ppp_fac' MXN/intl$ | CPI index: `cpi_idx' (2021=100)" _n
    file write fh "============================================================" _n

    foreach f of local filelist {
        _write_codebook_block "`year_path'\\`f'" fh
    }

    file close fh
    display "  Codebook saved → `outfile'"
}

display _n "========================================================"
display    " Pipeline complete."
display    " Raw copies  : $script_dir\data\01-raw\"
display    " Intermediary: $script_dir\data\02-interm\"
display    " Clean data  : $script_dir\data\03-clean\"
display    " Codebooks   : $out_path"
display    "========================================================"
