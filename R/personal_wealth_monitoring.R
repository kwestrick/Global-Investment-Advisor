# personal_wealth_monitoring.R
# Functions for tracking net worth, allocation, goals, and rebalancing

# ---- Financial position tracking ----

calculate_net_worth <- function(accounts_df) {
  # Sum assets and liabilities to get net worth
  assets <- accounts_df %>%
    dplyr::filter(account_category %in% c("Checking/Savings", "Investment", "Other Asset")) %>%
    dplyr::pull(balance) %>%
    sum()
  
  liabilities <- accounts_df %>%
    dplyr::filter(account_category %in% c("Credit Card", "Other Liability")) %>%
    dplyr::pull(balance) %>%
    sum()
  
  tibble::tibble(
    total_assets = assets,
    total_liabilities = liabilities,
    net_worth = assets + liabilities,
    timestamp = Sys.Date()
  )
}

calculate_allocation <- function(accounts_df, target_allocation) {
  # Calculate current allocation vs. target
  current <- accounts_df %>%
    dplyr::filter(account_category %in% c("Checking/Savings", "Investment")) %>%
    dplyr::group_by(account_category) %>%
    dplyr::summarise(balance = sum(balance), .groups = "drop") %>%
    dplyr::mutate(
      allocation_type = dplyr::case_when(
        account_category == "Checking/Savings" ~ "Cash",
        account_category == "Investment" ~ "Investments",
        TRUE ~ "Other"
      )
    )
  
  # Merge with targets
  allocation_detail <- current %>%
    dplyr::left_join(target_allocation, by = "allocation_type") %>%
    dplyr::mutate(
      current_pct = balance / sum(current$balance) * 100,
      target_pct = target_pct %||% 0,
      drift = current_pct - target_pct,
      needs_rebalance = abs(drift) > 5
    )
  
  allocation_detail
}

assess_goal_progress <- function(net_worth, target_estate = 500000) {
  # Track progress toward estate goal
  goal_met <- net_worth >= target_estate
  
  tibble::tibble(
    current_net_worth = net_worth,
    target_estate = target_estate,
    goal_met = goal_met,
    surplus = net_worth - target_estate,
    pct_of_goal = (net_worth / target_estate) * 100
  )
}

project_net_worth <- function(current_nw, monthly_contribution, annual_return, years) {
  # Simple projection: year-over-year growth with monthly contributions
  projections <- tibble::tibble(
    year = 0:years,
    annual_contribution = monthly_contribution * 12,
    balance = NA_real_
  )
  
  balance <- current_nw
  for (i in seq_along(projections$year)) {
    projections$balance[i] <- balance
    if (i < nrow(projections)) {
      # Compound growth + contributions
      balance <- balance * (1 + annual_return) + (monthly_contribution * 12)
    }
  }
  
  projections %>%
    dplyr::mutate(
      annual_gain = c(0, diff(balance)) - annual_contribution,
      cumulative_contributed = cumsum(annual_contribution)
    )
}

# ---- Rebalancing guidance ----

rebalance_guidance <- function(current_allocation, target_allocation, portfolio_value) {
  # Generate rebalancing actions
  guidance <- current_allocation %>%
    dplyr::mutate(
      target_dollar = portfolio_value * (target_pct / 100),
      current_dollar = balance,
      rebalance_amount = target_dollar - current_dollar,
      action = dplyr::case_when(
        rebalance_amount > 0 ~ paste0("BUY $", format(round(rebalance_amount), big.mark=",")),
        rebalance_amount < 0 ~ paste0("SELL $", format(round(abs(rebalance_amount)), big.mark=",")),
        TRUE ~ "HOLD"
      )
    ) %>%
    dplyr::select(allocation_type, current_dollar, target_dollar, rebalance_amount, action)
  
  guidance
}

# ---- Risk assessment ----

assess_drawdown_risk <- function(annual_return, volatility, confidence_level = 0.95) {
  # Calculate maximum expected drawdown at given confidence level
  # Using normal distribution approximation
  z_score <- qnorm(confidence_level)
  max_drawdown <- z_score * volatility
  
  tibble::tibble(
    confidence_level = confidence_level * 100,
    expected_return = annual_return * 100,
    volatility = volatility * 100,
    max_expected_drawdown = max_drawdown * 100
  )
}

# ---- Quarterly dashboard ----

generate_quarterly_dashboard <- function(accounts_df, target_allocation, 
                                        current_nw, target_estate = 500000,
                                        monthly_contribution = 5200,
                                        annual_return = 0.075) {
  
  # Calculate key metrics
  nw_calc <- calculate_net_worth(accounts_df)
  allocation <- calculate_allocation(accounts_df, target_allocation)
  goal <- assess_goal_progress(nw_calc$net_worth, target_estate)
  projection <- project_net_worth(nw_calc$net_worth, monthly_contribution, annual_return, 5)
  
  # Create report
  cat("\n")
  cat("=" %+% strrep("=", 60) %+% "=\n")
  cat("PERSONAL WEALTH QUARTERLY DASHBOARD\n")
  cat("Date: ", as.character(Sys.Date()), "\n")
  cat("=" %+% strrep("=", 60) %+% "=\n\n")
  
  # Section 1: Net Worth
  cat("NET WORTH SUMMARY\n")
  cat("-" %+% strrep("-", 60) %+% "-\n")
  cat("Total Assets:        $", format(nw_calc$total_assets, big.mark=",", decimal.mark="."), "\n", sep="")
  cat("Total Liabilities:   $", format(nw_calc$total_liabilities, big.mark=",", decimal.mark="."), "\n", sep="")
  cat("NET WORTH:           $", format(nw_calc$net_worth, big.mark=",", decimal.mark="."), "\n\n", sep="")
  
  # Section 2: Goal Progress
  cat("ESTATE GOAL TRACKING\n")
  cat("-" %+% strrep("-", 60) %+% "-\n")
  cat("Target:              $", format(goal$target_estate, big.mark=",", decimal.mark="."), "\n", sep="")
  cat("Current:             $", format(goal$current_net_worth, big.mark=",", decimal.mark="."), "\n", sep="")
  cat("Surplus/(Deficit):   $", format(goal$surplus, big.mark=",", decimal.mark="."), "\n", sep="")
  cat("% of Goal:           ", format(goal$pct_of_goal, digits=1), "%\n", sep="")
  cat("Status:              ", if_else(goal$goal_met, "✓ GOAL MET", "! GOAL NOT MET"), "\n\n", sep="")
  
  # Section 3: Allocation
  cat("PORTFOLIO ALLOCATION\n")
  cat("-" %+% strrep("-", 60) %+% "-\n")
  print(allocation %>% dplyr::select(allocation_type, balance, current_pct, target_pct, drift, needs_rebalance))
  cat("\n")
  
  # Section 4: Projection
  cat("5-YEAR NET WORTH PROJECTION (7.5% return, $5,200/month)\n")
  cat("-" %+% strrep("-", 60) %+% "-\n")
  print(projection %>% dplyr::select(year, balance, annual_gain) %>% dplyr::slice(c(1, 2, 3, 4, 5, 6)))
  cat("\n")
  
  # Section 5: Rebalancing
  rebalancing <- allocation %>% dplyr::filter(needs_rebalance)
  if (nrow(rebalancing) > 0) {
    cat("⚠ REBALANCING NEEDED\n")
    cat("-" %+% strrep("-", 60) %+% "-\n")
    print(rebalancing %>% dplyr::select(allocation_type, current_pct, target_pct, drift))
    cat("\n")
  } else {
    cat("✓ Portfolio is balanced (drift < 5%)\n\n")
  }
  
  cat("=" %+% strrep("=", 60) %+% "=\n")
  cat("Report generated:", Sys.time(), "\n")
  cat("=" %+% strrep("=", 60) %+% "=\n\n")
}

# ---- Dual-currency portfolio monitoring ----

#' Build a consolidated USD + COP balance sheet.
#'
#' Combines Banktivity USD accounts with Colombian COP assets (illiquid home +
#' liquid bank accounts + any COP investments) into a single net worth view,
#' translating everything to both currencies at the current spot rate.
#'
#' @param usd_accounts_df Tibble from import_qif_accounts(). Standard QIF schema.
#' @param cop_home_value Numeric. Appraised COP value of Colombian home. Default: 1.2B COP.
#' @param cop_bank_balance Numeric. COP bank accounts total (BBVA + Bancolombia). Default: 30M COP.
#' @param cop_investments Numeric. COP already deployed into TES/CDTs/COLCAP. Default: 0.
#' @param cop_per_usd Numeric. Current COP per 1 USD exchange rate.
#' @return Tibble with columns: asset_class, currency, cop_value, usd_value, is_liquid, is_investable.
calculate_dual_currency_net_worth <- function(
  usd_accounts_df,
  cop_home_value   = 1200000000,
  cop_bank_balance = 30000000,
  cop_investments  = 0,
  cop_per_usd      = 4000
) {
  if (!is.numeric(cop_per_usd) || cop_per_usd <= 0) {
    stop("cop_per_usd must be a positive number (e.g., 4000 for 4,000 COP per USD).")
  }

  # USD accounts aggregated by category
  usd_liquid <- usd_accounts_df %>%
    dplyr::filter(account_category == "Checking/Savings") %>%
    dplyr::pull(balance) %>%
    sum(na.rm = TRUE)

  usd_investments <- usd_accounts_df %>%
    dplyr::filter(account_category == "Investment") %>%
    dplyr::pull(balance) %>%
    sum(na.rm = TRUE)

  usd_other_assets <- usd_accounts_df %>%
    dplyr::filter(account_category == "Other Asset") %>%
    dplyr::pull(balance) %>%
    sum(na.rm = TRUE)

  usd_liabilities <- usd_accounts_df %>%
    dplyr::filter(account_category %in% c("Credit Card", "Other Liability")) %>%
    dplyr::pull(balance) %>%
    sum(na.rm = TRUE)  # already negative from QIF

  # Build balance sheet rows
  rows <- tibble::tribble(
    ~asset_class,          ~currency, ~usd_value,         ~is_liquid, ~is_investable,
    "USD Cash/Savings",    "USD",     usd_liquid,         TRUE,        TRUE,
    "USD Investments",     "USD",     usd_investments,    TRUE,        TRUE,
    "USD Other Assets",    "USD",     usd_other_assets,   FALSE,       FALSE,
    "COP Home (Illiquid)", "COP",     cop_home_value / cop_per_usd, FALSE, FALSE,
    "COP Bank Accounts",   "COP",     cop_bank_balance / cop_per_usd,  TRUE,  TRUE,
    "COP Investments",     "COP",     cop_investments / cop_per_usd,   TRUE,  TRUE,
    "USD Liabilities",     "USD",     usd_liabilities,    FALSE,       FALSE
  ) %>%
    dplyr::mutate(
      cop_value = dplyr::case_when(
        currency == "USD" ~ usd_value * cop_per_usd,
        currency == "COP" ~ dplyr::case_when(
          asset_class == "COP Home (Illiquid)" ~ cop_home_value,
          asset_class == "COP Bank Accounts"   ~ cop_bank_balance,
          asset_class == "COP Investments"     ~ cop_investments,
          TRUE                                 ~ usd_value * cop_per_usd
        )
      ),
      as_of = Sys.Date(),
      cop_per_usd_used = cop_per_usd
    )

  # Append net worth summary row
  net_worth_usd <- sum(rows$usd_value, na.rm = TRUE)
  net_worth_cop <- net_worth_usd * cop_per_usd

  summary_row <- tibble::tibble(
    asset_class      = "TOTAL NET WORTH",
    currency         = "BOTH",
    usd_value        = net_worth_usd,
    is_liquid        = NA,
    is_investable    = NA,
    cop_value        = net_worth_cop,
    as_of            = Sys.Date(),
    cop_per_usd_used = cop_per_usd
  )

  dplyr::bind_rows(rows, summary_row)
}

#' Calculate current USD vs. COP currency exposure.
#'
#' Focuses on investable (liquid, deployable) assets only. Compares the actual
#' USD/COP split to a target and flags whether rebalancing is warranted.
#'
#' @param dual_nw_df Tibble from calculate_dual_currency_net_worth().
#' @param target_usd_pct Numeric. Target % of investable assets held in USD (default: 80).
#' @param rebalance_threshold_pct Numeric. Drift threshold before action is flagged (default: 5).
#' @return List with: usd_investable, cop_investable, total_investable, current_usd_pct,
#'   current_cop_pct, target_usd_pct, target_cop_pct, usd_drift, action_needed, summary.
calculate_currency_exposure <- function(
  dual_nw_df,
  target_usd_pct         = 80,
  rebalance_threshold_pct = 5
) {
  investable <- dual_nw_df %>%
    dplyr::filter(is_investable == TRUE, asset_class != "TOTAL NET WORTH")

  usd_inv <- investable %>%
    dplyr::filter(currency == "USD") %>%
    dplyr::pull(usd_value) %>%
    sum(na.rm = TRUE)

  cop_inv_usd <- investable %>%
    dplyr::filter(currency == "COP") %>%
    dplyr::pull(usd_value) %>%
    sum(na.rm = TRUE)

  total_inv <- usd_inv + cop_inv_usd

  if (total_inv == 0) {
    stop("calculate_currency_exposure: no investable assets found in dual_nw_df.")
  }

  current_usd_pct <- (usd_inv / total_inv) * 100
  current_cop_pct <- (cop_inv_usd / total_inv) * 100
  target_cop_pct  <- 100 - target_usd_pct
  usd_drift       <- current_usd_pct - target_usd_pct

  action_needed <- abs(usd_drift) >= rebalance_threshold_pct
  action_direction <- dplyr::case_when(
    !action_needed   ~ "HOLD — within tolerance",
    usd_drift > 0    ~ paste0("SHIFT USD → COP: redeploy ~$",
                              format(round(abs(usd_drift) / 100 * total_inv), big.mark = ","),
                              " USD into COP assets"),
    usd_drift < 0    ~ paste0("SHIFT COP → USD: redeploy ~$",
                              format(round(abs(usd_drift) / 100 * total_inv), big.mark = ","),
                              " USD-equivalent from COP into USD assets")
  )

  list(
    usd_investable      = round(usd_inv, 0),
    cop_investable_usd  = round(cop_inv_usd, 0),
    total_investable    = round(total_inv, 0),
    current_usd_pct     = round(current_usd_pct, 1),
    current_cop_pct     = round(current_cop_pct, 1),
    target_usd_pct      = target_usd_pct,
    target_cop_pct      = target_cop_pct,
    usd_drift_pct       = round(usd_drift, 1),
    action_needed       = action_needed,
    action              = action_direction,
    summary = paste0(
      "Investable assets: $", format(round(total_inv), big.mark = ","), " USD total. ",
      "USD: ", round(current_usd_pct, 1), "% | COP: ", round(current_cop_pct, 1), "%. ",
      "Target: ", target_usd_pct, "% USD / ", target_cop_pct, "% COP. ",
      "Drift: ", ifelse(usd_drift >= 0, "+", ""), round(usd_drift, 1), "% USD. ",
      action_direction, "."
    )
  )
}

#' Project dual-currency net worth over multiple years.
#'
#' Models USD and COP portfolio growth separately, then translates to a
#' combined USD total under three FX scenarios. COP income is reinvested
#' at the blended COP nominal yield.
#'
#' @param usd_investable Numeric. Starting USD investable balance.
#' @param cop_investable_cop Numeric. Starting COP investable balance in COP (not USD).
#' @param usd_monthly_contribution Numeric. Monthly USD deposits/investments (default: 5200).
#' @param cop_monthly_income_cop Numeric. Monthly COP income (from CDTs/TES/COLCAP, reinvested).
#' @param usd_annual_return Numeric. Expected annual USD portfolio return (decimal). Default: 0.075.
#' @param cop_nominal_yield Numeric. Blended COP nominal yield (decimal). Default: 0.105.
#' @param years Integer. Projection horizon in years. Default: 5.
#' @param current_cop_per_usd Numeric. Starting COP/USD rate.
#' @param fx_scenarios Named numeric vector. Annual COP appreciation vs USD in percent.
#'   Positive = COP strengthens. Default: bear = -5, base = 0, bull = +3.
#' @return Tibble with year, scenario, usd_portfolio, cop_portfolio_cop, cop_portfolio_usd,
#'   combined_net_worth_usd, cop_per_usd.
project_dual_currency_growth <- function(
  usd_investable,
  cop_investable_cop,
  usd_monthly_contribution  = 5200,
  cop_monthly_income_cop    = 2000000,
  usd_annual_return         = 0.075,
  cop_nominal_yield         = 0.105,
  years                     = 5,
  current_cop_per_usd       = 4000,
  fx_scenarios              = c(bear = -5, base = 0, bull = 3)
) {
  # Build results row by row for each scenario; avoid <<- across purrr iterations
  results <- purrr::map_dfr(names(fx_scenarios), function(scenario) {
    cop_appreciation <- fx_scenarios[[scenario]] / 100

    usd_bal <- usd_investable
    cop_bal <- cop_investable_cop
    rate    <- current_cop_per_usd

    rows <- vector("list", years + 1L)

    for (yr in 0:years) {
      if (yr > 0) {
        usd_bal <- usd_bal * (1 + usd_annual_return) + (usd_monthly_contribution * 12)
        cop_bal <- cop_bal * (1 + cop_nominal_yield) + (cop_monthly_income_cop * 12)
        rate    <- rate * (1 - cop_appreciation)
      }

      rows[[yr + 1L]] <- tibble::tibble(
        year                   = yr,
        scenario               = scenario,
        usd_portfolio          = round(usd_bal, 0),
        cop_portfolio_cop      = round(cop_bal, 0),
        cop_per_usd            = round(rate, 0),
        cop_portfolio_usd      = round(cop_bal / rate, 0),
        combined_net_worth_usd = round(usd_bal + cop_bal / rate, 0)
      )
    }

    dplyr::bind_rows(rows)
  })

  results %>%
    dplyr::arrange(scenario, year) %>%
    dplyr::mutate(scenario = factor(scenario, levels = names(fx_scenarios)))
}

#' Assess whether to shift monthly contributions between USD and COP.
#'
#' Compares current currency exposure to target and provides specific guidance
#' on how to allocate the next month's surplus to close the gap.
#'
#' @param exposure List from calculate_currency_exposure().
#' @param monthly_usd_surplus Numeric. Total monthly investable surplus in USD (default: 5200).
#' @param monthly_cop_surplus_cop Numeric. Monthly COP income available to invest (default: 2M COP).
#' @param cop_per_usd Numeric. Current COP/USD rate (for translating COP amounts).
#' @return List with: current_allocation, recommended_usd_invest, recommended_cop_invest_cop,
#'   months_to_target, narrative.
assess_fx_rebalancing_need <- function(
  exposure,
  monthly_usd_surplus       = 5200,
  monthly_cop_surplus_cop   = 2000000,
  cop_per_usd               = 4000
) {
  monthly_cop_surplus_usd <- monthly_cop_surplus_cop / cop_per_usd
  total_monthly_usd       <- monthly_usd_surplus + monthly_cop_surplus_usd

  current_usd_pct <- exposure$current_usd_pct
  target_usd_pct  <- exposure$target_usd_pct
  drift_pct       <- exposure$usd_drift_pct
  total_inv       <- exposure$total_investable

  # If within tolerance, allocate contributions proportionally to target
  if (!exposure$action_needed) {
    usd_invest <- monthly_usd_surplus
    cop_invest_cop <- monthly_cop_surplus_cop

    return(list(
      current_usd_pct        = current_usd_pct,
      target_usd_pct         = target_usd_pct,
      drift_pct              = drift_pct,
      recommended_usd_invest = round(usd_invest, 0),
      recommended_cop_invest_cop = round(cop_invest_cop, 0),
      months_to_target       = 0L,
      narrative = paste0(
        "Portfolio is within the ", exposure$action_needed, "% tolerance band. ",
        "Continue current contribution split: $",
        format(round(usd_invest), big.mark = ","), " USD/month and ",
        format(round(cop_invest_cop / 1e6, 1), nsmall = 1), "M COP/month."
      )
    ))
  }

  # How much in USD terms is needed to reach target?
  gap_usd <- (drift_pct / 100) * total_inv  # positive = too much USD

  # Estimate months to close gap by redirecting contributions
  # If USD is over-weight: direct all new contributions to COP
  # If COP is over-weight: direct all new contributions to USD
  months_to_target <- if (abs(gap_usd) > 0 && total_monthly_usd > 0) {
    ceiling(abs(gap_usd) / total_monthly_usd)
  } else Inf

  if (drift_pct > 0) {
    # USD over-weight: redirect contributions to COP
    usd_invest     <- 0
    cop_invest_cop <- (monthly_usd_surplus + monthly_cop_surplus_usd) * cop_per_usd
    direction      <- "COP"
  } else {
    # COP over-weight: redirect contributions to USD
    usd_invest     <- monthly_usd_surplus + monthly_cop_surplus_usd
    cop_invest_cop <- 0
    direction      <- "USD"
  }

  list(
    current_usd_pct            = current_usd_pct,
    target_usd_pct             = target_usd_pct,
    drift_pct                  = drift_pct,
    gap_usd                    = round(gap_usd, 0),
    recommended_usd_invest     = round(usd_invest, 0),
    recommended_cop_invest_cop = round(cop_invest_cop, 0),
    months_to_target           = months_to_target,
    narrative = paste0(
      "USD exposure is ", ifelse(drift_pct > 0, "over", "under"), "-weight by ",
      abs(round(drift_pct, 1)), "pp vs. target. ",
      "Redirect all new contributions to ", direction, " assets for ~",
      months_to_target, " months to close the gap. ",
      "Recommended this month: $",
      format(round(usd_invest), big.mark = ","), " into USD assets; ",
      format(round(cop_invest_cop / 1e6, 1), nsmall = 1), "M COP into COP assets."
    )
  )
}

# ---- Helper: String concatenation operator ----
`%+%` <- function(x, y) paste0(x, y)
