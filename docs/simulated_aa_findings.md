# Simulated A/A and Hypothetical Experiment Planning

## Scope
This is a retrospective simulation using historical GA4 data.
No actual treatment, online exposure, or causal product effect exists.
Assignment checks do not validate a live experimentation platform.

## Population and outcome
- Unit: anonymous user_pseudo_id, not a verified individual person.
- Entry: first observed event date within the dataset, not registration.
- Eligible entry dates: 2020-11-01 through 2021-01-25.
- Dataset observation end: 2021-01-31.
- Outcome window: entry date through entry date + 6 days, inclusive.
- This is seven calendar dates, not exactly 168 hours after the first event.
- Main outcome: at least one purchase event during that window.
- All purchase events count, including events with unresolved order IDs.
- Late cohorts without complete follow-up are excluded.
- Eligibility: 253609 identifiers; 3343 purchasing identifiers; 4043 purchases.
- Historical purchase rate: 3343 / 253609 = approximately 1.3182%.

## Assignment
Fixed hash:
FARM_FINGERPRINT(CONCAT('simulated_aa_v1|', user_pseudo_id)).
Even hash values map to A; other values map to B.
The target allocation is approximately 50:50.
The salt is fixed and was not changed to obtain favorable results.

| Group | Users | Purchasing users | Purchase events | Purchase rate (%) |
|---|---:|---:|---:|---:|
| A | 126561 | 1652 | 2017 | 1.3053 |
| B | 127048 | 1691 | 2026 | 1.3310 |

Counts reconcile to the eligible population and baseline outcome totals.

## Sample ratio mismatch
Pearson chi-square goodness-of-fit test against 50:50 allocation:
- Chi-square: 0.935176, 1 degree of freedom.
- p-value: 0.333522.
- Diagnostic threshold: 0.001.
- No SRM flag.

This checks group size, not balance on every characteristic.
The deterministic hash is treated as a pseudo-random allocation mechanism
for this exercise; its independence properties are not formally proven here.

## Outcome comparison
Two-sided pooled two-proportion z-test, alpha = 0.05.
Approximate 95% Wald confidence interval uses unpooled standard error.

- Difference B minus A: +0.0257 percentage points.
- Relative difference: +1.97%.
- z statistic: 0.567247.
- p-value: 0.570547.
- 95% CI: [-0.0631, +0.1145] percentage points.
- No statistically significant difference detected.

Non-significance does not establish equivalence.
The relative difference is not a treatment uplift.
The analysis treats anonymous identifiers as independent units.

## First-observed device balance
Each identifier is assigned the device from its earliest observed event,
breaking timestamp ties by event_key.

| Device | A users | B users | SMD (B minus A) |
|---|---:|---:|---:|
| desktop | 73624 | 73666 | -0.003849 |
| mobile | 50101 | 50523 | +0.003688 |
| tablet | 2836 | 2859 | +0.000642 |

Maximum absolute SMD: 0.003849.
No material imbalance is apparent on this measured characteristic.
This does not establish balance on all observed or unobserved characteristics.

## Hypothetical sample size planning
Assumptions:
- Baseline = 3343 / 253609.
- Two independent proportions; equal group sizes.
- Two-sided alpha = 0.05; target power = 0.80.
- Normal approximation without continuity correction.
- Hypothetical positive effects, not observed product effects.
- No allowance for identity dependence, attrition, or operational data loss.

| Assumed relative improvement | Target rate (%) | Absolute difference (pp) | Users/group | Total users |
|---|---:|---:|---:|---:|
| 5% | 1.3841 | 0.0659 | 481661 | 963322 |
| 10% | 1.4500 | 0.1318 | 123310 | 246620 |
| 20% | 1.5818 | 0.2636 | 32274 | 64548 |

Using the smaller existing group (126561) for both groups:
- Approximate relative MDE: 9.87%.
- Approximate absolute MDE: 0.1301 percentage points.
- Corresponding target rate: 1.4482%.
- Target power: 80%.

This is hypothetical design sensitivity, not observed/post-hoc power.
Smaller effects may be detected, but are not assured 80% power by this design.
Historical baseline uncertainty and future population differences are not
incorporated in these point-estimate planning calculations.
No experiment duration is inferred from these counts.

## Reproduction
1. Validate that source models cover the complete 92-day dataset.
2. Run sql/experiments/01_simulated_aa_baseline.sql.
3. Run sql/experiments/02_simulated_aa_assignment.sql.
4. Run sql/experiments/03_simulated_aa_device_balance.sql.
5. Open notebooks/01_simulated_aa.ipynb and run its cells in order.

The notebook uses manually transcribed aggregate SQL results.
It is not an automated BigQuery data connection.
If SQL results change, update notebook input counts before rerunning.
Calculations use Python standard-library math and statistics.
JupyterLab and ipykernel are required to run the notebook interactively.
