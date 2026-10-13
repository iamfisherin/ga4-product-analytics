-- Build one row per source event.
-- Use an unpartitioned clustered table for historical data in Sandbox.
-- Purchase deduplication is performed separately in mart_orders.

CREATE OR REPLACE TABLE
  `ga4-product-analytics-511413.analytics.stg_events`
CLUSTER BY event_name, user_pseudo_id, ga_session_id
OPTIONS (
  description = 'GA4 event staging table; one row per source event; no purchase deduplication'
)
AS

WITH extracted_events AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS event_date,
    event_timestamp AS event_timestamp_micros,
    TIMESTAMP_MICROS(event_timestamp) AS event_timestamp_utc,
    event_name,
    user_pseudo_id,

    (
      SELECT param.value.int_value
      FROM UNNEST(event_params) AS param
      WHERE param.key = 'ga_session_id'
    ) AS ga_session_id,

    device.category AS device_category,
    geo.country AS country,
    geo.region AS region,
    geo.city AS city,

    -- First-user acquisition fields, not session attribution.
    traffic_source.source AS first_user_source,
    traffic_source.medium AS first_user_medium,
    traffic_source.name AS first_user_campaign,

    NULLIF(TRIM(ecommerce.transaction_id), '') AS transaction_id,
    ecommerce.purchase_revenue_in_usd AS purchase_revenue_usd,

    ecommerce,
    items,
    event_params

  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
)

SELECT
  *,
  TO_JSON_STRING(
    STRUCT(
      user_pseudo_id AS user_pseudo_id,
      ga_session_id AS ga_session_id
    )
  ) AS session_key,

  TO_HEX(
    SHA256(
      TO_JSON_STRING(
        STRUCT(
          user_pseudo_id AS user_pseudo_id,
          ga_session_id AS ga_session_id,
          event_name AS event_name,
          event_timestamp_micros AS event_timestamp_micros
        )
      )
    )
  ) AS event_key

FROM
  extracted_events;
