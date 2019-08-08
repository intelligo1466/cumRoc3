/*  ##########################################################################
    ##########################################################################
    SAS Version 9.4 TS1M3 and later
    Licenses    Apache-2.0, CC-BY-4.0
    ##########################################################################
    Name:       %cr3Results
    Type:       SAS macro
    Purpose:    Tabulate results from cutpoint selection datasets

    Author: B. Rey de Castro, Sc.D., rdecastro@cdc.gov
    Centers for Disease Control and Prevention, Atlanta, Georgia, USA
    ##########################################################################

USAGE

    %cr3Results(_dsnLst) ;

        Ex. %cr3Results(CUTPARMX CUTBASE) ;

    ==========================================================================

PARAMETERS, Positional
    _dsnLst     Space-delimited list of input SAS datasets

INPUT
    SAS7BDAT: Parametric cutpoints with 95% confidence intervals by Fieller's Method and Delta Method, including ROC curve-based criteria computed at parametric cutpoints and 2x2 table frequencies from %cut3Parmx and %parmx95
        TARGET: &_LIBNM..CUTPARMX_&_fileSfx
    SAS7BDAT: Optimal ROC curve-based cutpoints and cumulative ROC curve AUCs from %cut3Base
        TARGET: &_LIBNM..CUTBASE_&_fileSfx
    SAS7BDAT: Cumulative ROC curves 0 and 1 with 2x2 table frequencies, ROC criteria, AUCs
        TARGET: &_LIBNM..ROC_&_fileSfx
    SAS7BDAT: Parameter estimates and variances
        TARGET: &_LIBNM..CUMLOGTABLE_&_fileSfx
    SAS7BDAT: Association of predicted probabilities and observed responses
        TARGET: &_LIBNM..ASSOC_&_fileSfx

OUTPUT
    SAS7BDAT: Optimal ROC curve-based cutpoints, parametric cutpoints with 95% confidence intervals by Fieller's Method and Delta Method, and cumulative ROC curve AUCs
        TARGET: &_LIBNM..CUMROC3_&_fileSfx
    OPTION
        _outRtf=NO :: DEFAULT
            TXT: Tabulated results
                TARGET: &_dir00./&_dirOut/CUMROC3_&_fileSfx._&_dateOut..TXT
        _outRtf=YES
            RTF: Tabulated results
                TARGET: &_dir00./&_dirOut/CUMROC3_&_fileSfx._&_dateOut..RTF

DISCLAIMERS
1. DISCLAIMER OF WARRANTY. Under the terms of the Apache License 2.0 License, "Unless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its Contributions) on an "as is" basis, without warranties or conditions of any kind, either express or implied, including, without limitation, any warranties or conditions of title, non-infringement, merchantability, or fitness for a particular purpose. You are solely responsible for determining the appropriateness of using or redistributing the Work and assume any risks associated with Your exercise of permissions under this License."
2. The findings and conclusions in this report are those of the author and do not necessarily represent the views of the Centers for Disease Control and Prevention. Use of trade names is for identification only and does not imply endorsement by the Centers for Disease Control and Prevention.
*/

%MACRO cr3Results(_dsnLst) ;
    %LOCAL _nList _i _iCut _pageNow ;
    %LET _nList= %words(&_dsnLst) ;

    /* Compile cutpoint results
        Drop xPredCutTxt to reformat below */
    DATA &_LIBNM..CUMROC3_&_fileSfx (LABEL= "Optimal ROC curve-based cutpoints, parametric cutpoints 95CI, and cumulative ROC curve AUCs") ;
        SET
            %DO _i= 1 %TO &_nList ;
                %LET _iCut= %scan(&_dsnLst,&_i,,SOR) ;
                &_LIBNM..&_iCut._&_fileSfx (DROP= &_xPred.CutTxt)
            %END ;
        ;
        ATTRIB  vsCls       Label= "&_vsLbl"
                            Format= vsG.
                &_xPred.CutTxt  Label= "&_xLbl. Cutpoint"
                                Length= $40
        ;
        FORMAT  &_xPred.Cut xCut f_lo95 f_up95  BEST12.
                critMax tpr spec                10.6
        ;

        vsCls= INPUT(CHAR(STRIP(critPoint), LENGTH(STRIP(critPoint))) , 8.0) ;

        IF      upCase(STRIP(criterion)) IN("TOTAL ACCURACY" "YOUDEN INDEX" "MATTHEWS CORRELATION") THEN DO ;
            &_xPred.CutTxt= STRIP(PUT(&_xPred.Cut,&_cutFmt)) ;
            IF MISSING(Area) THEN AreaTxt= " " ;
        END ;
        ELSE IF upCase(STRIP(criterion))= "PARAMETRIC" THEN DO ;
            &_xPred.CutTxt= CAT(STRIP(PUT(xCut,&_cutFmt)) , " [" , STRIP(PUT(f_lo95,&_cutFmt)) , ", " , STRIP(PUT(f_up95,&_cutFmt)) , "]" ) ;
            AreaTxt= "^{unicode 2014}" ;
        END ;
    RUN ;
    PROC SORT   DATA=   &_LIBNM..CUMROC3_&_fileSfx
                OUT=    _0cumroc3
        ;
        BY critPoint ;
    RUN ;

/* ========================================================================== */
    /* Transpose and merge ROC curve-based criteria for parameteric cutpoints */
    PROC SORT   DATA=   &_LIBNM..CUTPARMX_&_fileSfx (KEEP= critPoint j acc mcc)
                OUT=    _0parmCrit
        ;
        BY critPoint ;
    RUN ;
        PROC TRANSPOSE  DATA=   _0parmCrit
                        OUT=    _1parmCrit (RENAME=(COL1=critMax _LABEL_=critParm))
                        NAME=   crit
            ;
            BY critPoint ;
            VAR j acc mcc;
        RUN ;
        DATA _parmCrit ;
            LENGTH criterion critPam $ 25 ;
            MERGE _1parmCrit
                  _0cumroc3 (
                        KEEP= critPoint criterion vsCls &_xPred.CutTxt tpr spec ppv npv AreaTxt
                        WHERE=(upCase(STRIP(criterion)) EQ "PARAMETRIC")
                  )
            ;
            BY critPoint ;
            ATTRIB  critParm    Label= "Criterion @Parametric Cutpoint" ;
            criterion= "Parametric^{SUPER 1}" ;
            IF NOT MISSING(critParm) THEN
                SELECT(upCase(STRIP(critParm))) ;
                    When("TOTAL ACCURACY")  critParm= "Total Accuracy^{SUPER 2}" ;
                    When("MATTHEWS CORR")   critParm= "Matthews Corr^{SUPER 2}" ;
                    When("YOUDEN INDEX")    critParm= "Youden Index^{SUPER 2}" ;
                    Otherwise ;
                END ;
        RUN ;

    /* Append */
    DATA _cumroc3 ;
        SET _parmCrit
            _0cumroc3 (
                    KEEP= critPoint criterion vsCls critMax &_xPred.CutTxt tpr spec ppv npv AreaTxt
                    WHERE=(upCase(STRIP(criterion)) NE "PARAMETRIC")
              )
        ;
        CALL MISSING(_idx) ;
        SELECT(upCase(STRIP(criterion))) ;
            When("TOTAL ACCURACY")      _idx= 0 ;
            When("MATTHEWS CORRELATION")_idx= 1 ;
            When("YOUDEN INDEX")        _idx= 2 ;
            When("PARAMETRIC^{SUPER 1}")_idx= 3 ;
            Otherwise ;
        END ;
    RUN ;
    PROC SORT   DATA=   _cumroc3 ;
        BY _idx vsCls ;
    RUN ;

/* ========================================================================== */
/* ========================================================================== */
/* =====    OUTPUT TABULATED RESULTS    ===== */
/* ========================================================================== */
    OPTIONS noDATE noNUMBER ORIENTATION= Landscape ;
    TITLE ; FOOTNOTE ;
    ODS NOPROCTITLE ;
/* ========================================================================== */
/* =====    O P E N  O U T P U T  A N D  S E T  O D S          ============== */
/* ========================================================================== */
/* =====    TXT SETUP :: DEFAULT    ==== */
    %IF       %upCase(&_outRtf)= NO  %THEN %DO ;
        %LET _pageNow= ;
        OPTIONS LINESIZE= 135
        /* Supress page breaks in LISTING */
                formDlim= '='
        ;
        ODS LISTING FILE= "&_dir00./&_dirOut/CUMROC3_&_fileSfx._&_dateOut..TXT" ;
    %END ;
/* ========================================================================== */
/* =====    RTF SETUP    ==== */
    %ELSE %IF %upCase(&_outRtf)= YES %THEN %DO ;
        %LET _pageNow= %STR(ODS STARTPAGE= Now ;) ;
        ODS HTML CLOSE ;
        ODS DECIMAL_ALIGN= YES ;
        ODS RTF FILE= "&_dir00./&_dirOut/CUMROC3_&_fileSfx._&_dateOut..RTF"
            STARTPAGE= Never
        ;
    %END ;

        FOOTNOTE5  BOLD Justify= CENTER "###########################################################################################" ;
        FOOTNOTE6  BOLD Justify= CENTER 'Output generated by SAS macro %cumRoc3.' ;
        FOOTNOTE7       Justify= CENTER '%cumRoc3 released under Apache License 2.0 and Creative Commons License CC-BY-4.0.' ;
        FOOTNOTE8       Justify= CENTER 'Disclaimer of Warranty: %cumRoc3 is provided on an "as is" basis,' ;
        FOOTNOTE9       Justify= CENTER 'without warranties or conditions of any kind, either express or implied.' ;
        FOOTNOTE10 BOLD Justify= CENTER "###########################################################################################" ;

        TITLE1 "Cumulative ROC Curve Analysis, N= &_nObs." ;
        TITLE2 "&_ordIng.ING &_yOut on &_xPred." ;
        PROC FREQ DATA= &_LIBNM..ROC_&_fileSfx (keep= &_yOut) ;
            TABLES &_yOut
            /   outCum  /* Include cumulative counts and percentages one-way tables */
        ;
        RUN ;
        PROC MEANS DATA= &_LIBNM..ROC_&_fileSfx (KEEP= &_yOut &_xPred)
                ORDER=  Unformatted
                MISSING
                NONOBS
                MAXDEC= 4
                N NMISS MEAN CLM STDDEV MIN Q1 MEDIAN Q3 MAX
            ;
            CLASS &_yOut ;
            VAR &_xPred ;
        RUN ;
&_pageNow ;
/* ========================================================================== */
        TITLE3 "Stage 1: Cumulative Logit Regression" ;
        TITLE4 "&_poTitle Assumed" ;
            PROC PRINT DATA= &_LIBNM..CUMLOGTABLE_&_fileSfx
                    noObs Label Split='$' ;
                LABEL   LowerCL=    'Profile LL95%LoCL$Parameter'
                        UpperCL=    'Profile LL95%UpCL$Parameter'
    %IF %UPCASE(&_propOdds)= PO %THEN poProbChiSq='PO Test$Pr > Chi-Square' ;
                ;
                VAR Parameter ClassVal0 Estimate LowerCL UpperCl ProbChiSq
    %IF %UPCASE(&_propOdds)= PO %THEN poProbChiSq ;
                ;
            RUN ;
            PROC PRINT DATA= &_LIBNM..CUMLOGTABLE_&_fileSfx(
                        WHERE=(Parameter= "&_xPred") )
                    noObs Label Split='$' ;
                LABEL   plLowerCL=  'Profile LL95%LoCL$Odds Ratio'
                        plUpperCL=  'Profile LL95%UpCL$Odds Ratio'
                        plPvalue=   "Profile LL$p-Value"
    %IF %UPCASE(&_propOdds)= PO %THEN poProbChiSq='PO Test$Pr > Chi-Square' ;
                ;
                VAR Parameter OddsRatioEst plLowerCL plUpperCL plPvalue
    %IF %UPCASE(&_propOdds)= PO %THEN poProbChiSq ;
                ;
            RUN ;
&_pageNow ;
/* ========================================================================== */
        TITLE5 "Association of Predicted Probabilities and Observed Responses" ;
            PROC PRINT DATA= &_LIBNM..ASSOC_&_fileSfx noObs Label ;
            /* Set variable column heading to blank */
                LABEL   Label1= '00'x
                        nValue1='00'x
                        Label2= '00'x
                        nValue2='00'x
                ;
                FORMAT nValue1 10.2 nValue2 10.4 ;
                VAR Label1 nValue1 Label2 nValue2 ;
            RUN ;
        TITLE5 ;
&_pageNow ;
/* ========================================================================== */
        FOOTNOTE1  Justify= LEFT '^{SUPER 1}95% Confidence intervals computed with Fieller''s Method.' ;
        FOOTNOTE2  Justify= LEFT '^{SUPER 2}Criterion computed at parametric cutpoint.' ;
        FOOTNOTE5  BOLD Justify= CENTER "###########################################################################################" ;
        FOOTNOTE6  BOLD Justify= CENTER 'Output generated by SAS macro %cumRoc3.' ;
        FOOTNOTE7       Justify= CENTER '%cumRoc3 released under Apache License 2.0 and Creative Commons License CC-BY-4.0.' ;
        FOOTNOTE8       Justify= CENTER 'Disclaimer of Warranty: %cumRoc3 is provided on an "as is" basis,' ;
        FOOTNOTE9       Justify= CENTER 'without warranties or conditions of any kind, either express or implied.' ;
        FOOTNOTE10 BOLD Justify= CENTER "###########################################################################################" ;

        TITLE3 "Stage 2: Cumulative ROC Curves" ;
        TITLE4 "&_xPred Cutpoints: Criteria, Sensitivity, Specificity" ;
            PROC PRINT DATA= _cumroc3 noObs Label Split='$' ;
                FORMAT critMax tpr spec 10.4 ;
                LABEL   critParm=       'Criterion$@Parametric Cutpoint'
                        critMax=        "Criterion, Optimum"
                        &_xPred.CutTxt= "&_xLbl.$Cutpoint"
                ;
                VAR criterion vsCls critParm critMax &_xPred.CutTxt tpr spec ;
            RUN ;
&_pageNow ;
/* ========================================================================== */
        FOOTNOTE1  Justify= LEFT '^{SUPER 1}95% Confidence intervals computed with Fieller''s Method.' ;
        FOOTNOTE2  Justify= LEFT "^{SUPER 2}PPV: Positive predictive value." ;
        FOOTNOTE3  Justify= LEFT "^{SUPER 3}NPV: Negative predictive value." ;
        FOOTNOTE4  Justify= LEFT "^{SUPER 4}AUC: Area under the cumulative ROC curve." ;
        FOOTNOTE5  BOLD Justify= CENTER "###########################################################################################" ;
        FOOTNOTE6  BOLD Justify= CENTER 'Output generated by SAS macro %cumRoc3.' ;
        FOOTNOTE7       Justify= CENTER '%cumRoc3 released under Apache License 2.0 and Creative Commons License CC-BY-4.0.' ;
        FOOTNOTE8       Justify= CENTER 'Disclaimer of Warranty: %cumRoc3 is provided on an "as is" basis,' ;
        FOOTNOTE9       Justify= CENTER 'without warranties or conditions of any kind, either express or implied.' ;
        FOOTNOTE10 BOLD Justify= CENTER "###########################################################################################" ;

        TITLE4 "&_xPred Cutpoints: PPV, NPV, AUC" ;
            PROC PRINT DATA= _cumroc3 (
                                WHERE= (MISSING(critParm)
                                    OR STRIP(UPCASE(critParm))= "TOTAL ACCURACY^{SUPER 2}")
                                )
                    noObs Label Split='$'
                ;
                FORMAT ppv npv 10.4 ;
                LABEL   &_xPred.CutTxt= "&_xLbl.$Cutpoint"
                        ppv=    "PPV: Precision^{SUPER 2}"
                        npv=    "NPV^{SUPER 3}"
                        AreaTxt="AUC [Wald 95CI]^{SUPER 4}"
                ;
                VAR criterion vsCls &_xPred.CutTxt ppv npv AreaTxt ;
            RUN ;
        TITLE3 ; TITLE4 ;
        FOOTNOTE ;

/* ========================================================================== */
/* =====    CONTENTS OF OUTPUT DATA :: DEFAULT    ==== */
        %IF %UPCASE(&_outCntnts) = YES %THEN %DO ;
            %IF %upCase(&_outRtf)= YES %THEN %STR(ODS STARTPAGE= YES ;) ;
            OPTIONS LINESIZE= 95 ORIENTATION= Portrait ;
            FOOTNOTE1  BOLD Justify= CENTER "###########################################################################################" ;
            FOOTNOTE2  BOLD Justify= CENTER 'Output generated by SAS macro %cumRoc3.' ;
            FOOTNOTE3       Justify= CENTER '%cumRoc3 released under Apache License 2.0 and Creative Commons License CC-BY-4.0.' ;
            FOOTNOTE4       Justify= CENTER 'Disclaimer of Warranty: %cumRoc3 is provided on an "as is" basis,' ;
            FOOTNOTE5       Justify= CENTER 'without warranties or conditions of any kind, either express or implied.' ;
            FOOTNOTE6 BOLD  Justify= CENTER "###########################################################################################" ;

            TITLE3 "Contents of Permanent Output Datasets" ;
                PROC DATASETS NOLIST ;
                    CONTENTS DATA= &_LIBNM..PARMS4VAR_&_fileSfx   ;
                    CONTENTS DATA= &_LIBNM..COVB_&_fileSfx        ;
                    CONTENTS DATA= &_LIBNM..CUMLOGPARM_&_fileSfx  ;
                    CONTENTS DATA= &_LIBNM..CUMLOGTABLE_&_fileSfx ;
                    CONTENTS DATA= &_LIBNM..CUMLOGPRED_&_fileSfx  ;
                    CONTENTS DATA= &_LIBNM..ASSOC_&_fileSfx       ;
                    CONTENTS DATA= &_LIBNM..ROC_&_fileSfx         ;
                    CONTENTS DATA= &_LIBNM..AUC_&_fileSfx         ;
                    CONTENTS DATA= &_LIBNM..CUTBASE_&_fileSfx     ;
                    CONTENTS DATA= &_LIBNM..CUTPARMX_&_fileSfx    ;
                    CONTENTS DATA= &_LIBNM..CUMROC3_&_fileSfx     ;
                RUN ; QUIT ;
        %END ;
/* ========================================================================== */

    %IF       %upCase(&_outRtf)= NO  %THEN %DO ;
        ODS LISTING CLOSE ;
        OPTIONS LINESIZE= 95
                formDlim= ''
        %IF %UPCASE(&_outCntnts) = NO %THEN ORIENTATION= Portrait ;
        ;
    %END ;
    %ELSE %IF %upCase(&_outRtf)= YES %THEN %DO ;
        ODS RTF CLOSE ;
        %IF %UPCASE(&_outCntnts) = NO %THEN %DO ;
            OPTIONS LINESIZE= 95 ORIENTATION= Portrait ;
            ODS STARTPAGE= YES ;
        %END ;
        ODS HTML ;
        ODS DECIMAL_ALIGN= NO ;
    %END ;
/* ========================================================================== */
/* =====    C L O S E  O U T P U T  A N D  R E S E T  O D S          ======== */
/* ========================================================================== */

    TITLE ; FOOTNOTE ;
    ODS PROCTITLE ;
    OPTIONS DATE NUMBER ;

    %IF %upCase(&_debug0)= NO %THEN %DO ;
        PROC DATASETS LIBRARY= WORK NOLIST ;
            DELETE _0cumroc3 _cumroc3 _0parmCrit _1parmCrit _parmCrit ;
        RUN ; QUIT ;
    %END ;
%MEND cr3Results ;
