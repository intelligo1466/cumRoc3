/*  ##########################################################################
    ##########################################################################
    SAS Version 9.4 TS1M3 and later
    License     Apache-2.0 Apache License 2.0
    Copyright   CC-BY-4.0 Creative Commons Attribution 4.0 International Public License
    ##########################################################################
    Name:       %cr3_1Logit
    Type:       SAS macro
    Purpose:    Cumulative ROC analysis, Stage 1: cumulative logit regression

    Author: B. Rey de Castro, Sc.D., rdecastro@cdc.gov
    Centers for Disease Control and Prevention, Atlanta, Georgia, USA
    ##########################################################################

ADVISORY
    * Occasionally had convergence problems running Stage 1 cumulative logit regression with SAS 9.4 TS1M3 on Windows 10 64-bit.
    * To ensure routine convergence, MAXITER= 500 was set for Newton-Raphson optimization with ridging (SAS default).
    * As this is an arbitrary setting, consider adjusting or eliminating this setting if it does not suit your needs.

OUTPUT
    MACRO VARIABLE, GLOBAL: Number of observations used for models
        _xObs   Formatted as integer
                _xObs = _nObs
    MACRO VARIABLE, GLOBAL: Number of observations used for models
        _nObs   Formatted with commas separating every three digits
                _nObs = _xObs
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

DISCLAIMERS
1. DISCLAIMER OF WARRANTY. Under the terms of the Apache License 2.0 License, "Unless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its Contributions) on an "as is" basis, without warranties or conditions of any kind, either express or implied, including, without limitation, any warranties or conditions of title, non-infringement, merchantability, or fitness for a particular purpose. You are solely responsible for determining the appropriateness of using or redistributing the Work and assume any risks associated with Your exercise of permissions under this License."
2. The findings and conclusions in this report are those of the author and do not necessarily represent the views of the Centers for Disease Control and Prevention. Use of trade names is for identification only and does not imply endorsement by the Centers for Disease Control and Prevention.
*/
%MACRO cr3_1Logit ;
    %GLOBAL _xObs _nObs ;
    TITLE ; FOOTNOTE ;
    TITLE1 "STAGE 1: Cumulative Logit Regression" ;
    TITLE2 "&_ordIng.ING &_yOut on &_xPred" ;
    TITLE3 "&_poTitle Assumed" ;

    PROC LOGISTIC   DATA=   _inDsn PLOTS= None ;
        FORMAT &_yOut 8.0 ; /* Strip formatted values and revert to numeric for indexing of predicted probabilties */
        MODEL &_yOut (ORDER=Internal) = &_xPred
            %IF       %UPCASE(&_propOdds)= PO
                %THEN %STR( /LINK= CumLogit covB CLPARM= PL CLOdds= BOTH ORPVALUE ) ;
            %ELSE %IF %UPCASE(&_propOdds)= NPO
                %THEN %STR( /LINK= CumLogit covB CLPARM= PL CLOdds= BOTH ORPVALUE UNEQUALSLOPES= (&_xPred) ) ;
        ;
/* ========================================================================== */
/* ============================A D V I S O R Y ============================== */
    * Occasionally had convergence problems running Stage 1 cumulative logit regression with SAS 9.4 TS1M3 on Windows 10 64-bit. ;
    * To ensure routine convergence, MAXITER= 500 was set for Newton-Raphson optimization with ridging (SAS default). ;
    * As this is an arbitrary setting, consider adjusting or eliminating this setting if it does not suit your needs. ;
/* ========================================================================== */
        NLOPTIONS MAXITER= 500 ;
        OUTPUT  Out=        &_LIBNM..CUMLOGPRED_&_fileSfx (
                                KEEP= &_xPred &_yOut y_0 y_1 cp_0 cp_1 cp_2
                                LABEL= "Predicted cumulative probabilities" )
                predProbs=  Cumulative
        ;
        ODS OUTPUT
        /* ParameterEstimates: for variance calculation of ratio by Delta and Fieller's Methods
            Variable ClassVal0 [Response] DF Estimate StdErr WaldChiSq ProbChiSq */
            ParameterEstimates=
                &_LIBNM..PARMS4VAR_&_fileSfx (
                    LABEL= "Parameter estimates for variance calculation of ratio by Delta and Fieller's Methods"
                    RENAME=(Variable=Parameter
                            %IF %UPCASE(&_propOdds)= NPO %THEN %STR( Response=ClassVal0 ) ;
                ))
        /* CLParmPL: Parameter estimates and profile-likelihood confidence intervals
            Parameter ClassVal0 [Response] Estimate LowerCL UpperCL */
            CLParmPL=_parmCl
                    %IF %UPCASE(&_propOdds)= NPO %THEN %STR( (RENAME=(Response=ClassVal0)) ) ;
        /* covB and NObs for variance calculation of ratio by Delta and Fieller's Methods */
            /* Variance-covariance matrix for parameter estimates */
            covB=   &_LIBNM..COVB_&_fileSfx (LABEL= "Variance-covariance matrix for parameter estimates")
            /* Number of observations used */
            NObs=   _NObs
        /* Odds Ratios Wald Confidence Limits */
            CLOddsWald= _oddsW (
                RENAME=(    Effect=     Parameter
                            LowerCL=    wLowerCL
                            UpperCL=    wUpperCL
                            pValue=     wPvalue )
                DROP= Unit OddsRatioEst )
        /* Odds Ratios Profile-Likelihood Confidence Limits */
            CLOddsPL=   _oddsPl (
                RENAME=(    Effect=     Parameter
                            LowerCL=    plLowerCL
                            UpperCL=    plUpperCL
                            pValue=     plPvalue )
                DROP= Unit )
        /* Association of Predicted Probabilities and Observed Responses */
            Association=&_LIBNM..ASSOC_&_fileSfx (LABEL= "Association of predicted probabilities and observed responses")
        ;
        /* Score Test for the Proportional Odds Assumption */
%IF %UPCASE(&_propOdds)= PO %THEN %DO ;
            ODS OUTPUT CumulativeModelTest= _testPo (
                RENAME=(    ChiSq=          poChiSq
                            DF=             poDF
                            ProbChiSq=      poProbChiSq) ) ;
%END ;
    RUN ;
    TITLE ; FOOTNOTE ;

/* Get number of observations used for models */
    DATA _NULL_ ;
        set _NObs (OBS= 1) ;
        call symputX('_xObs' , PUT(NObsUsed,10.0) ) ;
        call symputX('_nObs' , PUT(NObsUsed,COMMA8.) ) ;
    RUN ;

/* Regularize Parameter */
    DATA _oddsW ; LENGTH Parameter $9 ; SET _oddsW ;
        LABEL   wLowerCL=   'Wald 95%LoCL OR'
                wUpperCL=   'Wald 95%UpCL OR'
                wPvalue=    "Wald p-Value"
        ; RUN ;
    DATA _oddsPl ; LENGTH Parameter $9 ; SET _oddsPl ;
        LABEL   plLowerCL=  'Profile Likelihood 95%LoCL OR'
                plUpperCL=  'Profile Likelihood 95%UpCL OR'
                plPvalue=   "Profile Likelihood p-Value"
        ; RUN ;
%IF %UPCASE(&_propOdds)= PO %THEN %DO ;
    DATA _testPo ; LENGTH Parameter $9 ; SET _testPo ;
        LABEL   poChiSq=    "PO Test Chi-Square"
                poDF=       "PO Test DF"
                poProbChiSq="PO Test Pr > Chi-Square"
        ;
        Parameter= strip("&_xPred") ;
    RUN ;
    PROC SORT DATA= _testPo ; BY Parameter ; RUN ;
%END ;
    PROC SORT DATA= _oddsW  ; BY Parameter ; RUN ;
    PROC SORT DATA= _oddsPl ; BY Parameter ; RUN ;

    PROC SORT DATA=&_LIBNM..CUMLOGPRED_&_fileSfx PRESORTED ; BY &_xPred ; RUN ;
    PROC SORT DATA=&_LIBNM..PARMS4VAR_&_fileSfx PRESORTED ;
        BY Parameter ClassVal0 ;
    RUN ;
    PROC SORT DATA=_parmCl PRESORTED ;
        BY Parameter ClassVal0 ;
    RUN ;

/* Merge parameters and variances */
    DATA _0parm ;
        MERGE   &_LIBNM..PARMS4VAR_&_fileSfx (keep= Parameter ClassVal0 StdErr DF WaldChiSq ProbChiSq _ESTTYPE_)
                _parmCl
        ;
        BY Parameter ClassVal0 ;
    /* Variable names for transposed DATA */
        IF NOT MISSING(ClassVal0)
            THEN    _vname= CATT(strip(Parameter) , "_" , STRIP(ClassVal0) ) ;
        ELSE        _vname= STRIP(Parameter) ;
    RUN ;

/* Restructure variables for merge
   Regression parameter estimate */
    PROC TRANSPOSE  DATA=   _0parm (keep= _vname Estimate)
                    OUT=    _parmEst (drop= _:)
        ;
        VAR Estimate ; id _vname ;
    RUN ;
/* Regression parameter standard error */
    PROC TRANSPOSE  DATA=   _0parm (keep= _vname StdErr)
                    OUT=    _parmSe (drop= _:)
                    SUFFIX= _se
        ;
        VAR StdErr ; id _vname ;
    RUN ;
/* LOWER 95% profile likelihood CL */
    PROC TRANSPOSE  DATA=   _0parm (keep= _vname LowerCL)
                    OUT=    _parmLo (drop= _:)
                    SUFFIX= _lo95
        ;
        VAR LowerCL ; id _vname ;
    RUN ;
/* UPPER 95% profile likelihood CL */
    PROC TRANSPOSE  DATA=   _0parm (keep= _vname UpperCL)
                    OUT=    _parmHi (drop= _:)
                    SUFFIX= _hi95
        ;
        VAR UpperCL ; id _vname ;
    RUN ;

/* Lateral dataset */
    DATA &_LIBNM..CUMLOGPARM_&_fileSfx (LABEL= "Parameter Estimates") ;
        MERGE   _parmEst
                _parmSe
                _parmLo
                _parmHi
        ;
    RUN ;

/* Tabular dataset */
    DATA &_LIBNM..CUMLOGTABLE_&_fileSfx (LABEL= "Parameter estimates and variances");
        MERGE   _0parm (DROP= _vname)
                _oddsW
                _oddsPl
%IF %UPCASE(&_propOdds)= PO %THEN _testPo ;
        ;
        BY Parameter ;
    RUN ;

    PROC DATASETS LIBRARY= WORK NOLIST ;
        DELETE _NObs _parmEst _parmCl _oddsW _oddsPl
               _0parm _parmSe _parmLo _parmHi
%IF %UPCASE(&_propOdds)= PO %THEN _testPo ;
        ;
    RUN ; QUIT ;
%MEND cr3_1Logit ;
