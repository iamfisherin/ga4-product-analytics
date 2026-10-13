WITH classified_sessions AS (
  SELECT *, CASE
    WHEN first_user_source IS NULL OR TRIM(first_user_source) = ''
      OR first_user_medium IS NULL OR TRIM(first_user_medium) = ''
      OR LOWER(TRIM(first_user_source)) IN ('<other>', '(data deleted)', '(not set)')
      OR LOWER(TRIM(first_user_medium)) IN ('<other>', '(data deleted)', '(not set)')
      THEN '1_unknown_or_obfuscated'
    WHEN LOWER(TRIM(first_user_source)) = 'shop.googlemerchandisestore.com'
      THEN '2_store_domain_source'
    ELSE '3_other_named_sources'
  END AS acquisition_quality_group
  FROM `ga4-product-analytics-511413.analytics.mart_session_funnel`
)
SELECT acquisition_quality_group, COUNT(*) AS started_sessions,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_started_sessions,
  COUNTIF(completed_strict_funnel) AS strict_purchase_sessions,
  COUNTIF(has_any_purchase) AS any_purchase_sessions,
  ROUND(100.0 * SAFE_DIVIDE(COUNTIF(completed_strict_funnel), COUNT(*)), 2) AS strict_funnel_completion_pct,
  ROUND(100.0 * SAFE_DIVIDE(COUNTIF(has_any_purchase), COUNT(*)), 2) AS purchase_presence_pct
FROM classified_sessions
GROUP BY acquisition_quality_group ORDER BY acquisition_quality_group;
