# Cumulative ROC curves for discriminating three or more ordinal outcomes with cutpoints on a shared continuous measurement scale
## SUPPORTING INFORMATION -- SI3 File
Data, NHANES Tobacco Smoke Exposure. For demonstration of cumulative ROC curve analysis for a ternary ordinal outcome of self-reported tobacco smoke exposure.
* NHANES: National Health and Nutrition Examination Survey
## File: nhanes_SI3.csv
* Comma-delimited text file with 5 variables
* 16990 records

## Variables
1. SEQN -- Unique identifier for NHANES participant
	* Numeric
	* Original NHANES variable
1. SDDSRVYR -- NHANES cycle (original NHANES variable)
	* Numeric
		* 5 => 2007 - 2008
		* 6 => 2009 - 2010
		* 7 => 2011 - 2012
1. urxnalLN -- Ln NNAL, Urine [ng/mL]: natural log transformed from URXNAL (original NHANES variable)
	* Numeric
	* NNAL: 4-[methylnitrosamino]-1-[3-pyridyl]-1-butanol (CAS No. 76014-81-8)
1. shsX3_C -- Tobacco Smoke Exposure
	* Character
	* Three categories of self-reported tobacco smoke exposure
		* Non-exposed: non-user of tobacco products and not exposed to secondhand tobacco smoke
		* SHS Exposed: non-user of tobacco products exposed to secondhand tobacco smoke
			* SHS: secondhand tobacco smoke
		* Combusted, Exlusive: user of combusted tobacco products exclusively (exclusive smoker)
1. shsX3 -- Tobacco Smoke Exposure
	* Numeric
	* Three categories of tobacco smoke exposure, corresponding to shsX3_C
		* 0 => Non-exposed
		* 1 => SHS Exposed
		* 2 => Combusted tobacco, Exlusive

