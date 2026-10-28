# Dashboard run guide

[Live dashboard](https://ga4-appuct-analytics-fish.streamlit.app/)

## Run locally

From the repository root on Windows PowerShell:

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m streamlit run streamlit_app.py
```

Open http://localhost:8501. Keep the terminal running; Ctrl+C stops the app.

## Environment and data

requirements.txt delegates to requirements-dashboard.txt.
Local tested versions: Python 3.12, Streamlit 1.66.1, pandas 3.1.0,
Plotly 7.1.0.

The app reads nine aggregate CSV snapshots in data/dashboard.
No BigQuery credentials or live database connection are required.
Export queries and definitions are documented in data/dashboard/README.md.
Restart the app after replacing CSV files to clear cached data.

## Deployment

- Repository: iamfisherin/ga4-product-analytics
- Branch: main
- Entry point: streamlit_app.py
- Python: 3.12
- Secrets: none required

## Validation

Local AppTest passed on 2026-10-27 for initial loading, January retention,
top-10 ranking, item search and all three segment views.
Reported SRM p-value: 0.333522. Relative MDE: 9.87%.

Manual local checks covered funnel precision, retention maturity masking,
product totals/search and segment views.
An incognito browser screenshot on 2026-10-28 confirmed that the deployed
Overview was accessible and displayed validated totals.
This is not exhaustive cloud interaction testing.

## Interpretation

The six tabs are Overview, Strict session funnel, Retention, Products,
Segments and Simulated A/A.

Controls apply only to their described chart or table.
Revenue does not deduct refunds. Representative item lists are not verified
baskets. First-user acquisition is not session attribution.
Simulated A/A has no treatment and cannot establish causal uplift.