# Coding Standards

## General Style

Use clear, idiomatic R. Prefer readable pipelines and explicit function names. The goal is a maintainable research system, not the shortest possible code.

## Naming

Use `snake_case` for:

- Objects
- Functions
- Columns
- File names where practical

Examples:

```r
country_universe <- create_country_etf_universe()
calculate_return_summary <- function(returns) {
  ...
}
```

## Function Design

Functions should:

- Do one thing well.
- Validate important inputs.
- Return tidy data frames where possible.
- Avoid writing files unless file output is the function’s explicit purpose.
- Avoid relying on hidden global variables except for documented project defaults.

## Script Design

Scripts should:

- Be runnable from the project root.
- Source required helper files explicitly.
- Create required directories before writing outputs.
- Save generated outputs with clear names.
- Print a short completion message.

## Path Rules

Use relative paths from the project root.

Good:

```r
file.path("data", "processed", "market_prices.csv")
```

Avoid:

```r
"/Users/kenneth/Desktop/project/data/market_prices.csv"
```

## Error Handling

Use informative error messages.

Good:

```r
if (!"adjusted" %in% names(prices)) {
  stop("Expected column 'adjusted' was not found in price data.")
}
```

Avoid:

```r
prices$adjusted
```

without checking whether the column exists.

## Data Handling

Keep raw and processed data separate:

- `data/raw/`: original downloaded files
- `data/processed/`: cleaned or transformed files
- `data/external/`: lookup tables and manually maintained reference files

Do not overwrite raw data. Add dates to generated files when useful.

## Charting

Use reusable plotting functions from `R/plotting.R`. Save charts to `outputs/charts/`.

Charts should include:

- Clear title
- Subtitle when context is needed
- Labeled axes
- Sensible scales
- Source note in the memo or surrounding text when used in research

