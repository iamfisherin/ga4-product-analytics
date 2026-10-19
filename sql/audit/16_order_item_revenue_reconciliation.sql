-- Statement 1: completeness and reconciliation.
WITH order_item_audit AS (
  SELECT
    o.order_key,
    o.order_revenue_usd,
    COALESCE(ARRAY_LENGTH(o.representative_items), 0) AS item_rows,
    (
      SELECT COUNTIF(i.item_revenue_in_usd IS NULL)
      FROM UNNEST(o.representative_items) AS i
    ) AS missing_revenue_rows,
    (
      SELECT SUM(i.item_revenue_in_usd)
      FROM UNNEST(o.representative_items) AS i
    ) AS item_revenue_sum_usd
  FROM `ga4-product-analytics-511413.analytics.mart_orders` AS o
)
, classified AS (
  SELECT *,
    CASE
      WHEN item_rows = 0 THEN '1_no_items'
      WHEN missing_revenue_rows = item_rows
        THEN '2_all_item_revenue_missing'
      WHEN missing_revenue_rows > 0
        THEN '3_partial_item_revenue_missing'
      WHEN order_revenue_usd IS NULL THEN '4_order_revenue_missing'
      WHEN ABS(item_revenue_sum_usd - order_revenue_usd) <= 0.01
        THEN '5_reconciled'
      ELSE '6_revenue_mismatch'
    END AS reconciliation_status
  FROM order_item_audit
)
SELECT
  reconciliation_status,
  COUNT(*) AS identifiable_orders,
  SUM(item_rows) AS representative_item_rows,
  SUM(missing_revenue_rows) AS missing_item_revenue_rows,
  ROUND(SUM(order_revenue_usd), 2) AS order_revenue_usd,
  ROUND(SUM(item_revenue_sum_usd), 2) AS recorded_item_revenue_usd
FROM classified
GROUP BY reconciliation_status
ORDER BY reconciliation_status;

-- Statement 2: difference = item minus order revenue.
WITH order_item_audit AS (
  SELECT
    o.order_key,
    o.order_revenue_usd,
    COALESCE(ARRAY_LENGTH(o.representative_items), 0) AS item_rows,
    (
      SELECT COUNTIF(i.item_revenue_in_usd IS NULL)
      FROM UNNEST(o.representative_items) AS i
    ) AS missing_revenue_rows,
    (
      SELECT SUM(i.item_revenue_in_usd)
      FROM UNNEST(o.representative_items) AS i
    ) AS item_revenue_sum_usd
  FROM `ga4-product-analytics-511413.analytics.mart_orders` AS o
)
, differences AS (
  SELECT *,
    item_revenue_sum_usd - order_revenue_usd AS difference_usd
  FROM order_item_audit
),
classified AS (
  SELECT *,
    CASE
      WHEN difference_usd IS NULL THEN '0_missing'
      WHEN ABS(difference_usd) <= 0.01 THEN '1_within_0.01'
      WHEN ABS(difference_usd) <= 1 THEN '2_over_0.01_to_1'
      WHEN ABS(difference_usd) <= 5 THEN '3_over_1_to_5'
      WHEN ABS(difference_usd) <= 20 THEN '4_over_5_to_20'
      ELSE '5_over_20'
    END AS absolute_difference_band
  FROM differences
)
SELECT
  absolute_difference_band,
  COUNT(*) AS identifiable_orders,
  COUNTIF(difference_usd > 0.01) AS item_revenue_higher_orders,
  COUNTIF(difference_usd < -0.01) AS item_revenue_lower_orders,
  ROUND(SUM(order_revenue_usd), 2) AS order_revenue_usd,
  ROUND(SUM(item_revenue_sum_usd), 2) AS item_revenue_usd,
  ROUND(SUM(difference_usd), 2) AS net_difference_usd,
  ROUND(SUM(ABS(difference_usd)), 2) AS total_absolute_difference_usd,
  ROUND(MAX(ABS(difference_usd)), 2) AS max_absolute_difference_usd
FROM classified
GROUP BY absolute_difference_band
ORDER BY absolute_difference_band;
