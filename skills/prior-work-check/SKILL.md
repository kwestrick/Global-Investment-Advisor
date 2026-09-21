---
name: prior-work-check
description: "Use before starting fresh commodity, weather, or supply chain analysis on the Global Commodity Platform — checks Kenneth Westrick's Google Drive (LFTF Blog folder and related shared drives) and GitHub repos for prior notes, drafts, or scripts on the topic before generating new analysis. Required first step whenever a query touches a commodity, weather pattern, or supply chain issue that may have been previously researched. Not needed for pure factual lookups unrelated to the user's own prior work (e.g. 'what is ENSO')."
metadata:
  author: kwestrick
  version: '1.0'
  space: global-commodity-platform
---

# Prior-Work Check (Drive + GitHub)

## When to Use This Skill

Run this check BEFORE producing any commodity signal, memo, dashboard feature, or
analytical write-up — anytime the query involves a specific commodity, weather pattern,
or supply chain issue that Kenneth may have already researched or written about. This
includes requests that use the weather-price-signal-memo skill, R Shiny platform build
requests, and any ad hoc question about a commodity/weather/supply-chain topic.

Skip this check only for:
- Pure factual/definitional lookups with no personal research angle (e.g. "what is the
  Baltic Dry Index")
- Requests explicitly scoped to public data only (e.g. "just pull the latest WASDE numbers")
- Follow-ups within the same session where the check was already run for this topic

## Search Locations

### 1. Google Drive — LFTF Blog folder and shared drives

- Local mirror path (via `pc`, for on-device checks):
  `/Users/kwestrick/Library/CloudStorage/GoogleDrive-kenneth.westrick@leadfromthefront.org/Shared drives/LFTF/Blog`
- For content search (preferred when Drive connector is available), use the `files`
  connector (search_files_v2) — not per-connector Google Drive tools — with queries
  combining:
  - The commodity name (e.g. "coffee", "natural gas", "WTI")
  - The weather/climate driver (e.g. "El Niño", "polar vortex", "monsoon")
  - The supply chain issue (e.g. "Panama Canal", "Baltic Dry", "urea")
- Search the LFTF Blog folder and any other shared drives returned by the connector —
  do not limit to a single guessed folder name.

### 2. GitHub repos

- Use the `gh` CLI via `bash` with `api_credentials=["github"]`, or the GitHub connector
  if available, to search Kenneth's repos for:
  - Scripts or R files referencing the commodity/data source (e.g. `rnoaa`, `quantmod`,
    `ecmwfr` calls tied to the topic)
  - README or markdown notes mentioning the commodity, weather pattern, or supply chain
    issue
  - Prior dashboard modules relevant to the Shiny platform build
- Read-only search only (`gh search`, `git ls-remote`, `gh api` GET calls) — never modify
  repo content as part of this check.

## Required Actions

1. Run a search pass across both locations before starting fresh analysis. Use 2-3
   targeted queries per location (commodity name, weather driver, supply chain term) —
   don't run a single vague query and stop.
2. If relevant prior material is found:
   - Read it and explicitly state in the response: "Referencing my prior note from
     [date/filename]" or "Referencing my [repo name] script from [date]".
   - Build on it rather than restating from scratch — cite what's reused vs. what's new.
   - Note any ways the new analysis updates, confirms, or contradicts the prior work.
3. If no relevant prior material is found:
   - State explicitly that none was found (e.g. "No prior notes found on this in the
     LFTF Blog folder or GitHub repos — this is fresh analysis") rather than staying
     silent about the check.
4. Never fabricate a reference to prior work — only cite files/scripts actually found
   and read during this check.

## Output Convention

Always include one line near the top of the resulting analysis (before the main content)
using one of these two forms:

- `[Prior work found: <filename/repo>, dated <date> — building on/updating this]`
- `[Prior work check: none found — new analysis]`

This keeps it visible to Kenneth without requiring him to ask whether the check was run.
