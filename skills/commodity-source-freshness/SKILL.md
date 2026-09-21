---
name: commodity-source-freshness
description: "Use whenever citing quantitative data (prices, yields, inventories, freight rates, fertilizer prices, weather model outputs) for any in-scope commodity on the Global Commodity Platform. Provides the approved primary source list per data type, its expected update cadence, and rules for flagging stale or single-source data. Use as a pre-citation check before including any number in a memo, dashboard, or analysis. Not needed for purely qualitative or historical narrative claims with no specific figure attached."
metadata:
  author: kwestrick
  version: '1.0'
  space: global-commodity-platform
---

# Commodity Source-Freshness Checklist

## When to Use This Skill

Run this check before citing any quantitative figure in a memo, dashboard view, or
analysis for an in-scope commodity. Pair with weather-price-signal-memo's sourcing rules —
this skill supplies the specific source-to-cadence mapping that lets you judge whether a
given figure is current or stale.

## Approved Primary Sources by Data Type

| Data type | Primary source(s) | Expected update cadence | Staleness threshold |
|---|---|---|---|
| Crude oil (WTI/Brent) prices, inventories | EIA (Weekly Petroleum Status Report), IEA Oil Market Report | Weekly (EIA), monthly (IEA) | >7 days (EIA), >35 days (IEA) |
| Natural gas (Henry Hub, TTF, JKM) prices, storage | EIA Natural Gas Weekly, national grid/storage operators | Weekly | >7 days |
| Power/electricity pricing | Regional grid operator (e.g. ERCOT, PJM, ENTSO-E, national utility) | Daily/hourly for spot, monthly for generation mix | >2 days for spot |
| OPEC supply/policy | OPEC Monthly Oil Market Report | Monthly | >35 days |
| CFTC positioning | CFTC Commitment of Traders | Weekly (Fridays) | >7 days |
| Crop yield/production/stocks (corn, wheat, soybeans, cotton) | USDA WASDE | Monthly (typically 2nd week) | >35 days |
| Coffee, cocoa, sugar supply/demand | USDA FAS, ICO (coffee), ICCO (cocoa), USDA/ISO (sugar) | Monthly/quarterly, varies by body | >45 days |
| Weather/climate outlooks | NOAA CPC, ECMWF seasonal, IRI ENSO probabilities, EU Copernicus | Monthly (CPC/IRI updates ~monthly), seasonal updates for ECMWF | >35 days for seasonal outlooks; >7 days for short-range |
| Drought/soil moisture indices | NOAA/US Drought Monitor, national meteorological agencies | Weekly | >10 days |
| Freight rates (dry bulk, tanker) | Baltic Exchange (Baltic Dry Index, Baltic Clean/Dirty Tanker Indices) | Daily | >3 days |
| Chokepoint transit status (Panama, Suez, Hormuz) | Panama Canal Authority, Suez Canal Authority, IMO/shipping advisories | As-issued / weekly monitoring | >14 days without a check-in during an active disruption |
| Fertilizer prices (urea, phosphate, potash) | IFA (International Fertilizer Association), World Bank Commodity Markets Outlook | Monthly | >35 days |
| Macro commodity outlook / cross-checks | World Bank Commodity Markets Outlook | Quarterly | >100 days |

## Required Actions

1. Before citing a figure, identify its data type and match it to the table above.
2. Check the as-of date of the source actually used. If it exceeds the staleness
   threshold, flag it inline: e.g. "[stale: EIA figure is 12 days old, weekly refresh
   expected]" rather than presenting it as current without comment.
3. If only one source exists for a claim (no independent corroboration), flag it inline:
   "[single-source: no independent confirmation found]."
4. If a fresher source exists but conflicts with the one being cited, present both with
   dates rather than silently picking one — this mirrors the "present the range, don't
   average" rule for divergent forecasts.
5. When a data type isn't in the table above (edge case), still label it explicitly as
   observed/forecast/judgment per the weather-price-signal-memo sourcing rules, and note
   that no standard cadence benchmark exists for it.

## Notes on Paid/Upgraded Data

Some series are materially better with paid data (e.g. Bloomberg/Refinitiv freight and
physical cargo data, proprietary weather models, AIS vessel tracking). When free-tier
sourcing is a meaningful limitation for a specific claim, note it explicitly (e.g. "Baltic
Exchange public data used; AIS-level vessel tracking would sharpen this chokepoint delay
estimate") rather than presenting the free-tier figure as equivalent to what paid data
would show.
