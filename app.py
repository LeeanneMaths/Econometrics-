from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
import streamlit as st


APP_DIR = Path(__file__).resolve().parent
LOCAL_DATA_DIR = APP_DIR / "data"
LEGACY_DATA_DIR = Path(
    r"D:\NCEA_Secondary statistics consolidated data files for 2024"
    r"\Level 1 Literacy and Numeracy Attainment data files"
)

DEFAULT_FILES = {
    "National": "Level-1-Literacy-and-Numeracy-Attainment-Statistics-National-2024-20250302.csv",
    "Ethnicity": "Level-1-Literacy-and-Numeracy-Attainment-Statistics-National-Ethnicity-2024-20250302.csv",
    "Gender": "Level-1-Literacy-and-Numeracy-Attainment-Statistics-National-Gender-2024-20250302.csv",
    "Region": "Level-1-Literacy-and-Numeracy-Attainment-Statistics-National-Region-2024-20250302.csv",
    "School Equity Index Group": "Level-1-Literacy-and-Numeracy-Attainment-Statistics-National-School-Equity-Index-Group-2024-20250302.csv",
}

RATE_COLUMNS = [
    "Cumulative Year Attainment Rate",
    "Current Year Attainment Rate",
]

COUNT_COLUMNS = [
    "Cumulative Year Attainment",
    "Current Year Attainment",
    "Total Student Count",
]


st.set_page_config(
    page_title="Education Data Econometrics Explorer",
    page_icon=None,
    layout="wide",
)


def detect_dimension(df: pd.DataFrame, fallback: str) -> str:
    for col in ["Ethnicity", "Gender", "Region", "School Equity Index Group"]:
        if col in df.columns:
            return col
    return fallback


def clean_frame(df: pd.DataFrame, source: str) -> pd.DataFrame:
    df = df.copy()
    df["Dataset"] = source
    df["Dimension"] = detect_dimension(df, source)
    for col in ["Academic Year", "Year Level", "Typical Level Flag", *RATE_COLUMNS, *COUNT_COLUMNS]:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")
    df["Post 2020"] = (df["Academic Year"] >= 2020).astype(int)
    df["Year Trend"] = df["Academic Year"] - df["Academic Year"].min()
    return df


@st.cache_data(show_spinner=False)
def load_default_data() -> dict[str, pd.DataFrame]:
    data = {}
    data_dir = LOCAL_DATA_DIR if LOCAL_DATA_DIR.exists() else LEGACY_DATA_DIR
    for label, filename in DEFAULT_FILES.items():
        path = data_dir / filename
        if path.exists():
            frame = clean_frame(pd.read_csv(path), label)
            frame.attrs["display_name"] = filename
            data[label] = frame
    return data


def load_uploaded_data(uploaded_files) -> dict[str, pd.DataFrame]:
    data = {}
    for file in uploaded_files:
        name = Path(file.name).stem
        label = f"Uploaded: {name}"
        for candidate in DEFAULT_FILES:
            if candidate.lower().replace(" ", "-") in name.lower():
                label = candidate
                break
        frame = clean_frame(pd.read_csv(file), label)
        frame.attrs["display_name"] = file.name
        data[label] = frame
    return data


def format_pct(value: float) -> str:
    if pd.isna(value):
        return ""
    return f"{value:.1%}"


def weighted_mean(values: pd.Series, weights: pd.Series) -> float:
    mask = values.notna() & weights.notna() & (weights > 0)
    if not mask.any():
        return np.nan
    return float(np.average(values[mask], weights=weights[mask]))


def design_matrix(df: pd.DataFrame, target: str, predictors: list[str]) -> tuple[pd.Series, pd.DataFrame, pd.Series]:
    model_df = df.dropna(subset=[target, "Total Student Count"]).copy()
    y = model_df[target]
    weights = model_df["Total Student Count"].clip(lower=1)
    parts = [pd.Series(1.0, index=model_df.index, name="Intercept")]

    for predictor in predictors:
        if predictor in ["Academic Year", "Year Trend", "Post 2020", "Typical Level Flag"]:
            parts.append(pd.to_numeric(model_df[predictor], errors="coerce").rename(predictor))
        elif predictor in model_df.columns:
            dummies = pd.get_dummies(model_df[predictor].astype(str), prefix=predictor, drop_first=True)
            parts.append(dummies)

    x = pd.concat(parts, axis=1)
    keep = x.notna().all(axis=1)
    return y[keep], x[keep].astype(float), weights[keep]


def fit_wls(y: pd.Series, x: pd.DataFrame, weights: pd.Series, weighted: bool) -> pd.DataFrame:
    y_arr = y.to_numpy(dtype=float)
    x_arr = x.to_numpy(dtype=float)
    w = weights.to_numpy(dtype=float) if weighted else np.ones(len(y_arr))
    sqrt_w = np.sqrt(w)
    xw = x_arr * sqrt_w[:, None]
    yw = y_arr * sqrt_w

    beta, *_ = np.linalg.lstsq(xw, yw, rcond=None)
    fitted = x_arr @ beta
    resid = y_arr - fitted
    n = x_arr.shape[0]
    rank = np.linalg.matrix_rank(xw)
    df_resid = max(n - rank, 1)
    sigma2 = float((w * resid**2).sum() / df_resid)
    xtwx_inv = np.linalg.pinv(xw.T @ xw)
    se = np.sqrt(np.diag(xtwx_inv) * sigma2)
    t_stat = np.divide(beta, se, out=np.full_like(beta, np.nan), where=se > 0)

    ssr = float((w * resid**2).sum())
    centered = y_arr - np.average(y_arr, weights=w)
    tss = float((w * centered**2).sum())
    r2 = 1 - ssr / tss if tss > 0 else np.nan

    result = pd.DataFrame(
        {
            "term": x.columns,
            "coefficient": beta,
            "std_error": se,
            "t_stat": t_stat,
        }
    )
    result["coefficient_pp"] = result["coefficient"] * 100
    result.attrs["nobs"] = n
    result.attrs["r2"] = r2
    result.attrs["weighted"] = weighted
    return result


def main() -> None:
    with st.sidebar:
        st.header("Data")
        default_data = load_default_data()
        uploaded = st.file_uploader("Upload CSV files", type="csv", accept_multiple_files=True)
        data = load_uploaded_data(uploaded) if uploaded else default_data
        if default_data:
            st.success(f"Loaded {len(default_data)} default CSV files.")
        else:
            st.warning("The default data folder was not found. Please upload CSV files.")

        if not data:
            st.stop()

        dataset_name = st.selectbox("Analysis dimension", list(data.keys()))
        df = data[dataset_name]
        rate_col = st.selectbox("Outcome variable", RATE_COLUMNS)
        qualification = st.multiselect(
            "Qualification",
            sorted(df["Qualification"].dropna().unique()),
            default=sorted(df["Qualification"].dropna().unique()),
        )
        year_levels = st.multiselect(
            "Year Level",
            sorted(df["Year Level"].dropna().unique()),
            default=sorted(df["Year Level"].dropna().unique()),
        )

    filtered = df[
        df["Qualification"].isin(qualification)
        & df["Year Level"].isin(year_levels)
    ].copy()

    dimension = detect_dimension(filtered, dataset_name)
    group_col = dimension if dimension in filtered.columns and dimension != "National" else None

    st.title("Education Data Econometrics Explorer")
    display_name = df.attrs.get("display_name", dataset_name)
    st.caption(f"Current dataset: {display_name}")
    st.markdown("Interactive descriptive statistics, group comparisons, trends, and weighted regression.")

    tabs = st.tabs(["Overview", "Trends and Gaps", "Regression Model", "Teaching Notes"])

    with tabs[0]:
        c1, c2, c3, c4 = st.columns(4)
        c1.metric("Observations", f"{len(filtered):,}")
        c2.metric("Year Range", f"{int(filtered['Academic Year'].min())}-{int(filtered['Academic Year'].max())}")
        c3.metric(
            "Mean Cumulative Rate",
            format_pct(weighted_mean(filtered["Cumulative Year Attainment Rate"], filtered["Total Student Count"])),
        )
        c4.metric(
            "Mean Current-Year Rate",
            format_pct(weighted_mean(filtered["Current Year Attainment Rate"], filtered["Total Student Count"])),
        )

        st.subheader("Data Preview")
        st.dataframe(filtered.head(50), use_container_width=True)

        st.subheader("Variable Guide")
        st.markdown(
            """
            - `Cumulative Year Attainment Rate`: the share of students who had attained Level 1 literacy or numeracy by that year.
            - `Current Year Attainment Rate`: the share of students attaining the requirement in the current academic year.
            - `Total Student Count`: the number of students in the group; this can be used as a regression weight.
            - `Typical Level Flag`: an indicator for whether the year level is the typical assessment level.
            """
        )

    with tabs[1]:
        st.subheader("Annual Trend")
        line_group = ["Academic Year", "Qualification"]
        if group_col:
            selected_groups = st.multiselect(
                f"Select {group_col}",
                sorted(filtered[group_col].dropna().astype(str).unique()),
                default=sorted(filtered[group_col].dropna().astype(str).unique())[:6],
            )
            chart_df = filtered[filtered[group_col].astype(str).isin(selected_groups)].copy()
            line_group.append(group_col)
        else:
            chart_df = filtered.copy()

        trend = (
            chart_df.groupby(line_group, dropna=False)
            .apply(lambda g: weighted_mean(g[rate_col], g["Total Student Count"]))
            .reset_index(name=rate_col)
        )
        st.line_chart(trend, x="Academic Year", y=rate_col, color=line_group[-1])

        st.subheader("Group Differences")
        if group_col:
            gap_table = (
                filtered.groupby(group_col)
                .apply(lambda g: weighted_mean(g[rate_col], g["Total Student Count"]))
                .reset_index(name="Weighted Mean Rate")
                .sort_values("Weighted Mean Rate", ascending=False)
            )
            gap_table["Weighted Mean Rate"] = gap_table["Weighted Mean Rate"].map(format_pct)
            st.dataframe(gap_table, use_container_width=True)
        else:
            st.info("The National dataset has no additional grouping variable. Try Region, Ethnicity, Gender, or School Equity Index Group.")

    with tabs[2]:
        st.subheader("Weighted Least Squares Regression")
        st.markdown(
            "This model uses an attainment rate as the outcome. By default, observations are weighted by student count, because a group of 20 students and a group of 20,000 students carry different amounts of information."
        )

        candidate_predictors = ["Year Trend", "Post 2020", "Academic Year", "Qualification", "Year Level", "Typical Level Flag"]
        if group_col:
            candidate_predictors.append(group_col)
        predictors = st.multiselect(
            "Select predictors or fixed effects",
            candidate_predictors,
            default=[p for p in ["Year Trend", "Post 2020", "Qualification", "Year Level", group_col] if p],
        )
        weighted = st.checkbox("Weighted by Total Student Count", value=True)

        if len(filtered) <= len(predictors) + 2:
            st.warning("There are too few observations after filtering. Try fewer filters or fewer predictors.")
        else:
            y, x, weights = design_matrix(filtered, rate_col, predictors)
            if len(y) <= x.shape[1]:
                st.warning("The model has too few degrees of freedom. Try removing some predictors.")
            else:
                result = fit_wls(y, x, weights, weighted)
                st.write(f"Observations: {result.attrs['nobs']:,} | R-squared: {result.attrs['r2']:.3f}")
                show = result.copy()
                show["coefficient"] = show["coefficient"].map(lambda v: f"{v:.4f}")
                show["std_error"] = show["std_error"].map(lambda v: f"{v:.4f}")
                show["t_stat"] = show["t_stat"].map(lambda v: f"{v:.2f}")
                show["coefficient_pp"] = show["coefficient_pp"].map(lambda v: f"{v:.2f}")
                st.dataframe(show, use_container_width=True)

                st.markdown(
                    """
                    Interpretation guide:
                    - `Year Trend`, multiplied by 100, is the average annual change in the attainment rate in percentage points.
                    - `Post 2020` captures the average difference after 2020 relative to earlier years.
                    - Group dummy coefficients are interpreted relative to the omitted reference group.
                    - These are associations in aggregated data. They should not be interpreted as individual-level causal effects.
                    """
                )

    with tabs[3]:
        st.subheader("Suggested Presentation Flow")
        st.markdown(
            """
            1. Start with the research question, for example: did Level 1 literacy or numeracy attainment change after 2020?
            2. Define the unit of observation: academic year by qualification, year level, and group.
            3. Show trends before running regression models.
            4. Compare cumulative and current-year attainment rates.
            5. Use student-count weights so very small groups do not dominate the analysis.
            6. Add fixed effects to test whether the main patterns are stable.
            7. Be explicit about limitations: aggregated data, possible policy changes, pandemic disruption, assessment changes, and changes in student composition.
            """
        )


if __name__ == "__main__":
    main()
