-- Compare repeated purchase payloads under the candidate order key.
-- JSON comparisons are sensitive to item array ordering.

WITH purchases AS (
  SELECT
    user_pseudo_id,
    event_timestamp,
    NULLIF(TRIM(ecommerce.transaction_id), '') AS transaction_id,
    TO_JSON_STRING(items) AS items_json,
    TO_JSON_STRING(ecommerce) AS ecommerce_json
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
),

repeated_pairs AS (
  SELECT
    user_pseudo_id,
    transaction_id,
    COUNT(*) AS purchase_event_count,
    COUNT(DISTINCT items_json) AS item_payload_versions,
    COUNT(DISTINCT ecommerce_json) AS ecommerce_payload_versions,
    (
      MAX(event_timestamp) - MIN(event_timestamp)
    ) / 1000000.0 AS timestamp_span_seconds
  FROM
    purchases
  WHERE
    transaction_id IS NOT NULL
    AND LOWER(transaction_id) NOT IN ('(not set)', '<other>')
  GROUP BY
    user_pseudo_id,
    transaction_id
  HAVING
    COUNT(*) > 1
)

SELECT
  COUNT(*) AS repeated_pairs,
  SUM(purchase_event_count - 1) AS extra_purchase_events,
  COUNTIF(item_payload_versions > 1) AS pairs_with_different_items,
  COUNTIF(
    ecommerce_payload_versions > 1
  ) AS pairs_with_different_ecommerce,
  ROUND(MIN(timestamp_span_seconds), 3) AS min_span_seconds,
  ROUND(AVG(timestamp_span_seconds), 3) AS avg_span_seconds,
  ROUND(MAX(timestamp_span_seconds), 3) AS max_span_seconds
FROM
  repeated_pairs;
