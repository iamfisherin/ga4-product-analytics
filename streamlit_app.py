from pathlib import Path

import pandas as pd
import plotly.graph_objects as go
import streamlit as st


st.set_page_config(
    page_title="E-commerce Product Analytics",
    page_icon="📊",
    layout="wide",
)

ROOT = Path(__file__).resolve().parent
DATA = ROOT / "data" / "dashboard"


@st.cache_data
def load_csv(filename):
    return pd.read_csv(DATA / filename)


st.title("E-commerce Product Analytics")
st.caption(
    "Portfolio project by Wen Yingyu | "
    "GA4 public sample | 2020-11-01 to 2021-01-31"
)
st.info(
    "Historical, obfuscated sample data. "
    "Metrics describe the observation window; they do not establish causal effects."
)

try:
    overview = load_csv("overview.csv").iloc[0]
    funnel = load_csv("funnel.csv").sort_values("stage_order")
except (OSError, ValueError, pd.errors.ParserError) as exc:
    st.error(f"Could not load dashboard data: {exc}")
    st.stop()

overview_tab, funnel_tab, retention_tab, products_tab, segments_tab, experiment_tab = st.tabs(["Overview", "Strict session funnel", "Retention", "Products", "Segments", "Simulated A/A"])

with overview_tab:
    st.subheader("Observed activity")

    cols = st.columns(3)
    cols[0].metric(
        "Events", f"{int(overview['event_count']):,}"
    )
    cols[1].metric(
        "Anonymous user IDs", f"{int(overview['anonymous_user_ids']):,}"
    )
    cols[2].metric(
        "Observed sessions", f"{int(overview['observed_sessions']):,}"
    )

    purchase_rate = (
        overview["purchasing_sessions"] / overview["observed_sessions"]
    )

    cols = st.columns(3)
    cols[0].metric(
        "Purchasing sessions", f"{int(overview['purchasing_sessions']):,}"
    )
    cols[1].metric(
        "Session purchase presence", f"{purchase_rate:.2%}"
    )
    cols[2].metric(
        "Purchase events", f"{int(overview['purchase_events']):,}"
    )

    st.subheader("Identifiable orders")
    cols = st.columns(2)
    cols[0].metric(
        "Identifiable order proxies",
        f"{int(overview['identifiable_orders']):,}",
    )
    cols[1].metric(
        "Identifiable order revenue",
        f"${overview['identifiable_order_revenue_usd']:,.0f}",
    )
    st.caption(
        "Order proxies use (user_pseudo_id, transaction_id), "
        "excluding unusable transaction IDs. Revenue does not deduct refunds. "
        "Purchase behavior includes all purchase events."
    )

with funnel_tab:
    st.subheader("Strictly ordered session funnel")
    st.write(
        "Each step must occur after the preceding step at a strictly later "
        "timestamp within the same session. Only sessions with a recorded "
        "session_start enter the denominator."
    )

    completion_rate = (
        overview["strict_funnel_completions"] / overview["started_sessions"]
    )
    cols = st.columns(3)
    cols[0].metric(
        "Started sessions", f"{int(overview['started_sessions']):,}"
    )
    cols[1].metric(
        "Strict completions", f"{int(overview['strict_funnel_completions']):,}"
    )
    cols[2].metric("Strict completion rate", f"{completion_rate:.2%}")

    fig = go.Figure(
        go.Funnel(
            y=funnel["stage"],
            x=funnel["sessions"],
            texttemplate="%{value:,.0f}<br>%{percentInitial:.2%}",
            marker={"color": "#2563EB"},
        )
    )
    fig.update_layout(
        height=440,
        margin={"l": 20, "r": 20, "t": 20, "b": 20},
    )
    st.plotly_chart(fig)

    table = funnel[["stage", "sessions"]].copy()
    table["Cumulative completion"] = funnel["cumulative_rate"].map(
        lambda value: f"{value:.2%}" if pd.notna(value) else "—"
    )
    table["From previous stage"] = funnel["previous_stage_rate"].map(
        lambda value: f"{value:.2%}" if pd.notna(value) else "—"
    )
    st.dataframe(table, hide_index=True)

    st.warning(
        "Missing intermediate events cannot all be interpreted as abandonment. "
        "Strict funnel completion and purchase presence measure different things."
    )

with retention_tab:
    st.subheader("Exact-day return retention")
    st.write(
        "A cohort starts on the user's first observed date in this dataset, "
        "not their registration date. Retention means activity on exactly "
        "day 1, 7, 14 or 30 after that date."
    )

    retention = load_csv("retention_daily.csv").copy()
    retention["cohort_date"] = pd.to_datetime(retention["cohort_date"])
    retention["is_mature"] = (
        retention["is_mature"].astype(str).str.lower().eq("true")
    )

    mature = retention.loc[retention["is_mature"]].copy()
    summary = mature.groupby("retention_day")[
        ["eligible_users", "retained_users"]
    ].sum()

    cols = st.columns(4)
    for col, day in zip(cols, [1, 7, 14, 30]):
        row = summary.loc[day]
        rate = row["retained_users"] / row["eligible_users"]
        col.metric(f"D{day} retention", f"{rate:.2%}")
        col.caption(
            f"{int(row['retained_users']):,} returned / "
            f"{int(row['eligible_users']):,} eligible"
        )

    st.caption(
        "Each retention horizon has a different eligible population. "
        "These four rates are not a decline curve for one identical group."
    )

    st.subheader("Monthly cohorts and observation maturity")
    retention["cohort_month"] = (
        retention["cohort_date"].dt.strftime("%Y-%m")
    )

    monthly = retention.groupby(
        ["cohort_month", "retention_day"], as_index=False
    ).agg(
        cohort_users=("cohort_users", "sum"),
        observed_cohort_dates=("cohort_date", "nunique"),
        mature_cohort_dates=("is_mature", "sum"),
        eligible_users=("eligible_users", "sum"),
        retained_users=("retained_users", lambda s: s.sum(min_count=1)),
    )

    monthly["retention_pct"] = (
        100 * monthly["retained_users"]
        / monthly["eligible_users"].where(monthly["eligible_users"] > 0)
    )
    monthly["maturity_status"] = [
        "fully_mature" if mature_days == observed_days
        else "not_mature" if mature_days == 0
        else "partially_mature"
        for mature_days, observed_days in zip(
            monthly["mature_cohort_dates"],
            monthly["observed_cohort_dates"],
        )
    ]

    month = st.selectbox(
        "First-observed cohort month",
        sorted(monthly["cohort_month"].unique()),
    )
    selected = monthly.loc[monthly["cohort_month"].eq(month)].copy()

    st.dataframe(
        selected[
            [
                "retention_day",
                "cohort_users",
                "mature_cohort_dates",
                "observed_cohort_dates",
                "maturity_status",
                "eligible_users",
                "retained_users",
                "retention_pct",
            ]
        ],
        hide_index=True,
    )

    st.info(
        "For partially mature months, the rate covers only eligible cohort "
        "dates. January D30 covers January 1 only: 1,948 eligible users "
        "and zero observed returns on January 31. This is not a full-month "
        "January D30 estimate."
    )

    st.subheader("Daily cohort heatmap")
    daily = retention.loc[retention["cohort_month"].eq(month)].copy()
    daily["display_rate"] = daily["retention_pct"].where(
        daily["is_mature"]
    )
    heatmap = daily.pivot(
        index="cohort_date",
        columns="retention_day",
        values="display_rate",
    ).reindex(columns=[1, 7, 14, 30]).sort_index()

    fig = go.Figure(
        go.Heatmap(
            z=heatmap.to_numpy(dtype=float),
            x=[f"D{day}" for day in heatmap.columns],
            y=heatmap.index.strftime("%Y-%m-%d").tolist(),
            colorscale="Blues",
            zmin=0,
            zmax=float(retention["retention_pct"].max()),
            colorbar={"title": "Retention (%)"},
            hoverongaps=False,
            hovertemplate=(
                "Cohort: %{y}<br>Horizon: %{x}"
                "<br>Retention: %{z:.2f}%<extra></extra>"
            ),
        )
    )
    fig.update_layout(
        height=720,
        yaxis={"autorange": "reversed", "type": "category"},
        xaxis={"side": "top"},
        margin={"l": 20, "r": 20, "t": 30, "b": 20},
        plot_bgcolor="#E5E7EB",
    )
    st.plotly_chart(fig)
    st.caption(
        "Gray cells are not yet observable, not zero retention. "
        "The color scale is fixed across months. "
        "November cohorts may include users active before the dataset began."
    )

with products_tab:
    st.subheader("Recorded product revenue")
    st.caption("Full observation window: 2020-11-01 to 2021-01-31.")
    st.warning(
        "Revenue comes from representative item lists of identifiable order "
        "proxies. These lists are not verified baskets. Revenue does not "
        "deduct refunds; item-level conversion rates are not inferred."
    )

    products = pd.read_csv(
        DATA / "products.csv",
        dtype={"item_id": "string"},
    ).sort_values("revenue_rank").copy()

    total_revenue = products["recorded_item_revenue_usd"].sum()
    products["cumulative_share_pct"] = (
        100 * products["recorded_item_revenue_usd"].cumsum() / total_revenue
    )
    top20_share = (
        100 * products.head(20)["recorded_item_revenue_usd"].sum()
        / total_revenue
    )

    cols = st.columns(3)
    cols[0].metric("Distinct item IDs", f"{products['item_id'].nunique():,}")
    cols[1].metric("Recorded item revenue", f"${total_revenue:,.0f}")
    cols[2].metric("Top 20 revenue share", f"{top20_share:.2f}%")

    st.caption(
        "Identifiable order revenue is USD 308,830. Recorded item revenue is "
        "USD 79 lower; the difference is preserved without adjustment."
    )

    top_n = st.selectbox("Number of items in ranking", [10, 20, 50], index=1)
    top = products.head(top_n).sort_values(
        "recorded_item_revenue_usd", ascending=True
    ).copy()
    top["label"] = (
        top["display_item_name"] + " [" + top["item_id"] + "]"
    )

    fig = go.Figure(
        go.Bar(
            x=top["recorded_item_revenue_usd"],
            y=top["label"],
            orientation="h",
            marker={"color": "#2563EB"},
            hovertemplate="%{y}<br>Recorded revenue: $%{x:,.2f}<extra></extra>",
        )
    )
    fig.update_layout(
        height=max(440, top_n * 28),
        xaxis_title="Recorded item revenue (USD)",
        yaxis={"type": "category"},
        margin={"l": 20, "r": 20, "t": 20, "b": 20},
    )
    st.plotly_chart(fig)

    st.subheader("Revenue concentration across all item IDs")
    fig = go.Figure(
        go.Scatter(
            x=products["revenue_rank"],
            y=products["cumulative_share_pct"],
            mode="lines",
            line={"color": "#2563EB"},
            hovertemplate=(
                "Top %{x} item IDs"
                "<br>Cumulative revenue share: %{y:.2f}%<extra></extra>"
            ),
        )
    )
    fig.add_hline(y=50, line_dash="dash", annotation_text="50%")
    fig.add_hline(y=80, line_dash="dash", annotation_text="80%")
    fig.update_layout(
        xaxis_title="Number of item IDs, ranked by recorded revenue",
        yaxis_title="Cumulative revenue share (%)",
        yaxis_range=[0, 100],
        height=400,
    )
    st.plotly_chart(fig)

    st.subheader("Find an item")
    search = st.text_input("Search by item ID or name").strip()
    results = products
    if search:
        mask = (
            products["item_id"].str.contains(
                search, case=False, regex=False, na=False
            )
            | products["display_item_name"].str.contains(
                search, case=False, regex=False, na=False
            )
        )
        results = products.loc[mask]

    st.caption(
        "Search filters only the table below. Charts and headline metrics "
        "continue to describe the full product dataset. Order and user "
        "counts overlap across products and must not be summed."
    )
    st.dataframe(
        results[
            [
                "revenue_rank",
                "item_id",
                "display_item_name",
                "recorded_item_revenue_usd",
                "identifiable_orders_with_item",
                "purchasing_user_ids",
                "distinct_item_names",
            ]
        ],
        hide_index=True,
    )

with segments_tab:
    st.subheader("Device, country and acquisition quality")
    st.caption(
        "Full observation window: 2020-11-01 to 2021-01-31. "
        "These are separate descriptive breakdowns, not causal comparisons."
    )

    segment = st.radio(
        "Breakdown",
        ["Device", "Country", "First-user acquisition quality"],
        horizontal=True,
    )

    if segment == "Device":
        device = load_csv("funnel_by_device.csv").copy()
        st.write(
            "Both rates below use sessions with a recorded session_start "
            "as the denominator. Device comes from the earliest observed "
            "event in the session."
        )

        fig = go.Figure()
        for field, label, color in [
            ("strict_funnel_completion_pct", "Strict completion", "#2563EB"),
            ("purchase_presence_pct", "Any purchase present", "#14B8A6"),
        ]:
            fig.add_trace(
                go.Bar(
                    name=label,
                    x=device["device_category"],
                    y=device[field],
                    marker_color=color,
                    text=device[field].map(lambda value: f"{value:.2f}%"),
                    textposition="auto",
                    hovertemplate="%{x}<br>%{y:.2f}%<extra>%{fullData.name}</extra>",
                )
            )
        fig.update_layout(
            barmode="group",
            yaxis_title="Rate (%)",
            yaxis_rangemode="tozero",
            height=420,
        )
        st.plotly_chart(fig)
        st.dataframe(device, hide_index=True)
        st.caption(
            "Differences are descriptive. No significance test or causal "
            "device effect is claimed."
        )

    elif segment == "Country":
        countries = load_csv("country_revenue.csv").copy()
        st.write(
            "Country comes from the earliest observed event in each session. "
            "Purchase presence uses all observed sessions. Revenue covers "
            "identifiable order proxies and does not deduct refunds."
        )

        metric_labels = {
            "Observed sessions": "observed_sessions",
            "Identifiable revenue (USD)": "identifiable_revenue_usd",
            "Identifiable orders": "identifiable_orders",
        }
        metric_label = st.selectbox(
            "Rank countries by", list(metric_labels)
        )
        field = metric_labels[metric_label]
        country_top_n = st.selectbox(
            "Countries shown", [10, 15, 30], index=1
        )

        ranked_countries = countries.sort_values(
            [field, "country"], ascending=[False, True]
        ).head(country_top_n).sort_values(field)

        fig = go.Figure(
            go.Bar(
                x=ranked_countries[field],
                y=ranked_countries["country"],
                orientation="h",
                marker_color="#2563EB",
                hovertemplate="%{y}<br>%{x:,.2f}<extra></extra>",
            )
        )
        fig.update_layout(
            xaxis_title=metric_label,
            yaxis={"type": "category"},
            height=max(420, country_top_n * 27),
        )
        st.plotly_chart(fig)

        st.caption(
            "The ranking control changes only the chart. "
            "The table below contains all country groups. "
            "Distinct user counts overlap across countries and must not "
            "be summed. These comparisons alone do not justify expansion."
        )
        st.dataframe(
            countries.sort_values(field, ascending=False),
            hide_index=True,
        )

    else:
        acquisition = load_csv("acquisition_quality.csv").copy()
        labels = {
            "1_unknown_or_obfuscated": "Unknown / obfuscated",
            "2_store_domain_source": "Store-domain source",
            "3_other_named_sources": "Other named sources",
        }
        acquisition["source_quality"] = (
            acquisition["acquisition_quality_group"].map(labels)
            .fillna(acquisition["acquisition_quality_group"])
        )

        st.write(
            "These fields describe first-user acquisition, not attribution "
            "for the current session. The denominator is sessions with "
            "a recorded session_start."
        )

        fig = go.Figure(
            go.Bar(
                x=acquisition["source_quality"],
                y=acquisition["pct_of_started_sessions"],
                marker_color=["#94A3B8", "#F59E0B", "#2563EB"],
                text=acquisition["pct_of_started_sessions"].map(
                    lambda value: f"{value:.2f}%"
                ),
                textposition="auto",
                hovertemplate="%{x}<br>Share: %{y:.2f}%<extra></extra>",
            )
        )
        fig.update_layout(
            yaxis_title="Share of started sessions (%)",
            yaxis_range=[0, 100],
            height=420,
        )
        st.plotly_chart(fig)
        st.dataframe(
            acquisition[
                [
                    "source_quality",
                    "started_sessions",
                    "pct_of_started_sessions",
                    "strict_purchase_sessions",
                    "any_purchase_sessions",
                    "strict_funnel_completion_pct",
                    "purchase_presence_pct",
                ]
            ],
            hide_index=True,
        )
        st.warning(
            "Unknown/obfuscated and store-domain sources do not support "
            "advertising budget recommendations. A named source alone "
            "does not establish reliable session attribution."
        )

with experiment_tab:
    import math
    from statistics import NormalDist

    st.subheader("Simulated A/A and experiment planning")
    st.warning(
        "SIMULATION ONLY: historical users were assigned using a fixed hash. "
        "No treatment was delivered. Results do not measure a product effect."
    )
    st.write(
        "Unit: anonymous user ID. Outcome: at least one purchase during "
        "the first observed date through day +6, inclusive. Eligible users "
        "were first observed by 2021-01-25. This is a calendar-day window, "
        "not necessarily 168 hours."
    )

    aa = load_csv("simulated_aa.csv").set_index("simulated_group")
    n_a, n_b = int(aa.loc["A", "users"]), int(aa.loc["B", "users"])
    x_a = int(aa.loc["A", "purchasing_users_7d"])
    x_b = int(aa.loc["B", "purchasing_users_7d"])
    p_a, p_b = x_a / n_a, x_b / n_b
    pooled = (x_a + x_b) / (n_a + n_b)
    difference = p_b - p_a

    expected = (n_a + n_b) / 2
    chi_square = (
        (n_a - expected) ** 2 / expected
        + (n_b - expected) ** 2 / expected
    )
    srm_p = math.erfc(math.sqrt(chi_square / 2))

    pooled_se = math.sqrt(
        pooled * (1 - pooled) * (1 / n_a + 1 / n_b)
    )
    z = difference / pooled_se
    p_value = math.erfc(abs(z) / math.sqrt(2))

    unpooled_se = math.sqrt(
        p_a * (1 - p_a) / n_a + p_b * (1 - p_b) / n_b
    )
    critical = NormalDist().inv_cdf(0.975)
    ci_low = difference - critical * unpooled_se
    ci_high = difference + critical * unpooled_se

    st.subheader("Allocation check")
    cols = st.columns(3)
    cols[0].metric("Group A users", f"{n_a:,}")
    cols[1].metric("Group B users", f"{n_b:,}")
    cols[2].metric("SRM p-value", f"{srm_p:.6f}")
    st.caption(
        "Pearson chi-square test against 50:50 allocation; "
        "SRM threshold = 0.001. "
        + ("SRM flagged." if srm_p < 0.001 else "No SRM flag detected.")
        + " This check alone does not establish randomization quality."
    )

    st.subheader("Seven-day purchase outcome")
    cols = st.columns(3)
    cols[0].metric("A purchase rate", f"{p_a:.4%}")
    cols[1].metric("B purchase rate", f"{p_b:.4%}")
    cols[2].metric("B - A", f"{100 * difference:+.4f} pp")

    st.write(
        f"Two-sided pooled z-test p-value: **{p_value:.6f}**. "
        f"95% unpooled Wald confidence interval for B - A: "
        f"**[{100 * ci_low:+.4f}, {100 * ci_high:+.4f}] "
        "percentage points**."
    )
    st.info(
        "The observed difference is not statistically significant at 5%."
        if p_value >= 0.05
        else "The observed difference is statistically significant at 5%."
    )
    st.caption(
        "A nonsignificant result does not prove equivalence. "
        "This simulated comparison is not evidence of treatment uplift."
    )
    st.dataframe(aa.reset_index(), hide_index=True)

    st.subheader("First-observed device balance")
    balance = load_csv("simulated_aa_device_balance.csv")
    device_counts = balance.pivot(
        index="first_device", columns="simulated_group", values="users"
    )
    device_balance = pd.DataFrame(index=device_counts.index)
    device_balance["A share (%)"] = 100 * device_counts["A"] / n_a
    device_balance["B share (%)"] = 100 * device_counts["B"] / n_b
    device_balance["B - A (pp)"] = (
        device_balance["B share (%)"] - device_balance["A share (%)"]
    )
    share_a = device_counts["A"] / n_a
    share_b = device_counts["B"] / n_b
    denominator = (
        (share_a * (1 - share_a) + share_b * (1 - share_b)) / 2
    ) ** 0.5
    device_balance["SMD"] = (
        (share_b - share_a) / denominator.where(denominator > 0)
    )
    st.dataframe(device_balance.reset_index(), hide_index=True)
    st.caption(
        f"Maximum absolute SMD: "
        f"{device_balance['SMD'].abs().max():.6f}. "
        "This evaluates device balance only, not every user characteristic."
    )

    st.subheader("Prospective sample-size planning")
    st.write(
        "Historical baseline, equal-sized independent groups, two-sided "
        "alpha = 5%, target power = 80%. Normal approximation without "
        "continuity correction. These are planning assumptions."
    )

    def required_per_group(relative_lift):
        target = pooled * (1 + relative_lift)
        average = (pooled + target) / 2
        numerator = (
            NormalDist().inv_cdf(0.975)
            * math.sqrt(2 * average * (1 - average))
            + NormalDist().inv_cdf(0.80)
            * math.sqrt(pooled * (1 - pooled) + target * (1 - target))
        ) ** 2
        return math.ceil(numerator / (target - pooled) ** 2)

    planning = []
    for lift in [0.05, 0.10, 0.20]:
        per_group = required_per_group(lift)
        planning.append({
            "Relative lift (%)": 100 * lift,
            "Target purchase rate (%)": 100 * pooled * (1 + lift),
            "Absolute MDE (pp)": 100 * pooled * lift,
            "Users per group": per_group,
            "Total users": 2 * per_group,
        })
    st.caption(f"Historical baseline purchase rate: {pooled:.4%}")
    st.dataframe(pd.DataFrame(planning), hide_index=True)

    available = min(n_a, n_b)
    low, high = 0.0001, 1.0
    for _ in range(80):
        midpoint = (low + high) / 2
        if required_per_group(midpoint) > available:
            low = midpoint
        else:
            high = midpoint

    st.metric(
        "Approximate relative MDE at current group size",
        f"{100 * high:.2f}%",
    )
    st.caption(
        f"Planning users per group: {available:,}. "
        f"Absolute MDE: {100 * pooled * high:.4f} percentage points. "
        "This is a prospective sensitivity estimate, not observed power "
        "or an achieved improvement. Future experiments also need a "
        "credible assignment mechanism and complete outcome follow-up."
    )

st.divider()
st.caption(
    "Fixed-window aggregate snapshots. "
    "Rebuild queries and metric definitions are included in the repository."
)