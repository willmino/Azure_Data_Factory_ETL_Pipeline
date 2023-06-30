# Breakdown of Automated Data Cleaning Pipeline

The ADF Pipeline is triggered an then carries out the following steps.

Function #1: Stored Procedure
ADF automatically performs this SQL function: EXEC [utility].[CreateSourceTable]
This creates the first SQL table to which the input CSV file data will be recorded.

Function #2: Copy data
This function finds the input CSV file from an Azure Blob Storage account and copies the data into a table the first SQL raw database.

Function #3: GetConfig
Looks for the stored procedure in the config file to carry out the functions to clean and manipulate the data.
It looks for [utility].[CleanData] and prepares it to be performed in the raw SQL database.


Function #4: Stored Procedure
ADF autmatically performs this SQL function: EXEC [utility].[CreateSinkTable]
This creates the destination table for the cleaned data in the Data Warehouse SQL database.

Function #5: ForEach Copy Function:
This function copies data from the raw SQL database to the Data Warehouse SQL database.
ADF performs this SQL function: EXEC [utility].[CleanData]

Function #6: RefreshPowerBI:
What ever cleaned dataset ends up in the Data Warehouse is trasmitted to a Power BI Dashboard.

The entire process enables automated data reporting. Now an end-user can log in and check the Dashboard before the work day gets going.

Here is the layout of the ADF Data Pipeline:
![Automated_ETL_Pipeline](https://github.com/willmino/Azure_Data_Factory_ETL_Pipeline/blob/main/Files/Images/ADF_ETLPipeline.png)