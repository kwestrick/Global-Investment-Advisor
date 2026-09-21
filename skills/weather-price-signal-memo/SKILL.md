---
name: weather-price-signal-memo
description: "Use when producing a commodity trading/risk signal, thesis, or memo for the Global Commodity Platform — anytime the user asks for analysis, a signal, a call, an opportunity/risk flag, or a write-up on a specific commodity (crude oil, natural gas, power, corn, wheat, soybeans, coffee, cocoa, sugar, cotton) tied to weather, climate, or supply chain conditions. Produces a structured 7-section analyst memo with explicit weather-to-price causal chain, forecast horizon, sourcing, and confidence level. Do not use for generic market news summaries or non-weather-linked commodity questions."
metadata:
  author: kwestrick
  version: '1.0'
  space: global-commodity-platform
---

# Weather-to-Price Signal Memo

## When to Use This Skill

Use whenever the user requests a commodity signal, thesis, trade idea, risk flag, or
analytical write-up for any in-scope commodity:

- Energy: crude oil (WTI/Brent), natural gas (Henry Hub, TTF, JKM), power/electricity
  (regional grid pricing, hydropower-dependent regions)
- Weather-sensitive ag: corn, wheat, soybeans, coffee, cocoa, sugar, cotton

Trigger phrases: "what's the signal on...", "any opportunity in...", "risk flag for...",
"write up the case for...", "how does [weather event] affect [commodity]", "give me a memo on..."

Do NOT use for: metals, carbon markets, generic "what happened to prices today" news
recaps with no weather/climate angle, or pure company/equity questions.

## Required Causal Chain (always trace all four steps explicitly)

1. **Weather/climate driver** — ENSO phase (El Niño/La Niña/neutral), polar vortex
   behavior, monsoon timing, drought indices, hurricane/cyclone activity, heating/cooling
   degree day anomalies, soil moisture, snowpack. State current phase/reading and date.
2. **Physical/production impact** — crop yield risk, refinery/pipeline exposure,
   hydropower generation, LNG cargo routing, heating/cooling demand shifts.
3. **Market transmission** — inventory draws/builds, spread dynamics, volatility term
   structure, insurance/reinsurance loss exposure, basis risk.
4. **Price/positioning signal** — directional bias, timing window, magnitude estimate,
   confidence level.

## Forecast Horizon (always state explicitly, pick one or more)

- **1-3 months** = tactical
- **3-6 months** = seasonal
- **6-12 months** = strategic

State which weather/climate model or outlook underpins the call: NOAA CPC, ECMWF seasonal,
IRI ENSO probabilities, EU Copernicus. If horizons blend (e.g. tactical entry within a
seasonal thesis), say so explicitly rather than picking one bucket by default.

## Supply Chain & Input-Cost Layer (required secondary lens, not optional)

For every memo, explicitly check and report on whichever of these are relevant to the
commodity in question:

- **Shipping & freight**: Baltic Dry Index, Baltic Clean/Dirty Tanker Indices, chokepoint
  risk (Strait of Hormuz, Suez Canal, Panama Canal incl. drought-driven transit
  restrictions), port congestion, LNG/crude tanker availability, rail/barge disruptions
  (e.g. Mississippi River low-water constraints), sanctions/shadow-fleet insurance effects,
  Red Sea/Houthi disruptions, Black Sea grain corridor status.
- **Fertilizer & ag inputs**: nitrogen/urea, phosphate, potash price and availability
  (tied to natural gas costs and export policy from Russia, Belarus, China, Morocco).
  Flag fertilizer affordability/application-rate risk as a leading indicator for next-season
  yield and acreage.
- **Energy input costs**: diesel/bunker fuel as a cost driver for shipping and farm
  operations; natural gas as a direct input to nitrogen fertilizer economics.

State explicitly whether each relevant supply chain factor **reinforces or offsets** the
weather signal. If a weather signal and one or more supply chain factors compound in the
same direction (e.g. drought cutting yield AND raising fertilizer costs AND constraining
barge transit), label this a **stacked-risk scenario** and note that conviction should be
higher than for a single-factor signal. See the prior-work-check skill / space instructions
for the full stacked-risk framing rule — this skill only requires flagging it when present.

## Required Output Structure (always use these 7 sections, in this order)

1. **Thesis** — one sentence, plain directional/risk statement.
2. **Weather/climate driver and current state** — with source and as-of date.
3. **Supply chain layer** — relevant shipping/transit or input-cost conditions, with
   source/date, and an explicit reinforces/offsets call relative to the weather signal.
4. **Historical analog(s)** — similar past setups and how prices responded then. If no
   good analog is found, say so rather than forcing a weak comparison.
5. **Time horizon and expected magnitude/direction** — using the horizon buckets above.
6. **Confidence level** (high/medium/low) **and key invalidating conditions** — what
   specific data or event would break the thesis.
7. **Insurance/reinsurance angle** — catastrophe bond triggers, crop insurance loss ratios,
   weather derivative pricing implications, marine cargo/hull insurance cost shifts from
   chokepoint risk. If genuinely not applicable, state that explicitly rather than omitting
   the section.

## Sourcing Rules

- Prefer primary/official sources: EIA, NOAA/NWS, ECMWF, USDA WASDE, IEA, CFTC Commitment
  of Traders, OPEC monthly reports, national meteorological agencies, Baltic Exchange, IFA
  (International Fertilizer Association), World Bank Commodity Markets Outlook, Panama
  Canal Authority, Suez Canal Authority.
- Every quantitative claim (price, yield estimate, inventory figure, freight rate,
  fertilizer price, probability) must carry a source and as-of date inline. Flag stale
  (>30 days for fast-moving series) or single-source data explicitly.
- Distinguish clearly, using labels in the text: **[observed]** historical data,
  **[forecast]** model-based projections with stated confidence intervals where available,
  **[judgment]** qualitative/narrative inference.
- When forecasts disagree across models/agencies, present the range and reasons for
  divergence — never average them into a single number.

## Tone & Style

- Write like a research analyst memo, not a trading newsletter. No hype, appropriately
  hedged language ("suggests," "consistent with," "would imply if X holds").
- Use tables for multi-commodity or multi-scenario comparisons.
- Any options strategy, position sizing, or trade structuring must be clearly labeled
  "illustrative, not investment advice" — never presented as a recommendation to act.
- Before finalizing, check Google Drive (LFTF Blog folder) and GitHub repos for prior
  related work per the prior-work-check skill, and flag explicitly if this memo builds on
  or updates something previously written.

## Example Skeleton

```
### Thesis
[One sentence]

### Weather/Climate Driver
[Current ENSO phase / anomaly reading], as of [date] ([NOAA CPC link]).

### Supply Chain Layer
[Freight index level / fertilizer price], as of [date] ([source link]).
This [reinforces/offsets] the weather signal because...

### Historical Analog
In [year], a similar [driver] setup led to [price response] ([source]).

### Horizon & Magnitude
[1-3mo tactical / 3-6mo seasonal / 6-12mo strategic]: expect [direction], magnitude
[range] based on [model/outlook].

### Confidence & Invalidating Conditions
Confidence: [high/medium/low]. Would be invalidated by [specific condition].

### Insurance/Reinsurance Angle
[Cat bond / crop insurance / weather derivative implication, or "not materially
applicable here"].
```
