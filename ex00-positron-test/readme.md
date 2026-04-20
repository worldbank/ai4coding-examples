# Exercise 0 — Software Setup Test

This example is in `ex00-positron-test`, which should be in `C:/WBG/ai/` on your computer if you followed the setup instructions correctly.
Open this folder as a project in Positron to ensure that all file paths work correctly.

## Objective

This exercise verifies that your software environment is correctly set up for the course. Each file in this folder runs a small analysis that exercises a different language or tool. If every file runs without errors, your setup is ready.

## What is being tested

| File                 | Language / Tool  | What it checks                                         |
| -------------------- | ---------------- | ------------------------------------------------------ |
| `test-r.R`           | R                | tidyverse, ggplot2, palmerpenguins, OLS regression     |
| `test-python.py`     | Python           | pandas, seaborn, matplotlib, statsmodels, scikit-learn |
| `test-jupyter.ipynb` | Python (Jupyter) | Same Python stack inside a Jupyter notebook            |
| `test-quarto.qmd`    | Quarto + R       | Quarto rendering with R code chunks, knitr, broom      |
| `test-stata.do`      | Stata            | Data generation, regression, and graphing              |

## How to run each file

1. **Open the file** in Positron (or VS Code).
2. **Run it:**
   - **R script** (`test-r.R`) — Open the file and click the **Run** button (or press `Ctrl+Shift+Enter` to run all lines). The R console will execute the script.
   - **Python script** (`test-python.py`) — Open the file and click **Run** (or press `Ctrl+Shift+Enter`). The Python console will execute the script.
   - **Jupyter notebook** (`test-jupyter.ipynb`) — Open the notebook, then click **Run All** in the toolbar to execute every cell.
   - **Quarto document** (`test-quarto.qmd`) — Open the file and click the **Render** button (or run `quarto render test-quarto.qmd` in the terminal) to produce an HTML report.
   - **Stata do-file** (`test-stata.do`) — Open the file and click **Run** (or execute `do test-stata.do` in Stata).
3. **Check the output.** Each file should produce tables, plots, or regression output without errors. If something fails, the error message will tell you which package or dependency is missing.

## Expected outcome

- Four ggplot2 charts and an OLS summary (R)
- Four seaborn/matplotlib charts and an OLS summary (Python script and notebook)
- A rendered HTML document with figures, tables, and inline statistics (Quarto)
- Three Stata graphs, summary statistics, and a regression table (Stata)

If all files run successfully, your environment is ready for the course.
