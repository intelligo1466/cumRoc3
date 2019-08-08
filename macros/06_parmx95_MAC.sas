/*  ##########################################################################
    ##########################################################################
    SAS Version 9.4 TS1M3 and later
    Licenses    Apache-2.0, CC-BY-4.0
    ##########################################################################
    Name:       %parmx95
    Type:       SAS macro
    Purpose:    Compute 95% CI for parametric cutpoints and merge with output from %cut3Parmx.
                NB: Parametric cutpoints are ratios of parameter estimates, so variances may be computed with Fieller's Method or the Delta Method. Both methods are calculated here.

    Author: B. Rey de Castro, Sc.D., rdecastro@cdc.gov
    Centers for Disease Control and Prevention, Atlanta, Georgia, USA
    ##########################################################################

INPUT
    SAS7BDAT: Parameter estimates for variance calculation of ratio by Delta and Fieller's Methods
        TARGET: &_LIBNM..PARMS4VAR_&_fileSfx
    SAS7BDAT: Variance-covariance matrix for parameter estimates
        TARGET: &_LIBNM..COVB_&_fileSfx
    SAS7BDAT: Parametric cutpoints with ROC curve-based criteria computed at parametric cutpoints, including 2x2 table frequencies from %cut3Parmx
        TARGET: _cutParmx

OUTPUT
    SAS7BDAT: Parametric cutpoints with 95% confidence intervals by Fieller's Method and Delta Method, including ROC curve-based criteria computed at parametric cutpoints and 2x2 table frequencies
                Merged with parametric cutpoints in _cutParmx from %cut3Parmx
        TARGET: &_LIBNM..CUTPARMX_&_fileSfx

DISCLAIMERS
1. DISCLAIMER OF WARRANTY. Under the terms of the Apache License 2.0 License, "Unless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its Contributions) on an "as is" basis, without warranties or conditions of any kind, either express or implied, including, without limitation, any warranties or conditions of title, non-infringement, merchantability, or fitness for a particular purpose. You are solely responsible for determining the appropriateness of using or redistributing the Work and assume any risks associated with Your exercise of permissions under this License."
2. The findings and conclusions in this report are those of the author and do not necessarily represent the views of the Centers for Disease Control and Prevention. Use of trade names is for identification only and does not imply endorsement by the Centers for Disease Control and Prevention.
*/
%MACRO parmx95 ;
    %LET _CRIT = parmx ;
    %LET _critLbl = %STR(Parametric) ;

    PROC IML ;
        USE     &_LIBNM..PARMS4VAR_&_fileSfx ;
            READ all var {Estimate} INTO parms [colname=varNames] ;
        CLOSE   &_LIBNM..PARMS4VAR_&_fileSfx ;
        USE     &_LIBNM..COVB_&_fileSfx ;
            READ all var _NUM_ INTO covB [colname=varNames] ;
        CLOSE   &_LIBNM..COVB_&_fileSfx ;

        n= &_xOBS ;
        df= n -
            %IF       %UPCASE(&_propOdds)= PO  %THEN 2 ;
            %ELSE %IF %UPCASE(&_propOdds)= NPO %THEN 3 ;
        ;

        /* Quantile for 95% confidence interval */
        t975=   TINV(0.975,df) ;

        /* Ternary ordinal outcome */
        muA1=   parms[1] ;
        muA2=   parms[2] ;
        muB1=   parms[3] ;
        %IF %UPCASE(&_propOdds)= NPO %THEN %STR(muB2= parms[4] ;) ;

        /* Ratio of parameter estimates */
        cut1=   (-1 * muA1) / muB1 ;
        cut2=   (-1 * muA2) /
            %IF       %UPCASE(&_propOdds)= PO  %THEN muB1 ;
            %ELSE %IF %UPCASE(&_propOdds)= NPO %THEN muB2 ;
        ;

/* ========================================================================== */
    /* FIELLER'S METHOD: Variances for ratio of parameter estimates */
        %IF       %UPCASE(&_propOdds)= PO %THEN %DO ;
            cNum1=  {-1, 0, 0} ;
            cNum2=  { 0,-1, 0} ;
            cDen1=  { 0, 0, 1} ;
        %END ;
        %ELSE %IF %UPCASE(&_propOdds)= NPO %THEN %DO ;
            cNum1=  {-1, 0, 0, 0} ;
            cNum2=  { 0,-1, 0, 0} ;
            cDen1=  { 0, 0, 1, 0} ;
            cDen2=  { 0, 0, 0, 1} ;
        %END ;
        num1Vec= t(cNum1) * parms ;
        num2Vec= t(cNum2) * parms ;
        den1Vec= t(cDen1) * parms ;
        %IF %UPCASE(&_propOdds)= NPO %THEN %STR(den2Vec= t(cDen2) * parms ;) ;

        cut1Vec=    num1Vec / den1Vec ;
        cut2Vec=    num2Vec /
            %IF       %UPCASE(&_propOdds)= PO  %THEN den1Vec ;
            %ELSE %IF %UPCASE(&_propOdds)= NPO %THEN den2Vec ;
        ;

        num1Var=    t(cNum1) * covb * cNum1 ;
        num2Var=    t(cNum2) * covb * cNum2 ;
        den1Var=    t(cDen1) * covb * cDen1 ;
        %IF %UPCASE(&_propOdds)= NPO %THEN %STR(den2Var= t(cDen2) * covb * cDen2 ;) ;

        cut1Covar=  t(cNum1) * covb * cDen1 ;
        cut2Covar=  t(cNum2) * covb *
            %IF       %UPCASE(&_propOdds)= PO  %THEN cDen1 ;
            %ELSE %IF %UPCASE(&_propOdds)= NPO %THEN cDen2 ;
        ;

        f2den1Vec= den1Vec**2-(t975**2)*den1Var ;
        %IF %UPCASE(&_propOdds)= NPO %THEN %STR(f2den2Vec= den2Vec**2-(t975**2)*den2Var ;) ;

        f10Vec= num1Vec**2-(t975**2)*num1Var ;
        f11Vec= num1Vec*den1Vec-(t975**2)*cut1Covar ;

        f20Vec= num2Vec**2-(t975**2)*num2Var ;
        f21Vec= num2Vec*
            %IF       %UPCASE(&_propOdds)= PO  %THEN den1Vec ;
            %ELSE %IF %UPCASE(&_propOdds)= NPO %THEN den2Vec ;
            -(t975**2)*cut2Covar
        ;

        D1Vec=  f11vec**2-f10vec*f2den1Vec ;
        D2Vec=  f21vec**2-f20vec*
            %IF       %UPCASE(&_propOdds)= PO  %THEN f2den1Vec ;
            %ELSE %IF %UPCASE(&_propOdds)= NPO %THEN f2den2Vec ;
        ;

        IF f2den1Vec^= 0 THEN DO ;
            lo95f1Vec=  (f11Vec-sqrt(D1vec)) / f2den1Vec ;
            up95f1Vec=  (f11Vec+sqrt(D1vec)) / f2den1Vec ;
            %IF       %UPCASE(&_propOdds)= PO %THEN %DO ;
                lo95f2Vec=  (f21Vec-sqrt(D2vec)) / f2den1Vec ;
                up95f2Vec=  (f21Vec+sqrt(D2vec)) / f2den1Vec ;
            %END ;
        END ;
        %IF %UPCASE(&_propOdds)= NPO %THEN %DO ;
            IF f2den2Vec^= 0 THEN DO ;
                lo95f2Vec=  (f21Vec-sqrt(D2vec)) / f2den2Vec ;
                up95f2Vec=  (f21Vec+sqrt(D2vec)) / f2den2Vec ;
            END ;
        %END ;

/*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
    /* DELTA METHOD PART 1: Variances for ratio of parameter estimates */
        IF den1Vec ^= 0 THEN DO ;
            varD1Vec= (num1Var + (cut1Vec**2) * den1Var - (2*cut1Vec*cut1Covar))
                        / (den1Vec**2) ;
            seD1Vec=    SQRT( varD1Vec ) ;
            margD1Vec=  t975 * seD1Vec ;
            lo95D1Vec=  cut1Vec - margD1Vec ;
            up95D1Vec=  cut1Vec + margD1Vec ;

            %IF       %UPCASE(&_propOdds)= PO %THEN %DO ;
                varD2Vec= (num2Var + (cut2Vec**2) * den1Var - (2*cut2Vec*cut2Covar))
                            / (den1Vec**2) ;
                seD2Vec=    SQRT( varD2Vec ) ;
                margD2Vec=  t975 * seD2Vec ;
                lo95D2Vec=  cut2Vec - margD2Vec ;
                up95D2Vec=  cut2Vec + margD2Vec ;
            %END ;
        END ;
        ELSE IF den1Vec= 0 THEN PRINT '  95% Interval 1 (Delta) Undefined' ;

        %IF %UPCASE(&_propOdds)= NPO  %THEN %DO ;
            IF den2Vec ^= 0 THEN DO ;
                varD2Vec= (num2Var + (cut2Vec**2) * den2Var - (2*cut2Vec*cut2Covar))
                            / (den2Vec**2) ;
                seD2Vec=    SQRT( varD2Vec ) ;
                margD2Vec=  t975 * seD2Vec ;
                lo95D2Vec=  cut2Vec - margD2Vec ;
                up95D2Vec=  cut2Vec + margD2Vec ;
            END ;
            ELSE IF den2Vec= 0 THEN PRINT '  95% Interval 2 (Delta) Undefined' ;
        %END ;

    /* Parametric cutpoints */
        varN0 = {"xCut"} ;
    /* Concatenate results vertically */
        parmx = cut1vec // cut2vec ;

/*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
    /* FIELLER'S METHOD: Variances for ratio of parameter estimates */
        /* Variable names for output dataset */
        f95varN = {"f_lo95" "f_up95" "f0" "f1" "f_D" "f2"} ;
        /* Concatenate results horizontally */
        f95_1 = lo95f1Vec || up95f1Vec || f10Vec || f11Vec || D1vec || f2den1Vec ;
        f95_2 = lo95f2Vec || up95f2Vec || f20Vec || f21Vec || D2vec ||
            %IF       %UPCASE(&_propOdds)= PO  %THEN f2den1Vec ;
            %ELSE %IF %UPCASE(&_propOdds)= NPO %THEN f2den2Vec ;
        ;

/*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
    /* DELTA METHOD PART 2: Variances for ratio of parameter estimates */
        /* Variable names for output dataset */
        d95varN = {"d_lo95" "d_up95" "d_var" "d_se" "d_marg"} ;
        /* Concatenate results horizontally */
        d95_1 = lo95D1Vec || up95D1Vec || varD1vec || seD1vec || margD1Vec ;
        d95_2 = lo95D2Vec || up95D2Vec || varD2vec || seD2vec || margD2Vec ;

/* ========================================================================== */
    /* Compile Fieller's Method and Delta Method */
        /* Concatenate variable names horizontally for output dataset */
        varN = varN0 || f95varN || d95varN ;
        /* Concatenate results vertically for output dataset */
        f95 = f95_1 // f95_2 ;
        d95 = d95_1 // d95_2 ;

        /* Concatenate results horizontally for output dataset */
        parmx95 = parmx || f95 || d95 ;

        /* Write to output dataset */
        CREATE _0parmx95 FROM parmx95 [colname= varN] ;
            APPEND FROM parmx95 ;
        CLOSE _0parmx95 ;
    QUIT ;

    DATA _parmx95 ;
        SET _0parmx95 ;
        ATTRIB  xCut        Format= 14.8    Label=  'X Cutpoint'
                f_lo95      Format= 14.8    Label=  'X Cutpoint, 95%LCL Fieller'
                f_up95      Format= 14.8    Label=  'X Cutpoint, 95%UCL Fieller'
                d_lo95      Format= 14.8    Label=  'X Cutpoint, 95%LCL Delta'
                d_up95      Format= 14.8    Label=  'X Cutpoint, 95%UCL Delta'
                f0          Format= 10.6    Label=  'Fieller Statistic F0'
                f1          Format= 10.6    Label=  'Fieller Statistic F1'
                f2          Format= 10.6    Label=  'Fieller Statistic F2'
                f_D         Format= 10.6    Label=  'Fieller Statistic D'
                d_var       Format= 10.6    Label=  'Delta Variance'
                d_se        Format= 10.6    Label=  'Delta SE'
                d_marg      Format= 10.6    Label=  'Delta 95% Margin'
                &_xPred.CutTxt  Label=  'X Cutpoint' /* Fieller */
                                Length= $55
                &_xPred.Cut95d  Label=  'X Cutpoint [95CI Delta]'
                                Length= $55
                critPoint       Length= $40     Label= "Criterion :: Cutpoint"
        ;
        CALL MISSING(&_xPred.CutTxt,&_xPred.Cut95d,critPoint) ;

    /* X Cutpoint [95CI Fieller] */
        &_xPred.CutTxt= CATT(strip(put(xCut,12.4)) , " [" , strip(put(f_lo95,12.4)) , ":" , strip(put(f_up95,12.4)) , "]" ) ;
    /* X Cutpoint [95CI Delta] */
        &_xPred.Cut95d= CATT(strip(put(xCut,12.4)) , " [" , strip(put(d_lo95,12.4)) , ":" , strip(put(d_up95,12.4)) , "]" ) ;

        _idx = _N_ - 1 ;

    /* To report results in given order for ternary ordinal outcome with DESCENDING outcome levels,
        undo reversal of outcome levels for internal calculations */
        %IF %UPCASE(&_yOrd) = D %THEN %DO ;
            IF      _idx = 0 THEN _idx = 1 ;
            ELSE IF _idx = 1 THEN _idx = 0 ;
        %END ;
        critPoint= CAT("&_critLbl :: " , STRIP(PUT(_idx,8.0)) ) ;

        DROP _: ;
    RUN ;

    PROC SORT   DATA= _parmx95 ;
        BY critPoint ;
    RUN ;
    DATA &_LIBNM..CUTPARMX_&_fileSfx (LABEL= "Parametric cutpoints 95CI, including ROC curve-based criteria computed at parametric cutpoints and 2x2 table frequencies") ;
        MERGE   _cutParmx
                _parmx95
        ;
        BY critPoint ;
    RUN ;

    %IF %upCase(&_debug0)= NO %THEN %DO ;
        PROC DATASETS LIBRARY= WORK NOLIST ;
            DELETE _0parmx95 ;
        RUN ; QUIT ;
    %END ;
%MEND parmx95 ;
