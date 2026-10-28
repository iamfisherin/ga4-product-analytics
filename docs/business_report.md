# Business decision brief

E-commerce Product Analytics and Experimentation — Wen Yingyu

Scope: public, obfuscated GA4 sample, 2020-11-01 to 2021-01-31.
Findings are descriptive. Proposed actions have not been implemented or
evaluated as business improvements.

## Recommended priority

Validate measurement before interpreting funnel gaps as abandonment or
recommending acquisition-budget changes. Use the historical purchase baseline
to scope a future experiment with prospective assignment and a defined intervention.

## Evidence and proposed actions

| Evidence | Interpretation | Proposed action |
|---|---|---|
| 4,848 of 360,129 sessions contain a purchase (1.35%); 2,735 of 354,857 started sessions complete the strict funnel (0.77%). | Purchase presence and a complete ordered path measure different things. | Audit event coverage and alternate purchase paths before attributing gaps to UX friction. |
| Of 4,745 purchasing sessions with a start, 1,929 lack an intermediate step; allowing equal timestamps adds 67 completions. | Missing records and timestamp precision affect classification. | Validate view_item and add_to_cart instrumentation and document timestamp behavior. |
| D1 retention is 4.68%; D7 is 0.78%. | Exact-day retention uses window-relative cohorts and different eligible populations. | Define a business-relevant return cadence and preserve maturity controls. |
| Unknown/obfuscated sources account for 33.09% of started sessions; store-domain sources account for 7.90%. | First-user source quality limits attribution interpretation. | Validate source collection before recommending budget allocation. |
| Top 20 of 789 item IDs contribute 18.65% of recorded item revenue; 265 IDs reach 80%. | Revenue is spread across many IDs, but representative lists are not verified baskets. | Validate catalog identities and item payloads before assortment decisions. |

## Revenue scope

There are 4,466 identifiable order proxies with USD 308,830 revenue.
Representative item rows record USD 308,751, a net difference of USD 79.
The difference is preserved without forced adjustment.

Order revenue excludes unresolved transaction-ID purchases and does not deduct
refunds. Raw purchase-event revenue of USD 362,165 includes repeated events and
unresolved IDs and is not interchangeable with identifiable order revenue.

## Experiment planning

The historical simulated A/A exercise covers 253,609 anonymous user IDs.
SRM p = 0.333522; purchase-rate comparison p = 0.570547.
B - A = +0.0257 percentage points, with a 95% Wald interval of
[-0.0631, +0.1145]. This is not a real treatment effect or proof of equivalence.

At the historical baseline of 1.3182%, equal allocation, two-sided alpha 5%
and power 80%, approximate total sample requirements are:

| Relative lift | Total users |
|---|---:|
| 5% | 963,322 |
| 10% | 246,620 |
| 20% | 64,548 |

A real experiment needs a defined intervention, eligibility rules, assignment
before outcome measurement, complete follow-up, guardrails and a predefined
analysis plan. Historical volume does not guarantee future experiment duration.

## Deliverable

[Live dashboard](https://ga4-appuct-analytics-fish.streamlit.app/)

No conversion uplift, revenue growth or cost savings were measured.