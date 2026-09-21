# 02_build_macro_dataset.R
# Build a starter macro dataset from World Bank indicators

source("R/00_setup.R")
install_missing_packages()
load_required_packages()
create_project_dirs()

source("R/data_import.R")

countries <- c(
  "US", "JP", "GB", "DE", "FR", "IT", "ES", "CA", "AU",
  "CN", "IN", "BR", "MX", "CL", "ZA", "TR", "SA", "AE",
  "QA", "KR", "TW", "SG", "ID", "MY", "TH", "PH", "VN",
  "PL", "GR", "AR"
)

indicators <- c(
  gdp_current_usd = "NY.GDP.MKTP.CD",
  gdp_growth = "NY.GDP.MKTP.KD.ZG",
  inflation_cpi = "FP.CPI.TOTL.ZG",
  current_account_pct_gdp = "BN.CAB.XOKA.GD.ZS",
  government_debt_pct_gdp = "GC.DOD.TOTL.GD.ZS",
  population_growth = "SP.POP.GROW"
)

macro_data <- get_world_bank_indicators(
  countries = countries,
  indicators = indicators,
  start_year = 2000
)

macro_clean <- macro_data %>%
  dplyr::select(
    iso2c,
    iso3c,
    country,
    region,
    income,
    year,
    dplyr::all_of(names(indicators))
  ) %>%
  dplyr::arrange(country, year)

write_processed_csv(macro_clean, "world_bank_macro")

message("Macro dataset build complete.")
