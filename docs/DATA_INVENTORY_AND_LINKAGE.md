# Data Inventory & Global-Insights-Dashboard Linkage

**Date:** September 21, 2026  
**Status:** Completed inventory; workflows operational

---

## Executive Summary

The Global Investment Advisor project is fully integrated with the Global-Insights-Dashboard (GID), which provides:

- **227,142 macro indicator observations** across 11 economic categories
- **135 unique global indicators** covering growth, inflation, policy, commodities, and markets
- **Historical data back to 2014** for deep time-series analysis
- **Real-time snapshots** (refreshed daily) for current conditions

This document inventories the available data and describes how it flows into the investment research workflow.

---

## Global-Insights-Dashboard Data Inventory

### File Location
```
/Users/kwestrick/Library/CloudStorage/Dropbox/MyBusiness/Development/RCode/Global-Insights-Dashboard/data/
```

### Available Files

#### 1. **indicators_long.rds** (227,142 observations)
Long-format time series of all macro indicators.

**Structure:**
| Column | Type | Example |
|--------|------|---------|
| `id` | character | "us_real_gdp_growth", "brent_crude_spot" |
| `name` | character | "US Real GDP Growth — GDPNow Nowcast" |
| `category` | character | "growth_output", "commodities_energy", "inflation" |
| `source` | character | "enrichment", "Federal Reserve", "CME" |
| `units` | character | "Percent (seasonally adjusted)", "USD per barrel" |
| `geography` | character | "US", "JP", "CN", "WORLD", "EA19" |
| `transform` | character | "none", "log", "percent_change" |
| `date` | date | 2014-05-01 to 2026-09-17 |
| `value` | numeric | Raw indicator value |

**Coverage:**
- Date range: 2014-05-01 to 2026-09-17
- Geographies: 17 unique (US, JP, GB, DE, FR, CN, IN, BR, and others)
- Unique indicators: ~135
- Data density: High (varies by indicator; most have monthly or higher frequency)

**Key Geographies:**
- **Developed markets:** US, JP, GB, DE, FR, CH, NL, CA, AU
- **Emerging markets:** CN, IN, BR, MX, KR, TW, ID, PH, VN, TR, SA, ZA, AR, CL, PL, GR
- **Regional aggregates:** EA19 (Eurozone 19), EA20, EMU

#### 2. **latest_snapshot.rds** (135 observations)
Current values for all tracked indicators.

**Structure:**
| Column | Type | Example |
|--------|------|---------|
| `id` | character | "bab_el_mandeb_transits", "brent_crude_spot" |
| `name` | character | "Bab el-Mandeb Transits" |
| `category` | character | "international_geopolitical", "commodities_energy" |
| `units` | character | "Count", "USD per barrel" |
| `geography` | character | "WORLD", "US" |
| `latest_date` | date | Most recent data point |
| `latest` | numeric | Current value |
| `prior` | numeric | Previous observation |
| `change` | numeric | Absolute change |
| `pct_change` | numeric | Percent change |
| `trend` | character | "up", "down", "stable" |
| `refreshed_at` | datetime | Last update timestamp |

**Use:** Quick reference for current conditions; good for "current macro environment" sections in memos.

#### 3. **podcast_feed.rds**
Summaries and metadata for geopolitical and macro commentary podcasts.

**Use:** Narrative context for geopolitical risk assessment; helps frame catalysts and risks.

#### 4. **newsletter_feed.rds** & newsletter/*.csv
Article feeds and digests covering global markets and geopolitical developments.

**Use:** Source material for narrative context, especially in "Geopolitical Catalysts" sections of memos.

---

## Indicator Categories

### Available Categories in indicators_long.rds

| Category | Description | Examples | Geographies |
|----------|-------------|----------|-------------|
| **growth_output** | Real economic growth and production | Real GDP growth, industrial production, PMI | All major |
| **inflation** | Price levels and inflation metrics | CPI, PPI, inflation expectations | All major |
| **monetary_financial** | Central bank policy and credit | Policy rates, money supply, lending | All major |
| **commodities_energy** | Oil, metals, agriculture, energy | Brent crude, copper, wheat, natural gas | WORLD, some regional |
| **labor** | Employment and wage indicators | Unemployment rate, wage growth, hours | Developed |
| **markets** | Financial market indicators | Stock indices, spreads, volatility | Global |
| **consumer_housing** | Household spending and real estate | Consumer confidence, housing starts, retail | Developed |
| **trade_external** | Trade balances and capital flows | Exports, imports, trade balance | Mostly developed |
| **fiscal_debt** | Government budgets and debt | Government debt, fiscal balance | Developed |
| **international_geopolitical** | Risk and geopolitical events | Strait transits, sanctions, conflicts | WORLD/specific regions |
| **leading_indicators** | Forward-looking economic signals | Yield curve, PMI, leading index | Global |

### Coverage by Geography

**Full Coverage (Most Categories):**
- US, Japan, China, Germany, India, Brazil, UK

**Partial Coverage (Selected Categories):**
- EA19 (Eurozone aggregate)
- EA20, EMU (Regional aggregates)
- Most other country-level data is by ETF price, not macro indicators

---

## Data Quality and Freshness

### Refresh Schedule
- **Market prices:** Updated daily via tidyquant (Yahoo Finance)
- **Macro indicators:** Updated by GID pipeline (typically daily to weekly)
- **Latest snapshot:** Updated daily
- **Podcast/newsletter feeds:** Updated weekly

### Data Completeness Issues
1. **Geopolitical events** (e.g., Bab el-Mandeb transits) are event-based, not always current
2. **Emerging market macro data** is sparser than developed market data
3. **Country-level labor data** is not available for all countries
4. **Real-time vs. published data:** Some indicators are nowcasts or estimates, not official releases

### Missing Data Handling
- GID contains mostly non-missing data, but some series have gaps
- In screening workflow, missing macro values default to neutral (3.0) score
- Always check latest_snapshot for data currency before publishing analysis

---

## Integration into Global Investment Advisor

### Data Flow Architecture

```
┌─────────────────────────────────────────────────────────┐
│ Global-Insights-Dashboard                               │
│ └─ indicators_long.rds (227K obs)                        │
│ └─ latest_snapshot.rds (135 obs)                         │
│ └─ podcast_feed.rds, newsletter_feed.rds                │
└────────────┬────────────────────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────────────────────┐
│ 01_collect_market_data.R                                │
│ • Load indicators_long & latest_snapshot                │
│ • Filter to key geographies (US, JP, GB, DE, CN, IN)   │
│ • Filter to key categories (growth, inflation, policy)  │
│ • Download market prices (tidyquant)                    │
│ • Save to data/processed/                               │
└────────────┬────────────────────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────────────────────┐
│ data/processed/                                         │
│ ├─ market_prices_[DATE].csv (price history)             │
│ ├─ daily_returns_[DATE].csv (calculated returns)        │
│ ├─ macro_data_gid_[DATE].csv (macro indicators)         │
│ └─ monthly_returns_[DATE].csv (monthly data)            │
└────────────┬────────────────────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────────────────────┐
│ 02_screen_global_assets.R                               │
│ • Load processed market data                            │
│ • Load processed macro data (for context)               │
│ • Score countries/themes by conviction                  │
│ • Output ranked opportunities                           │
└────────────┬────────────────────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────────────────────┐
│ data/processed/                                         │
│ ├─ country_opportunity_screen_[DATE].csv                │
│ └─ theme_opportunity_screen_[DATE].csv                  │
└────────────┬────────────────────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────────────────────┐
│ Country Deep-Dive Memos                                 │
│ • Load latest macro data from GID                       │
│ • Integrate with screening results                      │
│ • Write narrative analysis                              │
│ • Save to reports/investment_memos/                     │
└─────────────────────────────────────────────────────────┘
```

### Key Integration Points

#### 1. Data Collection (01_collect_market_data.R)
```r
# Load GID indicators
indicators_long <- readRDS(
  "/Users/kwestrick/.../Global-Insights-Dashboard/data/indicators_long.rds"
)

# Filter to key countries and categories
macro_data <- indicators_long |>
  dplyr::filter(
    geography %in% c("US", "JP", "GB", "DE", "BR", "CN", "IN", "EA19"),
    category %in% c("growth_output", "inflation", "monetary_financial", "commodities_energy")
  )
```

#### 2. Macro Assessment (02_screen_global_assets.R)
Macro tailwinds and catalyst strength are scored based on:
- GID indicators for growth trajectory
- Policy rate trends (monetary_financial category)
- Commodity prices (relevant for resource exporters)
- Labor indicators (wage growth)

#### 3. Deep-Dive Memos (country_deep_dive_template.qmd)
Embed GID data in memo sections:
- **Macro Backdrop:** GDP growth, inflation, policy rates from indicators_long
- **Latest Snapshot:** Current values from latest_snapshot.rds
- **Commodity Exposure:** Oil, metals prices for commodity-linked economies
- **Geopolitical Context:** Narrative from podcast/newsletter feeds

### Code Reference

**Load GID data in your R scripts:**
```r
gid_path <- "/Users/kwestrick/Library/CloudStorage/Dropbox/MyBusiness/Development/RCode/Global-Insights-Dashboard"

indicators_long <- readRDS(file.path(gid_path, "data/indicators_long.rds"))
latest_snapshot <- readRDS(file.path(gid_path, "data/latest_snapshot.rds"))
```

**Filter to specific countries and categories:**
```r
# Example: US inflation and growth
us_macro <- indicators_long |>
  dplyr::filter(
    geography == "US",
    category %in% c("growth_output", "inflation")
  ) |>
  dplyr::arrange(id, date)

# Example: Commodity prices for emerging markets
commodity_prices <- indicators_long |>
  dplyr::filter(
    geography == "WORLD",
    id %in% c("brent_crude_spot", "copper_price", "wheat_price")
  )
```

---

## Reusable Data Patterns

### Pattern 1: Country Macro Profile
Create a macro snapshot for any country:
```r
country_code <- "CN"  # or "BR", "IN", etc.

country_macro <- indicators_long |>
  dplyr::filter(geography == country_code) |>
  dplyr::group_by(id, category) |>
  dplyr::slice_max(date, n = 1) |>
  dplyr::select(id, category, value, date) |>
  dplyr::arrange(category)
```

### Pattern 2: Macro Trend (e.g., Inflation)
Analyze inflation trajectory:
```r
inflation_trend <- indicators_long |>
  dplyr::filter(
    geography %in% c("US", "JP", "CN", "BR"),
    str_detect(id, "inflation|cpi")
  ) |>
  dplyr::arrange(geography, id, date) |>
  dplyr::tail(20)  # Last 20 observations
```

### Pattern 3: Commodity Watch
Track commodity prices for screening:
```r
commodities <- indicators_long |>
  dplyr::filter(
    category == "commodities_energy",
    geography == "WORLD"
  ) |>
  dplyr::group_by(id) |>
  dplyr::mutate(
    pct_change_1m = (value / dplyr::lag(value, 20)) - 1,
    pct_change_3m = (value / dplyr::lag(value, 60)) - 1
  ) |>
  dplyr::slice_max(date, n = 1)
```

---

## Data Not Yet Integrated (Future Opportunities)

### Available in GID but not yet used:
1. **Podcast/newsletter text:** Could feed NLP analysis for sentiment on countries/sectors
2. **Alert state:** GID's own geopolitical alert logic; could trigger rescreening
3. **Regional macro:** EU, ASEAN, MERCOSUR aggregates available but not yet leveraged

### Could be added:
1. **Real-time market flows:** FX flows, bond flows from Bloomberg/Reuters (if available)
2. **Analyst consensus:** Earnings estimates, target prices (Bloomberg/Reuters)
3. **Satellite data:** Economic activity from alternative data (Diffuse Labs, etc.)
4. **Social sentiment:** Twitter/news sentiment on countries, companies

---

## Troubleshooting Data Issues

### Problem: GID data path not found
**Solution:** Verify the path is correct and GID project hasn't moved:
```r
gid_path <- "/Users/kwestrick/Library/CloudStorage/Dropbox/MyBusiness/Development/RCode/Global-Insights-Dashboard"
file.exists(file.path(gid_path, "data/indicators_long.rds"))
```

### Problem: Macro data is very old (last_date > 7 days ago)
**Solution:** 
1. Check if GID's data refresh is working
2. Comment out macro loading in 01_collect_market_data.R
3. Proceed with market-price-only analysis (still valid)

### Problem: Missing values for specific countries or indicators
**Solution:**
1. Verify in indicators_long that the indicator exists for that geography
2. Check date range; not all indicators go back to 2014
3. For emerging markets, expect more sparsity
4. Default to neutral (3.0) conviction score for missing macro data

### Problem: Mismatch between GID geography codes and my ticker symbols
**Reference:**
- GID uses ISO 3166-1 alpha-2 codes (US, JP, CN, BR, IN, etc.)
- Our universe uses ETF tickers (SPY, EWJ, INDA, EWZ, etc.)
- country_universe dataframe maps ticker → country_or_region; use that for joins

---

## Data Governance

### Access & Permissions
- GID data is in CloudStorage/Dropbox; available to all team members with Dropbox access
- No authentication required (local file access)
- Consider GID data as read-only; never modify `data/` files

### Data Lifecycle
- **Raw data retention:** GID maintains full history (2014+)
- **Processed data retention:** Keep in data/processed/ for 3 months, then archive
- **Analysis retention:** Keep final memos in reports/investment_memos/ permanently

### Data Updates & Syncing
- Market data: Fetch fresh on each workflow run (idempotent, no stale data risk)
- Macro data: Check freshness before publishing; comment if > 7 days old
- Version macro data files with timestamps to track changes

---

## Summary: What Data We Have & How to Use It

| Need | Source | Frequency | How to Access |
|------|--------|-----------|---------------|
| **Daily prices for all 48 ETFs** | Yahoo Finance (tidyquant) | Real-time | `get_market_prices()` function |
| **Returns & risk metrics** | Calculated from prices | On-demand | `calculate_return_summary()` etc. |
| **Economic growth metrics** | GID indicators_long (category: growth_output) | Weekly | Filter by geography & date |
| **Inflation trends** | GID indicators_long (category: inflation) | Weekly | Filter by geography & date |
| **Central bank policy rates** | GID indicators_long (category: monetary_financial) | Weekly | Filter by geography & date |
| **Commodity prices** | GID indicators_long (category: commodities_energy) | Daily | Filter by commodity ID |
| **Current macro snapshot** | GID latest_snapshot | Daily | Read directly, no filtering needed |
| **Geopolitical narrative** | GID podcast_feed, newsletter_feed | Weekly | Qualitative context |
| **Valuation multiples** | Not in GID; use relative price performance | On-demand | calculated from price data |
| **Company fundamentals** | Not in GID; would require separate data | – | Future enhancement |

---

## Next Steps

1. ✅ **Completed:** Inventory data availability
2. ✅ **Completed:** Integrate into 01_collect_market_data.R
3. ✅ **Completed:** Integrate macro assessment into 02_screen_global_assets.R
4. ⬜ **Upcoming:** Build macro-driven signals (e.g., "countries with rising growth & falling inflation")
5. ⬜ **Upcoming:** Create dashboard showing GID indicators alongside price performance
6. ⬜ **Upcoming:** Automate alerts when falsification triggers from macro data are hit

---

**Document Version:** 1.0  
**Last Updated:** September 21, 2026  
**Reviewed By:** Global Investment Advisor Team
