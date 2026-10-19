# Product Data Quality and Recorded Revenue

## Scope
Window: 2020-11-01 through 2021-01-31.
Event audits use stg_events, including all purchase events.
Revenue analysis uses representative_items from 4466 identifiable order proxies.
These lists are not verified shopping baskets.

## Event coverage
| Event | Events | Events with items | Coverage (%) | Item rows | Unusable ID/name rows |
|---|---:|---:|---:|---:|---:|
| view_item | 386068 | 241876 | 62.65 | 2748246 | 9 / 9 |
| add_to_cart | 58543 | 58543 | 100.00 | 667426 | 144 / 144 |
| begin_checkout | 38757 | 31991 | 82.54 | 77980 | 1933 / 1933 |
| purchase | 5692 | 5690 | 99.96 | 16003 | 448 / 448 |

Events without item lists and unusable IDs inside lists are separate issues.

## Multiplicity
| Event | Mean rows when present | Maximum rows | Events with repeated usable IDs | Extra same-ID rows |
|---|---:|---:|---:|---:|
| view_item | 11.36 | 12 | 92613 | 92613 |
| add_to_cart | 11.40 | 12 | 3 | 3 |
| begin_checkout | 2.44 | 31 | 54 | 305 |
| purchase | 2.81 | 30 | 8 | 46 |

Repeated IDs are not automatically errors. Item rows are not units sold.

## Quantity coverage
| Event | Null quantity rows | Zero quantity rows | Negative quantity rows | Positive quantity rows | Events with positive quantity and usable ID | Event coverage (%) |
|---|---:|---:|---:|---:|---:|---:|
| view_item | 2729121 | 0 | 0 | 19125 | 19125 | 4.95 |
| add_to_cart | 630166 | 2 | 1 | 37257 | 37257 | 63.64 |
| begin_checkout | 1933 | 0 | 0 | 76047 | 30058 | 77.56 |
| purchase | 448 | 0 | 0 | 15555 | 5242 | 92.09 |

Every view/add event with positive quantity has exactly one such row.
The diagnostic add-to-cart sample contains multiple different products,
often with quantity recorded for only one row; one sampled event has no quantities.
A sampled name also appears under two different IDs.
These samples do not establish the underlying collection mechanism.

Decision: do not replace missing quantity with 1 or treat every array row as
an actual product interaction. Do not build a cross-event product conversion
funnel in v1. Retain zero and negative quantity observations in the audit.

## Order-to-item revenue reconciliation
All 4466 representative lists contain item revenue with no missing values.
They contain 13274 item rows.

| Status | Orders | Item rows | Order revenue USD | Recorded item revenue USD |
|---|---:|---:|---:|---:|
| Exact agreement | 3630 | 8722 | 226758 | 226758 |
| Mismatch | 836 | 4552 | 82072 | 81993 |
| Total | 4466 | 13274 | 308830 | 308751 |

- 757 orders differ by exactly USD 1: 356 higher, 401 lower on the item side.
- 79 orders differ by more than USD 1 and at most USD 4:
  31 higher and 48 lower on the item side.
- Net item-minus-order difference: USD -79.
- Sum of absolute order-level differences: USD 923, about 0.30% of order revenue.
- Maximum absolute difference: USD 4.
- Rounding or obfuscation may be hypotheses; neither cause has been established.

Decision: retain USD 308830 as identifiable order revenue and USD 308751 as
recorded representative-item revenue. Do not allocate or force-adjust differences.
Revenue is not net of refunds.

## Identifier quality and aggregation
- 789 distinct trimmed item IDs.
- No missing/unusable IDs or names in representative order items.
- One ID has multiple names; none lacks a usable name.
- Group by item_id, keeping case; do not merge IDs based on matching names.
- Display the most frequent name, breaking ties alphabetically.
- Count distinct order_key and user_pseudo_id within each ID.
- Sum recorded item revenue without arbitrarily deleting same-ID rows.
- Counts across products are non-additive because orders/users can contain multiple IDs.

## Revenue ranking and concentration
| Metric | Result |
|---|---:|
| Recorded item revenue USD | 308751 |
| Item IDs | 789 |
| IDs with zero aggregate revenue | 0 |
| IDs with negative aggregate revenue | 0 |
| Top 10 revenue share (%) | 11.31 |
| Top 20 revenue share (%) | 18.65 |
| Top 50 revenue share (%) | 34.22 |
| Top 100 revenue share (%) | 51.87 |
| IDs needed for 50% of revenue | 94 |
| IDs needed for 80% of revenue | 265 |

94 IDs are 11.91% of observed IDs; 265 are 33.59%.
The observed ID-level distribution does not support an 80/20 claim.
The denominator covers IDs appearing in these orders, not the entire catalog.

Leading IDs:
| ID | Display name | Orders | Anonymous user IDs | Recorded revenue USD |
|---|---|---:|---:|---:|
| 9195292 | Google Canteen Bottle Black | 130 | 106 | 4930 |
| 9195140 | Google Utility BackPack | 47 | 35 | 4752 |
| 9195130 | Google Zip Hoodie F/C | 75 | 74 | 4020 |
| 9194259 | Google Campus Bike | 97 | 89 | 3840 |
| 9197759 | Google Incognito Techpack V2 | 36 | 24 | 3563 |

The top ID contributes 1.60%. Revenue rank does not imply unit-sales rank,
conversion performance, profitability, or a causal effect.
Revenue per order containing an item is not the item's unit price.

## Interpretation limits
- Same-name different IDs can split a product family or variants.
- The concentration result is ID-level, not product-family-level.
- Earlier audits found 287 order proxies with differing source item lists.
  Choosing the earliest purchase event does not verify the true basket.
- Matching revenue totals do not establish item identity accuracy.
- This analysis does not justify direct inventory or procurement decisions.
- Unidentifiable orders are excluded from this revenue analysis.
- All findings describe an obfuscated sample, not a verified live store.

## Reproduction
Run audits 14-17, then analyses 12-13 after rebuilding stg_events and mart_orders.
Audit 16 contains two result-producing statements.
Audit 14 consolidates the previously run coverage, multiplicity and quantity queries.
This consolidated layout should be checked against the documented results when rerun.
No new BigQuery tables are created by these product queries.
