/*  ##########################################################################
    ##########################################################################
    SAS Version 9.4 TS1M3 and later
    License     Apache-2.0 Apache License 2.0
    Copyright   CC-BY-4.0 Creative Commons Attribution 4.0 International Public License
    ##########################################################################
    Name:       %cr3_2ROC
    Type:       SAS macro
    Purpose:    Cumulative ROC analysis, Stage 2: cumulative ROC curves

    Author: B. Rey de Castro, Sc.D., rdecastro@cdc.gov
    Centers for Disease Control and Prevention, Atlanta, Georgia, USA
    ##########################################################################

ADVISORY
    * In SAS 9.4, OUTROC= in LOGISTIC includes the automatic variable _SOURCE_ and is used by %cr3_2ROC.
    * In versions before 9.4, this automatic variable is instead called _STEP_ and takes different values than _SOURCE_.
    * The macro's default is to refer to _SOURCE_, but to permit running the macro in version before 9.4 I have included commented-out code that refers to _STEP_.

INPUT
    SAS7BDAT: Predicted cumulative probabilities
        TARGET: &_LIBNM..CUMLOGPRED_&_fileSfx

OUTPUT
    SAS7BDAT: Cumulative ROC curves 0 and 1 with 2x2 table frequencies, ROC criteria, AUCs
        TARGET: &_LIBNM..ROC_&_fileSfx
    SAS7BDAT: Cumulative ROC curve AUCs 0 and 1
        TARGET: &_LIBNM..AUC_&_fileSfx
    PNG: [300 DPI] Charts of cumulative ROC curves 0 and 1 output by LOGISTIC. Black and white style suitable for journal manuscript.
        TARGET: &_dir00./&_dirPng./ROC&_J._&_fileSfx._&_dateOut..PNG

DISCLAIMERS
1. DISCLAIMER OF WARRANTY. Under the terms of the Apache License 2.0 License, "Unless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its Contributions) on an "as is" basis, without warranties or conditions of any kind, either express or implied, including, without limitation, any warranties or conditions of title, non-infringement, merchantability, or fitness for a particular purpose. You are solely responsible for determining the appropriateness of using or redistributing the Work and assume any risks associated with Your exercise of permissions under this License."
2. The findings and conclusions in this report are those of the author and do not necessarily represent the views of the Centers for Disease Control and Prevention. Use of trade names is for identification only and does not imply endorsement by the Centers for Disease Control and Prevention.
*/
%MACRO cr3_2ROC ;
    %LOCAL _j ;
/* ========================================================================== */
/* ========================================================================== */
/* =====    B   E   G   I   N   _J::Loop over artificial binary outcomes ==== */
/* ========================================================================== */
    %DO _J = 0 %TO 1 ;
        PROC SORT   DATA=   &_LIBNM..CUMLOGPRED_&_fileSfx (
                /* Cumulative probabilities predicted from cumulative logit models */
                                RENAME=(cp_1 = cumPr_1
                                        cp_0 = cumPr_0 )
                /* Omit observations with missing (negative) predicted cumulative probabilities for Y<=1 or 2 */
                                WHERE=(nmiss(cumPr_0,cumPr_1) = 0 )
                            )
                    OUT=    _PRED_&_J
                    PRESORTED
        ;
            BY cumPr_&_J ;
        RUN ;

        OPTIONS NODATE NONUMBER ;
        TITLE1 "STAGE 2: Cumulative ROC Curve, j = &_J" ;
        TITLE2 "&_ordIng.ING &_yOut on &_xPred" ;
        ODS NOPROCTITLE ;
/* ========================================================================== */
/* ========================================================================== */
/* GRAPHIC CUMULATIVE ROC CURVES 0 AND 1 */
        ODS GRAPHICS / noBorder Height= 100pct antiAliasMax= %EVAL(&_xObs + 1000) ;
        ODS PRINTER PRINTER=PNG300  /* For PNG at 300 DPI. */
                    STYLE=  JOURNAL /* B&W suitable for journal manuscript */
                    FILE=   "&_dir00./&_dirPng./ROC&_J._&_fileSfx._&_dateOut..PNG"
        ;
        ODS PRINTER SELECT ROCcurve ;
            PROC LOGISTIC DATA= _PRED_&_J PLOTS(Only)= ROC ROCoptions(noDetails) ;
            /* Artificial binary outcome from ternary ordinal outcome */
                MODEL   y_&_J (ORDER=Internal REFERENCE=First)
                        = &_xPred
                        /   noFit   /* NOFIT Suppresses logistic model fit for _xPred, but still calculates ROC curve */
                            OUTROC= _0ROC_&_J (RENAME=(_PROB_ = cumPr_&_J ) WHERE= (upCase(_SOURCE_)= "CUM PR &_J") )
    /* SEE ADVISORY ======= OUTROC= _0ROC_&_J (RENAME=(_PROB_ = cumPr_&_J ) WHERE= (_STEP_= 1) ) */
                ;
            /* PRED= predicted cumulative probability upon which the ROC curve will be based */
                ROC "&_xLbl" &_xPred ;
                ROC "Cum Pr &_J" PRED= cumPr_&_J ;
                ODS OUTPUT ROCAssociation= _0AUC_&_J (WHERE= (upCase(ROCModel)= "CUM PR &_J") );
            RUN ;
        ODS PRINTER CLOSE ;
        ODS GRAPHICS / RESET= border RESET= Height RESET= antiAliasMax ;
        ODS PROCTITLE ;
        OPTIONS DATE NUMBER ;
        TITLE ; FOOTNOTE ;

    /* ========================================================================== */
    /* ==== Process area under the curve results */
    /* ========================================================================== */
        DATA _0AUC_&_J ;
            SET _0AUC_&_J (
                    RENAME=(Area        =   Area_&_J
                            LowerArea   =   LowerArea_&_J
                            UpperArea   =   UpperArea_&_J) )
            ;
            ATTRIB  AreaTxt_&_J     Label= "AUC &_J [Wald 95CI]"
                                    Length= $40
            ;
            CALL MISSING(AreaTxt_&_J) ;
            IF NOT MISSING(Area_&_J)
                THEN AreaTxt_&_J= CAT(strip(put(Area_&_J,10.4)) , " [" , strip(put(LowerArea_&_J,10.4)) , ", " , strip(put(UpperArea_&_J,10.4)) , "]" ) ;
            ELSE     AreaTxt_&_J= " " ;
        RUN ;

    /* ========================================================================== */
    /* ==== Combine input data, cumulative predicted probabilities, and cumulative ROC curve calculations */
    /* ==== Compute 2x2 table frequencies and ROC criteria */
    /* ========================================================================== */
        PROC SORT DATA= _0ROC_&_J PRESORTED ; BY cumPr_&_J ; RUN ;
        DATA _1ROC_&_J ;
            MERGE   _PRED_&_J   /* &_xPred &_yOut y_0 y_1 cumPr_0 cumPr_1 */
                    _0ROC_&_J (
                        IN=     R
                        DROP=   _SOURCE_ /* SEE ADVISORY ======= _STEP_ */
                        RENAME=(_POS_       =   tp_&_J
                                _NEG_       =   tn_&_J
                                _FALPOS_    =   fp_&_J
                                _FALNEG_    =   fn_&_J
                                _SENSIT_    =   tpr_&_J
                                _1MSPEC_    =   fpr_&_J )
            ) ;
            BY cumPr_&_J ;
            IF R ;
            ATTRIB  &_xPred     Format= 14.8
                    &_yOut      Format= &_yFmt
                    cumPr_&_J   Label=  "Probability &_J"               Format= 10.6
                    tp_&_J      Label=  "True Positives, Count &_J"     Format=  8.0
                    tn_&_J      Label=  "True Negatives, Count &_J"     Format=  8.0
                    fp_&_J      Label=  "False Positives, Count &_J"    Format=  8.0
                    fn_&_J      Label=  "False Negatives, Count &_J"    Format=  8.0
                    n_&_J       Label=  "Total, Count &_J"              Format=  8.0
                    rp_&_J      Label=  "Positives, Prevalence &_J"     Format=  8.4
                    rn_&_J      Label=  "Negatives, Prevalence &_J"     Format=  8.4
                    pp_&_J      Label=  "Predicted Positives, Probability &_J"
                                Format=  8.4
                    pn_&_J      Label=  "Predicted Negatives, Probability &_J"
                                Format=  8.4
                    tpr_&_J     Label=  "TPR: Sensitivity &_J"          Format= 10.6
                    fpr_&_J     Label=  "FPR: 1-Specificity &_J"        Format= 10.6
                    spec_&_J    Label=  "Specificity &_J"               Format= 10.6
                    ppv_&_J     Label=  "PPV: Precision &_J"            Format= 10.6
                    npv_&_J     Label=  "NPV &_J"                       Format= 10.6
                    cOdds_&_J   Label=  "Odds, Skew &_J"                Format= 10.6
                    J_&_J       Label=  "Youden Index &_J"              Format= 10.6
                    acc_&_J     Label=  "Total Accuracy &_J"            Format= 10.6
                    mcc_&_J     Label=  "Matthews Corr &_J"             Format= 10.6
            ;
            CALL MISSING(n_&_J, rp_&_J, rn_&_J, pp_&_J, pn_&_J, spec_&_J, ppv_&_J, npv_&_J, cOdds_&_J,J_&_J,acc_&_J,mcc_&_J) ;

            /* Total counts */
                n_&_J= SUM(tp_&_J , tn_&_J , fp_&_J , fn_&_J ) ;
            /* Compute probabiities */
                IF n_&_J > 0 THEN DO ;
                    rp_&_J= sum(tp_&_J , fn_&_J ) / n_&_J ;
                    rn_&_J= sum(tn_&_J , fp_&_J ) / n_&_J ;
                    pp_&_J= sum(tp_&_J , fp_&_J ) / n_&_J ;
                    pn_&_J= sum(tn_&_J , fn_&_J ) / n_&_J ;
                END ;
                spec_&_J= 1 - fpr_&_J ;
                IF sum(tp_&_J , fp_&_J) > 0 THEN ppv_&_J= tp_&_J / sum(tp_&_J , fp_&_J) ;
                IF sum(tn_&_J , fn_&_J) > 0 THEN npv_&_J= tn_&_J / sum(tn_&_J , fn_&_J) ;
                IF rp_&_J > 0 THEN cOdds_&_J= rn_&_J / rp_&_J ;

        /* ========================================================================== */
        /* ==== Compute Youden Index, Total Accuracy, and Matthews Corr Coeff */
        /* ========================================================================== */
            /* Compute Youden Index = J = sensitivity + (specificity-1)
                    = sensitivity - ROCxcoordinate
                Overall measure of test accuracy: [-1,1], perfect prediction= 1 */
                J_&_J= tpr_&_J + spec_&_J - 1 ;
            /* Compute Total Accuracy
                Proportion of tests that accurately predict true outcome: [0,1], perfect prediction= 1 */
                acc_&_J= sum(tp_&_J, tn_&_J) / sum(tp_&_J, tn_&_J, fp_&_J, fn_&_J) ;
            /* Compute Matthews Correlation Coefficient
                Overall measure of test accuracy: [-1,1], perfect prediction= 1 */
                IF ((tp_&_J+fp_&_J)*(tp_&_J+fn_&_J)*(tn_&_J+fp_&_J)*(tn_&_J+fn_&_J)) NE 0
                    THEN mcc_&_J= ((tp_&_J*tn_&_J)-(fp_&_J*fn_&_J))
                                / SQRT(((tp_&_J+fn_&_J)*(tp_&_J+fp_&_J)*(tn_&_J+fp_&_J)*(tn_&_J+fn_&_J)))
                ;
                ELSE IF ((tp_&_J+fp_&_J)*(tp_&_J+fn_&_J)*(tn_&_J+fp_&_J)*(tn_&_J+fn_&_J)) EQ 0
                    THEN mcc_&_J= ((tp_&_J*tn_&_J)-(fp_&_J*fn_&_J)) / 1
                ;
        RUN ;

    /* ONE-TO-ONE MERGE (side-by-side): One (AUC) to many (ROC) */
        DATA _2ROC_&_J ;
            MERGE   _1ROC_&_J
                    _0AUC_&_J
            ;
        RUN ;
        PROC SORT DATA= _2ROC_&_J PRESORTED ; BY &_xPred ; RUN ;
    %END ;
/* ========================================================================== */
/* =====    E   N   D       _J::Loop over artificial binary outcomes ======== */
/* ========================================================================== */
/* ========================================================================== */

    /* Merge cumulative ROC curves 0 and 1 */
    DATA &_LIBNM..ROC_&_fileSfx (LABEL= "Cumulative ROC curves 0 and 1 with 2x2 table frequencies, ROC criteria, AUCs") ;
        MERGE   _2ROC_0
                _2ROC_1
        ;
        BY &_xPred ;
    RUN ;

    /* Merge cumulative ROC curve AUCs 0 and 1
       ONE-TO-ONE MERGE (side-by-side) */
    DATA &_LIBNM..AUC_&_fileSfx (LABEL= "Cumulative ROC curve AUCs 0 and 1") ;
        MERGE   _0AUC_0
                _0AUC_1
        ;
    RUN ;

    %IF %upCase(&_debug0)= NO %THEN %DO ;
        PROC DATASETS LIBRARY= WORK NOLIST ;
            DELETE _PRED_: _0ROC_: _1ROC_: _2ROC_: _0AUC_: ;
        RUN ; QUIT ;
    %END ;
%MEND cr3_2ROC ;
