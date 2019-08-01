/*  ##########################################################################
    ##########################################################################
    SAS Version 9.4 TS1M3 and later
    License     Apache-2.0 Apache License 2.0
    Copyright   CC-BY-4.0 Creative Commons Attribution 4.0 International Public License
    ##########################################################################
    Name:       %words
    Type:       SAS macro
    Purpose:    Return number of strings in delimited list of alphanumeric strings

    Author: B. Rey de Castro, Sc.D., rdecastro@cdc.gov
    Centers for Disease Control and Prevention, Atlanta, Georgia, USA
    ##########################################################################

USAGE

    %words(str,delim= %STR( )) ;

        Ex.     %LET _nList= %words(CUTPARMX CUTBASE CUTBOOK) ;

    ==========================================================================

PARAMETERS, Positional
    str             Delimited list of alphanumeric strings

PARAMETERS, Keyword with defaults
    delim= %STR( )  Delimiter for str
                    DEFAULT: <space>

RETURNS
    %eval(&i - 1): integer with number of strings

DISCLAIMERS
1. DISCLAIMER OF WARRANTY. Under the terms of the Apache License 2.0 License, "Unless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its Contributions) on an "as is" basis, without warranties or conditions of any kind, either express or implied, including, without limitation, any warranties or conditions of title, non-infringement, merchantability, or fitness for a particular purpose. You are solely responsible for determining the appropriateness of using or redistributing the Work and assume any risks associated with Your exercise of permissions under this License."
2. The findings and conclusions in this report are those of the author and do not necessarily represent the views of the Centers for Disease Control and Prevention. Use of trade names is for identification only and does not imply endorsement by the Centers for Disease Control and Prevention.
*/
%MACRO words(str,delim= %STR( )) ;
    %local i ;
    %let i= 1 ;
    /* O: processes the charlist and modifier arguments only once
       R: removes leading and trailing blanks */
    %do %while(%length(%qscan(&str,&i,&delim,OR)) GT 0) ;
        %let i= %eval(&i + 1) ;
    %end ;
%eval(&i - 1)
%MEND words ;
