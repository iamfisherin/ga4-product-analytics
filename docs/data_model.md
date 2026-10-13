# Data Model

## Source and observation window
Source: bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*
Window: 2020-11-01 through 2021-01-31.

## Tables
| Table | Grain | Key | Validated rows |
|---|---|---|---:|
| stg_events | One source event | event_key | 4295584 |
| mart_sessions | One observed session | session_key | 360129 |
| mart_orders | One identifiable order proxy | order_key | 4466 |
| mart_users | One anonymous user identifier | user_pseudo_id | 270154 |

## Build order
Run these files in BigQuery in sequence:
1. sql/models/00_create_dataset.sql
2. sql/models/01_stg_events.sql
3. sql/models/02_mart_sessions.sql
4. sql/models/03_mart_orders.sql
5. sql/models/04_mart_users.sql

Then run sql/checks/01_model_validation.sql.

## Relationships
- stg_events to mart_sessions: many-to-one on session_key.
- mart_orders to mart_sessions: many-to-one on session_key.
- mart_sessions to mart_users: many-to-one on user_pseudo_id.
- mart_orders to mart_users: many-to-one on user_pseudo_id.
- Session and order measures are aggregated separately before the user-level join.

## Validated totals
- Events: 4,295,584
- Sessions: 360,129
- Anonymous user identifiers: 270,154
- Purchasing user identifiers: 4,419
- Purchasing sessions: 4,848
- Purchase events: 5,692
- Identifiable order proxies: 4,466
- Identifiable order revenue: USD 308,830
- Raw purchase-event revenue: USD 362,165
- Duplicate event, session, order, and user keys: 0

## Definitions and limitations
- Session key: (user_pseudo_id, ga_session_id).
- Order proxy key: (user_pseudo_id, transaction_id), excluding known unusable IDs.
- Order representative: earliest purchase event within the order proxy.
- Item payload variation is flagged; representative_items is not a verified basket.
- First observed date is window-relative, not a registration date.
- Observed session span is not active engagement time.
- Event-presence flags do not establish an ordered funnel.
- first_user_source/medium/campaign describe first-user acquisition, not session attribution.
- Identifiable order revenue excludes unresolved-ID purchases and does not deduct refunds.

## BigQuery Sandbox storage
Historical event-date partitioning produced an empty staging table.
Removing date partitioning and rebuilding restored all expected records.
Models use unpartitioned tables with clustering where configured.
Sandbox resources have expiration limits; SQL files allow reconstruction.

## Analysis status
Data audit and initial analysis tables are complete.
Ordered funnel, retention, channel analysis, experimentation, and dashboard work remain.
