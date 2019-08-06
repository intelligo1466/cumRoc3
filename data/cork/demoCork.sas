/*  Data, Cork Quality.
For demonstration of cumulative ROC curve analysis for a ternary ordinal outcome of cork quality.

File:   cork_SI2.csv
        Comma-delimited text file with 3 variables
        150 records

Variables
    dArea       Defects, Total Area [px]
                Numeric
                Number of pixels with cork defects
    quality_C   Cork Quality
                Character
                Three categories of cork quality
                    Poor
                    Normal
                    Superior
    quality     Cork Quality
                Numeric
                Three categories of cork quality, corresponding to quality_C
                    0 => Poor
                    1 => Normal
                    2 => Superior

Original Cork Stopper Data Set
    http://extras.springer.com/2007/978-3-540-71972-4/DATASETS/Cork%20Stoppers/Cork%20Stoppers.xls

    Abstract: The Cork Stoppers.xls file contains measurements performed automatically by an
    image processing system on 150 cork stoppers belonging to three classes. Each
    image was digitised with an adequate threshold in order to enhance the defects.

    Joaquim P. Marques de Sá
    https://web.fe.up.pt/~jmsa/
    Pattern Recognition: Concepts, Methods and Applications
    Springer Berlin Heidelberg
    2012
    ISBN=9783642566516
*/
LIBNAME demo    ".\data\cork" ;

PROC FORMAT ;
    VALUE qual3G
        0   =   "Poor"
        1   =   "Normal"
        2   =   "Superior"
;
RUN ;

PROC IMPORT OUT= WORK._cork
            DATAFILE= "./data/cork/cork_SI2.csv"
            DBMS=CSV REPLACE ;
RUN ;

DATA demo.cork_SI ;
    LENGTH quality_C $ 10 ;
    SET _cork ;
    LABEL   quality	=   "Cork Quality"
            quality_C   =   "Cork Quality"
            dArea       =   "Defects, Total Area [px]"
    ;
    FORMAT quality qual3G. ;
RUN ;

PROC SORT   DATA=   demo.cork_SI ;
    BY quality ;
RUN ;
