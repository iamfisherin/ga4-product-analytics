# E-commerce Product Analytics and Experimentation

By Wen Yingyu | BigQuery SQL, Python, pandas, Plotly, Streamlit

An end-to-end portfolio project that transforms nested GA4 events into
validated analytics tables, examines conversion and retention, and demonstrates
experiment diagnostics using explicitly simulated A/A assignments.

**[Live dashboard](https://ga4-appuct-analytics-fish.streamlit.app/)** ·
**[Business report](docs/business_report.md)** ·
**[Dashboard guide](docs/dashboard.md)**

## Status

Version 1 analytics and dashboard are implemented.
The dashboard passed local interaction checks, and its deployed Overview
was verified in an incognito browser.

## Business questions

- How many sessions follow a strictly ordered purchase funnel?
- How does exact-day return retention vary across observed cohorts?
- How do device, country and first-user acquisition breakdowns differ?
- How concentrated is recorded product revenue?
- What can simulated A/A diagnostics and sample-size planning demonstrate?

## Selected findings

| Measure | Result |
|---|---:|
| Source events | 4,295,584 |
| Anonymous user IDs | 270,154 |
| Observed sessions | 360,129 |
| Sessions containing a purchase | 4,848 (1.35%) |
| Strict funnel completions / started sessions | 2,735 / 354,857 (0.77%) |
| Identifiable order proxies | 4,466 |
| Identifiable order revenue | USD 308,830 |
| Exact-day D1 / D7 / D14 / D30 retention | 4.68% / 0.78% / 0.41% / 0.18% |
| Recorded representative-item revenue | USD 308,751 |
| Top 20 item IDs' recorded revenue share | 18.65% |

Retention horizons use different eligible populations.
Purchase presence and strict funnel completion are different metrics.
Recorded item revenue and order revenue are retained separately.

## Data pipeline

GA4 source events -> stg_events -> session, order and user marts ->
strict session funnel and daily user activity -> aggregate CSV snapshots ->
Streamlit dashboard.

Key implementation choices:

- Extract nested event parameters and process repeated item arrays.
- Identify sessions with (user_pseudo_id, ga_session_id).
- Retain anomalous sessions and flag their observed structure.
- Identify order proxies with (user_pseudo_id, transaction_id), excluding
  missing and placeholder transaction IDs.
- Aggregate session and order measures separately to prevent join fan-out.
- Require strictly increasing timestamps for the primary funnel.
- Derive daily activity directly from event dates to preserve midnight crossings.
- Exclude immature cohort dates from each retention denominator.
- Keep rebuildable, unpartitioned model SQL after a historical partition
  expiration issue in Sandbox.

## Simulated experimentation

This is historical hash-based A/A assignment, not a real treatment experiment.

- Eligible anonymous user IDs: 253,609.
- Outcome: any purchase from first observed date through day +6, inclusive.
- Allocation: A = 126,561; B = 127,048.
- SRM p-value: 0.333522; no flag at threshold 0.001.
- Purchase-rate difference B - A: +0.0257 percentage points.
- Two-sided p-value: 0.570547.
- 95% Wald interval: [-0.0631, +0.1145] percentage points.
- Maximum absolute first-device SMD: 0.003849.
- Approximate relative MDE: 9.87% at 126,561 users per group,
  two-sided alpha 5% and target power 80%.

Nonsignificance does not prove equivalence. These results do not establish
product uplift. Power and MDE are prospective planning assumptions.

## Repository

| Location | Contents |
|---|---|
| sql/audit/ | Event, session, order and item data-quality audits |
| sql/models/ | Rebuildable analytics models |
| sql/checks/ | Model and funnel validation queries |
| sql/analysis/ | Funnel, retention, segment and product analyses |
| sql/experiments/ | Simulated assignment and balance queries |
| sql/dashboard/ | Dashboard export queries |
| data/dashboard/ | Aggregate CSV snapshots and metric definitions |
| notebooks/01_simulated_aa.ipynb | Statistical diagnostics and planning |
| streamlit_app.py | Six-tab dashboard |
| docs/ | Methods, findings, business report and run guide |

## Run the dashboard

Tested locally with Python 3.12. From the repository root on Windows:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m streamlit run streamlit_app.py
```

Skip environment creation if .venv already exists.
The dashboard reads committed aggregate CSVs; BigQuery credentials are not required.

To rebuild the source models, run sql/models/ in numeric order in BigQuery,
then the validation queries in sql/checks/. The SQL currently targets
project ga4-product-analytics-511413 and dataset analytics in US.
Change the project references if rebuilding in another account.
Export the full results of sql/dashboard/ using the filenames documented
in data/dashboard/README.md.

## Interpretation limits

- Public, obfuscated sample data; conclusions are descriptive.
- Anonymous IDs are not verified people, and first observation is not registration.
- Missing funnel events cannot all be interpreted as abandonment.
- First-user acquisition fields are not session-channel attribution.
- Representative order item lists are not verified baskets.
- Order revenue excludes unresolved transaction IDs and does not deduct refunds.
- Product order/user counts and country user counts are not additive.
- Snapshot controls do not support arbitrary cross-dimensional filtering.
- No recommender system, deep learning, Kafka, Spark, Airflow or dbt is used.

## Data source

`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

Observation window: 2020-11-01 through 2021-01-31 (92 days).

[Google dataset documentation](https://developers.google.com/analytics/bigquery/web-ecommerce-demo-dataset)

## Detailed findings

- [Data audit](docs/data_audit.md)
- [Data model](docs/data_model.md)
- [Funnel findings](docs/funnel_findings.md)
- [Retention findings](docs/retention_findings.md)
- [Product findings](docs/product_findings.md)
- [Simulated A/A findings](docs/simulated_aa_findings.md)