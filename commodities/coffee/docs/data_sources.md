# Coffee Platform — Data Source Registry

Legend: **Key needed?** — None / Free registration / Paid.
All URLs verified July 2026.

## 1. Price (target variable)

| Source | Series | Access | Key needed? | Notes |
|---|---|---|---|---|
| [ICE / Trading Economics](https://tradingeconomics.com/commodity/coffee) | ICE Arabica (KC) front-month | Web table / paid API for bulk | Free (web) / Paid (API) | Good for quick checks; for systematic pulls use `quantmod::getSymbols` via Yahoo/Stooq proxies or a paid feed (Quandl/Nasdaq Data Link, Barchart). |
| [International Coffee Organization (ICO)](https://ico.org/resources/public-market-information/) | ICO Composite Indicator Price, Colombian Milds, Other Milds, Brazilian Naturals, Robusta | CSV/PDF download | None | Daily/monthly indicator prices back to 1990s. No public REST API — download CSV on a schedule. |
| [Nasdaq Data Link (Quandl)](https://data.nasdaq.com/) | ICE Coffee C futures | REST API | Free tier / Paid | `Quandl` R package works directly. |
| Your brokerage/finance connector | Live KC, RM (Robusta) futures quotes | Internal `finance_*` tools | None (already connected) | Use for live/current price checks inside chat; use ICO/Quandl for the historical panel used in modeling. |

## 2. Weather & Climate (core signal)

| Source | Series | Access | Key needed? | Notes |
|---|---|---|---|---|
| [NOAA CPC — Oceanic Niño Index (ONI)](https://origin.cpc.ncep.noaa.gov/data/indices/oni.ascii.txt) | ENSO state (monthly, since 1950) | Flat text file | None | `read.table(url, header=TRUE)` — no key required. This is your primary macro-climate regime variable. |
| [NOAA CPC ENSO Forecast/Discussion](https://www.cpc.ncep.noaa.gov/products/analysis_monitoring/enso_advisory/ensodisc.shtml) | Forward-looking ENSO probability | HTML page (parse) | None | Monthly discussion; probabilities table can be parsed for forward-looking risk. |
| [CHIRPS Rainfall](https://www.chc.ucsb.edu/data/chirps) via R `chirps` package | Daily/monthly rainfall, 1981–present, 0.05° grid | R package (`get_chirps()`, ClimateSERV API) | None | Best single source for growing-region rainfall anomalies (Minas Gerais, São Paulo/Brazil; Central Highlands/Vietnam; Huila/Colombia). |
| [NOAA NCEI Data Service API](https://www.ncei.noaa.gov/cdo-web/webservices/v2) (successor patterns to `rnoaa`) | Station-level temp/precip | REST API | Free registration (token) | `rnoaa` is deprecated/archived on CRAN — use `readnoaa` package or direct `httr`/`httr2` calls to the NCEI API instead. |
| [Copernicus Climate Data Store (CDS)](https://cds.climate.copernicus.eu) via `ecmwfr` R package | ERA5 reanalysis (temp, precip, soil moisture), seasonal forecasts | R package + REST | Free registration (API key) | Use for gridded reanalysis where station coverage is sparse (e.g. remote Vietnamese highlands). |
| National met agencies: [INMET](https://portal.inmet.gov.br) (Brazil), [IDEAM](http://www.ideam.gov.co) (Colombia) | Station observations | Web download / API | None–Free | Ground-truth for Minas Gerais/Cerrado (Brazil) and Huila/Nariño (Colombia) frost and drought events. |

## 3. FX (macro layer)

| Source | Series | Access | Key needed? | Notes |
|---|---|---|---|---|
| [FRED (Federal Reserve)](https://fred.stlouisfed.org/) via `fredr` R package | USD/BRL, USD/VND, USD/COP daily | REST API | Free registration | `fredr::fredr(series_id = "DEXBZUS")` etc. Central to the "weak Real → cheaper exports → lower USD price" mechanism you already flagged. |
| Your finance connector | Live FX quotes | Internal `finance_*` tools | None | For current/live checks; use FRED for the historical panel. |

## 4. Shipping & Logistics

| Source | Series | Access | Key needed? | Notes |
|---|---|---|---|---|
| [Baltic Exchange](https://www.balticexchange.com/en/data-services.html) | Baltic Dry Index, container indices | Paid subscription for full API | Paid | Free daily headline BDI figure is often reported in financial news — usable as a coarse proxy without a subscription. |
| [Freightos Baltic Index (FBX)](https://fbx.freightos.com/) | Container freight rates by route | Web / paid API | Free (web) / Paid (API) | Good route-specific proxy: Brazil (Santos)→Asia, Brazil→US/EU, Vietnam (HCMC)→destinations. |
| News-based chokepoint tracking (Suez, Panama, Strait of Hormuz, Red Sea) | Event/disruption flags | Manual/search-based | None | Encode as a binary or severity-scored "chokepoint disruption index" feature — this is currently a live, material driver (2026 Hormuz closure raising shipping/insurance/fuel costs). |
| [Panama Canal Authority](https://pancanal.com) | Transit restrictions, draft limits | Web bulletin | None | Relevant to Panama-routed Brazil→Asia legs. |

## 5. Fertilizer & Input Costs

| Source | Series | Access | Key needed? | Notes |
|---|---|---|---|---|
| [World Bank Commodity Markets Outlook (Pink Sheet)](https://www.worldbank.org/en/research/commodity-markets) | Urea, DAP, potash monthly prices | Excel download | None | Monthly since 1960s — best free long-run fertilizer price series. |
| [International Fertilizer Association (IFA)](https://www.ifastat.org) | Production/consumption/trade by country and nutrient | Web (IFASTAT portal) | Free registration | Vietnam and Brazil-specific consumption data useful for input-cost-share modeling. |
| Natural gas price (nitrogen fertilizer feedstock) | Henry Hub / TTF | via `finance_*` tools or EIA | None | Already in scope for the energy side of your platform — reuse the same series. |

## 6. Production / Fundamentals

| Source | Series | Access | Key needed? | Notes |
|---|---|---|---|---|
| [USDA FAS PSD Online — Coffee](https://apps.fas.usda.gov/psdonline/downloads/psd_coffee_csv.zip) | Production, exports, stocks by country, annual | Direct CSV/ZIP download | None | Reference implementation: `tomcopple/coffeestats` R package (`getUSDA()`) shows the exact download/clean pattern — reusable almost as-is. |
| [USDA FAS "Coffee: World Markets and Trade"](https://apps.fas.usda.gov/psdonline/circulars/coffee.pdf) | Narrative + tables, semi-annual | PDF | None | Good for qualitative context/validation of model outputs. |
| [ICO World Coffee Statistics Database](https://ico.org/what-we-do/world-coffee-statistics-database/) | Exports, production, price by exporting country | CSV/Excel download | None | Cross-check against USDA PSD. |
| [CFTC Commitment of Traders](https://www.cftc.gov/MarketReports/CommitmentsofTraders/index.htm) — Coffee | Managed money / commercial positioning | CSV download or `finance_*` tools | None | Positioning extremes are a useful confirming (not causal) signal. |

## Recommended free-tier API keys to obtain first

1. **FRED API key** — [fredred.stlouisfed.org/docs/api](https://fred.stlouisfed.org/docs/api_key.html) (instant, free)
2. **NOAA NCEI token** — [ncdc.noaa.gov/cdo-web/token](https://www.ncdc.noaa.gov/cdo-web/token) (instant, free, email-based)
3. **Copernicus CDS API key** — [cds.climate.copernicus.eu](https://cds.climate.copernicus.eu) (free registration, needed only if CHIRPS station coverage proves insufficient)

Everything else in the Phase 1 build (ONI, CHIRPS, USDA PSD, ICO, World Bank
Pink Sheet) works with zero API key.
