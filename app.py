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


def format_pp(value: float) -> str:
    if pd.isna(value):
        return ""
    return f"{value * 100:+.1f} pp"


def weighted_mean(values: pd.Series, weights: pd.Series) -> float:
    mask = values.notna() & weights.notna() & (weights > 0)
    if not mask.any():
        return np.nan
    return float(np.average(values[mask], weights=weights[mask]))


def weighted_rate_by(df: pd.DataFrame, group_cols: list[str], rate_col: str) -> pd.DataFrame:
    return (
        df.groupby(group_cols, dropna=False)
        .apply(lambda g: weighted_mean(g[rate_col], g["Total Student Count"]))
        .reset_index(name=rate_col)
    )


def latest_weighted_rate(df: pd.DataFrame, rate_col: str) -> tuple[int | None, float]:
    if df.empty or "Academic Year" not in df:
        return None, np.nan
    latest_year = int(df["Academic Year"].max())
    latest = df[df["Academic Year"] == latest_year]
    return latest_year, weighted_mean(latest[rate_col], latest["Total Student Count"])


def earliest_weighted_rate(df: pd.DataFrame, rate_col: str) -> tuple[int | None, float]:
    if df.empty or "Academic Year" not in df:
        return None, np.nan
    earliest_year = int(df["Academic Year"].min())
    earliest = df[df["Academic Year"] == earliest_year]
    return earliest_year, weighted_mean(earliest[rate_col], earliest["Total Student Count"])


def latest_group_gap(df: pd.DataFrame, group_col: str | None, rate_col: str) -> tuple[pd.DataFrame, float]:
    if not group_col or group_col not in df.columns or df.empty:
        return pd.DataFrame(), np.nan
    latest_year = int(df["Academic Year"].max())
    latest = df[df["Academic Year"] == latest_year]
    table = (
        latest.groupby(group_col)
        .apply(lambda g: weighted_mean(g[rate_col], g["Total Student Count"]))
        .reset_index(name="Weighted Rate")
        .sort_values("Weighted Rate", ascending=False)
    )
    if len(table) < 2:
        return table, np.nan
    return table, float(table["Weighted Rate"].max() - table["Weighted Rate"].min())


def gap_change_over_time(df: pd.DataFrame, group_col: str | None, rate_col: str) -> tuple[int | None, float, int | None, float, float]:
    if not group_col or group_col not in df.columns or df.empty:
        return None, np.nan, None, np.nan, np.nan
    first_year = int(df["Academic Year"].min())
    latest_year = int(df["Academic Year"].max())
    gaps = []
    for year in [first_year, latest_year]:
        year_df = df[df["Academic Year"] == year]
        table = (
            year_df.groupby(group_col)
            .apply(lambda g: weighted_mean(g[rate_col], g["Total Student Count"]))
            .reset_index(name="Weighted Rate")
        )
        if len(table) < 2:
            gaps.append(np.nan)
        else:
            gaps.append(float(table["Weighted Rate"].max() - table["Weighted Rate"].min()))
    return first_year, gaps[0], latest_year, gaps[1], gaps[1] - gaps[0]


def literacy_numeracy_gap(df: pd.DataFrame, rate_col: str) -> tuple[int | None, float, str]:
    if df.empty or "Qualification" not in df.columns:
        return None, np.nan, "Not enough data to compare literacy and numeracy."
    latest_year = int(df["Academic Year"].max())
    latest = df[df["Academic Year"] == latest_year]
    table = (
        latest.groupby("Qualification")
        .apply(lambda g: weighted_mean(g[rate_col], g["Total Student Count"]))
        .reset_index(name="Weighted Rate")
    )
    if len(table) < 2:
        return latest_year, np.nan, "Select both literacy and numeracy to compare them."
    rates = dict(zip(table["Qualification"], table["Weighted Rate"]))
    literacy = rates.get("Level 1 Literacy")
    numeracy = rates.get("Level 1 Numeracy")
    if literacy is None or numeracy is None:
        return latest_year, np.nan, "This dataset does not contain both Level 1 Literacy and Level 1 Numeracy."
    gap = literacy - numeracy
    if gap > 0:
        interpretation = f"Literacy is higher than numeracy by {format_pp(gap)} in {latest_year}."
    elif gap < 0:
        interpretation = f"Numeracy is higher than literacy by {format_pp(abs(gap))} in {latest_year}."
    else:
        interpretation = f"Literacy and numeracy are almost identical in {latest_year}."
    return latest_year, gap, interpretation


def pre_post_2020_difference(df: pd.DataFrame, rate_col: str) -> tuple[float, str]:
    before = df[df["Academic Year"] < 2020]
    after = df[df["Academic Year"] >= 2020]
    if before.empty or after.empty:
        return np.nan, "Not enough years to compare pre-2020 and post-2020 periods."
    before_rate = weighted_mean(before[rate_col], before["Total Student Count"])
    after_rate = weighted_mean(after[rate_col], after["Total Student Count"])
    diff = after_rate - before_rate
    direction = "higher" if diff > 0 else "lower" if diff < 0 else "similar"
    return diff, f"The post-2020 weighted average is {direction} than the pre-2020 average by {format_pp(diff)}."


def cohort_warning_summary(df: pd.DataFrame) -> str:
    if "Cohort Warning" not in df.columns:
        return "This dataset does not include a cohort-warning field."
    warnings = df["Cohort Warning"].fillna("").astype(str).str.strip()
    count = int((warnings != "").sum())
    if count == 0:
        return "No cohort warnings are flagged in the current filtered data."
    share = count / len(df)
    return f"{count:,} observations ({share:.1%}) have cohort warnings and should be interpreted with extra care."


def answer_card(question: str, answer: str, why_it_matters: str) -> None:
    st.markdown(f"**{question}**")
    st.info(answer)
    st.caption(why_it_matters)


def high_level_takeaway(df: pd.DataFrame, group_col: str | None, rate_col: str) -> str:
    first_year, first_rate = earliest_weighted_rate(df, rate_col)
    latest_year, latest_rate = latest_weighted_rate(df, rate_col)
    if first_year is None or latest_year is None:
        return "Upload a compatible CSV to generate a high-level interpretation."
    change = latest_rate - first_rate
    direction = "improved" if change > 0 else "declined" if change < 0 else "remained almost unchanged"
    base = (
        f"From {first_year} to {latest_year}, the selected attainment rate {direction} "
        f"by {format_pp(change)}."
    )
    _, gap = latest_group_gap(df, group_col, rate_col)
    if group_col and not pd.isna(gap):
        base += f" In {latest_year}, the spread across {group_col.lower()} groups was {format_pp(gap)}."
    return base


def required_columns_available(df: pd.DataFrame) -> bool:
    required = {"Academic Year", "Qualification", "Year Level", "Total Student Count", *RATE_COLUMNS}
    return required.issubset(df.columns)


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
        if not required_columns_available(df):
            st.error(
                "This file is missing one or more required columns: Academic Year, Qualification, "
                "Year Level, Total Student Count, Cumulative Year Attainment Rate, and Current Year Attainment Rate."
            )
            st.stop()
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

    if filtered.empty:
        st.warning("No observations match the current filters. Please adjust the sidebar selections.")
        st.stop()

    dimension = detect_dimension(filtered, dataset_name)
    group_col = dimension if dimension in filtered.columns and dimension != "National" else None

    st.title("Education Data Econometrics Explorer")
    display_name = df.attrs.get("display_name", dataset_name)
    st.caption(f"Current dataset: {display_name}")
    st.markdown(
        "A deployable prototype that turns structured education data into interpretable trends, "
        "equity comparisons, and transparent statistical models."
    )

    tabs = st.tabs(["Executive Summary", "Question Map", "Overview", "Trends and Gaps", "Regression Model", "IDI Pathway"])

    with tabs[0]:
        st.subheader("What This Prototype Shows")
        first_year, first_rate = earliest_weighted_rate(filtered, rate_col)
        latest_year, latest_rate = latest_weighted_rate(filtered, rate_col)
        group_table, latest_gap = latest_group_gap(filtered, group_col, rate_col)
        c1, c2, c3, c4 = st.columns(4)
        c1.metric("Data Window", f"{first_year}-{latest_year}")
        c2.metric("Latest Weighted Rate", format_pct(latest_rate))
        c3.metric("Change Since Start", format_pp(latest_rate - first_rate))
        c4.metric("Latest Group Spread", format_pp(latest_gap) if group_col else "N/A")

        st.info(high_level_takeaway(filtered, group_col, rate_col))

        st.markdown(
            """
            This is not just a charting page. It demonstrates a repeatable analytical workflow:
            upload structured education data, define the outcome, compare groups, estimate a
            transparent weighted model, and translate results into questions that school leaders,
            researchers, and policy users can discuss.
            """
        )

        st.subheader("Why It Has Entrepreneurial Value")
        st.markdown(
            """
            - **Repeatable method**: the same analytical recipe can be reused across datasets.
            - **Low-friction communication**: non-technical users can inspect trends and gaps without reading code.
            - **Trust by design**: the app separates descriptive evidence from causal claims.
            - **Scalable pathway**: the prototype can move from public aggregated data to secure de-identified microdata.
            """
        )

        if group_col and not group_table.empty:
            st.subheader(f"Latest {group_col} Ranking")
            display_gap = group_table.copy()
            display_gap["Weighted Rate"] = display_gap["Weighted Rate"].map(format_pct)
            st.dataframe(display_gap, use_container_width=True)

    with tabs[1]:
        st.subheader("NCEA Question Map")
        st.markdown(
            """
            This page turns the dashboard into a set of research and decision questions.
            Each question is answerable from the current filtered data and can later become
            a reusable analytical recipe for other education datasets.
            """
        )

        first_year, first_rate = earliest_weighted_rate(filtered, rate_col)
        latest_year, latest_rate = latest_weighted_rate(filtered, rate_col)
        change = latest_rate - first_rate
        _, start_gap, _, end_gap, gap_delta = gap_change_over_time(filtered, group_col, rate_col)
        _, _, ln_interpretation = literacy_numeracy_gap(filtered, rate_col)
        pre_post_diff, pre_post_text = pre_post_2020_difference(filtered, rate_col)

        q1, q2 = st.columns(2)
        with q1:
            answer_card(
                "1. Has attainment changed over time?",
                f"From {first_year} to {latest_year}, the selected weighted attainment rate changed by {format_pp(change)}.",
                "This is the first macro signal: it tells the audience whether the system-level indicator is moving up, down, or staying flat.",
            )
        with q2:
            if group_col and not pd.isna(end_gap):
                answer = (
                    f"The latest spread across {group_col.lower()} groups is {format_pp(end_gap)}. "
                    f"Since {first_year}, the spread changed by {format_pp(gap_delta)}."
                )
            else:
                answer = "Select a grouped dataset such as Region, Ethnicity, Gender, or School Equity Index Group to calculate group gaps."
            answer_card(
                "2. Are group gaps widening or narrowing?",
                answer,
                "Averages can hide equity problems. Gap tracking shows whether differences between groups are becoming larger or smaller.",
            )

        q3, q4 = st.columns(2)
        with q3:
            answer_card(
                "3. Is literacy different from numeracy?",
                ln_interpretation,
                "This separates two outcomes that are often discussed together but may follow different patterns.",
            )
        with q4:
            answer_card(
                "4. What changed after 2020?",
                pre_post_text,
                "This is a structured before-after comparison, not a causal estimate. It creates a disciplined starting point for deeper research.",
            )

        st.subheader("Data Quality Check")
        st.warning(cohort_warning_summary(filtered))
        st.markdown(
            """
            **How to pitch this page:** the value is not only that the app draws charts.
            It converts a dataset into a map of questions, answers, cautions, and next steps.
            That is the core of an analytical recipe.
            """
        )

        question_table = pd.DataFrame(
            [
                {
                    "Question": "Has attainment changed over time?",
                    "Evidence used": "Earliest and latest weighted attainment rates",
                    "Next step": "Add confidence intervals or cohort-size sensitivity checks",
                },
                {
                    "Question": "Are group gaps widening or narrowing?",
                    "Evidence used": "Highest-minus-lowest group spread over time",
                    "Next step": "Track persistent gaps by region, ethnicity, gender, and equity index",
                },
                {
                    "Question": "Is literacy different from numeracy?",
                    "Evidence used": "Latest literacy-numeracy weighted rate difference",
                    "Next step": "Identify groups with the largest literacy-numeracy gaps",
                },
                {
                    "Question": "What changed after 2020?",
                    "Evidence used": "Pre/post weighted average difference",
                    "Next step": "Move from descriptive comparison to research design",
                },
            ]
        )
        st.dataframe(question_table, use_container_width=True)

    with tabs[2]:
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

    with tabs[3]:
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

    with tabs[4]:
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

    with tabs[5]:
        st.subheader("Pathway From Prototype To Secure Microdata")
        st.markdown(
            """
            This NCEA version uses aggregated public-style data. That makes it suitable for a
            safe demonstration, but it cannot answer student-level questions about pathways,
            transitions, or long-run outcomes.

            The next research and product step is to adapt the same workflow to de-identified
            student-level longitudinal data, such as secure administrative microdata. The value
            proposition is not only the dashboard. It is the reusable pipeline:

            1. define a research question,
            2. map raw administrative fields into analysis-ready variables,
            3. produce transparent descriptive evidence,
            4. estimate cautious statistical models,
            5. communicate findings through a web interface,
            6. keep privacy and governance visible at every stage.
            """
        )

        st.subheader("How To Explain The Demo")
        st.markdown(
            """
            A simple 30-second explanation:

            > This app takes structured education data and turns it into a transparent analytical
            > workflow. It shows trends, group differences, and weighted regression results. It
            > does not claim to prove causality from aggregated data. Instead, it demonstrates how
            > a repeatable analytical recipe can help schools, researchers, and policy teams move
            > faster from spreadsheets to evidence-informed questions.
            """
        )


if __name__ == "__main__":
    main()
