# Suggested prompts 

The goal of this exercise is to:
 explore Positron's AI coding features with Stata by:

1. Writing and executing a basic do-file
2. Using AI assistance to generate and refine Stata code
3. Iterating on code with inline suggestions and chat prompts

## Code for `my-first-do-in-positron.do`

```stata
* Load sys auto data and make a regression of milage over weight.
* Plot a density curve of the residuals and a histogram of the fitted values.

sysuse auto, clear
regress mpg weight
predict residuals, resid
predict fitted, xb
kdensity residuals, normal
histogram fitted, normal
```

Navigate to console and execute: 

```stata
help regress
```

Navigate to Session > Variables and open the data set for exploration.

## Prompts examples for using AI to create first Stata do file in Positron

1. Create the file: `second-positron-do-with-ai`

2. Write comments at the top of the file and save it. 

```stata
/*
Goal: To learn how to use Positron AI assistance to write Stata code and 
execute it. This code should include: data loading, descriptive statistics, 
regression analysis, and visualization.

In details, these steps are: 
*/
```

3. Then proceed adding the details and use in-line suggestions.

4. Here are the details I propose to have. Make your own version of it.

```stata
/*
1. Load exemplary data from data/raw/
2. Summarize descriptive statistics of all variables
3. Run a regression of income on individual characteristics
4. Create a scatter plot of income vs age 
5. Create a box plot of income vs education levels
6. Save regression results and figures in an Excel file
*/
```

4. Open Assistant chat and type:

```
Develop code that implements the steps outlined in the comments for the file `my-first-do-in-positron.do`. Do not run the code.
```

5. Inspect the code and choose which parts to accept or reject

6. Use `run` button to execute the code

7. Select code that does not do what you expected. Press `Ctrl + I` and 
   ask AI to revise it.

8. Ask the ai to:

```
Create a new regression adding a fixed-effect of time and implementing 
the robust standard errors. Use #executeCode to run stata code in console 
autonomously to check whether it works.
```
