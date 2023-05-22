--- Data Cleaning Project -NashVilleHousing Data.
--If you're following this sequentially, Note that some unused columns were deleted at the end, That's why they may come up as invalid

  --1. Standardise Date Format

  -- original sale date format on the table
  select saledate 
  from NashvilleHousing

  --standardizing
   --Used Alter Table to add a new column "SaleDateConverted"
   Alter Table NashvilleHousing
   add saleDateConverted Date;
   --updated table 
   Update NashvilleHousing
   SET SaleDateConverted = Convert(Date,SaleDate)
  --check to see new column "SaleDateConverted is added"
  select SaleDateConverted, Convert(Date,Saledate) 
   from NashvilleHousing

  -- 2. populate property address data

  --PropertyAddress format on the table(Notice some address have a null. we have to fix this)
  select PropertyAddress
  from NashvilleHousing
  where PropertyAddress is Null
 
  --PropertyAddress and ParcelID xhip in table(Notice that ParcelID and PropertyAddress tend to match). 
  -- The xhip btwn both will be useful in fixing the Property Address with null values.
  select PropertyAddress, ParcelID
  from NashvilleHousing
  Order by ParcelID

  -- Fixing the nulls on Property Addresses. (We want to populate same address that match a similar ParcelID into the nulls)
  -- First, we must do a self join on ParcelID and UniqueID
  -- ISNULL checked to update the nulls. It's the "No column name"

  Select a.parcelID, a.propertyAddress, b.parcelID, b.propertyAddress, ISNULL(a.propertyAddress, b.PropertyAddress)
  from NashvilleHousing a
  Join NashvilleHousing b
  on 
  a.parcelID = b.parcelID
  AND a.[UniqueID ] <> b.[UniqueID ]
  where a.PropertyAddress is null
 
 -- Update Table (to take away the nulls)
 Update a
 SET PropertyAddress = ISNULL(a.propertyAddress, b.PropertyAddress)
  from NashvilleHousing a
  Join NashvilleHousing b
  on 
  a.parcelID = b.parcelID
  AND a.[UniqueID ] <> b.[UniqueID ]
   where a.PropertyAddress is null

 ---3. Breaking out Address into Individual Columns (Address, City, State)

 -- See that only the address and City is separated by comma. 
 select PropertyAddress
 from NashvilleHousing

 -- To fix, we will use a substring and Character Index to fix the delimeter
 select SUBSTRING(propertyAddress, 1, CHARINDEX(',', propertyAddress)-1) as Address --look in the propertyaddress table, and stop on the 1st ","). The -1 at the end gets rid of the comma on our result output. the -1 simply put is we are going to the comma and one step behind the comma
 ,SUBSTRING(propertyAddress, CHARINDEX(',', propertyAddress)+1, LEN(PropertyAddress)) as City -- Go past the comma +1 and extarct the next sentences
 from NashvilleHousing

 -- Adding the 2 extra new columns"PropertySplitAddress" AND "PropertySplitCity" to the table **so we can delete the old original column that merged both add & city together
 Alter Table NashvilleHousing
   add PropertySplitAddress Nvarchar(255);
   
   Update NashvilleHousing
   SET PropertySplitAddress = SUBSTRING(propertyAddress, 1, CHARINDEX(',', propertyAddress)-1)

   Alter Table NashvilleHousing
   add PropertySPlitCity Nvarchar(255);
   
   Update NashvilleHousing
   SET PropertySPlitCity = SUBSTRING(propertyAddress, CHARINDEX(',', propertyAddress)+1, LEN(PropertyAddress))

   ---Check end of table to see 2 new columns added
   select *
   from NashvilleHousing

   ----4. Spliting  for OwnerAddress (Address, City, and State)

   --check original data
   select owneraddress
   from NashvilleHousing

   --Use Parse to break out the owner address. much better than substring and character Index
   -- parsename and replace the "," with ".". parsename only recognises "." so had to switch before parsing. parsing works backwards hence why "3, 2, 1)
   select 
   PARSENAME(REPLACE(owneraddress, ',', '.') , 3) 
   ,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2) 
   ,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1) 
   from NashvilleHousing

   ---Adding the 3 extra new columns
    Alter Table NashvilleHousing
   add OwnerSplitAddress Nvarchar(255);
   
   Update NashvilleHousing
   SET  OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3) 

    Alter Table NashvilleHousing
   add OwnerSplitCity Nvarchar(255);
   
   Update NashvilleHousing
   SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)

    Alter Table NashvilleHousing
   add OwnerSplitState Nvarchar(255);
   
   Update NashvilleHousing
   SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)

     --check to see 3 new columns at end
   select *
   from NashvilleHousing
  
  --- 5. Change Y and N to Yes and No in the "Sold as Vacant" column

      --check to see original data
   select Distinct(SoldAsVacant), Count(SoldAsVacant)
   from NashvilleHousing
   Group by SoldAsVacant
   Order by 2 desc

   --- Use Case Statement to update
   select SoldAsVacant
   ,CASE when SoldASVacant = 'Y' THEN 'Yes'
   when SoldASVacant = 'N' THEN 'No'
   ELSE SoldAsVacant
   END
   From NashvilleHousing

   --Update column
   update NashvilleHousing
   SET SoldAsVacant = CASE when SoldASVacant = 'Y' THEN 'Yes'
   when SoldASVacant = 'N' THEN 'No'
   ELSE SoldAsVacant
   END

   ---6. Removing Duplicates (*** Don't do this to raw data that come into the database

   -- Writing CTE's and Windows Function to find Duplicate Values

   WITH RowNumCTE As(
   select *,
   ROW_NUMBER() OVER (
   PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY
					UniqueID
					) row_num
   
   From NashvilleHousing
   )
   DELETE
   from RowNumCTE
   where row_num > 1
   
   ---check to see if the dupliactes were removes

    WITH RowNumCTE As(
   select *,
   ROW_NUMBER() OVER (
   PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY
					UniqueID
					) row_num
   
   From NashvilleHousing
   )
   Select *
   from RowNumCTE
   where row_num > 1

   ---7. Delete unused Columns
   Alter Table NashvilleHousing
   Drop Column OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

   --Check original
   select *
   from NashvilleHousing