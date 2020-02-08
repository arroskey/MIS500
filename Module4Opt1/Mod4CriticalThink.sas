/********************************************************************************************
*
* Module 4 Critical Think - Paired t-test
* Author: Alan Roskey
*
* In this example, tutoring is being examined to determine its effect on students.  Twelve
* students participate in the study.  Each student's score is measured before and after tutoring.
* The t-test is then executed.
*
********************************************************************************************/

/* Create the data set for the before and after scores */

data TestScores;
input TScore_before TScore_after @@;
datalines;
123 133 135 136 129 135 117 137
120 142 138 135 140 121 145 147
136 168 140 152 146 129 137 145
;
run;

/* Print out the test scores */
TITLE 'Test Score Observations';
proc print data=TestScores;
run;

/* Get some summary statistics */
TITLE 'Summary Statistics for Observations';
proc means data = TestScores;
run;

/* Execute the t-test */
TITLE 'T-Test Results';
ods graphics on;
proc ttest data=TestScores;
paired Tscore_before*Tscore_after;
run;
ods graphics off;
run;
TITLE '';


