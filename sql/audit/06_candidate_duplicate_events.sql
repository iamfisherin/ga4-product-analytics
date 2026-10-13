-- Candidate duplicate check using a limited event key.
-- Matching keys alone would not establish true event duplication.

WITH events AS (
  SELECT
    user_pseudo_id,
    event_name,
    event_timestamp,
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

event_groups AS (
  SELECT
    user_pseudo_id,
    ga_session_id,
    event_name,
    event_timestamp,
    COUNT(*) AS rows_in_group
  FROM
    events
  GROUP BY
    user_pseudo_id,
    ga_session_id,
    event_name,
    event_timestamp
)

SELECT
  event_name,
  SUM(rows_in_group) AS event_count,
  COUNTIF(rows_in_group > 1) AS candidate_duplicate_groups,
  SUM(rows_in_group - 1) AS candidate_extra_rows,
  MAX(rows_in_group) AS max_rows_per_group,
  SUM(
    IF(event_timestamp IS NULL, rows_in_group, 0)
  ) AS missing_timestamp_events
FROM
  event_groups
GROUP BY
  event_name
ORDER BY
  event_count DESC;
