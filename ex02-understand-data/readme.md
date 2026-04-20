## Data harmonization example

In this example, we explore how AI can support a common data science
workflow: taking raw data and transforming it into a clean,
analysis-ready format.

Following the common agentic
[data analysis workflow](https://worldbank.github.io/ai4coding/methods/common-workflow.html) and principles
of [safeguarding data](https://worldbank.github.io/ai4coding/methods/safeguard-data.html), we practice **metadata-driven approach** — using a data dictionary as an
intermediary between the raw data and the AI, rather than exposing
sensitive data directly.

### Learning objectives

By the end of this example, you will have practiced using AI to:

1. Set a clear objective and constraints for an AI coding session.
2. Build a data dictionary that captures variable names, types, units,
   and labels — without sharing raw data with the AI.
3. Document data harmonization requirements systematically as a
   mapping table.
4. Generate modular cleaning code driven by metadata, following
   [DIME Wiki](https://dimewiki.worldbank.org/) best practices.
   (The example prompts use **Stata** but include a substitution
   table for adapting to R or Python.)
5. Iterate on that code to resolve errors and refine outputs.
6. Verify results using an independent AI auditor session.
7. Document the harmonization for reproducibility.

### Data

We use Mexico's National Survey of Household Income and Expenditure
(ENIGH) for 2016 and 2018, which contains detailed information on
household income and other socio-economic characteristics.

|      | Download                                                      | Metadata                                                                |
| ---- | ------------------------------------------------------------- | ----------------------------------------------------------------------- |
| 2016 | [INEGI](https://en.www.inegi.org.mx/programas/enigh/nc/2016/) | [Catalog](https://www.inegi.org.mx/rnm/index.php/catalog/310) (Spanish) |
| 2018 | [INEGI](https://en.www.inegi.org.mx/programas/enigh/nc/2018/) | [Catalog](https://www.inegi.org.mx/rnm/index.php/catalog/511) (Spanish) |

This data is stored on your local machine at
`[your path to]/ai4coding-data/mex/` in subfolders `2016/` and
`2018/` as read-only files.

### Target specification

The objective is to clean and harmonize this data to the Global
Monitoring Database (GMD) specification, selectively outlined in
[Self-Study → GMD requirements](https://worldbank.github.io/ai4coding/selfstudy/gmd-requirements.html).
We harmonize only these three modules:

1. Demographics
2. Income
3. Consumption

## Detailed instructions

Let us proceed with the analysis of the data following the common agentic
[data analysis workflow](https://worldbank.github.io/ai4coding/methods/common-workflow.html).

::: {.callout-tip}
## How to use these prompts
Each prompt below is designed to be **copied and pasted** into your AI chat
with minimal modification. Placeholders in `[square brackets]` must be replaced
with your own values. Between prompts, we include brief guidance on what to
**expect** from the AI and what to **check** before moving on.
:::

::: {.callout-warning}
## Adapting prompts to R, Python, or other languages
The prompts below are written for **Stata**. If you use a different
language, replace the Stata-specific terms marked with
⚙ [Stata]{.badge .bg-info} using this reference table:

| Concept               | Stata                               | R                                                         | Python                                                                          |
| --------------------- | ----------------------------------- | --------------------------------------------------------- | ------------------------------------------------------------------------------- |
| **Language role**     | *"Stata co-programmer"*             | *"R co-programmer"*                                       | *"Python co-programmer"*                                                        |
| **Script files**      | `.do` files                         | `.R` files                                                | `.py` files                                                                     |
| **Output format**     | `.dta`                              | `.rds` or `.parquet`                                      | `.parquet` or `.csv`                                                            |
| **Master script**     | `00-master.do`                      | `00-master.R`                                             | `00_master.py`                                                                  |
| **Global parameters** | `global macro`                      | named list or `config.yml`                                | `config.yaml` or constants module                                               |
| **Path handling**     | globals (`$rawdata`)                | `here::here()` or named list                              | `pathlib.Path` or config dict                                                   |
| **User switching**    | `global user 1`                     | `Sys.getenv("USER")` or config                            | `os.getenv("USER")` or config                                                   |
| **Package install**   | `ssc install pkg, replace`          | `install.packages("pkg")`                                 | `pip install pkg`                                                               |
| **Settings**          | `ieboilstart, version(14)`          | `stopifnot(getRversion() >= "4.1")` + `renv::snapshot()`  | `assert sys.version_info >= (3, 9)` + `pip freeze > requirements.txt`           |
| **Seed**              | `set seed 12345`                    | `set.seed(12345)`                                         | `random.seed(12345)` / `np.random.seed(12345)`                                  |
| **Logging**           | `log using` / `log close`           | `sink()` or `logr` package                                | `logging` module                                                                |
| **ID check**          | `isid varlist`                      | `assertr::verify(is_uniq(id)) %>% verify(!is.na(id))`     | `assert df[cols].notna().all().all() and df.duplicated(subset=cols).sum() == 0` |
| **Extended missings** | `.a`, `.b`, … `.z` with labels      | `NA` + reason column or `tagged_na` (haven)               | `np.nan` + reason column                                                        |
| **Assertions**        | `assert condition`                  | `stopifnot(condition)`                                    | `assert condition`                                                              |
| **Encode strings**    | `encode, label() noextend`          | `factor()` with explicit levels                           | `pd.Categorical()` with explicit categories                                     |
| **Variable labels**   | `label variable`                    | `labelled::var_label()`                                   | column metadata / `attrs`                                                       |
| **Value labels**      | `label define` / `label values`     | `labelled::val_labels()`                                  | `pd.Categorical`                                                                |
| **Toggle execution**  | `if ($run_mod == 1) do "script.do"` | `if (config$run_mod) source(here::here("code/script.R"))` | `if config["run_mod"]: exec(open("script.py").read())`                          |

The workflow steps, data safeguarding principles, and DIME Wiki
conventions apply regardless of language.
:::

### Step 1. Set the Overall Objective

::: {.callout-note}
## Why this matters
A clear, specific objective anchors the entire conversation. A vague prompt
like *"help me clean some data"* gives the AI no guardrails and leads to
generic output. Instead, name the survey, country, years, target specification,
and language up front.
:::

```{.markdown file-name="Prompt"}
You are my Stata co-programmer. The objective is to harmonize Mexico's
ENIGH survey waves (2016 and 2018) into a single analysis-ready dataset
with consistent variable names, types, units, labels, categories, and
recall periods, following the Global Monitoring Database (GMD) specification.
```

::: {.callout-tip }
## What to check before moving on
The AI should echo back the survey name, years, and target specification.
If it asks clarifying questions — good, answer them. If it immediately
starts writing code, remind it: *"Do not write any code yet."*
:::


### Step 2. Define inputs and outputs

::: {.callout-note}
## Why this matters
Ambiguous output specs are the most common source of wrong results. Be
explicit about the unit of observation, file format, and which modules
to include. Note: demographics and labor income are individual-level,
while consumption is household-level — the AI needs to know this.
:::

```{.markdown file-name="Prompt"}
The final output should be a `.dta` master dataset following DIME Wiki
conventions (https://dimewiki.worldbank.org/Master_Dataset):

- Each row is an individual-year observation; each column is a
  harmonized variable.
- The dataset must have a unique, fully-identifying ID variable
  (`isid hhid pid year` must pass without error). ID variables must
  be uniquely identifying, fully identifying (no missing IDs), and
  constant across the project, per DIME Wiki ID variable properties
  (https://dimewiki.worldbank.org/ID_Variable_Properties).
- All variables must have variable labels (up to 80 characters).
- All categorical variables must be stored numerically with value
  labels attached.
- Missing values must use Stata extended missing values (`.a`, `.b`,
  etc.) with value labels explaining the reason — never regular `.`
  in the final dataset.
- Higher-level IDs (e.g., household ID in an individual dataset)
  must be included to enable merging across units of observation.

It should conform to the GMD variable specifications that I will
provide separately. Harmonize only these modules:
demographics, income, and consumption.

Note: consumption variables are at the household level; demographic
and income variables are at the individual level. Consumption
variables will be merged onto the individual-level dataset via
household ID, so each individual inherits their household's
consumption values.
The code should be modular, well-commented, and reproducible.
Do not write any code yet.
```

```{.markdown file-name="Prompt"}
Input data is located on my local machine at
`[your path to]/ai4coding-data/mex/` in subfolders `2016/` and `2018/`.
Files are read-only. You must never access the data directly or embed
file paths in the code. All paths must be specified as global macro
parameters so the code runs without modification on any machine.
Do not write any code yet.
```

::: {.callout-warning }
## Common mistake
Leaving the path as `OneDrive/.../` with an ellipsis. The AI will either
guess or error. Replace `[your path to]` with the actual path on your
machine, e.g., `C:/Users/jdoe/OneDrive - WBG/`.
:::


### Step 3. Create a data dictionary

::: {.callout-note}
## Why this matters
The data dictionary is the bridge between your data and the AI. It lets
the AI reason about variable structure without ever seeing actual
observations — a key
[data safeguarding](/methods/safeguard-data.qmd) practice.
:::

```{.markdown file-name="Prompt"}
Write Stata code in file `01-data-dictionary.do` that creates a data
dictionary for each survey wave (2016 and 2018). For every variable,
capture: name, storage type, display format, value label name, variable
label, number of missing values, number of distinct values, and
min/max for numeric variables.

The code should:

1. Accept a global macro `rawdata` specifying the path to raw data.
2. Loop over all `.dta` files in the `2016/` and `2018/` subfolders.
3. Save each dictionary as a markdown file in
   `data/dictionary/{original-filename}.md`.
   (This path will be parameterized as a global macro in Step 6;
   for now, hard-coding it is acceptable for this standalone script.)
4. Never print or display actual observation-level data values
   (microdata) in the console. File paths and variable metadata
   may be displayed.

Do not write any code yet. First, restate the objective, constraints,
and success criteria in your own words. Report any uncertainties. Only
when I confirm, proceed to write the code.
```

::: {.callout-tip }
## What to check before moving on
Review the AI's restatement carefully. Does it mention all four
constraints (global macro, loop, markdown output, no data display)?
If anything is off, correct it before confirming.

After the code is generated, **run it** and inspect a few of the
output `.md` files. Do the variable names, types, and labels look
correct? Are there any files that were missed?
:::


### Step 4. Gather external metadata

::: {.callout-note}
## Why this matters
Raw `.dta` labels often lack detail on recall periods, units of
measurement, or survey design. External metadata catalogs fill those
gaps — but the AI may not be able to browse the web. If web access
fails, download the documentation yourself and paste the relevant
sections into the chat.
:::

```{.markdown file-name="Prompt"}
Fetch the variable-level metadata for the ENIGH datasets from:

- 2016: <https://www.inegi.org.mx/rnm/index.php/catalog/310>
- 2018: <https://www.inegi.org.mx/rnm/index.php/catalog/511>

Extract: variable names, definitions, units of measurement, recall
periods, universe (who was asked), and any coding notes.
Save a summary in `data/dictionary/metadata-2016.md` and
`data/dictionary/metadata-2018.md`.

If you cannot access these URLs, tell me and I will paste the relevant
metadata manually. If pasting manually, include at minimum: the
variable list with definitions, the coding scheme for categorical
variables, and any notes on recall periods or skip patterns.
```


### Step 5. Verify understanding before coding

::: {.callout-note}
## Why this matters
This is a **checkpoint**, not a coding step. Before investing time in
code generation, force the AI to demonstrate that it understands the
data structure, the target specification, and the mapping between them.
Misunderstandings caught here save hours of debugging later.
:::

```{.markdown file-name="Prompt"}
Before we write any cleaning code, summarize your understanding of:

1. The structure of the raw data (which files, key variables, units
   of observation).
2. The target GMD variables for each module (demographics, income,
   consumption).
3. Any variables that are ambiguous, missing, or require assumptions.

Present this as a mapping table with columns: GMD variable name,
source file, source variable(s), transformation needed, and open
questions. Do not write any code yet.
```

::: {.callout-tip }
## What to check before moving on
The mapping table is the most important output of this workflow. Review
each row:

- Is the source variable correct?
- Is the proposed transformation reasonable?
- Are the open questions genuine or does the AI need more context?

Resolve every open question before proceeding to Step 6.
:::


### Step 6. Develop data cleaning code iteratively

::: {.callout-note}
## Why this matters
Asking for all code at once typically produces something that looks
plausible but fails on edge cases. Instead, first confirm the
variable-level plan, then request code module by module.

The master do-file should follow [DIME Wiki conventions](https://dimewiki.worldbank.org/Master_Do-files):
an intro header, standardised settings, root folder globals with user
switching, project folder globals, and toggle-controlled sub-scripts.
:::

``````{.markdown file-name="Prompt"}
Based on the confirmed mapping table, develop the data cleaning code
in Stata. The master do-file `00-master.do` must follow DIME Wiki
conventions (https://dimewiki.worldbank.org/Master_Do-files) and
include the following sections in this order:

1. **Intro header** — a comment block explaining the project purpose,
   required input files, output files, and unit of observation.
2. **Install user-written commands** — install all required packages
   (e.g., `ssc install ietoolkit, replace`). This section may be
   commented out after first run but must remain in the file.
3. **Settings** — use `ieboilstart, version(14.0)` (or the oldest
   Stata version on the team) followed by `` `r(version)' `` to
   standardise settings across users. Set `set seed` for
   reproducibility.
4. **Root folder globals** — define a `global user` switch so each
   team member sets only their own path:
   ```
   if $user == 1 global projectfolder "C:/Users/Ann/..."
   if $user == 2 global projectfolder "C:/Users/John/..."
   ```
5. **Project folder globals** — define globals for all sub-folders
   (`$rawdata`, `$cleaned`, `$logs`, `$dictionary`, etc.) relative
   to `$projectfolder`. No hard-coded paths anywhere else.
6. **Units and assumptions** — store any conversion rates, exchange
   rates, or control variable lists as globals.
7. **Log file** — open a log with `log using "$logs/harmonize.log",
   replace` and close it at the end with `log close`.
8. **Sub-scripts with toggles** — call each module script inside an
   `if` block so individual modules can be turned on/off:
   ```
   if ($run_demographics == 1) do "$dofiles/01-demographics.do"
   if ($run_income == 1)       do "$dofiles/02-income.do"
   if ($run_consumption == 1)  do "$dofiles/03-consumption.do"
   ```
9. **Final merge** — combine module outputs into a single dataset
   and save to `$cleaned`.

Module scripts:

- `01-demographics.do`: cleans and harmonises demographic variables.
- `02-income.do`: cleans and harmonises income/labor variables.
- `03-consumption.do`: cleans and harmonises consumption variables.

Each module script must follow DIME Wiki data cleaning best practices
(https://dimewiki.worldbank.org/Data_Cleaning) and Stata coding
practices (https://dimewiki.worldbank.org/Stata_Coding_Practices):

- Read all paths via global macros — no hard-coded paths. Use
  forward slashes (`/`) and double quotes around all file paths.
  Always include the file extension (`.dta`, `.csv`, etc.).
- **ID variables**: verify uniqueness and completeness with
  `isid` after every merge or reshape. Never allow regular missing
  values (`.`) in ID variables.
- **Survey codes and missing values**: replace survey codes
  (e.g., -999, -88) with Stata extended missing values (`.d` for
  "don't know", `.r` for "refused", etc.) and attach value labels
  to each extended missing value. Use the same letter consistently
  across all modules.

  ::: {.callout-note collapse="true"}
  ## R / Python equivalent for extended missing values
  **R**: Create a companion `_miss_reason` column (e.g.,
  `income_miss_reason`) coded as a factor with levels like
  `"don't know"`, `"refused"`. Alternatively, use
  `haven::tagged_na()` to preserve Stata-style tagged `NA`s.
  **Python**: Replace survey codes with `np.nan` and add a
  parallel `_miss_reason` column using `pd.Categorical` with
  explicit categories.
  :::
- **Strings**: convert all categorical string variables to labelled
  numeric variables using `encode` with both `label()` and
  `noextend` options.
- **Illogical values**: flag and document illogical values with
  comments explaining the correction logic.
- **Variable labels**: every cleaned variable must have a variable
  label (up to 80 characters).
- **Value labels**: all categorical variables must have value labels.
- After cleaning each variable, assert GMD constraints
  (e.g., `assert age >= 0 if !missing(age)`,
  `assert inlist(male, 0, 1) if !missing(male)`).
- Include comments explaining every transformation and its
  rationale. Document any corrections made to the data.
- **Merge safety**: after every `merge` or `reshape`, run `isid`
  to confirm the expected unit of observation is preserved. Use
  `iecodebook apply` if available to batch-apply variable and
  value labels.

Write the code for `00-master.do` first. Do not write the module
scripts yet.
``````

::: {.callout-tip }
## What to check before moving on
After the master script is generated, verify it contains all nine
DIME Wiki sections.

After confirming the master script, request each module script
individually using a prompt like the one below. Repeat for each
module (`02-income.do`, `03-consumption.do`), adjusting the
module name and variable list accordingly.
:::

```{.markdown file-name="Prompt"}
Now write `01-demographics.do` following the confirmed mapping table
and the coding standards defined in `00-master.do`. Process both the
2016 and 2018 waves. Read all paths from global macros. After every
merge or reshape, verify the unit of observation with `isid`.
```

::: {.callout-tip }
## What to check after each module script

After each module script is generated:

1. Read through the code — does every transformation match the mapping
   table you confirmed?
2. Run the code on one wave first.
3. Check the assertion results: any failures indicate either a coding
   bug or a mistaken assumption.
4. Report failures back to the AI and iterate.
:::


### Step 7. Verify results with an independent review

::: {.callout-important}
## Run this in a separate agent session
This step **must** be executed in a **different** AI agent session (a
new chat window or a different AI tool) than the one that wrote the
cleaning code. The AI that produced the code is biased toward
confirming its own work — it will tend to overlook its own mistakes.
A fresh agent has no prior context and will review the code on its
merits alone. This follows the independent verification principle from
the [common workflow](/methods/common-workflow.qmd).
:::

```{.markdown file-name="Prompt"}
Act as an independent data auditor. I will provide:

1. The GMD variable specifications for demographics, income, and
   consumption.
2. The cleaning code in `01-demographics.do`, `02-income.do`, and
   `03-consumption.do`.
3. Summary statistics of the cleaned output (which I will generate
   and paste).

For each GMD variable, check:
- Does the code correctly map from source to target?
- Are value labels and coding consistent with the GMD spec?
- Are edge cases handled (missings, top/bottom coding, skip patterns)?
- Are the assertions sufficient?

Also check DIME Wiki data cleaning and master dataset standards:
- Are ID variables uniquely and fully identifying (`isid` tested)?
- Are all survey codes replaced with extended missing values
  (`.a`–`.z`) with value labels — no regular `.` in the final data?
- Are all categorical variables stored numerically with value labels
  (no bare string variables)?
- Are all variables labelled (variable labels up to 80 characters)?
- Does `encode` use both `label()` and `noextend` options?
- Are higher-level IDs included for cross-level merging?
- Are file paths dynamic and absolute (globals, forward slashes,
  double quotes, file extensions)?

Report issues as a numbered list with the variable name, the problem,
and a suggested fix.
```

::: {.callout-tip }
## What to check before moving on
Run `summarize` and `tabulate` on key cleaned variables and paste the
output into the chat. The auditor prompt works best when it has
concrete numbers to check, not just code.
:::


### Step 8. Document the harmonization

::: {.callout-note}
## Why this matters
Code without documentation is a liability. The
[DIME Wiki Reproducible Research guidelines](https://dimewiki.worldbank.org/Reproducible_Research)
emphasise four pillars: data documentation, data publication, code
publication, and output publication. A harmonization report captures
decisions that are invisible in the code and ensures someone unfamiliar
with the project can reproduce the results.
:::

```{.markdown file-name="Prompt"}
Write a harmonization report in `docs/harmonization-report.md`
following DIME Wiki reproducible research guidelines
(https://dimewiki.worldbank.org/Reproducible_Research). It should
cover:

1. **Objective**: what was harmonized and to which specification.
2. **Data sources**: survey name, years, download URLs, file inventory.
3. **Data documentation**: describe the data dictionary, metadata
   sources, and any corrections or feedback incorporated during
   cleaning — including records of AI-suggested changes that were
   accepted or rejected.
4. **Variable mapping**: the confirmed mapping table from Step 5.
5. **Decisions and assumptions**: for each variable where a judgment
   call was needed, record the choice and rationale.
6. **Known limitations**: variables that could not be harmonized,
   quality concerns, or caveats for downstream users.
7. **Reproducibility checklist**:
   - Required Stata version (matching `ieboilstart` setting in master).
   - Required user-written packages (listed in master do-file).
   - Folder structure and global macro setup.
   - Instructions for a new user: change `$user` number in
     `00-master.do`, set path, and run.
   - Seed value used (if any randomisation or sampling is involved).
8. **Code publication readiness**: confirm that no hard-coded paths
   remain, all do-files run from the master, and the output is
   fully reproducible by toggling `$user` in one place.
```

::: {.callout-tip }
## What to check before moving on
The ultimate test: can a colleague clone your project folder, change
only the `$user` number in `00-master.do`, and reproduce every output?
If not, the documentation is incomplete.
:::
