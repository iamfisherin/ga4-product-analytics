-- One row per observed session.
-- Presence flags do not establish an ordered funnel.
-- Observed time span is not active engagement time.

CREATE OR REPLACE TABLE
  `ga4-product-analytics-511413.analytics.mart_sessions`
CLUSTER BY user_pseudo_id, device_category, country
OPTIONS (
  description = 'One row per observed session; event-presence flags are not an ordered funnel'
)
AS

WITH grouped_sessions AS (
  SELECT
    session_key,
    user_pseudo_id,
    ga_session_id,

    MIN(event_date) AS session_observed_date,
    COUNT(DISTINCT event_date) AS observed_date_count,
    MIN(event_timestamp_utc) AS first_observed_at,
    MAX(event_timestamp_utc) AS last_observed_at,
    (
      MAX(event_timestamp_micros) - MIN(event_timestamp_micros)
    ) / 1000000.0 AS observed_span_seconds,

    COUNT(*) AS event_count,
    COUNTIF(event_name = 'session_start') AS session_start_count,
    COUNTIF(event_name = 'page_view') AS page_view_count,
    COUNTIF(event_name = 'view_item') AS view_item_count,
    COUNTIF(event_name = 'add_to_cart') AS add_to_cart_count,
    COUNTIF(event_name = 'begin_checkout') AS begin_checkout_count,
    COUNTIF(event_name = 'purchase') AS purchase_event_count,

    ARRAY_AGG(
      STRUCT(
        device_category AS device_category,
        country AS country,
        region AS region,
        city AS city,
        first_user_source AS first_user_source,
        first_user_medium AS first_user_medium,
        first_user_campaign AS first_user_campaign
      )
      ORDER BY event_timestamp_micros, event_key
      LIMIT 1
    )[OFFSET(0)] AS first_event_dimensions

  FROM
    `ga4-product-analytics-511413.analytics.stg_events`
  GROUP BY
    session_key,
    user_pseudo_id,
    ga_session_id
)

SELECT
  * EXCEPT(first_event_dimensions),
  first_event_dimensions.*,

  CASE
    WHEN session_start_count = 0 THEN 'no_start'
    WHEN session_start_count = 1 THEN 'one_start'
    ELSE 'multiple_starts'
  END AS start_status,

  observed_date_count > 1 AS spans_dates,
  session_start_count > 0 AS has_session_start,
  view_item_count > 0 AS has_view_item,
  add_to_cart_count > 0 AS has_add_to_cart,
  begin_checkout_count > 0 AS has_begin_checkout,
  purchase_event_count > 0 AS has_purchase

FROM
  grouped_sessions;
