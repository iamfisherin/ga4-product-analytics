-- Representative-list revenue, not verified basket or net revenue.
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
, name_counts AS (
  SELECT item_id, item_name, COUNT(*) AS name_rows
  FROM item_rows
  GROUP BY item_id, item_name
),
display_names AS (
  SELECT item_id, item_name AS display_item_name
  FROM name_counts
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY item_id
    ORDER BY name_rows DESC, item_name
  ) = 1
),
product_totals AS (
  SELECT
    item_id,
    COUNT(*) AS representative_item_rows,
    COUNT(DISTINCT order_key) AS identifiable_orders_with_item,
    COUNT(DISTINCT user_pseudo_id) AS purchasing_user_ids,
    COUNT(DISTINCT item_name) AS distinct_item_names,
    SUM(item_revenue_usd) AS recorded_item_revenue_usd
  FROM item_rows
  GROUP BY item_id
),
ranked AS (
  SELECT *,
    ROW_NUMBER() OVER (
      ORDER BY recorded_item_revenue_usd DESC, item_id
    ) AS revenue_rank,
    SUM(recorded_item_revenue_usd) OVER () AS all_item_revenue_usd,
    SUM(recorded_item_revenue_usd) OVER (
      ORDER BY recorded_item_revenue_usd DESC, item_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_item_revenue_usd
  FROM product_totals
)
SELECT
  r.revenue_rank,
  r.item_id,
  n.display_item_name,
  r.distinct_item_names,
  r.representative_item_rows,
  r.identifiable_orders_with_item,
  r.purchasing_user_ids,
  ROUND(r.recorded_item_revenue_usd, 2) AS recorded_item_revenue_usd,
  ROUND(
    100.0 * SAFE_DIVIDE(r.recorded_item_revenue_usd, r.all_item_revenue_usd), 2
  ) AS item_revenue_share_pct,
  ROUND(
    100.0 * SAFE_DIVIDE(r.cumulative_item_revenue_usd, r.all_item_revenue_usd), 2
  ) AS cumulative_revenue_share_pct
FROM ranked AS r
LEFT JOIN display_names AS n USING (item_id)
WHERE r.revenue_rank <= 20
ORDER BY r.revenue_rank;
