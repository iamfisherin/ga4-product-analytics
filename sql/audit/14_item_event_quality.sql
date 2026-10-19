-- Event-level audit: correlated subqueries avoid multiplying event counts.
-- Quantity > 0 is an observed-data condition, not a universal validity rule.
WITH event_quality AS (
  SELECT
    event_name,
    COALESCE(ARRAY_LENGTH(items), 0) AS item_rows,
    (
      SELECT AS STRUCT
        COUNTIF(
          i.item_id IS NULL OR TRIM(i.item_id) = ''
          OR LOWER(TRIM(i.item_id)) IN ('(not set)', '<other>')
        ) AS unusable_id_rows,
        COUNTIF(
          i.item_name IS NULL OR TRIM(i.item_name) = ''
          OR LOWER(TRIM(i.item_name)) IN ('(not set)', '<other>')
        ) AS unusable_name_rows,
        COUNTIF(i.quantity IS NULL) AS null_quantity_rows,
        COUNTIF(i.quantity = 0) AS zero_quantity_rows,
        COUNTIF(i.quantity < 0) AS negative_quantity_rows,
        COUNTIF(i.quantity > 0) AS positive_quantity_rows,
        COUNTIF(
          i.quantity > 0
          AND i.item_id IS NOT NULL
          AND TRIM(i.item_id) != ''
          AND LOWER(TRIM(i.item_id)) NOT IN ('(not set)', '<other>')
        ) AS positive_usable_rows,
        COUNT(DISTINCT IF(
          i.item_id IS NOT NULL
          AND TRIM(i.item_id) != ''
          AND LOWER(TRIM(i.item_id)) NOT IN ('(not set)', '<other>'),
          TRIM(i.item_id), NULL
        )) AS distinct_usable_ids
      FROM UNNEST(items) AS i
    ) AS q
  FROM `ga4-product-analytics-511413.analytics.stg_events`
  WHERE event_name IN (
    'view_item', 'add_to_cart', 'begin_checkout', 'purchase'
  )
)
SELECT
  event_name,
  COUNT(*) AS event_count,
  COUNTIF(item_rows > 0) AS events_with_items,
  COUNTIF(item_rows = 0) AS events_without_items,
  ROUND(
    100.0 * SAFE_DIVIDE(COUNTIF(item_rows > 0), COUNT(*)), 2
  ) AS item_coverage_pct,
  SUM(item_rows) AS total_item_rows,
  SUM(q.unusable_id_rows) AS unusable_item_id_rows,
  SUM(q.unusable_name_rows) AS unusable_item_name_rows,
  ROUND(AVG(IF(item_rows > 0, item_rows, NULL)), 2)
    AS avg_item_rows_when_present,
  MAX(item_rows) AS max_item_rows,
  COUNTIF(q.distinct_usable_ids > 1) AS events_with_multiple_usable_ids,
  COUNTIF(item_rows - q.unusable_id_rows > q.distinct_usable_ids)
    AS events_with_repeated_item_ids,
  SUM(item_rows - q.unusable_id_rows - q.distinct_usable_ids)
    AS extra_rows_with_repeated_ids,
  SUM(q.null_quantity_rows) AS null_quantity_rows,
  SUM(q.zero_quantity_rows) AS zero_quantity_rows,
  SUM(q.negative_quantity_rows) AS negative_quantity_rows,
  SUM(q.positive_quantity_rows) AS positive_quantity_rows,
  COUNTIF(q.positive_quantity_rows = 0)
    AS events_without_positive_quantity,
  COUNTIF(q.positive_quantity_rows = 1)
    AS events_with_one_positive_quantity_row,
  COUNTIF(q.positive_quantity_rows > 1)
    AS events_with_multiple_positive_quantity_rows,
  COUNTIF(q.positive_usable_rows > 0)
    AS events_with_positive_quantity_and_usable_id,
  ROUND(
    100.0 * SAFE_DIVIDE(COUNTIF(q.positive_usable_rows > 0), COUNT(*)), 2
  ) AS positive_quantity_usable_id_coverage_pct
FROM event_quality
GROUP BY event_name
ORDER BY CASE event_name
  WHEN 'view_item' THEN 1
  WHEN 'add_to_cart' THEN 2
  WHEN 'begin_checkout' THEN 3
  WHEN 'purchase' THEN 4
END;
