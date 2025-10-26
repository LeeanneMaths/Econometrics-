# =============== Replication: data_cleaning.py ===============
import pandas as pd
import matplotlib.pyplot as plt
import ruptures as rpt

# Step 1: Load data
df = pd.read_csv(r"D:\8002 Assignment\replication_1970_2007_wage_productivity_inflation.csv")

# Step 2: Variable selection
X = df[["b_wage", "b_infl"]].values
y = df["b_cons"].values
years = df["year"].values

# Step 3: Bai–Perron break detection (using PELT method)
algo = rpt.Pelt(model="l2").fit(y)
breaks = algo.predict(pen=3)
break_years = [years[i - 1] for i in breaks if i - 1 < len(years)]

# Step 4: Plotting
plt.figure(figsize=(10, 5), dpi=300)
plt.plot(years, df["b_wage"], label="ln(Real Wage)", color="darkred", linewidth=1.8)
plt.plot(years, df["b_infl"], label="Inflation", color="seagreen", linewidth=1.8)

# Breakpoint lines and text
ymax = max(df["b_wage"].max(), df["b_infl"].max())
for i, b_year in enumerate(break_years):
    plt.axvline(x=b_year, color="blue", linestyle="--", linewidth=1)
    
    label_x = b_year - 2 if b_year > years.max() - 1 else b_year + 0.3
    label_y = ymax * (0.82 if i % 2 == 0 else 0.7)
    
    plt.text(label_x, label_y, f"Break: {int(b_year)}", color="blue", fontsize=6)

# Axis and legend
plt.title("Rolling Regression Coefficients and Bai–Perron Breaks Test for Extension", fontsize=9)
plt.xlabel("Year", fontsize=8)
plt.ylabel("Coefficient Value", fontsize=8)
plt.grid(True, linestyle='--', alpha=0.6)
plt.legend(fontsize=7, loc='lower left')
plt.xticks(fontsize=7)
plt.yticks(fontsize=7)
plt.tight_layout()

# Save and display
output_path = r"D:\8002 Assignment\replication_rolling_breaks_plot.png"
plt.savefig(output_path, dpi=300)
print(f"✅ Final plot saved to: {output_path}")
plt.show()

# =============== Manufacture: data_cleaning.py ===============
import pandas as pd
import matplotlib.pyplot as plt
import ruptures as rpt

# Step 1: Load the updated rolling regression data
df = pd.read_csv(r"D:\8002 Assignment\1990_2022_manufacture_wage_productivity_inflation.csv")

# Step 2: Use midpoint year if not already present
if 'year' in df.columns:
    years = df['year'].values
else:
    df['year'] = (df['start'] + df['end']) / 2
    years = df['year'].values

# Step 3: Variables to analyze
X = df[["b_wage", "b_infl"]].values
y = df["b_cons"].values  # structural change base

# Step 4: Structural break detection (Bai–Perron via PELT)
algo = rpt.Pelt(model="l2").fit(y)
breaks = algo.predict(pen=3)
break_years = [years[i - 1] for i in breaks if i - 1 < len(years)]

# Step 5: Plotting results
plt.figure(figsize=(12, 6), dpi=150)
plt.plot(years, df["b_wage"], label="ln(Real Wage)", color="darkred", linewidth=2)
plt.plot(years, df["b_infl"], label="Inflation", color="seagreen", linewidth=2)

# Step 6: Plot breakpoints with labels
ymax = max(df["b_wage"].max(), df["b_infl"].max())
for i, b_year in enumerate(break_years):
    plt.axvline(x=b_year, color="blue", linestyle="--", linewidth=1)
    label_x = b_year + 0.2 if b_year < years.max() - 1 else b_year - 0.8
    label_y = ymax * (0.84 if i % 2 == 0 else 0.7)
    plt.text(label_x, label_y, f"Break: {int(b_year)}", color="blue", fontsize=9)

# Step 7: Formatting
plt.title("Structural Breaks in Manufacturing Sector (1990–2022)", fontsize=12)
plt.xlabel("Year", fontsize=10)
plt.ylabel("Coefficient Value", fontsize=10)
plt.xlim(1990, 2022)
plt.grid(True, linestyle='--', alpha=0.6)
plt.legend(fontsize=9, loc='lower left')
plt.tight_layout()

# Step 8: Save plot
output_path = r"D:\8002 Assignment\1990-2022 manufacture_rolling_breaks_plot.png"
plt.savefig(output_path, dpi=300)
print(f"✅ Final plot saved to: {output_path}")
plt.show()

# ===============All industries: data_cleaning.py ===============

import pandas as pd
import matplotlib.pyplot as plt
import ruptures as rpt

# Step 1: Load the exported rolling regression data
df = pd.read_csv(r"D:\8002 Assignment\all_industries_wage_productivity_inflation.csv")

# Step 2: If 'window_mid' does not exist, create it as (start + end) / 2
if 'window_mid' not in df.columns:
    df['window_mid'] = (df['start'] + df['end']) / 2

# Step 3: Define independent variables (b_wage and b_infl) and the target (residual-like term b_cons)
X = df[["b_wage", "b_infl"]].values
y = df["b_cons"].values  # Use b_cons if analyzing structural breaks
years = df["window_mid"].values  # <-- now correctly based on midpoint

# Step 4: Fit a Bai–Perron test to detect structural breaks in b_cons
algo = rpt.Pelt(model="l2").fit(y)
breaks = algo.predict(pen=3)  # Penalty controls the number of breaks
break_years = [years[i - 1] for i in breaks if i - 1 < len(years)]

# Step 5: Plot the rolling coefficients and detected breakpoints
plt.figure(figsize=(12, 6), dpi=300)

plt.plot(years, df["b_wage"], label="ln(Wage)", color="red", linewidth=1.5)
plt.plot(years, df["b_infl"], label="Inflation", color="green", linewidth=1.5)

# Add vertical lines for breakpoints
for b_year in break_years:
    plt.axvline(x=b_year, color="blue", linestyle="--", linewidth=1)
    plt.text(b_year + 0.2, max(df["b_wage"].max(), df["b_infl"].max()) * 0.9,
             f"Break: {int(b_year)}", color="blue", fontsize=8)

plt.title("Rolling Regression Coefficients and Bai–Perron Breaks of all industries", fontsize=12)
plt.xlabel("Year", fontsize=10)
plt.ylabel("Coefficient Value", fontsize=10)
plt.grid(True)
plt.legend(fontsize=9)
plt.tight_layout()

# Step 6: Save the figure
output_path = r"D:\8002 Assignment\all_industries rolling_breaks_plot.png"
plt.savefig(output_path, dpi=300)
print(f"✅ Plot saved to: {output_path}")




