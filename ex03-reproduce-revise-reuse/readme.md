
This example is in `ex03-reproduce-revise-reuse`, which should be in
`C:/WBG/ai/` on your computer if you followed the setup instructions correctly.
Open this folder as a project in Positron.

## Objective

Practice the **3R workflow** — Reproduce, Revise, and Reuse — using AI
assistance to adapt, modify, and repurpose existing analytical code. This is
one of the most common tasks in applied economics: you inherit a script,
need to run it on new data, change the specification, and extract reusable
components, etc. This example will give you hands-on experience with how AI
can support each step of this process, and what to watch out for.

Our specific objectives are to learn how to use AI to:

1. Understand and reproduce existing analysis.
2. Revise it to make it clear, transparent, well documented.
3. Set up system prompt files that guide the AI to not do certain things.
4. Adapt it to new data.
5. Document it in accordance with the reproducibility package and requirements

## Part 1: Reproduce

* Develop prompts to understand the original code and its assumptions before making any changes.
* Run the original code and verify that you can reproduce the results as expected.
* Use AI to assist in running and debugging the code, but be cautious about blindly accepting AI suggestions without understanding them.

## Part 2: Revise

* Discuss with AI: What are the strengths and weaknesses of the original code? How maintainable is it? What are the potential risks of running this code as-is on new data? What is uncertain about it that you would want to verify before running? What must be addressed and changed to make it reusable and safe to run with the data?
* Critically reflect on the code's maintainability, strengths, weaknesses, and potential risks.
* Restructure the code with the help of AI to make it more modular, transparent, and well-documented. This may involve breaking it into functions, adding comments, improving variable names, and creating a clear workflow.
* Ensure that revised code reproduces the same results as the original code before moving on to the next step. Document if not.

## Part 3: Setup system prompts

* Create system prompt files `.github/copilot-instructions.md` and `claude.md` specifying key dos and don'ts.
* Check with AI if it adheres by asking to produce code that it is not allowed.

## Part 4: Reuse

* Adapt the revised code to new data.

## Part 5: Document

* Generate a reproducibility package that includes the revised code, a data dictionary, and a report documenting the analysis, decisions, limitations, and reproducibility checklist. Use AI to assist in generating these documents, but ensure that they are accurate and complete.
* Use links to the reproducibility requirements.
