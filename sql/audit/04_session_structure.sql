-- Group sessions by (user_pseudo_id, ga_session_id).
-- Preserve sessions spanning dates and audit session_start counts.

WITH events AS (
  SELECT
    user_pseudo_id,
    event_date,
    event_name,
    (
      SELECT param.value.int_value
      FROM UNNEST(event_params) AS param
      WHERE param.key = 'ga_session_id'
    ) AS ga_session_id
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),

sessions AS (
  SELECT
    user_pseudo_id,
    ga_session_id,
    COUNT(*) AS event_count,
    COUNTIF(event_name = 'session_start') AS session_start_count,
    COUNT(DISTINCT event_date) AS active_dates
  FROM
    events
  GROUP BY
    user_pseudo_id,
    ga_session_id
)

SELECT
  COUNT(*) AS observed_sessions,
  COUNT(DISTINCT ga_session_id) AS distinct_session_id_values,
  SUM(event_count) AS total_events,
  COUNTIF(session_start_count = 0) AS sessions_without_start,
  COUNTIF(session_start_count = 1) AS sessions_with_one_start,
  COUNTIF(session_start_count > 1) AS sessions_with_multiple_starts,
  COUNTIF(active_dates > 1) AS sessions_spanning_dates,
  COUNTIF(ga_session_id <= 0) AS sessions_with_nonpositive_id
FROM
  sessions;
