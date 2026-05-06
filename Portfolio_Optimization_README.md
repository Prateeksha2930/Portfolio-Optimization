# 📈 Financial Data Analysis & Portfolio Optimization

> **End-to-end equity data pipeline and Mean-Variance portfolio optimization using PostgreSQL and R**

---

## 📌 Project Overview

This project builds a complete financial data analysis and portfolio optimization pipeline from scratch. Using five years of historical equity market data, we design a custom ETL workflow, validate and transform time-series price data, and apply **Modern Portfolio Theory (Mean-Variance Optimization)** to construct an optimal investment portfolio — then rigorously evaluate its out-of-sample performance to understand the real-world limitations of historical return-based strategies.

---

## 🎯 Objectives

- Design and implement an ETL pipeline for equity market data with a custom trading calendar
- Clean, validate, and transform raw price data into daily log returns suitable for portfolio modeling
- Conduct exploratory data analysis to assess return distributions, correlations, and diversification potential
- Apply constrained Mean-Variance Optimization to construct an efficient portfolio
- Evaluate out-of-sample portfolio performance against benchmarks and identify key model limitations

---

## 🛠️ Tech Stack

| Category | Tools |
|----------|-------|
| **Database** | PostgreSQL |
| **Language** | R |
| **Data Manipulation** | `dplyr`, `tidyr`, `lubridate` |
| **Database Connection** | `DBI`, `RPostgres` |
| **Visualization** | `ggplot2` |
| **Portfolio Optimization** | `quadprog`, `PortfolioAnalytics` |
| **Time-Series** | `xts`, `zoo` |

---

## 📊 Dataset

- **Source**: Historical daily equity price data for multiple stock tickers
- **Time Period**: 5 years of daily trading data
- **Structure**: Date, Ticker, Open, High, Low, Close, Volume
- **Trading Calendar**: Custom NYSE calendar built to handle market holidays, early closures, and missing trading sessions

---

## 🔬 Methodology

### Step 1 – Database Design & ETL Pipeline (PostgreSQL)
- Designed a normalized PostgreSQL schema to store 5 years of daily equity price data across multiple tickers
- Built a **custom trading calendar** accounting for NYSE market holidays, early closures, and missing trading sessions to ensure data completeness
- Developed ETL scripts to ingest raw price data, validate schema integrity, and load clean records into the database
- Implemented automated data quality checks: duplicate detection, missing date identification, and price anomaly flagging

### Step 2 – Data Cleaning & Transformation (R)
- Extracted data from PostgreSQL into R using `DBI` and `RPostgres`
- **Filtering**: Removed tickers with incomplete price histories (fewer than 252 trading days per year)
- **Missing Values**: Applied forward-fill for isolated missing days; removed tickers with gaps exceeding 5 consecutive trading days
- **Daily Returns**: Calculated log returns using the formula: `r_t = log(P_t / P_{t-1})`
- **Outlier Removal**: Flagged and removed daily returns beyond ±5 standard deviations as likely data errors rather than genuine price movements

### Step 3 – Exploratory Data Analysis
- Computed and visualized the **correlation matrix** of asset returns to assess diversification potential across tickers
- Plotted return distributions, rolling 30-day volatility, and cumulative return curves for all assets
- Identified assets with low cross-correlation — ideal candidates for inclusion in an optimized portfolio
- Analyzed annualized return and volatility for each ticker to understand the risk-return profile of the investment universe

### Step 4 – Mean-Variance Portfolio Optimization
- Computed expected returns (annualized mean of daily log returns) and the variance-covariance matrix for all assets
- Applied **constrained Mean-Variance Optimization** using the `quadprog` package with the following constraints:
  - **Constraint 1**: Portfolio weights must sum to 1 (fully invested — no cash allocation)
  - **Constraint 2**: No short selling allowed (all weights ≥ 0)
  - **Constraint 3**: Maximum single-asset allocation capped at 30% to ensure diversification
- Generated the **Efficient Frontier** — the set of optimal portfolios offering the highest expected return for each level of risk
- Identified the **Minimum Variance Portfolio** (lowest risk) and **Maximum Sharpe Ratio Portfolio** (best risk-adjusted return)

### Step 5 – Out-of-Sample Evaluation
- Split data into a **training period (Years 1–4)** used to estimate model parameters and a **test period (Year 5)** for out-of-sample evaluation
- Applied optimized portfolio weights from the training period to actual test period returns
- Evaluated portfolio performance using: Annualized Return, Annualized Volatility, Sharpe Ratio, and Maximum Drawdown
- Compared results against two benchmarks: **S&P 500 index** and an **equal-weight portfolio** of the same assets

---

## 📈 Key Results

| Metric | Optimized Portfolio | Equal-Weight Portfolio | S&P 500 Benchmark |
|--------|--------------------|-----------------------|-------------------|
| Annualized Return | — | — | — |
| Annualized Volatility | — | — | — |
| Sharpe Ratio | — | — | — |
| Max Drawdown | — | — | — |

> *Exact figures available in the project report*

---

## 💡 Key Findings & Limitations

- **Mean-Variance Optimization is highly sensitive to input estimates** — small changes in expected return assumptions produce dramatically different portfolio weight allocations, a well-documented problem in financial literature known as "error maximization"
- **Out-of-sample performance degraded** relative to in-sample results, confirming that historical return patterns are an imperfect guide to future performance
- **Minimum Variance Portfolio outperformed Maximum Sharpe Ratio Portfolio** out-of-sample, suggesting that focusing on risk reduction rather than return maximization produces more stable results
- **The equal-weight portfolio** proved surprisingly competitive out-of-sample — highlighting the practical value of simplicity in portfolio construction
- **Future improvement**: Robust estimation techniques (e.g., shrinkage estimators like Ledoit-Wolf) and Black-Litterman framework could significantly improve out-of-sample stability

---

## 📬 Contact

**Prateeksha Mehta** | pratu2930@gmail.com | [LinkedIn](https://linkedin.com/in/prateeksha29) | [GitHub](https://github.com/Prateeksha2930)
