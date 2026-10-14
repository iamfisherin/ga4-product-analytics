# Exact-Day Return Retention

## Scope and definition
Data window: 2020-11-01 through 2021-01-31.
Activity means at least one event on a date.
Cohort date is the first observed activity date of an anonymous user identifier
within this window. It is not registration or verified new-customer acquisition.

D-N retention requires activity exactly N calendar days after cohort_date.
It is not cumulative or rolling retention.
Only users with target_date <= 2021-01-31 enter the denominator.

## Overall results
| Day | Eligible users | Retained users | Retention (%) |
|---|---:|---:|---:|
| D1 | 267942 | 12538 | 4.68 |
| D7 | 250712 | 1966 | 0.78 |
| D14 | 230014 | 934 | 0.41 |
| D30 | 181033 | 322 | 0.18 |

Eligible populations differ across horizons. These rates should not be presented
as an identical population's attrition curve.

## Monthly results
| Cohort month | Day | Cohort users | Eligible users | Retained users | Retention (%) | Maturity |
|---|---|---:|---:|---:|---:|---|
| 2020-11 | D1 | 79421 | 79421 | 4779 | 6.0173 | Full |
| 2020-11 | D7 | 79421 | 79421 | 965 | 1.2150 | Full |
| 2020-11 | D14 | 79421 | 79421 | 544 | 0.6850 | Full |
| 2020-11 | D30 | 79421 | 79421 | 197 | 0.2480 | Full |
| 2020-12 | D1 | 99664 | 99664 | 4200 | 4.2142 | Full |
| 2020-12 | D7 | 99664 | 99664 | 585 | 0.5870 | Full |
| 2020-12 | D14 | 99664 | 99664 | 250 | 0.2508 | Full |
| 2020-12 | D30 | 99664 | 99664 | 125 | 0.1254 | Full |
| 2021-01 | D1 | 91069 | 88857 | 3559 | 4.0053 | Partial |
| 2021-01 | D7 | 91069 | 71627 | 416 | 0.5808 | Partial |
| 2021-01 | D14 | 91069 | 50929 | 140 | 0.2749 | Partial |
| 2021-01 | D30 | 91069 | 1948 | 0 | 0.0000 | Partial |

Monthly rates are ratios of summed counts, not averages of daily percentages.

## Findings
- December has more first-observed identifiers than November, but lower
  exact-day return rates at all four measured horizons.
- December D1 is approximately 1.80 percentage points below November;
  D7 is approximately 0.63 percentage points below November.
- These are descriptive differences, not evidence that a product change
  or acquisition channel caused reduced retention.
- January is partially mature at every horizon and does not represent
  a complete-month retention comparison.
- January D30 covers only the 1948 identifiers first observed on January 1.
  None appeared on January 31. This observed zero is not a whole-month estimate.

## Observation-window limitations
- The November cohort can include users active before the dataset began.
  There is no pre-window history to distinguish them from genuinely new users.
- Anonymous identifiers are not guaranteed to correspond one-to-one to people.
- The dataset is an obfuscated sample; findings describe this observed dataset.
- Missing a specific target day does not mean a user never returned.
- No significance test or causal claim is made in this analysis.

## Maturity handling
- Latest eligible cohort dates: January 30 (D1), January 24 (D7),
  January 17 (D14), and January 1 (D30).
- Immature daily periods retain their rows and have NULL return counts/rates.
- Mature periods with no returns have zero return counts/rates.
- A future heatmap should distinguish unavailable cells from observed zero.
- Partial monthly estimates must retain their eligibility and maturity labels.

## Reconciliation
Summing monthly eligible and retained users reproduces all four overall totals.
Daily activity validation returned:
319066 user-day rows, 270154 identifiers, 92 dates,
4295584 events, 5692 purchases, 0 invalid rows,
and 0 duplicate user-date groups.

## SQL
- sql/models/06_mart_user_daily_activity.sql
- sql/checks/03_daily_activity_validation.sql
- sql/analysis/09_exact_day_retention.sql
- sql/analysis/10_daily_cohort_retention.sql
- sql/analysis/11_monthly_cohort_retention.sql
