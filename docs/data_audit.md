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

## Purchase and transaction audit
- Purchase events: 5,692
- Events with blank or null transaction_id: 23
- Events with known placeholder transaction_id: 883
- Events with missing purchase revenue: 0
- Events with zero purchase revenue: 450
- Events with negative purchase revenue: 0
- Purchase events without items: 2
- No duplicate groups under (user_pseudo_id, ga_session_id, event_name, event_timestamp).
- No missing event timestamps.

## Candidate order key validation
- Usable-ID purchase events: 4,786
- Distinct usable transaction_id values: 4,451
- Fifteen transaction IDs span users and have different revenues.
- Adopt (user_pseudo_id, transaction_id) as the sample-specific order proxy.
- Distinct user-transaction pairs: 4,466
- Repeated pairs: 314; additional purchase events: 320
- Every pair has consistent ecommerce content and stays within one date and session.
- Item payloads differ in 287 repeated pairs.
- Item row counts, total quantities, and item revenue sums are consistent within repeated pairs.
- Sixty-two repeated pairs contain an item-total versus transaction-revenue mismatch.
- These checks do not establish the cause of repeated purchase reporting.

## Revenue reconciliation (USD)
| Scope | Counting unit | Count | Source purchase events | Revenue |
|---|---|---:|---:|---:|
| Identifiable orders, deduplicated | User-transaction pair | 4466 | 4786 | 308830 |
| Missing transaction ID, raw | Purchase event | 23 | 23 | 1328 |
| Placeholder transaction ID, raw | Purchase event | 883 | 883 | 30489 |
| All purchases, raw baseline | Purchase event | 5692 | 5692 | 362165 |

## Reporting rules
- Use identifiable order count and deduplicated identifiable purchase revenue as primary order metrics.
- Report unresolved-ID event counts and raw revenue separately.
- Retain all purchase events for user/session purchase-presence flags.
- Do not blindly sum item revenue across repeated purchase events.
- Do not describe these sample metrics as verified real-world sales.
- Purchase revenue here does not deduct refunds and is not net revenue.
