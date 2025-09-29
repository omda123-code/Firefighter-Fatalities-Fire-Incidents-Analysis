use [Toronto FireIncidents]
select top 3 * from FireIncidents

-- Question: "How have the number of incidents changed year-by-year?"
-- Purpose: identify overall temporal trend and seasonality.
SELECT 
  YEAR(CONVERT(datetime,[TFS_Alarm_Time])) AS Year,
  COUNT(*) AS Incidents
FROM FireIncidents
WHERE [TFS_Alarm_Time] IS NOT NULL
GROUP BY YEAR(CONVERT(datetime,[TFS_Alarm_Time]))
ORDER BY Year;

-- Question: "Which Areas of Origin account for the most incidents?"
-- Purpose: prioritize prevention in most common origin areas.
SELECT TOP 10
  [Area_of_Origin],
  COUNT(*) AS Incidents
FROM FireIncidents
GROUP BY [Area_of_Origin]
ORDER BY Incidents DESC;

-- Question: "Which Final Incident Types have the highest average estimated dollar loss?"
-- Purpose: allocate resources to incident types with largest economic impact.
SELECT
  [Final_Incident_Type],
  AVG(CAST([Estimated_Dollar_Loss] AS FLOAT)) AS Avg_Estimated_Loss
FROM FireIncidents
WHERE ISNUMERIC([Estimated_Dollar_Loss]) = 1
GROUP BY [Final_Incident_Type]
ORDER BY Avg_Estimated_Loss DESC;

-- Question: "Is longer response time associated with more civilian casualties?"
-- Purpose: measure relationship between response delay and casualties.
SELECT
  DATEDIFF(SECOND, CONVERT(datetime,[TFS_Alarm_Time]), CONVERT(datetime,[TFS_Arrival_Time]))/60.0 AS Response_Minutes,
  SUM(CAST([Civilian_Casualties] AS INT)) AS Total_Civilian_Casualties,
  COUNT(*) AS Incidents
FROM FireIncidents
WHERE [TFS_Alarm_Time] IS NOT NULL AND [TFS_Arrival_Time] IS NOT NULL
GROUP BY DATEDIFF(SECOND, CONVERT(datetime,[TFS_Alarm_Time]), CONVERT(datetime,[TFS_Arrival_Time]))/60.0
ORDER BY Response_Minutes;

-- Question: "Do incidents with sprinkler systems have fewer casualties or lower losses?"
-- Purpose: evaluate effectiveness of sprinkler presence/operation.
SELECT
  [Sprinkler_System_Presence],
  [Sprinkler_System_Operation],
  COUNT(*) AS Incidents,
  SUM(CAST([Civilian_Casualties] AS INT)) AS Total_Civilian_Casualties,
  AVG(CASE WHEN ISNUMERIC([Estimated_Dollar_Loss])=1 THEN CAST([Estimated_Dollar_Loss] AS FLOAT) END) AS Avg_Loss
FROM FireIncidents
GROUP BY [Sprinkler_System_Presence],[Sprinkler_System_Operation]
ORDER BY Incidents DESC;

-- Question: "How does presence or failure of smoke alarms affect evacuation and casualties?"
-- Purpose: quantify life-safety impact of smoke alarms.
SELECT
  [Smoke_Alarm_at_Fire_Origin],
  [Smoke_Alarm_at_Fire_Origin_Alarm_Failure],
  [Smoke_Alarm_Impact_on_Persons_Evacuating_Impact_on_Evacuation],
  COUNT(*) AS Incidents,
  SUM(CAST([Civilian_Casualties] AS INT)) AS Total_Casualties
FROM FireIncidents
GROUP BY
  [Smoke_Alarm_at_Fire_Origin],
  [Smoke_Alarm_at_Fire_Origin_Alarm_Failure],
  [Smoke_Alarm_Impact_on_Persons_Evacuating_Impact_on_Evacuation]
ORDER BY Total_Casualties DESC;

-- Question: "What are the most common ignition sources and possible causes?"
-- Purpose: target prevention programs to common causes.
SELECT TOP 15
  [Ignition_Source],
  [Possible_Cause],
  COUNT(*) AS Incidents
FROM FireIncidents
GROUP BY [Ignition_Source],[Possible_Cause]
ORDER BY Incidents DESC;

-- Question: "How long does it take to bring fires under control?"
-- Purpose: analyze operational performance and identify long-duration incidents.
SELECT
  DATEDIFF(MINUTE, CONVERT(datetime,[TFS_Alarm_Time]), CONVERT(datetime,[Fire_Under_Control_Time])) AS Minutes_To_Control,
  COUNT(*) AS Incidents
FROM FireIncidents
WHERE [TFS_Alarm_Time] IS NOT NULL AND [Fire_Under_Control_Time] IS NOT NULL
GROUP BY DATEDIFF(MINUTE, CONVERT(datetime,[TFS_Alarm_Time]), CONVERT(datetime,[Fire_Under_Control_Time]))
ORDER BY Minutes_To_Control;

-- Question: "Which property uses cause the most displacement (Estimated_Number_Of_Persons_Displaced)?"
-- Purpose: identify property types with greatest humanitarian impact.
SELECT
  [Property_Use],
  SUM(COALESCE(CAST([Estimated_Number_Of_Persons_Displaced] AS INT),0)) AS Total_Displaced,
  COUNT(*) AS Incidents
FROM FireIncidents
GROUP BY [Property_Use]
HAVING SUM(COALESCE(CAST([Estimated_Number_Of_Persons_Displaced] AS INT),0)) > 0
ORDER BY Total_Displaced DESC;

-- Question: "Do incidents with more responding apparatus or personnel rescue more people?"
-- Purpose: evaluate resource-to-rescue efficiency.
SELECT
  [Number_of_responding_apparatus],
  [Number_of_responding_personnel],
  SUM(COALESCE(CAST([Count_of_Persons_Rescued] AS INT),0)) AS Total_Rescued,
  COUNT(*) AS Incidents
FROM FireIncidents
GROUP BY [Number_of_responding_apparatus],[Number_of_responding_personnel]
ORDER BY Total_Rescued DESC;

-- Question: "Where (lat/long) are incidents concentrated?"
-- Purpose: create heatmap / cluster map of incident locations.
SELECT
  CAST([Latitude] AS FLOAT) AS lat,
  CAST([Longitude] AS FLOAT) AS lon,
  COUNT(*) AS incidents
FROM FireIncidents
WHERE [Latitude] IS NOT NULL AND [Longitude] IS NOT NULL
GROUP BY CAST([Latitude] AS FLOAT), CAST([Longitude] AS FLOAT)
HAVING COUNT(*) >= 1
ORDER BY incidents DESC;

-- Question: "When (hour of day / day of week) do business-impacting incidents occur?"
-- Purpose: plan inspections / staffing during high-risk times.
SELECT
  DATEPART(dw, CONVERT(datetime,[TFS_Alarm_Time])) AS DayOfWeek, -- 1=Sunday on default SQL Server
  DATEPART(hour, CONVERT(datetime,[TFS_Alarm_Time])) AS HourOfDay,
  SUM(CASE WHEN [Business_Impact] IS NOT NULL AND [Business_Impact] <> '' THEN 1 ELSE 0 END) AS Business_Impact_Count
FROM FireIncidents
WHERE [TFS_Alarm_Time] IS NOT NULL
GROUP BY DATEPART(dw, CONVERT(datetime,[TFS_Alarm_Time])), DATEPART(hour, CONVERT(datetime,[TFS_Alarm_Time]))
ORDER BY DayOfWeek, HourOfDay;

-- Question: Which property uses have the highest casualty rate per incident?
-- Purpose: Identify property types that are more dangerous for civilians, so fire safety measures can be focused there.
SELECT 
    [Property_Use],
    COUNT(*) AS Total_Incidents,
    SUM(CAST([Civilian_Casualties] AS INT)) AS Total_Casualties,
    CAST(SUM(CAST([Civilian_Casualties] AS INT)) AS FLOAT) / NULLIF(COUNT(*),0) AS Casualty_Rate_Per_Incident
FROM FireIncidents
GROUP BY [Property_Use]
ORDER BY Casualty_Rate_Per_Incident DESC;

-- Question: How many incidents resulted in firefighter casualties?
-- Purpose: Evaluate the occupational risks faced by firefighters during operations
SELECT 
    COUNT(*) AS Incidents_With_Firefighter_Casualties,
    SUM(CAST([TFS_Firefighter_Casualties] AS INT)) AS Total_Firefighter_Casualties
FROM FireIncidents
WHERE CAST([TFS_Firefighter_Casualties] AS INT) > 0;

-- Question: At what times of day do incidents most frequently occur?
-- Purpose: Understand temporal patterns of fire incidents to optimize staffing, inspections, or awareness campaigns.
SELECT 
    DATEPART(HOUR, CONVERT(datetime, [TFS_Alarm_Time])) AS HourOfDay,
    COUNT(*) AS Incidents
FROM FireIncidents
WHERE [TFS_Alarm_Time] IS NOT NULL
GROUP BY DATEPART(HOUR, CONVERT(datetime, [TFS_Alarm_Time]))
ORDER BY HourOfDay;

-- Question: Which areas of origin show longer or shorter median response times?
-- Purpose: Assess if certain types of fire origin (e.g., vehicles, bedrooms, kitchens) are associated with faster or slower detection and response.
SELECT 
    [Area_of_Origin],
    PERCENTILE_CONT(0.5) WITHIN GROUP 
        (ORDER BY DATEDIFF(SECOND, CONVERT(datetime,[TFS_Alarm_Time]), CONVERT(datetime,[TFS_Arrival_Time]))/60.0)
        OVER (PARTITION BY [Area_of_Origin]) AS Median_Response_Minutes
FROM FireIncidents
WHERE [TFS_Alarm_Time] IS NOT NULL AND [TFS_Arrival_Time] IS NOT NULL;

-- Question: Is there correlation between higher dollar losses and longer times to control fires?
-- Purpose: Quantify whether faster control reduces economic impact.
WITH base AS (
    SELECT 
        CAST([Estimated_Dollar_Loss] AS FLOAT) AS Loss,
        DATEDIFF(MINUTE, CONVERT(datetime,[TFS_Alarm_Time]), CONVERT(datetime,[Fire_Under_Control_Time])) AS Minutes_To_Control
    FROM FireIncidents
    WHERE [Estimated_Dollar_Loss] IS NOT NULL 
      AND [TFS_Alarm_Time] IS NOT NULL 
      AND [Fire_Under_Control_Time] IS NOT NULL
)
SELECT 
    COUNT(*) AS N,
    CORR(Loss, Minutes_To_Control) AS Correlation_Coefficient
FROM base;


-- Question: In what percentage of incidents was a smoke alarm present?
-- Purpose: Evaluate the adoption of smoke alarms and their potential protective impact
SELECT 
    COUNT(*) AS Total_Incidents,
    SUM(CASE WHEN [Smoke_Alarm_at_Fire_Origin] LIKE '%present%' THEN 1 ELSE 0 END) AS With_Smoke_Alarm,
    100.0 * SUM(CASE WHEN [Smoke_Alarm_at_Fire_Origin] LIKE '%present%' THEN 1 ELSE 0 END) / COUNT(*) AS Percent_With_Smoke_Alarm
FROM FireIncidents;

-- Question: Which wards report the highest number of incidents?
-- Purpose: Map spatial distribution of incidents for resource allocation
SELECT TOP 10
    [Incident_Ward],
    COUNT(*) AS Incidents
FROM FireIncidents
GROUP BY [Incident_Ward]
ORDER BY Incidents DESC;

-- Question: Do incidents where sprinklers operated have lower average losses?
-- Purpose: Measure the effectiveness of sprinkler systems in reducing economic damage
SELECT 
    [Sprinkler_System_Operation],
    AVG(CAST([Estimated_Dollar_Loss] AS FLOAT)) AS Avg_Estimated_Loss,
    COUNT(*) AS Incidents
FROM FireIncidents
WHERE [Estimated_Dollar_Loss] IS NOT NULL
GROUP BY [Sprinkler_System_Operation]
ORDER BY Avg_Estimated_Loss;















