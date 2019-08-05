/*  ##########################################################################
    ##########################################################################
    SAS Version 9.4 TS1M3 and later
    License     Apache-2.0 Apache License 2.0
    Copyright   CC-BY-4.0 Creative Commons Attribution 4.0 International Public License
    ##########################################################################
    Name:       %cut3Parmx
    Type:       SAS macro
    Purpose:    Compute parametric cutpoints that discriminate outcome levels based on cumulative logit regression parameters

    Author: B. Rey de Castro, Sc.D., rdecastro@cdc.gov
    Centers for Disease Control and Prevention, Atlanta, Georgia, USA
    ##########################################################################

INPUT
    SAS7BDAT: Parameter estimates from cumulative logit regression
        TARGET: &_LIBNM..CUMLOGPARM_&_fileSfx
    SAS7BDAT: Predicted cumulative probabilities from cumulative logit regression
        TARGET: &_LIBNM..CUMLOGPRED_&_fileSfx

OUTPUT
    SAS7BDAT: Parametric cutpoints with ROC curve-based criteria computed at parametric cutpoints, including 2x2 table frequencies
                To be merged with 95% confidence intervals from subsequent %parmx95
        TARGET: _cutParmx

DISCLAIMERS
1. DISCLAIMER OF WARRANTY. Under the terms of the Apache License 2.0 License, "Unless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its Contributions) on an "as is" basis, without warranties or conditions of any kind, either express or implied, including, without limitation, any warranties or conditions of title, non-infringement, merchantability, or fitness for a particular purpose. You are solely responsible for determining the appropriateness of using or redistributing the Work and assume any risks associated with Your exercise of permissions under this License."
2. The findings and conclusions in this report are those of the author and do not necessarily represent the views of the Centers for Disease Control and Prevention. Use of trade names is for identification only and does not imply endorsement by the Centers for Disease Control and Prevention.
*/
%MACRO cut3Parmx ;
    %LOCAL _j ;

    %LET _CRIT = parmx ;
    %LET _critLbl = %STR(Parametric) ;
/* ========================================================================== */
/* ========================================================================== */
/* =====    B   E   G   I   N   _J::Loop over artificial binary outcomes ==== */
/* ========================================================================== */
    %DO _J = 0 %TO 1 ;
    /* To report results in given order for ternary ordinal outcome with DESCENDING outcome levels,
        undo reversal of outcome levels for internal calculations */
        %LET _J0= &_J ;
        %IF %UPCASE(&_yOrd) = D %THEN %DO ;
            %IF       &_J = 0 %THEN %LET _J0= 1 ;
            %ELSE %IF &_J = 1 %THEN %LET _J0= 0 ;
        %END ;

        /* Compute optimum cutpoint from parameter estimates of converged models */
        DATA _NULL_ ;
            SET &_LIBNM..CUMLOGPARM_&_fileSfx (KEEP= Intercept: &_xPred.:) ;
            ATTRIB  &_xPred.Cut Label= "&_xLbl. Cutpoint"
                                Format= 14.8
            ;
            /* Reminder: Ternary ordinal outcome now has Y=2 as reference category
                for internal calculations and artificial binary outcomes.
            Cutpoint and corresponding binary outcome
                xCut10 :: _J=0 :: y_0 :: Y=0   vs 1,2
                xCut21 :: _J=1 :: y_1 :: Y=0,1 vs 2   */
            CALL MISSING(&_xPred.Cut) ;
            %IF       %UPCASE(&_propOdds)= PO %THEN %DO  ;
                &_xPred.Cut= -(Intercept_&_J / &_xPred) ;
                CALL SYMPUTX('_parmEst',put(&_xPred,14.8) ) ;
            %END ;
            %ELSE %IF %UPCASE(&_propOdds)= NPO  %THEN %DO ;
                &_xPred.Cut= -(Intercept_&_J / &_xPred._&_J) ;
                CALL SYMPUTX('_parmEst',put(&_xPred._&_J,14.8) ) ;
            %END ;
            CALL SYMPUTX('_parmCut',put(&_xPred.Cut,14.8) ) ;
        RUN ;

        /* Artificial data to count 2x2 table frequencies at parametric cutpoints */
        DATA _ONES_&_CRIT._&_J ;
            SET &_LIBNM..CUMLOGPRED_&_fileSfx (
                KEEP= y_&_J &_xPred cp_0 cp_1
                WHERE=(nmiss(cp_0,cp_1) = 0) )
            ;
            CALL MISSING(y_Ones, _tn_&_J , _fp_&_J , _tp_&_J , _fn_&_J) ;

        /* Account for possible negative relationship between predictor and outcome */
            IF      SIGN(&_parmEst) > 0 THEN y_Ones=  y_&_J ;
            ELSE IF SIGN(&_parmEst) < 0 THEN y_Ones= (y_&_J EQ 0) ;

            SELECT(y_Ones) ;
                WHEN(0)     /* NEGATIVE */
                    SELECT ;
                        /* True Negative */
                        WHEN(&_xPred LE &_parmCut)
                            DO; _tn_&_J=1; _fp_&_J=0; _tp_&_J=0; _fn_&_J=0; END;
                        /* False Positive */
                        WHEN(&_xPred GT &_parmCut)
                            DO; _tn_&_J=0; _fp_&_J=1; _tp_&_J=0; _fn_&_J=0; END;
                        OTHERWISE ;
                    END ;
                WHEN(1)    /* POSITIVE */
                    SELECT ;
                        /* True Positive */
                        WHEN(&_xPred GT &_parmCut)
                            DO; _tn_&_J=0; _fp_&_J=0; _tp_&_J=1; _fn_&_J=0; END;
                        /* False Negative */
                        WHEN(&_xPred LE &_parmCut)
                            DO; _tn_&_J=0; _fp_&_J=0; _tp_&_J=0; _fn_&_J=1; END;
                        OTHERWISE ;
                    END ;
                OTHERWISE ;
            END ;
            KEEP _: ;
        RUN ;
    /* Sum _ones_ to get 2x2 table frequencies at parametric cutpoints */
        PROC SQL noPrint ;
            CREATE TABLE _SUM1_&_CRIT._&_J
                AS
            SELECT  SUM(_tp_&_J) AS tp_&_J ,
                    SUM(_tn_&_J) AS tn_&_J ,
                    SUM(_fp_&_J) AS fp_&_J ,
                    SUM(_fn_&_J) AS fn_&_J
                FROM _ONES_&_CRIT._&_J
            ;
        QUIT ;

    /* Compute 2x2 table statistics at parametric cutpoints */
        DATA _0CUT_&_CRIT._&_J ;
            SET _SUM1_&_CRIT._&_J ;
            ATTRIB
                /* Variables READ from CUT */
                    tp_&_J      Label=  "True Positives, Count &_J"     Format=  8.0
                    tn_&_J      Label=  "True Negatives, Count &_J"     Format=  8.0
                    fp_&_J      Label=  "False Positives, Count &_J"    Format=  8.0
                    fn_&_J      Label=  "False Negatives, Count &_J"    Format=  8.0
                /* Variables created here */
                    &_xPred.Cut Label=  "&_xLbl. Cutpoint"              Format= 14.8
                    tpr_&_J     Label=  "TPR &_J: Sensitivity"          Format= 10.6
                    spec_&_J    Label=  "Specificity &_J"               Format= 10.6
                    fpr_&_J     Label=  "FPR &_J: 1-Specificity"        Format= 10.6
                    ppv_&_J     Label=  "PPV &_J: Precision"            Format= 10.6
                    npv_&_J     Label=  "NPV &_J"                       Format= 10.6
                    J_&_J       Label=  "Youden Index &_J"              Format= 10.6
                    acc_&_J     Label=  "Total Accuracy &_J"            Format= 10.6
                    mcc_&_J     Label=  "Matthews Corr &_J"             Format= 10.6
            ;
            ;
            CALL MISSING(&_xPred.Cut, tpr_&_J, spec_&_J, fpr_&_J, ppv_&_J, npv_&_J, acc_&_J) ;

            &_xPred.Cut= &_parmCut ;

            tpr_&_J=   tp_&_J / SUM(tp_&_J , fn_&_J ) ;
            spec_&_J=  tn_&_J / SUM(tn_&_J , fp_&_J ) ;
            fpr_&_J=   1 - spec_&_J ;

            IF SUM(tp_&_J , fp_&_J) > 0 THEN ppv_&_J= tp_&_J / SUM(tp_&_J , fp_&_J) ;
            IF SUM(tn_&_J , fn_&_J) > 0 THEN npv_&_J= tn_&_J / SUM(tn_&_J , fn_&_J) ;
    /* ========================================================================== */
    /* ========================================================================== */
    /*  For comparison to cutpoints selected by ROC curve-based criteria,
        compute criteria for parametric cutpoints */
    /* ========================================================================== */
        /* Youden Index = J = sensitivity + (specificity-1)
                = sensitivity - ROCxcoordinate */
            J_&_J= tpr_&_J + spec_&_J - 1 ;
        /* Total Accuracy */
            acc_&_J= sum(tp_&_J, tn_&_J) / sum(tp_&_J, tn_&_J, fp_&_J, fn_&_J) ;
        /* Matthews Correlation Coefficient */
            IF ((tp_&_J+fp_&_J)*(tp_&_J+fn_&_J)*(tn_&_J+fp_&_J)*(tn_&_J+fn_&_J)) NE 0
                THEN mcc_&_J= ((tp_&_J*tn_&_J)-(fp_&_J*fn_&_J))
                            / SQRT(((tp_&_J+fn_&_J)*(tp_&_J+fp_&_J)*(tn_&_J+fp_&_J)*(tn_&_J+fn_&_J)))
            ;
            ELSE IF ((tp_&_J+fp_&_J)*(tp_&_J+fn_&_J)*(tn_&_J+fp_&_J)*(tn_&_J+fn_&_J)) EQ 0
                THEN mcc_&_J= ((tp_&_J*tn_&_J)-(fp_&_J*fn_&_J)) / 1
            ;
        RUN ;

        /* Prepare for appending with other criteria::cutpoints */
        DATA _1CUT_&_CRIT._&_J ;
            SET   _0CUT_&_CRIT._&_J (
                        KEEP= &_xPred.Cut tpr_&_J fpr_&_J spec_&_J ppv_&_J npv_&_J
                                J_&_J acc_&_J mcc_&_J
                        RENAME=(tpr_&_J     = tpr
                                fpr_&_J     = fpr
                                spec_&_J    = spec
                                ppv_&_J     = ppv
                                npv_&_J     = npv
                                J_&_J       = J
                                acc_&_J     = acc
                                mcc_&_J     = mcc )
                    )
            ;
            ATTRIB  critMax     Label= "Criterion, Optimum"
                                Format= 10.6
                    criterion   Label= "Criterion"
                                Length= $25
                    critPoint   Label= "Criterion :: Cutpoint"
                                Length= $40
                    tpr         Label= "TPR: Sensitivity"
                                Format= 10.6
                    fpr         Label= "FPR: 1-Specificity"
                                Format= 10.6
                    spec        Label= "Specificity"
                                Format= 10.6
                    ppv         Label= "PPV: Precision"
                                Format= 10.6
                    npv         Label= "NPV"
                                Format= 10.6
                    J           Label=  "Youden Index"
                                Format= 10.6
                    acc         Label=  "Total Accuracy"
                                Format= 10.6
                    mcc         Label=  "Matthews Corr"
                                Format= 10.6
            ;
        /* critMax is placeholder with intentionally missing values
           critPoint merged by critPoint created in parmx95 */
            CALL MISSING(critMax,criterion,critPoint) ;
            criterion= LEFT(STRIP(PROPCASE("&_critLbl"))) ;
            critPoint= LEFT(STRIP("&_critLbl :: &_J0")) ;
        RUN ;
    %END ;
/* ========================================================================== */
/* =====    E   N   D       _J::Loop over artificial binary outcomes ======== */
/* ========================================================================== */
/* ========================================================================== */

    PROC DATASETS LIBRARY= WORK NOLIST ;
        DELETE  _cutParmx ;
        APPEND  BASE= _cutParmx DATA= _1CUT_parmx_0  FORCE ;
        APPEND  BASE= _cutParmx DATA= _1CUT_parmx_1  FORCE ;
        %IF %upCase(&_debug0)= NO %THEN %DO ;
            DELETE _ONES_: _0CUT_: _1CUT_: ;
        %END ;
    QUIT ;
    PROC SORT   DATA= _cutParmx ;
        BY critPoint ;
    RUN ;
%MEND cut3Parmx ;
