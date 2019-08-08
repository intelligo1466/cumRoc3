[![DOI](https://zenodo.org/badge/200124550.svg)](https://zenodo.org/badge/latestdoi/200124550)
# %cumRoc3 -- Cumulative ROC curve analysis of three-level ordinal outcomes
## Type
User-called SAS macro that wraps supporting macros.
## Purpose
Implements cumulative ROC curve analysis for three-level (ternary) ordinal outcomes and comprises a two-stage semiprametric method where Stage 1 is cumulative logit regression and Stage 2 is cumulative ROC curve analysis. Analysis includes identification of cutpoints that discriminate ordinal outcome levels based on ROC curve-based criteria -- Total Accuracy, Youden Index, Matthews Correlation -- as well as calculation of parametric cutpoints from cumulative logit regression parameters.
* Three operational modes may be selected for the macro
1. Complete procedure [DEFAULT]: analysis, post-processing, reporting
1. Analysis and post-processing only
1. Reporting only (prerequisite: modes 1 or 2 must have been run at least once before)

* Author: B. Rey de Castro, Sc.D., rdecastro@cdc.gov
	* Centers for Disease Control and Prevention, Atlanta, Georgia, USA
* Licenses: Apache-2.0, CC-BY-4.0
* SUGGESTED CITATION FOR %cumRoc3:

> ***deCastro, B.R. 2019, %cumRoc3 -- Cumulative ROC curve analysis of three-level ordinal outcomes, v1.0.1, DOI:10.5281/zenodo.3364094.***

## PREREQUISITES
* SAS 9.4 and later
	* Base SAS
	* SAS/STAT
	* SAS IML
* Three-level (ternary) ordinal outcome with levels encoded as: 0, 1, 2
	* Designated reference level
		* DEFAULT:      encoded as: 2 (Macro parameter _yOrd=A)
		* Alternative:  encoded as: 0 (Macro parameter _yOrd=D)
* Continuous predictor variable
* User-specified directory structure for output of tabulated results and cumulative ROC curve images (see macro parameters _dir00, _dirOut, _dirPng)

## ADVISORIES
* The code has been tested in SAS 9.4 TS1M3 with the two included demonstration datasets and runs with no ERRORs or WARNINGs output to the LOG.
* It is possible for ROC curve-based criteria to be tied for different values of the continuous predictor. Ties are displayed in the tabulated results.
* Preferences to facilitate interpretation
	* Numeric levels of the ternary ordinal outcome should be assigned a SAS format
	* The continuous predictor should be assigned a SAS label
* For supporting macro %cr3_1Logit
	* Occasionally had convergence problems running Stage 1 cumulative logit regression with SAS 9.4 TS1M3 on Windows 10 64-bit.
	* To ensure routine convergence, MAXITER= 500 was set for Newton-Raphson optimization with ridging (SAS default).
	* As this is an arbitrary setting, consider adjusting or eliminating this setting if it does not suit your needs.
* For supporting macro %cr3_2ROC
	* In SAS 9.4, OUTROC= in LOGISTIC includes the automatic variable _SOURCE_ and is used by %cr3_2ROC.
	* In versions before 9.4, this automatic variable is instead called _STEP_ and takes different values than _SOURCE_.
	* The macro's default is to refer to _SOURCE_, but to permit use in versions before 9.4 I have included commented-out code that refers to _STEP_.

***

## USAGE
~~~sas
%cumRoc3(_yOut,_xPred,_vsLbl,_cutFmt,
	_dsn,_dir00,_dirOut,_dirPng,_dateOut,
	_libNm=DEMO,_propOdds=PO,_yOrd=A,_macMode=1,_macComp=YES,_macComp=YES,
	_outCntnts=YES,_outRtf=NO,_debug0=NO) ;
~~~

__Note__: macro parameter **_macMode** selects one of three operational modes:

	1: Complete procedure [DEFAULT]: analysis, post-processing, reporting
	2: Analysis and post-processing only
	3: Reporting only (prerequisite: modes 1 or 2 must have been run at least once before)

### PARAMETERS, Positional
	_yOut		Dependent variable, three-level ordinal outcome encoded as numeric: 0, 1, 2
	_xPred		Predictor variable, continuous
	_vsLbl		Label for predictor variable: for LABEL statement
	_cutFmt		SAS format for cutpoints of predictor variable
	_dsn		SAS7BDAT input data comprising ternary ordinal dependent variable and continuous predictor
	_dir00		Root output directory location
	_dirOut		Results output subdirectory location
				&_dir00./&_dirOut fully specifies text output subdirectory location
	_dirPng		Image output subdirectory location
				&_dir00./&_dirPng fully specifies image output subdirectory location
	_dateOut	Date suffix for output filename

### PARAMETERS, Keyword with defaults
	_libNm=DEMO	Input SAS library name: for LIBNAME statement
			DEFAULT: DEMO
	_propOdds=PO	Specify model odds assumption
			DEFAULT: PO
				PO: proportional odds assumption
				NPO: non-proportional odds assumption
	_yOrd=A		Specify order of ordinal outcome levels
			Equivalent to specifying reference outcome level
			DEFAULT: A
				A: levels in ascending order ==> reference level &_yOut=2
				D: levels in descending order ==> reference level &_yOut=0
	_macMode=1	Specify macro's operating mode
			DEFAULT: 1
				1: Complete procedure: analysis, criteria and parametric cutpoint calculation, reporting
				2: Analysis and criteria and parametric cutpoint calculation only
				3: Reporting only: modes 1 or 2 must have been run at least once before
	_macComp=YES	Request compilation of supporting macros
			Supporting macros must be compiled at least once during current SAS session before running %cumRoc3
			DEFAULT: YES
				YES: compile supporting macros
				NO: skip compilation
	_outCntnts=YES	Request CONTENTS of permanent output datasets
			DEFAULT: YES
				YES: append CONTENTS of permanent output datasets to results
				NO: do not run CONTENTS for permanent output datasets
	_outRtf=NO	Request tabulated results output to RTF
			DEFAULT: NO
				NO: Outputs results to TXT
				YES: Outputs results to RTF
	_debug0=NO	Request temporary scratch datasets be saved for review and debugging
			DEFAULT: NO
				NO: Scratch datasets discarded
				YES: Scratch datasets retained in WORK library after end of macro run

## INPUT
	SAS7BDAT: input data comprising ternary ordinal dependent variable (&_yOut) and continuous predictor (&_xPred)
		TARGET: &_LIBNM..&_dsN

## OUTPUT
	MACRO VARIABLE, GLOBAL: Suffix for output filename
		_fileSfx	&_YOUT._&_XPRED._PO for proportonal odds assumption
				&_YOUT._&_XPRED._NPO for non-proportonal odds assumption
	MACRO VARIABLE, GLOBAL: Title text indicating which proportional odds assumption used in cumulative logit model
		_poTitle	Proportonal Odds
				Non-Proportonal Odds
	MACRO VARIABLE, GLOBAL: Indicator that ternary ordinal dependent variable is compatible
		_yOK=FAIL	DEFAULT: FAIL
						FAIL: incompatible
						PASS: compatible
	MACRO VARIABLE, GLOBAL: Indicates order of ordinal outcome for transformation to binary	outcome
		_ordIng		ASCEND for _yOrd = A: Y=2 reference category
				DESCEND for _yOrd = D: Y=0 reference category
	MACRO VARIABLE, GLOBAL: Format name of ordinal outcome
		_yFmt		<SAS format>
	MACRO VARIABLE, GLOBAL: Label of continuous predictor
		_xLbl		<SAS label>
	MACRO VARIABLE, GLOBAL: Number of observations used for models
		_xObs		Formatted as integer
				_xObs = _nObs
	MACRO VARIABLE, GLOBAL: Number of observations used for models
		_nObs		Formatted with commas separating every three digits
				_nObs = _xObs
	SAS7BDAT: Temporary input data from &_LIBNM..&_dsN used for macro processing
		TARGET: _inDsn
	SAS7BDAT: Parameter estimates for variance calculation of ratio by Delta and Fieller's Methods
		TARGET: &_LIBNM..PARMS4VAR_&_fileSfx
	SAS7BDAT: Variance-covariance matrix for parameter estimates
		TARGET: &_LIBNM..COVB_&_fileSfx
	SAS7BDAT: Parameter estimates
		TARGET: &_LIBNM..CUMLOGPARM_&_fileSfx
	SAS7BDAT: Parameter estimates and variances
		TARGET: &_LIBNM..CUMLOGTABLE_&_fileSfx
	SAS7BDAT: Predicted cumulative probabilities
		TARGET: &_LIBNM..CUMLOGPRED_&_fileSfx
	SAS7BDAT: Association of predicted probabilities and observed responses
		TARGET: &_LIBNM..ASSOC_&_fileSfx
	SAS7BDAT: Cumulative ROC curves 0 and 1 with 2x2 table frequencies, ROC criteria, AUCs
		TARGET: &_LIBNM..ROC_&_fileSfx
	SAS7BDAT: Cumulative ROC curve AUCs 0 and 1
		TARGET: &_LIBNM..AUC_&_fileSfx
	SAS7BDAT: Optimal ROC curve-based cutpoints and cumulative ROC curve AUCs
		TARGET: &_LIBNM..CUTBASE_&_fileSfx
	SAS7BDAT: Parametric cutpoints with 95% confidence intervals by Fieller's Method and Delta Method, including ROC curve-based criteria computed at parametric cutpoints and 2x2 table frequencies
		TARGET: &_LIBNM..CUTPARMX_&_fileSfx
	SAS7BDAT: Optimal ROC curve-based cutpoints, parametric cutpoints with 95% confidence intervals by Fieller's Method and Delta Method, and cumulative ROC curve AUCs
		TARGET: &_LIBNM..CUMROC3_&_fileSfx
	PNG: [300 DPI] Charts of cumulative ROC curves 0 and 1 output by LOGISTIC. Black and white style suitable for journal manuscript.
		TARGET: &_dir00./&_dirPng./ROC&_J._&_fileSfx._&_dateOut..PNG
	Output options for tabulated results
		_outRtf=NO :: DEFAULT
			TXT:: TARGET: &_dir00./&_dirOut/CUMROC3_&_fileSfx._&_dateOut..TXT
		_outRtf=YES
			RTF:: TARGET: &_dir00./&_dirOut/CUMROC3_&_fileSfx._&_dateOut..RTF

## Demonstrations
### Example Call 1 -- Cork Quality
~~~sas
%cumRoc3(quality,dArea,Quality,%STR(BESTD8.3),cork_SI,
	%STR(C:/rootDir/project),
	%STR(Output/Cork),
	%STR(Images/Cork),
	2019_DEMO,_macMode=1,_macComp=YES,
	_outCntnts=YES,_outRtf=NO) ;
~~~
A more routine (and less verbose) call to %cumRoc3.
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

### Example Call 2 -- NHANES NNAL Tobacco Smoke Exposure
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

## DEVELOPMENT PLATFORM
OS: Microsoft Windows 10 64-bit

SAS: 9.4 TS1M3 64-bit

# DISCLAIMERS
1. DISCLAIMER OF WARRANTY. Under the terms of the Apache License 2.0 License, "Unless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its Contributions) on an "as is" basis, without warranties or conditions of any kind, either express or implied, including, without limitation, any warranties or conditions of title, non-infringement, merchantability, or fitness for a particular purpose. You are solely responsible for determining the appropriateness of using or redistributing the Work and assume any risks associated with Your exercise of permissions under this License."
1. The findings and conclusions in this repository are those of the author and do not necessarily represent the views of the Centers for Disease Control and Prevention. Use of trade names is for identification only and does not imply endorsement by the Centers for Disease Control and Prevention.

# ATTRIBUTION
1. Under the terms of Creative Commons License CC-BY-4.0, "You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use."
1. SUGGESTED CITATION FOR %cumRoc3:

> ***deCastro, B.R. 2019, %cumRoc3 -- Cumulative ROC curve analysis of three-level ordinal outcomes, v1.0.1, DOI:10.5281/zenodo.3364094.***