* Example stata code for Positron

* Load auto dataset
sysuse auto, clear
* Generate a new variable for price in thousands
gen price_k = price / 1000
* Run a regression of price on weight and length
regress price_k weight length
* Create a scatter plot of price vs weight
scatter price_k weight
* Create a histogram of price
histogram price_k, normal
* Save the dataset with the new variable
save auto_modified, replace
