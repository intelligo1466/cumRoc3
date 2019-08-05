/*  ##########################################################################
    ##########################################################################
    SAS Version 9.4 TS1M3 and later
    License     Apache-2.0 Apache License 2.0
    Copyright   CC-BY-4.0 Creative Commons Attribution 4.0 International Public License
    ##########################################################################
    Cumulative ROC curve analysis of cork data

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
    VALUE qual3G
        0   =   "Poor"
        1   =   "Normal"
        2   =   "Superior"
;
/*  Categories discriminated by cutpoints.
    vsG: REQUIRED FORMAT NAME */
    VALUE vsG
        0   =   "Poor vs. Normal, Superior"
        1   =   "Poor, Normal vs. Superior"
;
RUN ;

/* Compile cumulative ROC curve macro %cumRoc3 and if &_macComp=YES then also compile supporting macros */
%INCLUDE "./macros/cumRoc3_MAIN_MAC.sas" ;

/* PROPORTIONAL ODDS: Ascending outcome modeled */
/* Compare cork quality categories */
/* Defect area [px] */
ODS HTML Close ; ODS HTML ;
    /* Macro debugging: ENABLED */
    OPTIONS MLOGIC MPRINT SYMBOLGEN ;
    %cumRoc3(quality,dArea,Quality,%STR(BESTD8.3),cork_SI,
        %STR(C:/rootDir/project),
        %STR(Output/Cork),
        %STR(Images/Cork),
        2019_DEMO,_macMode=1,_macComp=YES,
        _outCntnts=YES,_outRtf=NO) ;
    /* Macro debugging: DISABLED */
    OPTIONS noMLOGIC noMPRINT noSYMBOLGEN ;
ODS HTML Close ; ODS HTML ;

/* A more routine (and less verbose) call to %cumRoc3
    * No macro debugging to LOG
    * Supporting macros not recompiled (prerequisite: macros compiled at least once before during current SAS session)
    * CONTENTS of permanent output datasets not appended to results
    * Tabulated results output to RTF
*/
ODS HTML Close ; ODS HTML ;
    %cumRoc3(quality,dArea,Quality,%STR(BESTD8.3),cork_SI,
        %STR(C:/rootDir/project),
        %STR(Output/Cork),
        %STR(Images/Cork),
        2019_DEMO,_macComp=NO,
        _outCntnts=NO,_outRtf=YES) ;
ODS HTML Close ; ODS HTML ;
