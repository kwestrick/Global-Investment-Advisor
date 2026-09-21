# Methodology

## Research Philosophy

The Global Investment Advisor project uses a comparative, evidence-driven framework to evaluate global investment opportunities against U.S. alternatives. The process is designed to avoid both U.S.-centric bias and indiscriminate enthusiasm for foreign markets.

The methodology combines:

- Relative valuation
- Macro regime analysis
- Currency analysis
- Geopolitical risk assessment
- Sector and factor exposure
- Liquidity and implementation review
- Scenario analysis
- Falsification discipline

## Research Process

### Define the Question

Every analysis should begin with a clearly stated question. Examples:

- Are Japanese equities likely to outperform the S&P 500 over the next 12 to 36 months?
- Are Latin American local-currency bonds attractive relative to U.S. Treasuries?
- Are European defense stocks still underpriced relative to U.S. defense contractors?
- Is India worth its valuation premium relative to other emerging markets?

### Define the Benchmark

The benchmark should be selected before the conclusion is formed. This prevents the analysis from cherry-picking favorable comparisons.

Examples:

- Country equity ETF versus S&P 500
- Regional ETF versus MSCI USA
- Local-currency bond index versus U.S. Treasuries
- Commodity producer basket versus U.S. energy or materials sector
- Currency exposure versus U.S. dollar cash

### Define the Time Horizon

Each thesis should have a stated time horizon:

- Tactical: 0 to 6 months
- Cyclical: 6 to 24 months
- Strategic: 2 to 5 years
- Structural: 5 years or more

The evidence required depends on the horizon. Tactical calls need near-term catalysts and positioning analysis. Strategic theses need deeper structural support.

### Gather Evidence

Evidence should be grouped into:

- Market data
- Valuation data
- Macro data
- Earnings or cash-flow data
- Policy and geopolitical information
- Currency and liquidity information
- Implementation details

### Evaluate the Thesis

The analysis should separate:

- What the data says
- What the interpretation is
- What remains speculative
- What would falsify the view

### Compare Against U.S. Alternatives

Each conclusion should explicitly answer:

- Why might this outperform the U.S.?
- What U.S. asset is the fair comparison?
- Is the opportunity better because of valuation, growth, yield, currency, policy, or diversification?
- Is the expected return sufficient to compensate for liquidity, political, currency, and implementation risks?

## Quantitative Methods

Suggested quantitative methods include:

- Total return comparison
- Rolling return windows
- Drawdown analysis
- Volatility and Sharpe ratio
- Correlation to U.S. equities and bonds
- Currency-adjusted returns
- Valuation percentile ranking
- Momentum ranking
- Relative strength analysis
- Macro z-scores
- Composite scoring models

## Example R Workflow

```r
library(tidyverse)
library(tidyquant)
library(lubridate)
library(PerformanceAnalytics)

tickers <- c(
  "SPY",  # U.S. equity benchmark
  "VEA",  # developed markets ex-U.S.
  "VWO",  # emerging markets
  "EWJ",  # Japan
  "INDA", # India
  "EWZ",  # Brazil
  "EWW"   # Mexico
)

prices <- tq_get(
  tickers,
  from = "2015-01-01",
  to = Sys.Date()
)

returns <- prices %>%
  group_by(symbol) %>%
  arrange(date) %>%
  mutate(daily_return = adjusted / lag(adjusted) - 1) %>%
  ungroup()

summary_returns <- returns %>%
  group_by(symbol) %>%
  summarize(
    annualized_return = mean(daily_return, na.rm = TRUE) * 252,
    annualized_volatility = sd(daily_return, na.rm = TRUE) * sqrt(252),
    sharpe_proxy = annualized_return / annualized_volatility,
    .groups = "drop"
  )
```

## Qualitative Methods

Qualitative assessment should include:

- Political regime stability
- Policy credibility
- Sanctions or capital-control risk
- Trade exposure
- Energy security
- Military conflict risk
- Social stability
- Reform momentum
- Institutional quality
- Investor positioning and narrative crowding

## Scenario Analysis

Each memo should include at least three scenarios:

| Scenario | Description | Expected Outcome | Probability |
|---|---|---|---:|
| Bull | Thesis works better than expected | Strong outperformance | TBD |
| Base | Main thesis plays out gradually | Moderate outperformance or diversification value | TBD |
| Bear | Key assumptions fail | Underperformance or capital loss | TBD |

Scenario probabilities should be treated as subjective estimates, not precise forecasts.

## Review Cadence

Suggested review cadence:

- Tactical theses: weekly to monthly
- Cyclical theses: monthly to quarterly
- Strategic theses: quarterly to semiannual
- Structural theses: semiannual to annual

Review triggers:

- Major policy change
- Currency shock
- Earnings revision inflection
- War, sanctions, or major geopolitical event
- Liquidity breakdown
- Valuation gap closes
- U.S. benchmark risk/reward changes materially

## Final Standard

The project should produce conclusions that are clear, testable, and humble. A good conclusion states not only what may work, but why it may fail.

Every investment research output should end with:

This is research and analysis only, not personalized financial advice. Consult a qualified financial advisor before making investment decisions.
