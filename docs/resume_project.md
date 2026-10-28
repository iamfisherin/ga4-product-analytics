# Resume project wording

Owner: Wen Yingyu / 文颖榆
Project: E-commerce Product Analytics and Experimentation
Stack: BigQuery SQL, Python, pandas, Plotly, Streamlit, Git

[GitHub](https://github.com/iamfisherin/ga4-product-analytics)
[Live dashboard](https://ga4-appuct-analytics-fish.streamlit.app/)

## 中文版

- 基于 BigQuery SQL 处理 429 万条 GA4 嵌套事件，构建用户、Session、订单代理、顺序漏斗及每日活动模型；通过复合键去重和关联前聚合，识别 4,466 个订单代理并核验 USD 308,830 收入。
- 完成严格时间顺序漏斗、带观察期成熟度控制的 Cohort 留存，以及设备、国家、首次获客来源和商品收入分析；区分购买出现率与漏斗完成率，保留商品记录收入与订单收入的口径差异。
- 对 25.36 万匿名用户标识实施明确标注的模拟 A/A 分组，完成 SRM、购买率检验、设备平衡及 Power/MDE/样本量规划，并开发部署包含 6 个标签页的 Streamlit 仪表盘。

## English version

- Transformed 4.30M nested GA4 events with BigQuery SQL into user, session, order-proxy, sequential-funnel and daily-activity models; validated 4,466 identifiable order proxies and USD 308,830 revenue using composite-key deduplication and pre-join aggregation.
- Analyzed strictly ordered funnels, maturity-aware cohort retention, device/country segments, first-user acquisition quality and recorded product revenue, documenting coverage and metric-definition limitations.
- Conducted explicitly simulated A/A diagnostics for 253.6K anonymous user IDs, including SRM, purchase-rate testing, device balance and power/MDE planning; built and deployed a six-tab Streamlit dashboard.

## Claims to avoid

Do not describe this as a production system or a real randomized A/B test.
Do not claim measured conversion uplift, revenue growth or cost savings.
Do not claim use of dbt, Spark, Kafka, Airflow or machine learning.
Anonymous IDs are not verified unique people.
Add project dates only after confirming the actual dates.