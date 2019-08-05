/*  ##########################################################################
    ##########################################################################
    SAS Version 9.4 TS1M3 and later
    License     Apache-2.0 Apache License 2.0
    Copyright   CC-BY-4.0 Creative Commons Attribution 4.0 International Public License
    ##########################################################################
    Name:       %cut3Base
    Type:       SAS macro
    Purpose:    Identify optimal cutpoints that discriminate outcome levels based on ROC curve-based selection criteria.
                    Youden Index (J), Total Accuracy (acc), and Matthews Correlation Coefficient (mcc)

    Author: B. Rey de Castro, Sc.D., rdecastro@cdc.gov
    Centers for Disease Control and Prevention, Atlanta, Georgia, USA
    ##########################################################################

INPUT
    SAS7BDAT: Cumulative ROC curves 0 and 1 with 2x2 table frequencies, ROC criteria, AUCs
        TARGET: &_LIBNM..ROC_&_fileSfx
    SAS7BDAT: Cumulative ROC curve AUCs 0 and 1
        TARGET: &_LIBNM..AUC_&_fileSfx

OUTPUT
    SAS7BDAT: Optimal ROC curve-based cutpoints and cumulative ROC curve AUCs
        TARGET: &_LIBNM..CUTBASE_&_fileSfx

DISCLAIMERS
1. DISCLAIMER OF WARRANTY. Under the terms of the Apache License 2.0 License, "Unless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its Contributions) on an "as is" basis, without warranties or conditions of any kind, either express or implied, including, without limitation, any warranties or conditions of title, non-infringement, merchantability, or fitness for a particular purpose. You are solely responsible for determining the appropriateness of using or redistributing the Work and assume any risks associated with Your exercise of permissions under this License."
2. The findings and conclusions in this report are those of the author and do not necessarily represent the views of the Centers for Disease Control and Prevention. Use of trade names is for identification only and does not imply endorsement by the Centers for Disease Control and Prevention.
*/
%MACRO cut3Base ;
    %LOCAL _j _k ;

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

/* ========================================================================== */
/* ==== Compute Youden Index, Total Accuracy, and Matthews Corr Coeff */
/* ========================================================================== */
        /* Delete duplicate observations of _xPred */
        PROC SORT   DATA=   &_LIBNM..ROC_&_fileSfx (
                        KEEP= &_xPred
                            TP_&_j TN_&_j FP_&_j FN_&_j
                            tpr_&_J fpr_&_J spec_&_J
                            ppv_&_J npv_&_J
                            J_&_J acc_&_J mcc_&_J
                    )
                    OUT=    _CRITERIA_&_J
                NODUPKEY
            ;
            BY &_xPred ;
        RUN ;
    /* ========================================================================== */
    /* =====    B   E   G   I   N   _K::Loop over J, ACC, MCC: Find optimal cutpoint */
        %DO _K = 1 %TO 3 ;
            %IF         &_K = 1 %THEN %DO ;
                %LET _CRIT = j ;
                %LET _critLbl = %STR(Youden Index) ;
            %END ;
            %ELSE %IF   &_K = 2 %THEN %DO ;
                %LET _CRIT = acc ;
                %LET _critLbl = %STR(Total Accuracy) ;
            %END ;
            %ELSE %IF   &_K = 3 %THEN %DO ;
                %LET _CRIT = mcc ;
                %LET _critLbl = %STR(Matthews Correlation) ;
            %END ;
/* ========================================================================== */
/* ==== Empirically and nonparametrically identify the optimal cutpoint at MAX. */
/* ========================================================================== */
            PROC SQL noPrint ;
                CREATE TABLE _0CUT_&_CRIT._&_J
                    AS
                SELECT &_xPred , &_CRIT._&_J ,
                        TP_&_j , TN_&_j , FP_&_j , FN_&_j ,
                        tpr_&_J , fpr_&_J , spec_&_J ,
                        ppv_&_J , npv_&_J
                    FROM    _CRITERIA_&_J
                        HAVING &_CRIT._&_J= MAX(&_CRIT._&_J)
                ;
            QUIT ;

        /* Prepare for appending with other criteria::cutpoints
           ONE-TO-ONE MERGE (side-by-side) */
            DATA _1CUT_&_CRIT._&_J ;
                MERGE   _0CUT_&_CRIT._&_J (
                            KEEP= &_CRIT._&_J &_xPred tpr_&_J fpr_&_J spec_&_J ppv_&_J npv_&_J
                            RENAME=(&_CRIT._&_J = critMax
                                    &_xPred     = &_xPred.Cut
                                    tpr_&_J     = tpr
                                    fpr_&_J     = fpr
                                    spec_&_J    = spec
                                    ppv_&_J     = ppv
                                    npv_&_J     = npv )
                        )
                        &_LIBNM..AUC_&_fileSfx (
                            KEEP= AreaTxt_&_J Area_&_J LowerArea_&_J UpperArea_&_J
                            RENAME=(AreaTxt_&_J   = AreaTxt
                                    Area_&_J      = Area
                                    LowerArea_&_J = LowerArea
                                    UpperArea_&_J = UpperArea )
                        )
                ;
                ATTRIB  critMax     Label= "Criterion, Optimum"
                                    Format= 10.6
                        &_xPred.Cut Label= "&_xLbl. Cutpoint"
                                    Format= 14.8
                        &_xPred.CutTxt  Label= "&_xLbl. Cutpoint"
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
                        criterion   Label= "Criterion"
                                    Length= $25
                        critPoint   Label= "Criterion :: Cutpoint"
                                    Length= $40
                        AreaTxt     Label= "AUC [Wald 95CI]"
                ;
                CALL MISSING(&_xPred.CutTxt,criterion,critPoint) ;

                &_xPred.CutTxt= STRIP(PUT(&_xPred.Cut,14.8)) ;

                criterion= LEFT(STRIP(PROPCASE("&_critLbl"))) ;
                critPoint= LEFT(STRIP("&_critLbl :: &_J0")) ;
            RUN ;
        %END ;
    /* =====    E   N   D       _K::Loop over J, ACC, MCC: Find optimal cutpoint  */
    /* ========================================================================== */
    %END ;
/* ========================================================================== */
/* =====    E   N   D       _J::Loop over artificial binary outcomes ======== */
/* ========================================================================== */
/* ========================================================================== */

/* ========================================================================== */
/* Compile optimal cutpoints for all criteria */
/* ========================================================================== */
    PROC DATASETS LIBRARY= WORK NOLIST ;
        DELETE  CUTBASE_&_fileSfx ;
        APPEND  BASE= CUTBASE_&_fileSfx DATA= _1CUT_j_0    FORCE ;
        APPEND  BASE= CUTBASE_&_fileSfx DATA= _1CUT_j_1    FORCE ;
        APPEND  BASE= CUTBASE_&_fileSfx DATA= _1CUT_acc_0  FORCE ;
        APPEND  BASE= CUTBASE_&_fileSfx DATA= _1CUT_acc_1  FORCE ;
        APPEND  BASE= CUTBASE_&_fileSfx DATA= _1CUT_mcc_0  FORCE ;
        APPEND  BASE= CUTBASE_&_fileSfx DATA= _1CUT_mcc_1  FORCE ;
        %IF &_LIBNM NE WORK %THEN %DO ;
            COPY OUT= &_LIBNM ;
                SELECT  CUTBASE_&_fileSfx ;
            RUN ;
        %END ;
        %IF %upCase(&_debug0)= NO %THEN %DO ;
            DELETE _CRITERIA_: _0CUT_: _1CUT_: ;
        %END ;
    RUN ; QUIT ;
    PROC SORT   DATA= &_LIBNM..CUTBASE_&_fileSfx (LABEL= "Optimal ROC curve-based cutpoints and cumulative ROC curve AUCs") ;
        BY critPoint ;
    RUN ;
%MEND cut3Base ;
