# %cumRoc3 -- Cumulative ROC curve analysis of three-level (ternary) ordinal outcomes
**%cumRoc3** is a SAS® macro that implements cumulative ROC curve analysis for three-level (ternary) ordinal outcomes and comprises a two-stage semiprametric method where Stage 1 is cumulative logit regression and Stage 2 is cumulative ROC curve analysis. Analysis includes identification of cutpoints that discriminate outcome levels based on ROC curve-based criteria -- Total Accuracy, Youden Index, Matthews Correlation -- as well as calculation of parametric cutpoints from cumulative logit regression parameters.

## MANIFEST
* %cumRoc3 (in macros/cumRoc3_MAIN_MAC.sas)
	* Macro that is called directly by the user and wraps several supporting macros (in macros/)
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
	* Base SAS
	* SAS/STAT
	* SAS IML
* Three-level (ternary) ordinal outcome with levels encoded as: 0, 1, 2
* Continuous predictor variable

## ADVISORIES
* The code has been tested in SAS 9.4 TS1M3 with the two included demonstration datasets and runs with no ERRORs or WARNINGs output to the LOG.
* It is possible for ROC curve-based criteria to be tied for different values of the continuous predictor. Ties are displayed in the tabulated results.
* Preferences to facilitate interpretation
	* Numeric levels of the ternary ordinal outcome should be assigned a SAS format
	* The continuous predictor should be assigned a SAS label
* For %cr3_1Logit
	* There may be occasional convergence problems running Stage 1 cumulative logit regression with SAS 9.4 TS1M3 on Windows 10 64-bit.
	* To ensure routine convergence, MAXITER= 500 was set for Newton-Raphson optimization with ridging (SAS default).
	* As this is an arbitrary setting, consider adjusting or eliminating this setting if it does not suit your needs.
* For %cr3_2ROC
	* In SAS 9.4, OUTROC= in LOGISTIC includes the automatic variable _SOURCE_ and is used by %cr3_2ROC.
	* In versions before 9.4, this automatic variable is instead called _STEP_ and takes different values than _SOURCE_.
	* The macro's default is to refer to _SOURCE_, but to permit use in versions before 9.4 I have included commented-out code that refers to _STEP_.

## USAGE
~~~sas
%cumRoc3(_yOut,_xPred,_vsLbl,_cutFmt,
	_dsn,_dir00,_dirOut,_dirPng,_dateOut,
	_libNm=DEMO,_propOdds=PO,_yOrd=A,_macMode=1,_macComp=YES,_macComp=YES,
	_outCntnts=YES,_outRtf=NO,_debug0=NO) ;
~~~
* Example Call 1 -- Cork Quality
~~~sas
%cumRoc3(shsX3,URXNALln,Exposure,%STR(BESTD8.1),nnal_SI,
    %STR(C:/rootDir/project),
    %STR(Output/NNAL),
    %STR(Images/NNAL),
    2019_DEMO,_propOdds=NPO,_macMode=1,_macComp=YES,
    _outCntnts=YES,_outRtf=NO) ;
~~~
A more routine (and less verbose) call to %cumRoc3
* Supporting macros not recompiled (prerequisite: macros compiled at least once before during current SAS session)
* CONTENTS of permanent output datasets not appended to results
* Tabulated results output to RTF
~~~sas
%cumRoc3(quality,dArea,Quality,%STR(BESTD8.3),cork_SI,
    %STR(C:/rootDir/project),
    %STR(Output/Cork),
    %STR(Images/Cork),
    2019_DEMO,_macComp=NO,
    _outCntnts=NO,_outRtf=YES) ;
~~~

* Example Call 2 -- NHANES NNAL Tobacco Smoke Exposure
~~~sas
%cumRoc3(shsX3,URXNALln,Exposure,%STR(BESTD8.1),nnal_SI,
    %STR(C:/rootDir/project),
    %STR(Output/NNAL),
    %STR(Images/NNAL),
    2019_DEMO,_propOdds=NPO,_macMode=1,_macComp=YES,
    _outCntnts=YES,_outRtf=NO) ;
~~~
A less verbose call.
~~~sas
%cumRoc3(shsX3,URXNALln,Exposure,%STR(BESTD8.1),nnal_SI,
    %STR(C:/rootDir/project),
    %STR(Output/NNAL),
    %STR(Images/NNAL),
    2019_DEMO,_propOdds=NPO,_macComp=NO,
    _outCntnts=NO,_outRtf=YES) ;
~~~