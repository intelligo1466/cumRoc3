/*  ##########################################################################
    ##########################################################################
    SAS Version 9.4 TS1M3 and later
    License     Apache-2.0 Apache License 2.0
    Copyright   CC-BY-4.0 Creative Commons Attribution 4.0 International Public License
    ##########################################################################
    Name:       %preCheck
    Type:       SAS macro
    Purpose:    Check ternary ordinal outcome encoding is compatible with macro
                * PASS: Ordinal outcome is ternary and encoding is numeric 0, 1, 2
                ADVISORY: it is preferable for a SAS format to be assigned to the numeric outcome levels

    Author: B. Rey de Castro, Sc.D., rdecastro@cdc.gov
    Centers for Disease Control and Prevention, Atlanta, Georgia, USA
    ##########################################################################

OUTPUT
    MACRO VARIABLE, GLOBAL: Indicator that ternary ordinal dependent variable is compatible
        _yOK=FAIL :: DEFAULT
            FAIL:  incompatible
            PASS:  compatible

DISCLAIMERS
1. DISCLAIMER OF WARRANTY. Under the terms of the Apache License 2.0 License, "Unless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its Contributions) on an "as is" basis, without warranties or conditions of any kind, either express or implied, including, without limitation, any warranties or conditions of title, non-infringement, merchantability, or fitness for a particular purpose. You are solely responsible for determining the appropriateness of using or redistributing the Work and assume any risks associated with Your exercise of permissions under this License."
2. The findings and conclusions in this report are those of the author and do not necessarily represent the views of the Centers for Disease Control and Prevention. Use of trade names is for identification only and does not imply endorsement by the Centers for Disease Control and Prevention.
*/

%MACRO preCheck ;
    %GLOBAL _yOK ;
    %LET _yOK= FAIL ;

    %LET _yFail_N = ;
    %LET _yFail_0 = ;
    %LET _yFail_1 = ;
    %LET _yFail_2 = ;

    PROC DATASETS NOLIST ;
        DELETE _yLevels _yCheck ;
    QUIT ; RUN ;

    PROC SORT   DATA=   &_LIBNM..&_dsN (KEEP= &_yOut)
                OUT=    _yLevels
        NODUPKEY
    ;
        BY &_yOut ;
    RUN ;
    PROC MEANS DATA= _yLevels NOPRINT ;
        VAR &_yOut ;
        OUTPUT  Out= _yCheck
                N=
                MIN=
                MEDIAN=
                MAX=
            /   AUTONAME
        ;
    RUN ;

    DATA _NULL_ ;
        SET _yCheck ;
        IF  &_yOut._N= 3
            AND
            &_yOut._MIN= 0
            AND
            &_yOut._MEDIAN= 1
            AND
            &_yOut._MAX= 2
        THEN CALL SYMPUTX('_yOK' , 'PASS') ;
        ELSE DO ;
            IF      &_yOut._N > 3 THEN CALL SYMPUTX('_yFail_N' , 'Too Many Outcome Levels.') ;
            ELSE IF &_yOut._N < 3 THEN CALL SYMPUTX('_yFail_N' , 'Too Few Outcome Levels.') ;

            IF &_yOut._MIN    NE 0 THEN CALL SYMPUTX('_yFail_0' , 'Lowest Outcome Level Must be Encoded 0 Numeric [zero].') ;
            IF &_yOut._MEDIAN NE 1 THEN CALL SYMPUTX('_yFail_1' , 'Middle Outcome Level Must be Encoded 1 Numeric.') ;
            IF &_yOut._MAX    NE 2 THEN CALL SYMPUTX('_yFail_2' , 'Highest Outcome Level Must be Encoded 2 Numeric.') ;
        END ;
    RUN ;
    %IF &_yOK= PASS %THEN %DO ;
        %PUT    ====================================================== ;
        %PUT    ====================================================== ;
        %PUT    === MACRO PRE-CHECK: PASS === ;
        %PUT    === OUTCOME VARIABLE COMPATIBLE WITH MACRO === ;
        %PUT    ====================================================== ;
        %PUT    ====================================================== ;
        %IF       %UPCASE(&_yOrd) = A %THEN %PUT %STR(    Designated Reference Level: Y = 2) ;
        %ELSE %IF %UPCASE(&_yOrd) = D %THEN %PUT %STR(    Designated Reference Level: Y = 0) ;
    %END ;
    %ELSE %IF &_yOK= FAIL %THEN %DO ;
        %PUT    ====================================================== ;
        %PUT    ====================================================== ;
        %PUT    === MACRO PRE-CHECK: FAIL === ;
        %PUT    === OUTCOME VARIABLE INCOMPATIBLE WITH MACRO === ;
        %PUT    ====================================================== ;
        %PUT    ====================================================== ;
        %PUT %STR(REASON(S)) ;
        %IF &_yFail_N NE %THEN %PUT %STR(    ) &_yFail_N ;
        %IF &_yFail_0 NE %THEN %PUT %STR(    ) &_yFail_0 ;
        %IF &_yFail_1 NE %THEN %PUT %STR(    ) &_yFail_1 ;
        %IF &_yFail_2 NE %THEN %PUT %STR(    ) &_yFail_2 ;
    %END ;

    %IF %upCase(&_debug0)= NO %THEN %DO ;
        PROC DATASETS LIBRARY= WORK NOLIST ;
            DELETE _yLevels _yCheck ;
        RUN ; QUIT ;
    %END ;
%MEND preCheck ;
