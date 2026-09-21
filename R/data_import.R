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

# ---- QIF transaction import (Banktivity, YNAB, etc.) ----

import_qif_transactions <- function(qif_file,
                                    exclude_transfers = TRUE,
                                    exclude_starting_balance = TRUE) {
  # Parse transaction-level records from a QIF file.
  # Returns a tibble with one row per transaction, including account name,
  # date, amount, payee, memo, category, and cleared status.
  #
  # QIF field codes used:
  #   D = date, T = amount, C = cleared, P = payee, M = memo,
  #   L = category (or [Transfer Account]), N = check number
  #   ^ = end of record

  if (!file.exists(qif_file)) {
    stop("QIF file not found: ", qif_file)
  }

  lines <- readLines(qif_file, warn = FALSE)

  # Find the !Clear:AutoSwitch boundary (end of account header section)
  clear_idx <- which(lines == "!Clear:AutoSwitch")[1]
  if (is.na(clear_idx)) {
    stop("QIF file missing !Clear:AutoSwitch. Cannot locate transaction section.")
  }

  # Work only on the body (everything after the header)
  body <- lines[(clear_idx + 1):length(lines)]

  transactions <- list()
  current_account <- NA_character_
  current_tx <- list()
  in_tx <- FALSE

  for (line in body) {

    # ---- Account header block ----
    if (line == "!Account") {
      in_tx <- FALSE
      current_tx <- list()
      next
    }

    # Account name (only meaningful right after !Account marker;
    # N inside a transaction block is check number — disambiguate by in_tx)
    if (!in_tx && startsWith(line, "N") && nchar(line) > 1) {
      current_account <- substr(line, 2, nchar(line))
      next
    }

    # !Type: line marks start of transaction block for the current account
    if (startsWith(line, "!Type:")) {
      in_tx <- TRUE
      current_tx <- list()
      next
    }

    if (!in_tx) next

    # ---- Transaction fields ----
    if (line == "^") {
      # End of transaction record — save if it has a date
      if (!is.null(current_tx$date)) {
        current_tx$account <- current_account
        transactions <- c(transactions, list(current_tx))
      }
      current_tx <- list()
      next
    }

    if (nchar(line) < 2) next

    key <- substr(line, 1, 1)
    val <- substr(line, 2, nchar(line))

    switch(key,
      "D" = { current_tx$date_raw    <- val },
      "T" = { current_tx$amount_raw  <- val },
      "C" = { current_tx$cleared     <- val },
      "P" = { current_tx$payee       <- val },
      "M" = { current_tx$memo        <- val },
      "L" = { current_tx$category    <- val },
      "N" = { current_tx$check_num   <- val }
    )
  }

  if (length(transactions) == 0) {
    warning("No transactions found in QIF file.")
    return(tibble::tibble())
  }

  # Coerce list of lists to tibble
  tx_df <- tibble::tibble(
    account      = sapply(transactions, \(x) x$account    %||% NA_character_, USE.NAMES = FALSE),
    date_raw     = sapply(transactions, \(x) x$date_raw   %||% NA_character_, USE.NAMES = FALSE),
    amount_raw   = sapply(transactions, \(x) x$amount_raw %||% NA_character_, USE.NAMES = FALSE),
    payee        = sapply(transactions, \(x) x$payee      %||% NA_character_, USE.NAMES = FALSE),
    memo         = sapply(transactions, \(x) x$memo       %||% NA_character_, USE.NAMES = FALSE),
    category     = sapply(transactions, \(x) x$category   %||% NA_character_, USE.NAMES = FALSE),
    cleared      = sapply(transactions, \(x) x$cleared    %||% NA_character_, USE.NAMES = FALSE),
    check_num    = sapply(transactions, \(x) x$check_num  %||% NA_character_, USE.NAMES = FALSE)
  ) |>
    dplyr::mutate(
      # Parse dates: Banktivity uses M/D/YY
      date = lubridate::mdy(date_raw),
      # Parse amounts: remove commas, coerce to numeric
      amount = as.numeric(gsub(",", "", amount_raw)),
      # Flag transfers (category wrapped in square brackets)
      is_transfer = grepl("^\\[", category)
    ) |>
    dplyr::select(account, date, amount, payee, memo, category, is_transfer, cleared, check_num)

  # Optionally drop transfer transactions
  if (exclude_transfers) {
    tx_df <- dplyr::filter(tx_df, !is_transfer)
  }

  # Optionally drop starting-balance rows
  if (exclude_starting_balance) {
    tx_df <- dplyr::filter(
      tx_df,
      !grepl("STARTING BALANCE|BALANCE ADJUSTMENT", payee, ignore.case = TRUE)
    )
  }

  dplyr::arrange(tx_df, date, account)
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
