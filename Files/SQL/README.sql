--Stored Procedure #3 utility.PopulateNullValues

-- The dataset had a fair amount of null values in the PropertyAddress column.
-- I noticed that each row has a value for ParcelID. It turns out rows with the same PropertyAddress all had equivalent
-- ParcelID values. Thus, I performed COALESCE function performed and a self-join function where every row with PropertyAddress
-- null values is placed next to the row with matching ParcelID values and PropertyAddress values. The null values are then
-- populated with the corresponding PropertyAddress values
-- This function was used as a stored procedure for the automated data cleaning process.

CREATE PROCEDURE utility.PopulateNullValues
AS
BEGIN
    UPDATE a
    SET a.PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress)
    FROM housing.##TempTable a
    JOIN housing.##TempTable b
        ON a.ParcelID = b.ParcelID
        AND a.[UniqueID] <> b.[UniqueID]
    WHERE a.PropertyAddress IS NULL;
END;


-- Stored Procedure #4
-- Columns were created before executing a split column function later on.
-- This function was used as a stored procedure for the automated data cleaning process.

CREATE PROCEDURE utility.ColumnsToWrite
AS
BEGIN
    ALTER TABLE housing.##TempTable
    ADD PropertyAddressSplit VARCHAR(255)

    ALTER TABLE housing.##TempTable
    ADD PropertyCity VARCHAR(255)

    ALTER TABLE housing.##TempTable
    ADD OwnerAddressSplit VARCHAR(255)

    ALTER TABLE housing.##TempTable
    ADD OwnerCity VARCHAR(255)

    ALTER TABLE housing.##TempTable
    ADD OwnerState VARCHAR(255)
END;


-- Stored Procedure #5
-- By using SUBSTRING function and in another case the PARSENAME function for character index detection, the address, city, and state values (all in a single row),
-- were extracted and loaded into new columns in the table.
-- This function was used as a stored procedure for the automated data cleaning process.

CREATE PROCEDURE utility.WriteDataToColumns
AS
BEGIN
    Update housing.##TempTable
    SET PropertyAddressSplit = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)

    Update housing.##TempTable
    SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))

    UPDATE housing.##TempTable
    SET OwnerAddressSplit = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

    UPDATE housing.##TempTable
    SET OwnerCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

    UPDATE housing.##TempTable
    SET OwnerState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)
END


-- Stored Procedure #6: Change the 'Y' and 'N' Values to Yes and No
-- By using the UPDATE housing.##TempTable function, and the SET SoldAsVacant with the CASE statements,
-- I changed the values of all rows with a Y and an N to a 'Yes' and a 'No', respectively.
-- For the values in all other rows, simply saying the column name would not change anything else.
-- This function was used as a stored procedure for the automated data cleaning process.

CREATE PROCEDURE utility.ChangeYNtoYesNo
AS
BEGIN
    UPDATE housing.##TempTable
    SET SoldAsVacant =
        CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
            WHEN SoldAsVacant = 'N' THEN 'NO'
            ELSE SoldAsVacant
            END
END


-- Stored Procedure #7: Drop Duplicate Values
-- This function determines duplicate rows in the table and then deletes the rows that are marked with a number indicating a duplicate.
-- First, notice the SELECT * function with the ROW_NUMBER() OVER (PARTITION BY...) statement.
-- In this statement, we are essentially creating bins of data to determine what rows have column fields with the exact same values
-- save for a few different values. The ROW_NUMBER() function creates a new column called "row_num". The first bin of data is for unique rows and the ROW_NUMBER() function assigns it a value of 1.
-- The second bin is for duplicate data, these rows have all exact values compared to another row. Only one row of set of duplciates
-- is marked with the value 2.
-- The PARITION BY... statement is the criteria for which columns we are looking in to find unique or exact values.
-- I picked these columns for the PARTITION BY statement because they were the most likely to have unique values.
-- This function then relies on making a temporary result set called a Common Table Expression (CTE). 
-- This is necessary because we don't want to perform certain functions directly on the final data set like creating the temporary
-- column called row_num.
-- Finally, the rows that are greater than 1 (aka a value of 2 for the column row_num) are deleted from the CTE.
-- The original table is updated with the results.
-- This function was used as a stored procedure for the automated data cleaning process.

CREATE PROCEDURE utility.DropDuplicates
AS
BEGIN
    WITH RowNumCTE AS(
    SELECT *,
        ROW_NUMBER() OVER (
        PARTITION BY ParcelID,
                 PropertyAddress,
                 SalePrice,
                 SaleDate,
                 LegalReference
                 ORDER BY UniqueID
                ) row_num
    FROM housing.##TempTable
    )
    DELETE
    FROM RowNumCTE
    WHERE row_num > 1
END


-- Stored Procedure #8: Drop Unused Columns
-- This function simply drops specified columns from the table.
-- This function was used as a stored procedure for the automated data cleaning process.

CREATE PROCEDURE utility.DropUnusedColumns
AS
BEGIN
    ALTER TABLE housing.##TempTable
    DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict
END

--Stored Procedure #9: Select ALL
-- We have to include this function in order for the data pipeline to select the data that is required to be copied to the 
-- Data Warehouse.
-- This function was used as a stored procedure for the automated data cleaning process.

CREATE PROCEDURE utility.SelectAll
AS
BEGIN
    SELECT * FROM housing.##TempTable
END