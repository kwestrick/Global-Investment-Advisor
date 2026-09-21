---
name: stacked-risk-flagging
description: "Use when analyzing any in-scope commodity (crude oil, natural gas, power, corn, wheat, soybeans, coffee, cocoa, sugar, cotton) where a weather/climate signal co-occurs with a supply chain or input-cost condition (freight, fertilizer, energy input costs). Determines whether multiple factors are compounding in the same direction and, if so, requires labeling the situation a stacked-risk scenario with elevated conviction language and a comparison table. Use alongside weather-price-signal-memo whenever more than one risk factor is present. Do not use for single-factor signals with no supply chain overlap."
metadata:
  author: kwestrick
  version: '1.0'
  space: global-commodity-platform
---

# Stacked-Risk Scenario Flagging

## When to Use This Skill

Use this skill whenever a commodity analysis involves **more than one** risk factor from
the list below acting on the same commodity in the same direction over a similar time
window. This is a required companion check to the weather-price-signal-memo skill — run it
whenever the supply chain layer section of that memo turns up a factor beyond the primary
weather driver.

Do NOT use when only one factor (weather alone, or a single supply chain factor alone with
no weather angle) is present — that's a standard single-factor signal and doesn't need the
stacked-risk framing.

## Risk Factor Categories to Check

1. **Weather/climate** — ENSO phase, polar vortex, monsoon timing, drought index,
   hurricane/cyclone activity, degree-day anomalies, soil moisture, snowpack.
2. **Shipping & freight** — Baltic Dry/Tanker indices, chokepoint disruption (Hormuz,
   Suez, Panama), port congestion, barge/rail constraints, shadow-fleet insurance effects.
3. **Fertilizer & ag inputs** — nitrogen/urea, phosphate, potash price/availability,
   export policy shifts from Russia, Belarus, China, Morocco.
4. **Energy input costs** — diesel/bunker fuel, natural gas as nitrogen fertilizer input.

## Determination Logic

For the commodity and time window in question:

1. Identify every risk factor currently active (from the categories above) with a source
   and as-of date.
2. For each active factor, determine its directional effect on the commodity's price
   (upward pressure, downward pressure, or neutral/mixed).
3. **If two or more factors point in the same direction and overlap in time window** →
   this is a stacked-risk scenario. Proceed to the required output below.
4. **If factors point in offsetting directions** → do not label it stacked-risk. Instead,
   explicitly note the offset and explain which factor likely dominates and why (or state
   that the net effect is ambiguous).
5. **If only one factor is active** → not a stacked-risk scenario; use the standard
   single-factor memo format.

## Required Output When Stacked-Risk Is Identified

Add a **Stacked-Risk Assessment** block to the memo (in addition to, not replacing, the
standard weather-price-signal-memo structure), containing:

1. **Compounding factors table** — one row per active factor:

   | Factor | Category | Direction | Source/Date | Independent magnitude estimate |
   |---|---|---|---|---|

2. **Compounding rationale** — one to two sentences on why these factors reinforce rather
   than merely coincide (e.g. "drought reduces yield directly AND raises fertilizer costs
   AND constrains barge transit for the same crop in the same window").
3. **Elevated conviction statement** — explicitly state that confidence is higher than a
   comparable single-factor signal would warrant, and explain why (multiple independent
   mechanisms failing together is lower-probability to reverse than any one alone).
4. **Historical stacked analog** — prefer a historical case where multiple factors
   compounded similarly, over a single-factor analog, if one exists. If none exists, say so.
5. **Unwind risk** — note what would need to happen for the stack to break apart (e.g. one
   factor reversing independently of the others), since stacked risks can unwind
   asymmetrically if only one leg resolves.

## Tone Rules

- Do not inflate confidence language beyond "medium-high" or "high" even for strong
  stacks — avoid absolute language ("certain," "guaranteed").
- Keep the elevated-conviction framing evidence-based: point to the specific mechanisms
  compounding, not just the fact that multiple factors exist.
- This skill does not change the illustrative-only labeling rule for any options/position
  sizing commentary — stacked-risk conviction is about the underlying thesis, not license
  to give more assertive trading advice.
