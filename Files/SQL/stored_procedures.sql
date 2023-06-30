-- Stored Procedure #1
CREATE PROCEDURE utility.DropTempTable
AS
BEGIN
    DROP TABLE IF EXISTS housing.##TempTable
END



--Stored Procedure #2: Create TempTable for editing
CREATE PROCEDURE utility.CreateTempTable
AS
BEGIN
    SELECT *
    INTO housing.##TempTable
    FROM [minosqldatabase].[housing].[nashville_housing_data]
END


--Stored Procedure #3 utility.PopulateNullValues
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


--Stored Procedure #4
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


--Stored Procedure #5 (Takes a long time to run)
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


-- Stored Procedure #6: Change the 'Y' and 'N' Values to Yes and No (Does not take long to run)
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


--Stored Procedure #7: Drop Duplicate Values
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
CREATE PROCEDURE utility.DropUnusedColumns
AS
BEGIN
    ALTER TABLE housing.##TempTable
    DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict
END

--Stored Procedure #9: Select
CREATE PROCEDURE utility.SelectAll
AS
BEGIN
    SELECT * FROM housing.##TempTable
END


-- Data Cleaning All in One Stored Procedure
CREATE PROCEDURE utility.CleanData
AS
BEGIN
    EXEC [utility].[DropTempTable]
    EXEC [utility].[CreateTempTable]
    EXEC [utility].[PopulateNullValues]
    EXEC [utility].[ColumnsToWrite]
    EXEC [utility].[WriteDataToColumns]
    EXEC [utility].[ChangeYNtoYesNo]
    EXEC [utility].[DropDuplicates]
    EXEC [utility].[DropUnusedColumns]
    EXEC [utility].[SelectAll]
END


-- In source database (rawsqldatabase) there is also:
--EXEC [utility].[CreateSourceTable]

CREATE PROCEDURE  utility.CreateSourceTable
AS
BEGIN
    DROP TABLE IF EXISTS housing.nashville_housing_data
    CREATE TABLE housing.nashville_housing_data (
        UniqueID INT,
        ParcelID VARCHAR(255),
        LandUse VARCHAR(255),
        PropertyAddress VARCHAR(255),
        SaleDate DATE,
        SalePrice INT,
        LegalReference VARCHAR(255),
        SoldAsVacant VARCHAR(255),
        OwnerName VARCHAR(255),
        OwnerAddress VARCHAR(255),
        Acreage FLOAT,
        TaxDistrict VARCHAR(255),
        LandValue INT,
        BuildingValue INT,
        TotalValue INT,
        YearBuilt INT,
        Bedrooms INT,
        FullBath INT,
        HalfBath INT
    );
END


-- In sink database there is also:
--EXEC [utility].[CreateSinkTable]

CREATE PROCEDURE  utility.CreateSinkTable
AS
BEGIN
    DROP TABLE IF EXISTS data_warehouse.clean_housing_data
    CREATE TABLE data_warehouse.clean_housing_data (
        UniqueID INT,
        ParcelID VARCHAR(255),
        LandUse VARCHAR(255),
        PropertyAddress VARCHAR(255),
        SaleDate DATE,
        SalePrice INT,
        LegalReference VARCHAR(255),
        SoldAsVacant VARCHAR(255),
        OwnerName VARCHAR(255),
        OwnerAddress VARCHAR(255),
        Acreage FLOAT,
        TaxDistrict VARCHAR(255),
        LandValue INT,
        BuildingValue INT,
        TotalValue INT,
        YearBuilt INT,
        Bedrooms INT,
        FullBath INT,
        HalfBath INT
    );
END