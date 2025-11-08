---Who are the top 100 “tip earners”, the taxi IDs that earn more money than others
--for the last 3 months.

SELECT
  taxi_id,
  SUM(tips) AS total_tips
FROM
  `bigquery-public-data.chicago_taxi_trips.taxi_trips` 
WHERE
  trip_start_timestamp >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH)) -- max trip_start_timestamp  2023-12-31 23:45:00 UTC
GROUP BY
  taxi_id
ORDER BY
  total_tips DESC
LIMIT 100;