# Initial GA4 Data Audit

## Scope
- Source: bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*
- Table suffix filter: 20201101 to 20210131
- Observed event dates: 2020-11-01 to 2021-01-31
- Observed days: 92
- Event rows: 4,295,584
- Distinct user_pseudo_id values: 270,154
- Events with null or blank user_pseudo_id: 0
- Anonymous identifiers do not necessarily represent unique people.

## Session identifier checks
- Every event contains exactly one ga_session_id parameter.
- Every ga_session_id parameter has a non-null integer value.
- Session grouping key: (user_pseudo_id, ga_session_id).
- Observed sessions: 360,129
- Distinct ga_session_id values: 349,545
- Events after session aggregation: 4,295,584
- Sessions with nonpositive ga_session_id: 0
- Sessions spanning event dates: 845

## Session start quality
| Start status | Sessions | Event rows | Purchasing sessions | Purchase events |
|---|---:|---:|---:|---:|
| Exactly one start | 354752 | 4225409 | 4744 | 5577 |
| No start | 5272 | 68982 | 103 | 113 |
| Multiple starts | 105 | 1193 | 1 | 2 |

## Initial modeling decisions
- Retain all observed sessions and flag session_start quality.
- Do not include event_date in the session grouping key.
- Do not automatically remove sessions spanning dates.
- Removing sessions without exactly one start would remove 115 purchase events.
- Define funnel entry and event ordering explicitly before calculating conversion.
- Do not assume purchase events are unique orders.

## Limitations and pending checks
- The source is an obfuscated sample with potentially limited internal consistency.
- Missing session_start causes have not been established.
- Session counts describe sessions observed within the selected data window.
- Event duplication, timestamp ordering, transactions, and revenue require further auditing.
