#############################################################
#Program name - Data Exploration
#input - NONE
#output - Some Exploration statistics
###############################################################
import pandas as pd

# Create data_frame of array values to use in exploration
print("*** Begin Execution")
print("*** Creating dataframe")
df = pd.DataFrame({
    'name':['matt','lisa','richard','john','Julia','jane','marlon'],
    'age':[23,78,22,19,45,33,20],
    'gender':['M','F','M','M','M','F','M'],
    'state':['DC','CO','DE','VA','MD','DE','NY'],
    'years_of_service':[10,0,2,0,2,1,5],
    'iq':[300,100,110,200,300,10,40]
})
########################################################
# BEGIN extract a 25% sample of data
########################################################
print("*** Extracting sample")
print()
rows = df.sample(frac =.25)
# validate first to check if sample is 0.25 times data or not
if (0.25*(len(df))== len(rows)):
    print(len(df), len(rows))

# Display Sample
print('Sample Of 25%')
print(rows)

#END extract a 25% sample of data

############################################################
# BEGIN Split categorical variables by gender, Sum, Mean, count,
# and describe on the data
############################################################

#Categorical Variables splitting
#Group the data by gender
print("\n*** Grouping data set")
groupby_gender = df.groupby('gender')
print("\nMean of iq by Gender")
for gender, value in groupby_gender['iq']:
    print((gender, value.mean()))

# Find the Summation of all ages in the data
print("\n*** Producing analysis and description\n")
SumofAge=df['age'].sum()
print('\nSum of Ages:', SumofAge)

#Find the mean of Age
MeanAge = df['age'].mean()
print('\nAverage Ages:', MeanAge)

# Find the mean of all columns
print ('\nMeans of each column:')
print(df.mean(axis=0))

# Describe the Data
print("\nPython description of iq")
print(df['iq'].describe())
print("*** End Execution")
