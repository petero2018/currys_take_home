--Count the number of sessions per taxi ID (We assume that a new session starts
--if at least 8 hours have passed since the previous trip).


--We need to compare each trip with the trip before it to detect whether enough time has passed to start a new session

WITH ordered AS (
  SELECT
    taxi_id,
    trip_start_timestamp,
    -- Look at the previous trip for this taxi
    LAG(trip_start_timestamp) OVER (
      PARTITION BY taxi_id
      ORDER BY trip_start_timestamp
    ) AS prev_trip_start
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
),

/*
It looks at the gap between trip_start_timestamp and prev_trip_start:
	•	If prev_trip_start is NULL → first trip for taxi → new session
	•	If gap ≥ 8 hours → new session
	•	Otherwise → same session
*/

session_flags AS (
  SELECT
    taxi_id,
    trip_start_timestamp,
    -- Start a new session if it's the first trip OR >8 hours since previous
    CASE
      WHEN prev_trip_start IS NULL THEN 1
      WHEN TIMESTAMP_DIFF(trip_start_timestamp, prev_trip_start, HOUR) >= 8 THEN 1
      ELSE 0
    END AS new_session
  FROM ordered
)

-- This counts only the rows flagged as session beginnings
SELECT
  taxi_id,
  COUNTIF(new_session = 1) AS session_count
FROM session_flags
GROUP BY taxi_id
ORDER BY session_count DESC;