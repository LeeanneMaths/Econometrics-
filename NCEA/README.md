# NCEA Level 1 Literacy and Numeracy Econometrics App

This Streamlit app is designed as a deployable education-data analytics prototype using the 2024 NCEA Level 1 Literacy and Numeracy attainment CSV files.

## What The App Demonstrates

1. Loading multiple CSV files with different grouping dimensions.
2. Producing executive-level summary metrics.
3. Comparing trends and attainment-rate gaps across groups.
4. Estimating weighted least squares models on aggregated data.
5. Framing a pathway from public aggregated data to secure de-identified microdata analysis.

## How To Run

Open this folder:

```powershell
cd "<path-to-this-folder>\ncea_lit_num_streamlit_app"
```

If your normal Python installation has Streamlit installed, run:

```powershell
python -m streamlit run app.py
```

If `python` opens the Windows Store alias or does not respond correctly, run:

```powershell
.\run_app.bat
```

Then open:

```text
http://localhost:8501
```

## Suggested Demonstration Flow

1. Start with `Executive Summary` to show the value proposition.
2. Use `Overview` to explain the structure of the dataset.
3. Switch to `Trends and Gaps` to show regional, gender, ethnicity, or equity-index differences.
4. Open `Regression Model` and keep `Weighted by Total Student Count` selected.
5. Use `IDI Pathway` to explain how the same analytical workflow could be adapted to secure student-level microdata.

## Econometric Framing

The app uses aggregated data, not student-level microdata. A useful model framing is:

```text
Attainment Rate = year trend + qualification + year level + group effects + error
```

The `Post 2020` variable can show average differences after 2020, but it is not a strict causal estimate. Many factors may have changed at the same time, including assessment rules, policy settings, school behaviour, pandemic disruption, and student composition.

## Entrepreneurship Framing

The app demonstrates a reusable analytical recipe:

```text
structured education data -> analysis-ready variables -> interpretable dashboard -> transparent model output
```

The immediate product value is reducing the time between receiving an education spreadsheet and producing evidence-informed questions. The longer-term value is adapting the same workflow to secure de-identified longitudinal data.

## Files

- `app.py`: Streamlit application.
- `requirements.txt`: Python dependencies.
- `run_app.bat`: Windows launcher using the Codex-managed Python runtime.
- `README.md`: This guide.
