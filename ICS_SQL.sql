Create database ICS_2
select TOP 1 * from dbo.Table1
select TOP 1 * from dbo.Table2
select TOP 1 * from dbo.Table3

--Q1. Import all three tables & Join them.--
SELECT *
FROM Table1 AS T1
JOIN Table2 AS T2 ON T1.Primary_Producer = T2.Primary_Producer
JOIN Table3 AS T3 ON T1.Account_Name = T3.Account_Name


--Q2.What are the percentage of deals closed.--
SELECT 
    (COUNT(CASE WHEN Stage_Name = '3-Closed Won' THEN 1 ELSE NULL END) * 100.0) / COUNT(*) AS PercentageDealsClosed
FROM Table1;


--Q3. Replace missing values in  "Niche Affiliations" variable with "Others"--
UPDATE Table1
SET Niche_Affiliations = 'Others'
WHERE Niche_Affiliations IS NULL

--**Q4. Select the deals with criteria (Revenue should >5000 and Opportunity Name = Cyber Consultancy and office = "Office2")--

  SELECT *
FROM Table1
WHERE TRY_CAST(REPLACE(REPLACE(Annual_Revenue, 'GBP ', ''), ',', '') AS float) > 5000
  AND Opportunity_Name = 'Cyber Consultancy'
  AND Primary_Producer IN (
    SELECT Primary_Producer FROM Table2 WHERE Office = 'Office2'
  )


--Q5. Select top 5 opportunities by revenue for each stage--
WITH RankedOpportunities AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY Stage_Name ORDER BY Annual_Revenue DESC) AS OpportunityRank
    FROM Table1
)
SELECT *
FROM RankedOpportunities
WHERE OpportunityRank <= 5

--Q6. Find the number of opportunities and total opportunity amount (revenue) by each month? (Use Date field)--
	SELECT
    DATEPART(year, Date) AS Year,
    DATEPART(month, Date) AS Month,
    COUNT(*) AS NumberOfOpportunities,
    SUM(ISNULL(TRY_CAST(Annual_Revenue AS float), 0)) AS TotalOpportunityAmount
FROM Table1
GROUP BY
    DATEPART(year, Date),
    DATEPART(month, Date)
ORDER BY
    Year, Month

--Q7. Create a separate file with accounts and Group the accounts based on revenue as Tier1 (having revenue > 10000), Tier 2(5000 to 10000), Teir 3 (<5000)-- 
SELECT
    Account_Name,
    Annual_Revenue,
    CASE
        WHEN TRY_CAST(REPLACE(REPLACE(Annual_Revenue, 'GBP ', ''), ',', '') AS float) > 10000 THEN 'Tier 1'
        WHEN TRY_CAST(REPLACE(REPLACE(Annual_Revenue, 'GBP ', ''), ',', '') AS float) BETWEEN 5000 AND 10000 THEN 'Tier 2'
        ELSE 'Tier 3'
    END AS RevenueTier
INTO Account_Tiers1
FROM Table1


--Q8. Calculate revenue contribution of each producer.--
SELECT
Primary_Producer,
 SUM(ISNULL(TRY_CAST(Annual_Revenue AS float), 0.0)) AS RevenueContribution
FROM Table1
GROUP BY Primary_Producer
ORDER BY RevenueContribution DESC

--Q9. Create a calculated column to derive stage numbers from Stage Name (ex: 3-Closed Won stage number is 3)--
ALTER TABLE Table1
ADD StageNumber AS (
    CASE
        WHEN CHARINDEX('-', [Stage_Name]) > 0
        THEN CAST(SUBSTRING([Stage_Name], 1, CHARINDEX('-', [Stage_Name]) - 1) AS INT)
        ELSE NULL  -- Handle cases where no hyphen is found in the Stage Name
    END
);

--Q10. Compare quarterly sales for different years (Use Date field)--
SELECT
    YEAR(Date) AS SalesYear,
    DATEPART(QUARTER, Date) AS SalesQuarter,
    SUM(ISNULL(TRY_CAST(Annual_Revenue AS float), 0.0)) AS QuarterlySales
FROM Table1
GROUP BY
    YEAR(Date),
    DATEPART(QUARTER, Date)
ORDER BY
    SalesYear, SalesQuarter;

