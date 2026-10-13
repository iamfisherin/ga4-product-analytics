-- Initial data overview: event counts, date coverage, and user ID completeness.
-- Counts describe the selected observation window.

SELECT
  MIN(event_date) AS first_event_date,
  MAX(event_date) AS last_event_date,
  COUNT(DISTINCT event_date) AS observed_days,
  COUNT(*) AS event_count,
  COUNT(DISTINCT user_pseudo_id) AS distinct_user_pseudo_ids,
  COUNTIF(
    user_pseudo_id IS NULL OR TRIM(user_pseudo_id) = ''
  ) AS missing_user_id_events
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE
  _TABLE_SUFFIX BETWEEN '20201101' AND '20210131';
