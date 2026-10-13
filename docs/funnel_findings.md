# Funnel and Segment Findings

Observation window: 2020-11-01 to 2021-01-31. Source: obfuscated GA4 ecommerce sample.
All numerical results below were supplied from successful BigQuery runs during the guided analysis.

## Metric definitions
- Strict funnel: same session; session_start -> view_item -> add_to_cart -> begin_checkout -> purchase; strictly increasing timestamps; earliest qualifying event after each previous step.
- Funnel denominator: 354,857 sessions containing session_start. The 5,272 sessions without a start remain in mart_sessions.
- Equal-timestamp sensitivity: nondecreasing timestamps; equal timestamps do not prove event order.
- Purchase presence: any purchase within a session, without intermediate-stage or ordering requirements.
- Country analysis uses all 360,129 observed sessions. Identifiable revenue covers user-transaction order proxies only.
- Device and geographic session dimensions come from the earliest observed event. Acquisition fields describe first-user acquisition, not session attribution.

## Funnel results
| Stage | Strict sessions | Equal-timestamp sensitivity sessions |
|---|---:|---:|
| session_start | 354857 | 354857 |
| view_item | 74974 | 75264 |
| add_to_cart | 14043 | 14892 |
| begin_checkout | 5080 | 5325 |
| purchase | 2735 | 2802 |

Strict funnel completion: 0.77%. Equal-timestamp sensitivity: 0.79%.
Purchase presence: 1.34% among started sessions; 1.35% among all observed sessions.
There are 4,745 purchasing started sessions and 103 purchasing sessions without a start.

## Purchasing started-session coverage
| Mutually exclusive category | Sessions |
|---|---:|
| Missing view_item | 143 |
| Has view_item, missing add_to_cart | 1786 |
| Has view and cart, missing checkout | 0 |
| All five event types present | 2816 |

The 4,745 purchasing started sessions decompose into 2,735 strict completions, 67 additional completions allowing timestamp equality, 14 with all events but no nondecreasing path, and 1,929 missing intermediate steps.
Missing events cannot be assumed to represent customer abandonment: purchase-path differences, collection issues, and obfuscation remain possible explanations.

## Device comparison
| Device | Started sessions | Strict completion % | Purchase presence % |
|---|---:|---:|---:|
| desktop | 205899 | 0.75 | 1.31 |
| mobile | 141079 | 0.80 | 1.38 |
| tablet | 7879 | 0.76 | 1.28 |

Observed device differences are small. View-to-cart rates are approximately 18-19% across devices.
No causal device effect or statistical significance has been established. Sessions from the same user are not necessarily independent.

## First-user acquisition quality
| Source quality group | Started sessions | Share % | Strict purchases | Any purchases |
|---|---:|---:|---:|---:|
| Unknown or obfuscated | 117429 | 33.09 | 975 | 1744 |
| Store domain source | 28044 | 7.90 | 331 | 567 |
| Other named sources | 209384 | 59.01 | 1429 | 2434 |

Store-domain sources require separate interpretation; they are not verified external referrals. Named sources are not verified session attribution either.
Do not recommend budget increases based on masked source values or these descriptive comparisons alone.

## Country comparison: selected high-volume groups
| Country | Observed sessions | Purchasing sessions | Identifiable orders | Identifiable revenue USD | Purchase presence % |
|---|---:|---:|---:|---:|---:|
| United States | 158155 | 2117 | 1942 | 136196 | 1.34 |
| India | 33769 | 449 | 405 | 29240 | 1.33 |
| Canada | 26824 | 390 | 363 | 27250 | 1.45 |
| United Kingdom | 11327 | 151 | 136 | 9853 | 1.33 |
| Japan | 4732 | 76 | 69 | 5269 | 1.61 |

The United States is the largest observed traffic and identifiable-revenue group. Higher sample rates elsewhere do not establish an expansion opportunity.
Country groups can share user identifiers, so distinct user counts are not additive across countries.

## Reproduction
1. Existing sql/models/00 through 04 must be built first.
2. Run sql/models/05_mart_session_funnel.sql.
3. Run sql/checks/02_funnel_validation.sql.
4. Run sql/analysis/01 through 08 as needed.
5. Expected funnel validation: 354857 rows, 0 duplicate keys, 74974 views, 14043 carts, 5080 checkouts, 2735 strict completions, 4745 purchasing sessions, 0 invalid stage flags, 0 invalid time-order rows.

## Business interpretation
Prioritize measurement and path validation for missing add_to_cart records before interpreting strict-funnel gaps as recoverable sales.
Investigate low view-to-cart progression across segments as a hypothesis, not a confirmed cause.
These observations support follow-up analysis and experiment planning, not causal conclusions or claimed real A/B results.
