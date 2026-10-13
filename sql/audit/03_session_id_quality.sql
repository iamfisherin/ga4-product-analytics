-- Audit ga_session_id parameter presence, integer values, and duplicate keys.
-- Correlated subqueries preserve one row per source event.

WITH session_id_audit AS (
  SELECT
    event_name,
    (
      SELECT COUNT(*)
      FROM UNNEST(event_params) AS param
      WHERE param.key = 'ga_session_id'
    ) AS session_id_param_count,
    (
      SELECT COUNTIF(param.value.int_value IS NOT NULL)
      FROM UNNEST(event_params) AS param
      WHERE param.key = 'ga_session_id'
    ) AS integer_session_id_count
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
)

SELECT
  event_name,
  COUNT(*) AS event_count,
  COUNTIF(session_id_param_count = 0) AS missing_session_id_events,
  COUNTIF(
    session_id_param_count > 0
    AND integer_session_id_count = 0
  ) AS no_integer_session_id_events,
  COUNTIF(session_id_param_count > 1) AS duplicate_session_id_param_events,
  ROUND(
    100.0 * COUNTIF(integer_session_id_count > 0) / COUNT(*),
    2
  ) AS integer_session_id_coverage_pct
FROM
  session_id_audit
GROUP BY
  event_name
ORDER BY
  event_count DESC;
