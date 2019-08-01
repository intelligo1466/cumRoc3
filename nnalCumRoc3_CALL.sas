/*  ##########################################################################
    ##########################################################################
    SAS Version 9.4 TS1M3 and later
    License     Apache-2.0 Apache License 2.0
    Copyright   CC-BY-4.0 Creative Commons Attribution 4.0 International Public License
    ##########################################################################
    Cumulative ROC curve analysis of NHANES NNAL.

    Author: B. Rey de Castro, Sc.D., rdecastro@cdc.gov
    Centers for Disease Control and Prevention, Atlanta, Georgia, USA
    ##########################################################################

DEVELOPMENT PLATFORM
    OS:     Microsoft Windows 10 64-bit
    SAS:    9.4 TS1M3 64-bit

    ##########################################################################
    ##########################################################################
DISCLAIMERS
1. DISCLAIMER OF WARRANTY. Under the terms of the Apache License 2.0 License, "Unless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its Contributions) on an "as is" basis, without warranties or conditions of any kind, either express or implied, including, without limitation, any warranties or conditions of title, non-infringement, merchantability, or fitness for a particular purpose. You are solely responsible for determining the appropriateness of using or redistributing the Work and assume any risks associated with Your exercise of permissions under this License."
2. The findings and conclusions in this report are those of the author and do not necessarily represent the views of the Centers for Disease Control and Prevention. Use of trade names is for identification only and does not imply endorsement by the Centers for Disease Control and Prevention.

ATTRIBUTION
1. Under the terms of Creative Commons License CC-BY-4.0, "You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use."
2. SUGGESTION ON HOW TO CITE %cumRoc3
    ##########################################################################
*/
/* Change SAS working directory to enable relative path referencing. */
x 'cd C:/rootDir/project' ;

/* DEMO: Default name for input SAS library in %cumRoc3 */
LIBNAME DEMO "./data/cork" ;

PROC FORMAT ;
    Value nhCyc
        5  = "2007 - 2008"
        6  = "2009 - 2010"
        7  = "2011 - 2012"
    ;
    Value exp3G
        0  = "Non-Exposed"
        1  = "ETS-Exposed"
        2  = "Smoker, Exclusive"
    ;
/*  Categories discriminated by cutpoints.
    REQUIRED FORMAT NAME: vsG */
    Value vsG
        0   =   "Non-Exposed vs. ETS, Smoker"
        1   =   "Non-Exposed, ETS vs. Smoker"
;
RUN ;

/* Load cumulative ROC curve macro %cumRoc3 and supporting macros */
%INCLUDE "./macros/cumRoc3_MAIN_MAC.sas" ;
    %INCLUDE "./macros/words_MAC.sas"          ;
    %INCLUDE "./macros/00_preCheck_MAC.sas"    ;
    %INCLUDE "./macros/01_dataPre_MAC.sas"     ;
    %INCLUDE "./macros/02_cr3_1Logit_MAC.sas"  ;
    %INCLUDE "./macros/03_cr3_2ROC_MAC.sas"    ;
    %INCLUDE "./macros/04_cut3Base_MAC.sas"    ;
    %INCLUDE "./macros/05_cut3Parmx_MAC.sas"   ;
    %INCLUDE "./macros/06_parmx95_MAC.sas"     ;
    %INCLUDE "./macros/07_cr3Results_MAC.sas"  ;

/* NON-PROPORTIONAL ODDS: Ascending outcome modeled */
/* Compare tobacco smoke exposure categories */
/* URXNALln:    Ln NNAL, urine [ng/ml] */
ODS HTML Close ;
ODS HTML ;
    /* Macro debugging: ENABLED */
    OPTIONS MLOGIC MPRINT SYMBOLGEN ;
    %cumRoc3(shsX3,URXNALln,Exposure,%STR(BESTD8.1),nnal_SI,
        %STR(C:/rootDir/project),
        %STR(Output/NNAL),
        %STR(Images/NNAL),
        2019_DEMO,_propOdds=NPO,_macMode=1) ;
    /* Macro debugging: DISABLED */
    OPTIONS noMLOGIC noMPRINT noSYMBOLGEN ;
ODS HTML Close ;
ODS HTML ;
