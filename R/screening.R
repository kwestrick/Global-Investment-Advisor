# screening.R
# Screening functions for countries, regions, sectors, ETFs, and themes

calculate_conviction_score <- function(data,
                                       valuation,
                                       macro_tailwind,
                                       catalyst_strength,
                                       risk_control,
                                       implementation_quality) {
  valuation <- rlang::enquo(valuation)
  macro_tailwind <- rlang::enquo(macro_tailwind)
  catalyst_strength <- rlang::enquo(catalyst_strength)
  risk_control <- rlang::enquo(risk_control)
  implementation_quality <- rlang::enquo(implementation_quality)

  data %>%
    dplyr::mutate(
      weighted_score =
        (!!valuation * 0.25) +
        (!!macro_tailwind * 0.25) +
        (!!catalyst_strength * 0.20) +
        (!!risk_control * 0.15) +
        (!!implementation_quality * 0.15),
      conviction_bucket = dplyr::case_when(
        weighted_score >= 4.25 ~ "High conviction",
        weighted_score >= 3.50 ~ "Attractive, monitor closely",
        weighted_score >= 2.75 ~ "Watchlist or tactical",
        weighted_score >= 2.00 ~ "Weak thesis",
        TRUE ~ "Avoid unless conditions change"
      )
    )
}

rank_opportunities <- function(data,
                               score_col = weighted_score,
                               top_n = 20) {
  score_col <- rlang::enquo(score_col)

  data %>%
    dplyr::arrange(dplyr::desc(!!score_col)) %>%
    dplyr::slice_head(n = top_n)
}

create_country_etf_universe <- function() {
  tibble::tribble(
    ~symbol, ~country_or_region, ~category,
    "SPY", "United States", "Benchmark",
    "VEA", "Developed markets ex-U.S.", "Benchmark",
    "VWO", "Emerging markets", "Benchmark",
    "EWJ", "Japan", "Country ETF",
    "EWU", "United Kingdom", "Country ETF",
    "EWG", "Germany", "Country ETF",
    "EWQ", "France", "Country ETF",
    "EWI", "Italy", "Country ETF",
    "EWP", "Spain", "Country ETF",
    "EWN", "Netherlands", "Country ETF",
    "EWL", "Switzerland", "Country ETF",
    "EWC", "Canada", "Country ETF",
    "EWA", "Australia", "Country ETF",
    "EWS", "Singapore", "Country ETF",
    "EWH", "Hong Kong", "Country ETF",
    "EWY", "South Korea", "Country ETF",
    "EWT", "Taiwan", "Country ETF",
    "INDA", "India", "Country ETF",
    "MCHI", "China", "Country ETF",
    "EWZ", "Brazil", "Country ETF",
    "EWW", "Mexico", "Country ETF",
    "ECH", "Chile", "Country ETF",
    "EZA", "South Africa", "Country ETF",
    "TUR", "Turkey", "Country ETF",
    "KSA", "Saudi Arabia", "Country ETF",
    "UAE", "United Arab Emirates", "Country ETF",
    "QAT", "Qatar", "Country ETF",
    "ARGT", "Argentina", "Country ETF",
    "EPOL", "Poland", "Country ETF",
    "GREK", "Greece", "Country ETF",
    "THD", "Thailand", "Country ETF",
    "EWM", "Malaysia", "Country ETF",
    "EIDO", "Indonesia", "Country ETF",
    "EPHE", "Philippines", "Country ETF",
    "VNM", "Vietnam", "Country ETF"
  )
}

create_theme_etf_universe <- function() {
  tibble::tribble(
    ~symbol, ~theme, ~category,
    "XLE", "U.S. energy benchmark", "U.S. sector benchmark",
    "XLI", "U.S. industrials benchmark", "U.S. sector benchmark",
    "XLF", "U.S. financials benchmark", "U.S. sector benchmark",
    "URA", "Uranium and nuclear fuel", "Commodity theme",
    "COPX", "Copper miners", "Commodity theme",
    "PICK", "Global metals and mining", "Commodity theme",
    "WOOD", "Global timber and forestry", "Commodity theme",
    "FAN", "Wind energy", "Energy transition",
    "TAN", "Solar energy", "Energy transition",
    "GRID", "Electric grid infrastructure", "Infrastructure",
    "PAVE", "U.S. infrastructure benchmark", "U.S. theme benchmark",
    "ITA", "U.S. aerospace and defense benchmark", "U.S. sector benchmark",
    "DFEN", "U.S. aerospace and defense leveraged proxy", "High-risk proxy"
  )
}
