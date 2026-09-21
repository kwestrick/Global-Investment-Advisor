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

# ---- Helper: String concatenation operator ----
`%+%` <- function(x, y) paste0(x, y)
