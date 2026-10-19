WITH item_rows AS (
  SELECT
    o.order_key,
    o.user_pseudo_id,
    TRIM(i.item_id) AS item_id,
    TRIM(i.item_name) AS item_name,
    i.item_revenue_in_usd AS item_revenue_usd
  FROM `ga4-product-analytics-511413.analytics.mart_orders` AS o
  CROSS JOIN UNNEST(o.representative_items) AS i
)
, cleaned AS (
  SELECT *,
    CASE
      WHEN item_id IS NULL OR item_id = ''
        OR LOWER(item_id) IN ('(not set)', '<other>')
      THEN NULL ELSE item_id
    END AS usable_item_id,
    CASE
      WHEN item_name IS NULL OR item_name = ''
        OR LOWER(item_name) IN ('(not set)', '<other>')
      THEN NULL ELSE item_name
    END AS usable_item_name
  FROM item_rows
),
id_names AS (
  SELECT
    usable_item_id,
    COUNT(DISTINCT usable_item_name) AS distinct_usable_names
  FROM cleaned
  WHERE usable_item_id IS NOT NULL
  GROUP BY usable_item_id
)
SELECT
  COUNT(*) AS representative_item_rows,
  COUNT(DISTINCT order_key) AS identifiable_orders,
  COUNTIF(usable_item_id IS NULL) AS unusable_item_id_rows,
  COUNT(DISTINCT IF(usable_item_id IS NULL, order_key, NULL))
    AS orders_with_unusable_item_ids,
  ROUND(SUM(IF(usable_item_id IS NULL, item_revenue_usd, 0)), 2)
    AS revenue_with_unusable_item_ids_usd,
  COUNTIF(usable_item_name IS NULL) AS unusable_item_name_rows,
  COUNT(DISTINCT usable_item_id) AS distinct_usable_item_ids,
  (SELECT COUNTIF(distinct_usable_names > 1) FROM id_names)
    AS item_ids_with_multiple_names,
  (SELECT COUNTIF(distinct_usable_names = 0) FROM id_names)
    AS item_ids_without_usable_names,
  ROUND(SUM(item_revenue_usd), 2) AS total_recorded_item_revenue_usd
FROM cleaned;
