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

You may find detailed instructions here: [https://worldbank.github.io/ai4coding/selfstudy/example-2.html](https://worldbank.github.io/ai4coding/selfstudy/example-2.html)
