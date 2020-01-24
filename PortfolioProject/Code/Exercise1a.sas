/**********************************************************************************

DESCRIPTION:  THIS PROGRAM GENERATES THE FOLLOWING ESTIMATES ON NATIONAL HEALTH CARE EXPENSES, 2017:

	           (1) OVERALL EXPENSES
	           (2) PERCENTAGE OF PERSONS WITH AN EXPENSE
	           (3) MEAN EXPENSE PER PERSON WITH AN EXPENSE


INPUT FILE:   /folders/myfolders/MEPS/H201.SAS7BDAT (2017 FULL-YEAR FILE)

*********************************************************************************/;
/* IMPORTANT NOTES: Use the next 6 lines of code, if you want to specify an alternative destination for SAS log and
SAS procedure output.*/

/*********  Portfolio project will not leverage this functionality
%LET MyFolder= /folders/myfolders/MEPS;
OPTIONS LS=132 PS=79 NODATE FORMCHAR="|----|+|---+=|-/\<>*" PAGENO=1;
FILENAME MYLOG "&MyFolder\Exercise1_log.TXT";
FILENAME MYPRINT "&MyFolder\Exercise1_OUTPUT.TXT";
PROC PRINTTO LOG=MYLOG PRINT=MYPRINT NEW;
RUN;
************/

proc datasets lib=work nolist kill; quit; /* delete  all files in the WORK library */
libname CDATA "/folders/myfolders/MEPS";

PROC FORMAT;
  VALUE AGEF
     .      = 'ALL AGES'
     0-  64 = '0-64'
     65-HIGH = '65+';

  VALUE AGECAT
      .      = 'ALL AGES'
	   1 = '0-64'
	   2 = '65+';

  VALUE GTZERO
     0         = '0'
     0 <- HIGH = '>0';

  VALUE FLAG
      .         = 'No or any expense'
      0         = 'No expense'
      1         = 'Any expense';
RUN;

TITLE1 'MIS500 Portfolio Project';
TITLE2 "EXERCISE1.SAS: NATIONAL HEALTH CARE EXPENSES, 2017";

/* READ IN DATA FROM 2017 CONSOLIDATED DATA FILE (HC-201) */
DATA PUF201;
  SET CDATA.H201 (KEEP= TOTEXP17 AGE17X AGE42X AGE31X
	                      VARSTR   VARPSU   PERWT17F );

  TOTAL                = TOTEXP17;

  /* CREATE FLAG (1/0) VARIABLES FOR PERSONS WITH AN EXPENSE */
  X_ANYSVCE=0;
  IF TOTAL > 0 THEN X_ANYSVCE=1;

  /* CREATE A SUMMARY VARIABLE FROM END OF YEAR, 42, AND 31 VARIABLES*/

       IF AGE17X >= 0 THEN AGE = AGE17X ;
  ELSE IF AGE42X >= 0 THEN AGE = AGE42X ;
  ELSE IF AGE31X >= 0 THEN AGE = AGE31X ;

       IF 0 LE AGE LE 64 THEN AGECAT=1 ;
  ELSE IF      AGE  > 64 THEN AGECAT=2 ;
RUN;

TITLE3 "Supporting crosstabs for the flag variables";
PROC FREQ DATA=PUF201;
   TABLES X_ANYSVCE*TOTAL
          AGECAT*AGE
          /LIST MISSING;
   FORMAT TOTAL        	gtzero.
          AGE            agef.
     ;
RUN;
ods graphics off;
ods exclude all; /* Suppress the printing of output */
TITLE3 'PERCENTAGE OF PERSONS WITH AN EXPENSE & OVERALL EXPENSES';
PROC SURVEYMEANS DATA=PUF201 MEAN NOBS SUMWGT STDERR SUM STD;
	STRATUM VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT17F;
	VAR  X_ANYSVCE TOTAL ;
	ods output Statistics=work.Overall_results;
RUN;

ods exclude none ; /* Unsuppress the printing of output */
TITLE3 'PERCENTAGE OF PERSONS WITH AN EXPENSE';
proc print data=work.Overall_results (firstobs=1 obs=1) noobs split='*';
var  N  SumWgt  mean StdErr  Sum stddev;
 label SumWgt = 'Population*Size'
       mean = 'Proportion'
       StdErr = 'SE of Proportion'
       Sum = 'Persons*with Any*Expense '
       Stddev = 'SE of*Number*Persons*with*Any Expense';
       format N SumWgt Comma12. mean comma7.2 stderr 7.5
              sum Stddev comma17.;
run;

TITLE3 'OVERALL EXPENSES';
proc print data=work.Overall_results (firstobs=2) noobs split='*';
var  N  SumWgt  mean StdErr  Sum stddev;
 label SumWgt = 'Population*Size'
       mean = 'Mean($)'
       StdErr = 'SE of Mean($)'
       Sum = 'Total*Expense ($)'
       Stddev = 'SE of*Total Expense($)';
       format N SumWgt Comma12. mean comma9.2 stderr 9.5
              sum Stddev comma17.;
run;

ods exclude all; /* suspend all destinations */
TITLE3 'MEAN EXPENSE PER PERSON WITH AN EXPENSE, FOR OVERALL, AGE 0-64, AND AGE 65+';
PROC SURVEYMEANS DATA= PUF201 MEAN NOBS SUMWGT STDERR SUM STD;
	STRATUM VARSTR ;
	CLUSTER VARPSU ;
	WEIGHT  PERWT17F ;
	VAR  TOTAL;
	DOMAIN X_ANYSVCE('1')  X_ANYSVCE('1')*AGECAT ;
	FORMAT  AGECAT agecat.;
	ods output domain= work.domain_results;
RUN;

ods exclude none ; /* Unsuppress the printing of output */
proc print data= work.domain_results noobs split='*';
 var AGECAT  N  SumWgt  mean StdErr  Sum stddev;
 label AGECAT = 'Age Group'
       SumWgt = 'Population*Size'
       mean = 'Mean($)'
       StdErr = 'SE of Mean($)'
       Sum = 'Total*Expense ($)'
       Stddev = 'SE of*Total Expense($)';
       format AGECAT agecat. N SumWgt Comma12. mean comma9.1 stderr 9.4
              sum Stddev comma17.;
run;
ODS _ALL_ CLOSE;
/* THE PROC PRINTTO null step is required to close the PROC PRINTTO */
PROC PRINTTO;
RUN;
