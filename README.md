# %cumRoc3 -- SAS® macro for cumulative ROC curve analysis of three-level (ternary) ordinal outcomes
**%cumRoc3** is a SAS macro that implements cumulative ROC curve analysis for three-level (ternary) ordinal outcomes and comprises a two-stage semiprametric method where Stage 1 is cumulative logit regression and Stage 2 is cumulative ROC curve analysis. Analysis includes identification of cutpoints that discriminate outcome levels based on ROC curve-based criteria -- Total Accuracy, Youden Index, Matthews Correlation -- as well as calculation of parametric cutpoints from cumulative logit regression parameters.

## INVENTORY
* %cumRoc3
	* Macro that is called directly by the user and wraps several supporting macros
* Demonstration datasets
	* Cork Quality -- cork_SI2.CSV in data/cork
		* Description: see README_SI2.md in data/cork.
		* Reference: Campilho A.J. [Image Recognition and Automatic Classification of Natural Products] (Portuguese). Available at http://extras.springer.com/2007/978-3-540-71972-4/DATASETS/Cork%20Stoppers/Cork%20Stoppers.xls (February 27, 2017) 1985.
		* Usage: import CSV to SAS7BDAT by revising demoCork.sas in data\cork\ for your local circumstances then running the program.
	* NHANES NNAL Tobacco Smoke Exposure -- nhanes_SI3.CSV in data/nnal
		* Description: see README_SI3.md in data/nnal.
		* Reference: CDC National Center for Health Statistics. National Health and Nutrition Examination Survey. Available at http://www.cdc.gov/nchs/nhanes.htm (April 22, 2017) 2017.
		* Usage: import CSV to SAS7BDAT by revising demoNnal.sas in data\nnal\ for your local circumstances then running the program.
## PREREQUISITES
* SAS 9.4 or later
* Three-level (ternary) ordinal outcome with levels encoded as: 0, 1, 2
* Continuous predictor variable

## ADVISORIES
* The code has been tested in SAS 9.4 TS1M3 with the two included demonstration datasets and runs with no ERRORs or WARNINGs output to the LOG.
* It is preferable for a SAS format to be assigned to the numeric outcome levels
* It is preferable for a SAS label to be assigned to the continuous predictor

## USAGE
~~~sas
%cumRoc3(_yOut,_xPred,_vsLbl,_cutFmt,_dsn,
_dir00,
_dirOut,
_dirPng,
_dateOut,_libNm=DEMO,_propOdds=PO,_yOrd=A,_macMode=1,_outCntnts=YES) ;
~~~
* Example Call 1 Cork Quality
~~~sas
%cumRoc3(quality,dArea,Quality,%STR(BESTD8.3),cork_SI,
%STR(C:/rootDir/project),
%STR(Output/Cork),
%STR(Images/Cork),
2019_DEMO,_macMode=1) ;
~~~
* Example Call 2 NHANES NNAL Tobacco Smoke Exposure
~~~sas
%cumRoc3(shsX3,URXNALln,Exposure,%STR(BESTD8.1),nnal_SI,
%STR(C:/rootDir/project),
%STR(Output/NNAL),
%STR(Images/NNAL),
2019_DEMO,_propOdds=NPO,_macMode=1) ;
~~~