-- Diagnostic sample, not a random or representative sample.
WITH sampled_events AS (
  SELECT event_key, event_timestamp_utc, items
  FROM `ga4-product-analytics-511413.analytics.stg_events` AS e
  WHERE event_name = 'add_to_cart'
    AND (
      SELECT COUNT(DISTINCT TRIM(i.item_id))
      FROM UNNEST(e.items) AS i
      WHERE i.item_id IS NOT NULL
        AND TRIM(i.item_id) != ''
        AND LOWER(TRIM(i.item_id)) NOT IN ('(not set)', '<other>')
    ) > 1
  ORDER BY event_timestamp_micros, event_key
  LIMIT 5
)
SELECT
  e.event_key,
  e.event_timestamp_utc,
  item_offset + 1 AS item_position,
  i.item_id,
  i.item_name,
  i.item_variant,
  i.item_category,
  i.quantity,
  i.price_in_usd,
  i.item_revenue_in_usd
FROM sampled_events AS e
CROSS JOIN UNNEST(e.items) AS i WITH OFFSET AS item_offset
ORDER BY e.event_timestamp_utc, e.event_key, item_position;
