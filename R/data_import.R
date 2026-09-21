# data_import.R
# Data import functions for prices, macro series, and reference data

# ---- Market prices ----

get_market_prices <- function(tickers,
                              from = analysis_defaults$start_date,
                              to = Sys.Date(),
                              source = "stock.prices") {
  prices <- tidyquant::tq_get(
    tickers,
    from = from,
    to = to,
    get = source
  )

  prices <- prices %>%
    janitor::clean_names() %>%
    dplyr::arrange(.data$symbol, .data$date)

  required_cols <- c("symbol", "date", "adjusted")

  missing_cols <- setdiff(required_cols, names(prices))

  if (length(missing_cols) > 0) {
    stop(
      "Market price download did not return expected columns: ",
      paste(missing_cols, collapse = ", "),
      ". Check ticker symbols, internet access, and the tidyquant getter."
    )
  }

  prices
}

get_adjusted_returns <- function(prices) {
  prices %>%
    dplyr::group_by(symbol) %>%
    dplyr::arrange(date, .by_group = TRUE) %>%
    dplyr::mutate(
      daily_return = adjusted / dplyr::lag(adjusted) - 1
    ) %>%
    dplyr::ungroup()
}

get_monthly_returns <- function(prices) {
  prices %>%
    dplyr::group_by(symbol) %>%
    tidyquant::tq_transmute(
      select = adjusted,
      mutate_fun = periodReturn,
      period = "monthly",
      type = "arithmetic",
      col_rename = "monthly_return"
    ) %>%
    dplyr::ungroup()
}

# ---- FRED data ----

get_fred_series <- function(series_ids,
                            observation_start = as.Date(analysis_defaults$start_date),
                            observation_end = Sys.Date()) {
  if (!requireNamespace("fredr", quietly = TRUE)) {
    stop("Package 'fredr' is required. Install it and set your FRED API key with fredr::fredr_set_key().")
  }

  purrr::map_dfr(
    series_ids,
    ~ fredr::fredr(
      series_id = .x,
      observation_start = observation_start,
      observation_end = observation_end
    ),
    .id = "series_index"
  ) %>%
    janitor::clean_names()
}

# ---- World Bank data ----

get_world_bank_indicators <- function(countries,
                                      indicators,
                                      start_year = 2000,
                                      end_year = as.integer(format(Sys.Date(), "%Y"))) {
  WDI::WDI(
    country = countries,
    indicator = indicators,
    start = start_year,
    end = end_year,
    extra = TRUE
  ) %>%
    janitor::clean_names()
}

# ---- QIF import (Banktivity, YNAB, etc.) ----

import_qif_accounts <- function(qif_file) {
  # Parse QIF file and extract account structure
  # Returns tibble with account names, types, and balances from header section only
  
  if (!file.exists(qif_file)) {
    stop("QIF file not found: ", qif_file)
  }
  
  lines <- readLines(qif_file, warn = FALSE)
  
  # Find the boundary: account headers end at !Clear:AutoSwitch
  clear_idx <- which(lines == "!Clear:AutoSwitch")[1]
  if (is.na(clear_idx)) {
    stop("QIF file missing !Clear:AutoSwitch marker. Cannot identify header section.")
  }
  
  # Parse only lines 1 to clear_idx
  header_lines <- lines[1:clear_idx]
  
  # Extract account definitions
  accounts_list <- list()
  current_account <- NULL
  in_account_section <- FALSE
  
  for (i in seq_along(header_lines)) {
    line <- header_lines[i]
    
    if (line == "!Account") {
      in_account_section <- TRUE
      current_account <- list()
      next
    }
    
    if (line == "!Clear:AutoSwitch") {
      # End of header section; finalize current account if present
      if (!is.null(current_account$name)) {
        accounts_list[[current_account$name]] <- current_account
      }
      break
    }
    
    if (!in_account_section) next
    
    if (line == "^") {
      # End of account record
      if (!is.null(current_account$name)) {
        accounts_list[[current_account$name]] <- current_account
      }
      current_account <- NULL
      next
    }
    
    # Parse field: first character is key, rest is value
    if (nchar(line) > 1) {
      key <- substr(line, 1, 1)
      val <- substr(line, 2, nchar(line))
      
      if (key == "N") current_account$name <- val
      if (key == "T") current_account$type <- val
      if (key == "B") current_account$balance <- as.numeric(val)
    }
  }
  
  # Convert to tibble
  accounts <- tibble::tibble(
    account_name = names(accounts_list),
    account_type = sapply(accounts_list, function(x) x$type %||% NA_character_, USE.NAMES = FALSE),
    balance = sapply(accounts_list, function(x) as.numeric(x$balance %||% 0), USE.NAMES = FALSE)
  ) %>%
    dplyr::mutate(
      account_category = dplyr::case_when(
        account_type == "Bank" ~ "Checking/Savings",
        account_type == "CCard" ~ "Credit Card",
        account_type == "Invst" ~ "Investment",
        account_type == "Oth A" ~ "Other Asset",
        account_type == "Oth L" ~ "Other Liability",
        TRUE ~ "Other"
      )
    ) %>%
    dplyr::arrange(account_category, account_name)
  
  accounts
}

# ---- Reference tables ----

read_reference_table <- function(file_name, sheet = NULL) {
  file_path <- file.path("data/external", file_name)

  if (!file.exists(file_path)) {
    stop("File not found: ", file_path)
  }

  extension <- tools::file_ext(file_path)

  if (extension %in% c("csv", "txt")) {
    readr::read_csv(file_path, show_col_types = FALSE)
  } else if (extension %in% c("xlsx", "xls")) {
    readxl::read_excel(file_path, sheet = sheet)
  } else {
    stop("Unsupported file extension: ", extension)
  }
}
