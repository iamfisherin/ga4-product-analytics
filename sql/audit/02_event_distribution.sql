-- Event frequencies and distinct anonymous user identifiers.
-- Event counts are not session funnel conversion rates.

SELECT
  event_name,
  COUNT(*) AS event_count,
  COUNT(DISTINCT user_pseudo_id) AS distinct_user_pseudo_ids,
  ROUND(
    100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
    2
  ) AS pct_of_all_events
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE
  _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY
  event_name
ORDER BY
  event_count DESC;
