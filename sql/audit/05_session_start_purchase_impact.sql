-- Assess purchase activity by session_start quality.
-- Window-start observations do not establish the cause of missing starts.

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
    COUNTIF(event_name = 'purchase') AS purchase_event_count,
    MIN(event_date) AS first_observed_date,
    COUNT(DISTINCT event_date) AS active_dates
  FROM
    events
  GROUP BY
    user_pseudo_id,
    ga_session_id
),

classified_sessions AS (
  SELECT
    *,
    CASE
      WHEN session_start_count = 0 THEN 'no_start'
      WHEN session_start_count = 1 THEN 'one_start'
      ELSE 'multiple_starts'
    END AS start_status
  FROM
    sessions
)

SELECT
  start_status,
  COUNT(*) AS session_count,
  SUM(event_count) AS event_count,
  COUNTIF(purchase_event_count > 0) AS purchasing_sessions,
  SUM(purchase_event_count) AS purchase_events,
  COUNTIF(
    first_observed_date = '20201101'
  ) AS sessions_first_observed_on_window_start,
  COUNTIF(active_dates > 1) AS sessions_spanning_dates
FROM
  classified_sessions
GROUP BY
  start_status
ORDER BY
  session_count DESC;
