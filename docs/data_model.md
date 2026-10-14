# Data Model

## Source and observation window
Source: bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*
Window: 2020-11-01 through 2021-01-31, inclusive (92 days).

## Tables
| Table | Grain | Key | Validated rows |
|---|---|---|---:|
| stg_events | One source event | event_key | 4295584 |
| mart_sessions | One observed session | session_key | 360129 |
| mart_orders | One identifiable order proxy | order_key | 4466 |
| mart_users | One anonymous user identifier | user_pseudo_id | 270154 |
| mart_session_funnel | One session with a session_start event | session_key | 354857 |
| mart_user_daily_activity | One user identifier per event date | user_pseudo_id, activity_date | 319066 |

## Build order
Run these files in BigQuery in sequence:
1. sql/models/00_create_dataset.sql
2. sql/models/01_stg_events.sql
3. sql/models/02_mart_sessions.sql
4. sql/models/03_mart_orders.sql
5. sql/models/04_mart_users.sql
6. sql/models/05_mart_session_funnel.sql
7. sql/models/06_mart_user_daily_activity.sql

Then run:
- sql/checks/01_model_validation.sql
- sql/checks/02_funnel_validation.sql
- sql/checks/03_daily_activity_validation.sql

Run analysis queries after their required models have been rebuilt.
Retention analyses 09-11 read mart_user_daily_activity.

## Relationships
- stg_events to mart_sessions: many-to-one on session_key.
- mart_orders to mart_sessions: many-to-one on session_key.
- mart_sessions to mart_users: many-to-one on user_pseudo_id.
- mart_orders to mart_users: many-to-one on user_pseudo_id.
- mart_session_funnel is a subset of sessions with a start event.
- mart_user_daily_activity to mart_users: many-to-one on user_pseudo_id.
- Session and order measures are aggregated separately before the user-level join.
- Daily activity is aggregated directly from stg_events by user and event_date.

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
- User-day rows: 319,066 across 92 dates
- Daily activity totals: 4,295,584 events and 5,692 purchases
- Daily activity audit: 0 invalid rows and 0 duplicate user-date groups

## Definitions and limitations
- Session key: (user_pseudo_id, ga_session_id).
- Order proxy key: (user_pseudo_id, transaction_id), excluding known unusable IDs.
- Order representative: earliest purchase event within the order proxy.
- Item payload variation is flagged; representative_items is not a verified basket.
- First observed date is window-relative, not a registration date.
- User counts refer to anonymous identifiers, not verified individual people.
- Observed session span is not active engagement time.
- Session date, device, and geography use the earliest observed event.
- Anomalous sessions are retained and flagged.
- Event-presence flags do not establish an ordered funnel.
- Strict funnel timestamps must increase (>); equal timestamps are excluded.
- The >= sensitivity analysis is separate from the strict funnel.
- Missing funnel steps are not automatically evidence of user abandonment.
- first_user_source/medium/campaign describe first-user acquisition, not session attribution.
- Identifiable order revenue excludes unresolved-ID purchases and does not deduct refunds.

## Daily activity and retention
- Activity means at least one event on an event_date.
- Fields: user_pseudo_id, activity_date, event_count,
  observed_session_count, purchase_event_count.
- Activity dates come from event_date, not the session's first date.
- Cross-midnight activity is therefore preserved on each event date.
- Daily session counts cannot be summed to obtain overall unique sessions.
- Cohort date is the earliest activity_date observed within this window.
- D1/D7/D14/D30 require activity on exactly cohort_date + N days.
- Only users whose target date falls within the window enter the denominator.
- Immature daily periods have NULL retained_users and retention_pct.
- A mature period with no returns has zero retention.
- Monthly rates use summed retained users divided by summed eligible users.
- Monthly results explicitly label full, partial, or absent maturity.
- Different horizons can have different eligible populations.

## BigQuery Sandbox storage
Historical event-date partitioning produced an empty staging table;
Sandbox partition expiration was the suspected cause.
Removing date partitioning and rebuilding restored all expected records.
Models use unpartitioned tables with clustering where configured.
Sandbox resources have expiration limits; SQL files allow reconstruction.
After rebuilding, validate the complete 92-day window before interpreting retention.

## Analysis status
Completed:
- Event, session, purchase, order, and item-consistency audits.
- Strict session funnel and equal-timestamp sensitivity analysis.
- Purchase presence and missing-step coverage analysis.
- Device, first-user acquisition quality, and country/revenue analysis.
- Daily activity model and exact-day overall/daily/monthly cohort retention.

Remaining:
- Product-level analysis, subject to item-payload limitations.
- Clearly labeled simulated experiments, randomization checks, and power/MDE planning.
- Streamlit dashboard, business report, README, and resume descriptions.

No real randomized experiment or causal product effect has been established.
