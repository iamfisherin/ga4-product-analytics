-- Item-ID-level concentration, not product-family concentration.
WITH product_revenue AS (
  SELECT
    TRIM(i.item_id) AS item_id,
    SUM(i.item_revenue_in_usd) AS item_revenue_usd
  FROM `ga4-product-analytics-511413.analytics.mart_orders` AS o
  CROSS JOIN UNNEST(o.representative_items) AS i
  GROUP BY item_id
),
ranked AS (
  SELECT *,
    ROW_NUMBER() OVER (
      ORDER BY item_revenue_usd DESC, item_id
    ) AS revenue_rank,
    SUM(item_revenue_usd) OVER () AS total_item_revenue_usd,
    SUM(item_revenue_usd) OVER (
      ORDER BY item_revenue_usd DESC, item_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue_usd
  FROM product_revenue
)
SELECT
  COUNT(*) AS distinct_item_ids,
  COUNTIF(item_revenue_usd = 0) AS zero_revenue_item_ids,
  COUNTIF(item_revenue_usd < 0) AS negative_revenue_item_ids,
  ROUND(MAX(total_item_revenue_usd), 2) AS total_recorded_item_revenue_usd,
  ROUND(100.0 * SAFE_DIVIDE(
    SUM(IF(revenue_rank <= 10, item_revenue_usd, 0)),
    MAX(total_item_revenue_usd)), 2) AS top10_revenue_share_pct,
  ROUND(100.0 * SAFE_DIVIDE(
    SUM(IF(revenue_rank <= 20, item_revenue_usd, 0)),
    MAX(total_item_revenue_usd)), 2) AS top20_revenue_share_pct,
  ROUND(100.0 * SAFE_DIVIDE(
    SUM(IF(revenue_rank <= 50, item_revenue_usd, 0)),
    MAX(total_item_revenue_usd)), 2) AS top50_revenue_share_pct,
  ROUND(100.0 * SAFE_DIVIDE(
    SUM(IF(revenue_rank <= 100, item_revenue_usd, 0)),
    MAX(total_item_revenue_usd)), 2) AS top100_revenue_share_pct,
  MIN(IF(
    cumulative_revenue_usd >= 0.50 * total_item_revenue_usd,
    revenue_rank, NULL
  )) AS item_ids_to_reach_50pct,
  MIN(IF(
    cumulative_revenue_usd >= 0.80 * total_item_revenue_usd,
    revenue_rank, NULL
  )) AS item_ids_to_reach_80pct
FROM ranked;
