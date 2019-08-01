/*  ##########################################################################
    ##########################################################################
    SAS Version 9.4 TS1M3 and later
    License     Apache-2.0 Apache License 2.0
    Copyright   CC-BY-4.0 Creative Commons Attribution 4.0 International Public License
    ##########################################################################
    Name:       %DATAPre
    Type:       SAS macro
    Purpose:    Pre-process input data for transformation of ordinal outcome to binary outcomes

    Author: B. Rey de Castro, Sc.D., rdecastro@cdc.gov
    Centers for Disease Control and Prevention, Atlanta, Georgia, USA
    ##########################################################################

OUTPUT
    MACRO VARIABLE, GLOBAL: Indicates order of ordinal outcome for transformation to binary outcome
        _ordIng ASCEND  for _yOrd = A: Y=2 reference category
                DESCEND for _yOrd = D: Y=0 reference category
    MACRO VARIABLE, GLOBAL: Format name of ordinal outcome
        _yFmt   <SAS format>
                ADVISORY: it is preferable for a SAS format to be assigned to the numeric outcome levels
    MACRO VARIABLE, GLOBAL: Label of continuous predictor
        _xLbl   <SAS label>
                ADVISORY: it is preferable for a SAS label to be assigned to the continuous predictor
    SAS7BDAT: Temporary input data from &_LIBNM..&_dsN used for macro processing
        TARGET: _inDsn

DISCLAIMERS
1. DISCLAIMER OF WARRANTY. Under the terms of the Apache License 2.0 License, "Unless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its Contributions) on an "as is" basis, without warranties or conditions of any kind, either express or implied, including, without limitation, any warranties or conditions of title, non-infringement, merchantability, or fitness for a particular purpose. You are solely responsible for determining the appropriateness of using or redistributing the Work and assume any risks associated with Your exercise of permissions under this License."
2. The findings and conclusions in this report are those of the author and do not necessarily represent the views of the Centers for Disease Control and Prevention. Use of trade names is for identification only and does not imply endorsement by the Centers for Disease Control and Prevention.
*/

%MACRO DATAPre ;
    %GLOBAL _ordIng _yFmt _xLbl ;

/* Ordinal outcome: 0, 1, 2
    ASCENDING  transform ternary ordinal outcome to binary: Y=2 reference category
    DESCENDING transform ternary ordinal outcome to binary: Y=0 reference category
    Formats for artificial binary outcomes below consistent with original order of ternary ordinal outcome */
    PROC FORMAT ;
        %IF %UPCASE(&_yOrd) = A %THEN %DO ;
            Value y1fmt
                0   =   "&_yOut= 2"
                1   =   "&_yOut= 0,1"
        ;
            Value y0fmt
                0   =   "&_yOut= 1,2"
                1   =   "&_yOut= 0"
        ;
        %END ;
        %ELSE %IF %UPCASE(&_yOrd) = D %THEN %DO ;
            Value y1fmt
                0   =   "&_yOut= 0"
                1   =   "&_yOut= 1,2"
        ;
            Value y0fmt
                0   =   "&_yOut= 0,1"
                1   =   "&_yOut= 2"
        ;
        %END ;
    RUN ;

    PROC SORT   DATA=   &_LIBNM..&_dsN (KEEP= &_yOut &_xPred)
                OUT=    _inDsn
    ;
        BY &_xPred ;
    RUN ;
    DATA _inDsn ;
        SET _inDsn ;
        ATTRIB
    %IF %UPCASE(&_yOrd) = A %THEN %DO ;
            y_1 Format= y1fmt.  Label= "&_yOut= 0,1 vs.   2"
            y_0 Format= y0fmt.  Label= "&_yOut= 0   vs. 1,2"
    %END ;
    %ELSE %IF %UPCASE(&_yOrd) = D %THEN %DO ;
            y_1 Format= y1fmt.  Label= "&_yOut= 1,2 vs. 0"
            y_0 Format= y0fmt.  Label= "&_yOut=   2 vs. 0,1"
    %END ;
        ;
        /* Get Y format name and X label for use in ROC data */
        IF _N_=1 THEN DO ;
            CALL SYMPUTX('_yFmt' , VFORMAT(&_yOut) ) ;
            CALL SYMPUTX('_xLbl' , VLABEL(&_xPred) ) ;
        END ;
        %IF       %UPCASE(&_yOrd) = A %THEN %LET _ordIng= ASCEND ;
        %ELSE %IF %UPCASE(&_yOrd) = D %THEN %DO ;
            %LET _ordIng= DESCEND ;
        /* For ternary ordinal outcome with DESCENDING outcome levels,
            reverse top and bottom ternary outcomes for internal calculations,
            but report results in given order */
            SELECT(&_yOut) ;
                WHEN(0) &_yOut = 2 ;
                WHEN(2) &_yOut = 0 ;
                OTHERWISE ;
            END ;
        %END ;

    /* Ternary ordinal outcome now has Y=2 as reference category
        for internal calculations and artificial binary outcomes. */
        y_1= (&_yOut EQ 0 | &_yOut EQ 1) ;  /* ARTIFICIAL Y_1=0,1 vs 2  :: Y=2 reference category  */
        y_0= (&_yOut EQ 0) ;                /* ARTIFICIAL Y_0=0   vs 1,2:: Y=2 reference category  */
    RUN ;
%MEND DATAPre ;
