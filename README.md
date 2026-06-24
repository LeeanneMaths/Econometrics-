# NCEA Level 1 Literacy and Numeracy Econometrics App

This Streamlit app is designed for a short teaching demonstration using the 2024 NCEA Level 1 Literacy and Numeracy attainment CSV files.

## What The App Demonstrates

1. Loading multiple CSV files with different grouping dimensions.
2. Producing descriptive statistics and trend charts.
3. Comparing attainment-rate gaps across groups.
4. Estimating weighted least squares models on aggregated data.
5. Interpreting coefficients carefully without overstating causal claims.

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

1. Start with `National` to show the overall 2015-2024 trend.
2. Switch to `Ethnicity`, `Gender`, `Region`, or `School Equity Index Group` to show group differences.
3. Compare `Cumulative Year Attainment Rate` with `Current Year Attainment Rate`.
4. Open the regression tab and keep `Weighted by Total Student Count` selected.
5. Add year, qualification, year-level, and group fixed effects, then discuss how the coefficients change.

## Econometric Framing

The app uses aggregated data, not student-level microdata. A useful model framing is:

```text
Attainment Rate = year trend + qualification + year level + group effects + error
```

The `Post 2020` variable can show average differences after 2020, but it is not a strict causal estimate. Many factors may have changed at the same time, including assessment rules, policy settings, school behaviour, pandemic disruption, and student composition.

## Files

- `app.py`: Streamlit application.
- `requirements.txt`: Python dependencies.
- `run_app.bat`: Windows launcher using the Codex-managed Python runtime.
- `README.md`: This guide.
