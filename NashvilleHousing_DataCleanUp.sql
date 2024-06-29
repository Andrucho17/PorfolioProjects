
------------------------------------------------------------------------------------------------------------------------------------

--Data cleanup

SELECT *
FROM dbo.NashvilleHousing

--Adjusting sale date format

SELECT SaleDateConverted, CONVERT(Date, SaleDate)
FROM dbo.NashvilleHousing

UPDATE dbo.NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate) --Not working properly at the moment

ALTER TABLE dbo.NashvilleHousing
ADD SaleDateConverted Date;

UPDATE dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

------------------------------------------------------------------------------------------------------------------------------------

-- Populating property address where values are null

SELECT PropertyAddress
FROM dbo.NashvilleHousing
WHERE PropertyAddress is null

SELECT *
FROM dbo.NashvilleHousing
--WHERE PropertyAddress is null
ORDER BY ParcelID

-- Joining addresses that have the same ParcelID where the Unique ID row is not the same

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.NashvilleHousing a
JOIN dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null
--Updating table
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.NashvilleHousing a
JOIN dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null
--Recheck
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.NashvilleHousing a
JOIN dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
--WHERE a.PropertyAddress is null

------------------------------------------------------------------------------------------------------------------------------------

-- Separating addresses into individual columns (address, city, state)

--Property Address

SELECT PropertyAddress
FROM dbo.NashvilleHousing

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM dbo.NashvilleHousing


ALTER TABLE dbo.NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE dbo.NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))
--Recheck
SELECT *
FROM dbo.NashvilleHousing

--Owner address

SELECT OwnerAddress
FROM dbo.NashvilleHousing

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM dbo.NashvilleHousing

ALTER TABLE dbo.NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE dbo.NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE dbo.NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
--Recheck
SELECT *
FROM dbo.NashvilleHousing

------------------------------------------------------------------------------------------------------------------------------------

--Change Y and N to YES and NO in "Sold as vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM dbo.NashvilleHousing

UPDATE dbo.NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END

------------------------------------------------------------------------------------------------------------------------------------

-- Removing duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

FROM dbo.NashvilleHousing
--order by ParcelID
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

------------------------------------------------------------------------------------------------------------------------------------

--Removing unsued columns

SELECT *
FROM dbo.NashvilleHousing

ALTER TABLE dbo.NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress, SaleDate

------------------------------------------------------------------------------------------------------------------------------------