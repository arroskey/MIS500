/**********************************************************************************
Title: MIS500 Porftolio Project - Data prep and analysis

Description: This program will go through and create two populations:
	1) Age 20-60 with medical events paid by Medicaid (Public option)
	2) Age 20-60 with medical events paid by private insurance (Private option)
	Then perform the analysis by showing summary statistics and t-test.
	
	All events will be collected from the seperate event files and merged into one data set. 
	Then the number of events will be collect per person and merged with the people collected
	from H201(consolidated data file).
	
	Medicines will not be included as an event.

Input Files:  1) /folders/myfolders/MEPS/H201.SAS7BDAT    (2017 FY PUF DATA)
              4) /folders/myfolders/MEPS/H197D.SAS7BDAT   (2017 INPATIENT VISITS PUF DATA)
              5) /folders/myfolders/MEPS/H197E.SAS7BDAT   (2017 EROM VISITS PUF DATA)
              6) /folders/myfolders/MEPS/H197F.SAS7BDAT   (2017 OUTPATIENT VISITS PUF DATA)
              7) /folders/myfolders/MEPS/H197G.SASBDAT   (2017 OFFICE-BASED VISITS PUF DATA)
              8) /folders/myfolders/MEPS/H197H.SAS7BDAT   (2017 HOME HEALTH PUF DATA)

*********************************************************************************/;

/* Set the library name and the top titles. */
LIBNAME CDATA '/folders/myfolders/MEPS';

TITLE1 'MIS500 Portfolio Project';
TITLE2 'Compare access to medical care between public and private payment';
PROC FORMAT;
  VALUE GTZERO
     0         = '0'
     0 <- HIGH = '>0'
               ;
  VALUE GEZERO
     0 - HIGH = 'GE 0' ;
RUN;

/***********************************************************************************
 The general processing for steps 1 - 5 are:
	1. Select each event by the person's id (DUPERSID)
	2. Only bring over the medicaid and private insurance.  
	3. Make sure the event is only paid by one or another.  If both are marked then drop the event.
************************************************************************************/

/* Step 1 - Get office based events for each person (DUPERSID) */
ods graphics on;
DATA OB (KEEP=DUPERSID MD PV);
 SET CDATA.H197G ;
     MD     = OBMD17X ;
     PV     = OBPV17X ;
     TOTEXP = OBXP17X ;
     
     IF (MD EQ 0 OR PV EQ 0) AND (MD+PV) GT 0;
RUN ;

/* Step 2 - Get Emergency room events */
DATA EROM (KEEP=DUPERSID MD PV);
SET  CDATA.H197E;
     MD     = ERFMD17X + ERDMD17X ;
     PV     = ERFPV17X + ERDPV17X ;

     IF (MD EQ 0 OR PV EQ 0) AND (MD+PV) GT 0;
RUN;

/* Step 3 - Get Inpatient hospital events */
DATA IPAT (KEEP=DUPERSID MD PV);
SET  CDATA.H197D ;

     MD    = IPFMD17X + IPDMD17X ;
     PV    = IPFPV17X + IPDPV17X ;

     IF (MD EQ 0 OR PV EQ 0) AND (MD+PV) GT 0;
RUN;

/* Step 4 - Get home health visits events */
DATA HVIS (KEEP=DUPERSID MD PV);
SET  CDATA.H197H;

     MD     = HHMD17X ;
     PV     = HHPV17X ;

     IF (MD EQ 0 OR PV EQ 0) AND (MD+PV) GT 0;
RUN;

/* Step 5 - Get out patient hospital events */
DATA OPAT (KEEP=DUPERSID MD PV);
SET  CDATA.H197F ;

     MD     = OPFMD17X + OPDMD17X ;
     PV     = OPFPV17X + OPDPV17X ;

     IF (MD EQ 0 OR PV EQ 0) AND (MD+PV) GT 0;
RUN;

/* Step 6 - Combine all the events into one dataset */
DATA ALLEVENT;
   SET OB   (KEEP=DUPERSID MD PV)
       EROM (KEEP=DUPERSID MD PV)
       IPAT (KEEP=DUPERSID MD PV)
       HVIS (KEEP=DUPERSID MD PV)
       OPAT (KEEP=DUPERSID MD PV);
   BY DUPERSID;

      LABEL  PV     = "SOURCE OF PAYMENT: Private Insurance"
             MD     = "SOURCE OF PAYMENT: MEDICAID"
                    ;

RUN;

/* Step 7 - Merge events with consoldated data file but only select the age group 20-60 */
DATA  Population;
MERGE CDATA.H201 (IN=AA KEEP=DUPERSID AGELAST)
      ALLEVENT   (IN=BB KEEP=DUPERSID MD PV);
   BY DUPERSID;

           IF (AA AND BB) AND  (20 LE AGELAST LE 60);
RUN;

/* Step 8 - Summarize the Population to count number of events per individual */
PROC SUMMARY DATA=Population NWAY;
CLASS DUPERSID AGELAST;
VAR MD PV;
OUTPUT OUT=PopulationSummarized SUM=;
RUN;

/* Step 9 - Categorize the Population for Public or Private. If there are both medicaid and private
*           payments, then delete the observation 
*/
DATA PopulationCategorized (KEEP=DUPERSID EVENTCOUNT POPCAT AGELAST AGECAT MD PV) ;
	SET PopulationSummarized;
	IF MD GT 0 AND PV EQ 0 THEN POPCAT = 'Public';
	ELSE IF MD EQ 0 AND PV GT 0 THEN POPCAT = 'Private';
	ELSE DELETE; 
	
	IF AGELAST GE 20 AND AGELAST LT 30 THEN AGECAT = '20-29';
	ELSE IF AGELAST GE 30 AND AGELAST LT 40 THEN AGECAT = '30-39';
	ELSE IF AGELAST GE 40 AND AGELAST LT 50 THEN AGECAT = '40-49';
	ELSE AGECAT = '50-59';
	
	EVENTCOUNT = _FREQ_;
	LABEL EVENTCOUNT = "Number of Medical Events";
	LABEL POPCAT = "Payment Method"
RUN;

/* Step 10 - Analysis of final data set */

TITLE3 "Sumary Statistics After Summarization and Categorization";
PROC MEANS DATA=PopulationCategorized;
RUN;

TITLE3 "Summary Statistics by Payment Category After Summarization and Categorization";
PROC SORT DATA=PopulationCategorized; BY POPCAT;
PROC MEANS; VAR EVENTCOUNT AGELAST; BY POPCAT;
RUN;

/* Perform the t-test for the two populations */
TITLE3 "T-Test After Summarization and Categorization";
PROC TTEST; 
	CLASS POPCAT;
	VAR EVENTCOUNT;
	Title "Public vs. Private t-Test";
RUN;

ods graphics off;

QUIT;










