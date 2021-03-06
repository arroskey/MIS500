/**********************************************************************************

DESCRIPTION:  THIS PROGRAM ILLUSTRATES HOW TO CALCULATE EXPENDITURES FOR ALL EVENTS ASSOCIATED WITH A CONDITION

              THE CONDITION USED IN THIS EXERCISE IS DIABETES (ICD10CDX='E11')



INPUT FILES:  1) /folders/myfolders/MEPS/H201.SAS7BDAT    (2017 FY PUF DATA)
              2) /folders/myfolders/MEPS/H199.SAS7BDAT    (2017 CONDITION PUF DATA)
              3) /folders/myfolders/MEPS/H197A.SAS7BDAT   (2017 PMED PUF DATA)
              4) /folders/myfolders/MEPS/H197D.SAS7BDAT   (2017 INPATIENT VISITS PUF DATA)
              5) /folders/myfolders/MEPS/H197E.SAS7BDAT   (2017 EROM VISITS PUF DATA)
              6) /folders/myfolders/MEPS/H197F.SAS7BDAT   (2017 OUTPATIENT VISITS PUF DATA)
              7) /folders/myfolders/MEPS/H197G.SASBDAT   (2017 OFFICE-BASED VISITS PUF DATA)
              8) /folders/myfolders/MEPS/H197H.SAS7BDAT   (2017 HOME HEALTH PUF DATA)
              9) /folders/myfolders/MEPS/H197IF1.SAS7BDAT  (2017 CONDITI/folder/folder/folders/myfolders/MEPS/ DATA)

*********************************************************************************/;


LIBNAME CDATA '/folders/myfolders/MEPS';

TITLE1 'MIS500 Portfolio Project';
TITLE2 'EXERCISE3B.SAS: CALCULATE EXPENDITURES FOR ALL EVENTS ASSOCIATED WITH A CONDITION (DIABETES)';

PROC FORMAT;
  VALUE GTZERO
     0         = '0'
     0 <- HIGH = '>0'
               ;
  VALUE GEZERO
     0 - HIGH = 'GE 0' ;
RUN;

/*1) PULL OUT CONDITIONS WITH DIABETES (ICD10CDX='E11') FROM 2017 CONDITION PUF - HC199*/

DATA DIAB;
 SET CDATA.H199;
 IF ICD10CDX IN ('E11');
RUN;

TITLE3 "CHECK ICD10DX CODES";
PROC FREQ DATA=DIAB;
  TABLES ICD10CDX / LIST MISSING;
RUN;


/*2) GET EVENT ID FOR THE DIABETIC CONDITIONS FROM CONDITION-EVENT LINK FILE*/

DATA  DIAB2 ;
MERGE DIAB          (IN=AA KEEP=DUPERSID CONDIDX ICD10CDX)
      CDATA.H197IF1 (IN=BB KEEP=CONDIDX  EVNTIDX );
   BY CONDIDX;
      IF AA AND BB ;
RUN;

TITLE3 "SAMPLE DUMP FOR CONDITION-EVEL LINK FILE";
PROC PRINT DATA=DIAB2 (OBS=20);
BY CONDIDX;
RUN;


/*3) DELETE DUPLICATE CASES PER EVENT*/

PROC SORT DATA=DIAB2 (KEEP=DUPERSID EVNTIDX) OUT=DIAB3 NODUPKEY;
  BY EVNTIDX;
RUN;

TITLE3 "SAMPLE DUMP AFTER DUPLICATE CASES ARE DELETED";
PROC PRINT DATA=DIAB3 (OBS=30);
RUN;


/*4) SUM UP PMED PURCHASE-LEVEL DATA TO EVENT-LEVEL */

PROC SORT DATA=CDATA.H197A  OUT=PMED (KEEP=LINKIDX RXXP17X  RXSF17X--RXOU17X RENAME=(LINKIDX=EVNTIDX));
  BY LINKIDX;
RUN;

PROC SUMMARY DATA=PMED NWAY;
CLASS EVNTIDX;
VAR RXXP17X  RXSF17X--RXOU17X;
OUTPUT OUT=PMED2 SUM=;
RUN;


/*5) ALIGN EXP VARIABLES IN DIFFERENT EVENTS WITH THE SAME NAMES*/

DATA PMED3 (KEEP=EVNTIDX COUNT  SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP);
SET  PMED2;

     SF     = RXSF17X ;
     MR     = RXMR17X ;
     MD     = RXMD17X ;
     PV     = RXPV17X ;
     VA     = RXVA17X ;
     TR     = RXTR17X ;
     OF     = RXOF17X ;
     SL     = RXSL17X ;
     WC     = RXWC17X ;
     OR     = RXOR17X ;
     OU     = RXOU17X ;
     OT     = RXOT17X ;
     TOTEXP = RXXP17X ;
     COUNT = _FREQ_;

     IF TOTEXP GE 0 ;
RUN;

/* Get office based events */
DATA OB (KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP);
 SET CDATA.H197G ;

     SF     = OBSF17X ;
     MR     = OBMR17X ;
     MD     = OBMD17X ;
     PV     = OBPV17X ;
     VA     = OBVA17X ;
     TR     = OBTR17X ;
     OF     = OBOF17X ;
     SL     = OBSL17X ;
     WC     = OBWC17X ;
     OR     = OBOR17X ;
     OU     = OBOU17X ;
     OT     = OBOT17X ;
     TOTEXP = OBXP17X ;

     IF TOTEXP GE 0 ;
RUN ;


/* Get Emergency room events */
DATA EROM (KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP);
SET  CDATA.H197E;
     SF     = ERFSF17X + ERDSF17X ;
     MR     = ERFMR17X + ERDMR17X ;
     MD     = ERFMD17X + ERDMD17X ;
     PV     = ERFPV17X + ERDPV17X ;
     VA     = ERFVA17X + ERDVA17X ;
     TR     = ERFTR17X + ERDTR17X ;
     OF     = ERFOF17X + ERDOF17X ;
     SL     = ERFSL17X + ERDSL17X ;
     WC     = ERFWC17X + ERDWC17X ;
     OR     = ERFOR17X + ERDOR17X ;
     OU     = ERFOU17X + ERDOU17X ;
     OT     = ERFOT17X + ERDOT17X ;
     TOTEXP = ERXP17X ;

     IF TOTEXP GE 0;
RUN;

/* Get Inpatient hospital events */
DATA IPAT (KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP);
SET  CDATA.H197D ;

     SF    = IPFSF17X + IPDSF17X ;
     MR    = IPFMR17X + IPDMR17X ;
     MD    = IPFMD17X + IPDMD17X ;
     PV    = IPFPV17X + IPDPV17X ;
     VA    = IPFVA17X + IPDVA17X ;
     TR    = IPFTR17X + IPDTR17X ;
     OF    = IPFOF17X + IPDOF17X ;
     SL    = IPFSL17X + IPDSL17X ;
     WC    = IPFWC17X + IPDWC17X ;
     OR    = IPFOR17X + IPDOR17X ;
     OU    = IPFOU17X + IPDOU17X ;
     OT    = IPFOT17X + IPDOT17X ;
     TOTEXP= IPXP17X ;

     IF TOTEXP GE 0 ;
RUN;

/* Get home health visits events */
DATA HVIS (KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP);
SET  CDATA.H197H;

     SF     = HHSF17X ;
     MR     = HHMR17X ;
     MD     = HHMD17X ;
     PV     = HHPV17X ;
     VA     = HHVA17X ;
     TR     = HHTR17X ;
     OF     = HHOF17X ;
     SL     = HHSL17X ;
     WC     = HHWC17X ;
     OR     = HHOR17X ;
     OU     = HHOU17X ;
     OT     = HHOT17X ;
     TOTEXP = HHXP17X ;

     IF TOTEXP GE 0;
RUN;

/* Get out patient hospital events */
DATA OPAT (KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP);
SET  CDATA.H197F ;

     SF     = OPFSF17X + OPDSF17X ;
     MR     = OPFMR17X + OPDMR17X ;
     MD     = OPFMD17X + OPDMD17X ;
     PV     = OPFPV17X + OPDPV17X ;
     VA     = OPFVA17X + OPDVA17X ;
     TR     = OPFTR17X + OPDTR17X ;
     OF     = OPFOF17X + OPDOF17X ;
     SL     = OPFSL17X + OPDSL17X ;
     WC     = OPFWC17X + OPDWC17X ;
     OR     = OPFOR17X + OPDOR17X ;
     OU     = OPFOU17X + OPDOU17X ;
     OT     = OPFOT17X + OPDOT17X ;
     TOTEXP = OPXP17X ;

     IF TOTEXP GE 0;
RUN;


/*6)  COMBINE ALL EVENTS INTO ONE DATASET*/

DATA ALLEVENT;
   SET OB   (IN=MV KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP)
       EROM (IN=ER KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP)
       IPAT (IN=ST KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP)
       HVIS (IN=HH KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP)
       OPAT (IN=OP KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP)
      PMED3 (IN=RX KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP);
   BY EVNTIDX;

      LENGTH EVNTYP $4;

      LABEL  EVNTYP = 'EVENT TYPE'
             TOTEXP = 'TOTAL EXPENDITURE FOR EVENT'
             SF     = "SOURCE OF PAYMENT: FAMILY"
             MR     = "SOURCE OF PAYMENT: MEDICARE"
             MD     = "SOURCE OF PAYMENT: MEDICAID"
             PV     = "SOURCE OF PAYMENT: PRIVATE INSURANCE"
             VA     = "SOURCE OF PAYMENT: VETERANS"
             TR     = "SOURCE OF PAYMENT: TRICARE"
             OF     = "SOURCE OF PAYMENT: OTHER FEDERAL"
             SL     = "SOURCE OF PAYMENT: STATE & LOCAL GOV"
             WC     = "SOURCE OF PAYMENT: WORKERS COMP"
             OR     = "SOURCE OF PAYMENT: OTHER PRIVATE"
             OU     = "SOURCE OF PAYMENT: OTHER PUBLIC"
             OT     = "SOURCE OF PAYMENT: OTHER INSURANCE"
                    ;

           IF MV OR OP THEN EVNTYP = 'AMBU' ;
      ELSE IF ER       THEN EVNTYP = 'EROM' ;
      ELSE IF ST       THEN EVNTYP = 'IPAT' ;
      ELSE IF HH       THEN EVNTYP = 'HVIS' ;
      ELSE IF RX       THEN EVNTYP = 'PMED' ;
RUN;

TITLE3 "ALL EVENTS ARE COMBINED INTO ONE FILE";
PROC FREQ DATA=ALLEVENT;
  TABLES EVNTYP TOTEXP SF MR MD PV VA TR OF SL WC OR OU OT /LIST MISSING;
  FORMAT TOTEXP  SF MR MD PV VA TR OF SL WC OR OU OT gtzero. ;
RUN;

PROC PRINT DATA=ALLEVENT (OBS=20);
RUN;


/*7) SUBSET EVENTS TO THOSE ONLY WITH DIABETES*/

DATA DIAB4;
  MERGE DIAB3(IN=AA) ALLEVENT(IN=BB);
  BY EVNTIDX;
  IF AA AND BB;
RUN;


/*8) CALCULATE ESTIMATES ON EXPENDITURES AND USE, ALL TYPES OF SERVICE*/

PROC SUMMARY DATA=DIAB4 NWAY;
  CLASS DUPERSID;
  VAR TOTEXP SF MR MD PV VA TR OF SL WC OR OU OT;
  OUTPUT OUT=ALL SUM=;
RUN;


DATA  FY1;
MERGE CDATA.H201 (IN=AA KEEP=DUPERSID VARPSU VARSTR PERWT17F /*ADD MORE VARIABLES*/)
      ALL        (IN=BB KEEP=DUPERSID TOTEXP SF MR MD PV VA TR OF SL WC OR OU OT);
   BY DUPERSID;

      LABEL SUB = 'PERSONS WHO HAVE AT LEAST 1 EVENT ASSOCIATED WITH DIABETES';

           IF AA AND     BB THEN SUB=1;
      ELSE IF AA AND NOT BB THEN DO ;  /*PERSONS WITHOUT EVENTS WITH DIABETES*/
           SUB   = 2 ;
           TOTEXP= 0 ;
           SF    = 0 ;
           MR    = 0 ;
           MD    = 0 ;
           PV    = 0 ;
           VA    = 0 ;
           TR    = 0 ;
           OF    = 0 ;
           SL    = 0 ;
           WC    = 0 ;
           OR    = 0 ;
           OU    = 0 ;
           OT    = 0 ;
       END;
       IF PERWT17F > 0 ;
RUN;
ODS GRAPHICS OFF;
ODS LISTING CLOSE;
PROC SURVEYMEANS DATA=FY1 NOBS SUMWGT SUM STD MEAN STDERR;
	STRATA  VARSTR ;
	CLUSTER VARPSU ;
	WEIGHT PERWT17F ;
	DOMAIN  SUB('1') ;
	VAR TOTEXP SF MR MD PV VA TR OF SL WC OR OU OT;
    ODS OUTPUT DOMAIN=OUT1;
RUN;
ODS LISTING;

TITLE3 "ESTIMATES ON USE AND EXPENDITURES FOR ALL EVENTS ASSOCIATED WITH DIABETES, 2017";
PROC PRINT DATA=OUT1 NOOBS LABEL;
VAR  VARNAME /*VARLABEL*/ N SUMWGT SUM STDDEV MEAN STDERR;
FORMAT N                    comma6.0
       SUMWGT SUM    STDDEV comma17.0
       MEAN   STDERR        comma9.2
    ;
RUN;


/*9) CALCULATE ESTIMATES ON EXPENDITURES AND USE BY TYPE OF SERVICE */

PROC SUMMARY DATA=DIAB4 NWAY;
  CLASS DUPERSID EVNTYP;
  VAR TOTEXP SF MR MD PV VA TR OF SL WC OR OU OT;
  OUTPUT OUT=TOS SUM=;
RUN;

DATA TOS2;
  SET TOS (DROP=_TYPE_ RENAME=(_FREQ_=N_VISITS));
  LABEL N_VISITS = '# OF VISITS PER PERSON FOR EACH TYPE OF SERVICE' ;
RUN;

TITLE3 "SAMPLE DUMP AFTER DATA IS SUMMED UP TO PERSON-EVENT TYPE-LEVEL";
PROC PRINT DATA=TOS2 (OBS=20);
  BY DUPERSID;
RUN;

DATA  FYTOS;
MERGE CDATA.H201 (IN=AA KEEP=DUPERSID VARPSU VARSTR PERWT17F /*ADD MORE VARIABLES*/)
      TOS2       (IN=BB);
  BY DUPERSID;

          IF AA AND     BB THEN SUB=1;
     ELSE IF AA AND NOT BB THEN DO ;   /*PERSONS WITHOUT EVENTS WITH DIABETES*/
          SUB=2;
          EVNTYP   = 'NA';
          N_VISITS = 0 ;
          TOTEXP   = 0 ;
          SF       = 0 ;
          MR       = 0 ;
          MD       = 0 ;
          PV       = 0 ;
          VA       = 0 ;
          TR       = 0 ;
          OF       = 0 ;
          SL       = 0 ;
          WC       = 0 ;
          OR       = 0 ;
          OU       = 0 ;
          OT       = 0 ;
     END;

     LABEL SUB = 'PERSONS WHO HAVE AT LEAST 1 EVENT ASSOCIATED WITH DIABETES';

     IF PERWT17F > 0 ;
RUN;

ODS GRAPHICS OFF;
ODS LISTING CLOSE;
PROC SURVEYMEANS DATA=FYTOS NOBS SUMWGT SUM STD MEAN STDERR;
	STRATA  VARSTR ;
	CLUSTER VARPSU ;
	WEIGHT  PERWT17F ;
	DOMAIN SUB('1') * EVNTYP ;
	VAR N_VISITS TOTEXP  SF  MR  MD PV VA TR OF SL WC OR OU OT;
    ODS OUTPUT DOMAIN=OUT2 ;
RUN;
ODS LISTING;

PROC SORT DATA=OUT2;
  BY EVNTYP;
RUN;

TITLE3 "ESTIMATES ON USE AND EXPENDITURES FOR EVENTS ASSOCIATED WITH DIABETES, BY TYPE OF SERVICE, 2017";
PROC PRINT DATA=OUT2 NOOBS LABEL;
BY EVNTYP;
VAR  VARNAME /*VARLABEL*/ N SUMWGT SUM STDDEV MEAN STDERR;
FORMAT N                    comma6.0
       SUMWGT SUM    STDDEV comma17.0
       MEAN   STDERR        comma9.2
 ;
RUN;
PROC PRINTTO;
RUN;
