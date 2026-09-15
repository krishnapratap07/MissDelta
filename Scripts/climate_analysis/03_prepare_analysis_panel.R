# Prepare the common station-year analysis panel
#
# IMPORTANT:
# Climate indices are standardized ONCE on the unique annual series
# over WY1960-WY2020 BEFORE joining to the station-year flood panel.

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

STATIONS <- c("Daily_01300","Daily_01320","Daily_01340","Daily_01400","Daily_01480")

CATEGORIES <- c(
  "Coast_only",
  "River_only",
  "Compound_extreme",
  "Compound_moderate",
  "Non_extreme"
)

THRESHOLD <- "p85"
WY_START <- 1960
WY_END <- 2020
MIN_VALID_DAYS <- 5

RUN_TAG <- paste0(
  THRESHOLD,
  "_WY",WY_START,"_",WY_END,
  "_mindays",MIN_VALID_DAYS,
  "_zeroENSO"
)

OUTDIR <- "final_outputs"
if (!dir.exists(OUTDIR)) dir.create(OUTDIR, recursive = TRUE)

standardize_year_column <- function(df) {
  nms <- tolower(names(df))
  i <- which(nms %in% c("water_year","wateryear","water.year","wyear","wy","year","years"))
  if (length(i) != 1) stop("Could not identify exactly one year column.")
  names(df)[i] <- "wyear"
  df$wyear <- as.integer(df$wyear)
  df
}

standardize_index <- function(x) {
  s <- sd(x, na.rm = TRUE)
  if (!is.finite(s) || s == 0) stop("Cannot standardize climate index.")
  (x - mean(x, na.rm = TRUE)) / s
}

parse_dates <- function(x) {
  if (inherits(x,"Date")) return(x)
  if (inherits(x,c("POSIXct","POSIXlt"))) return(as.Date(x))
  x <- sub("[ T].*$","",trimws(as.character(x)))
  formats <- c("%Y-%m-%d","%m/%d/%Y","%d/%m/%Y","%d-%b-%Y","%Y%m%d")
  for (f in formats) {
    d <- suppressWarnings(as.Date(x,format=f))
    if (sum(!is.na(d)) > 0) return(d)
  }
  stop("Could not parse wl_data.csv dates.")
}

flood <- read_csv("flood_annual_counts_water_year_5_cat.csv", show_col_types = FALSE)
nao   <- read_csv("processed_noa.csv", show_col_types = FALSE)
enso  <- read_csv("processed_enso_ondjf.csv", show_col_types = FALSE)
amm   <- read_csv("AMM_annual_wateryear.csv", show_col_types = FALSE)
wl    <- read_csv("wl_data.csv", show_col_types = FALSE)

flood <- standardize_year_column(flood)
nao   <- standardize_year_column(nao)
enso  <- standardize_year_column(enso)
amm   <- standardize_year_column(amm)

nao <- nao %>%
  rename(NAO = NAO_DJFM_lag1) %>%
  filter(wyear >= WY_START, wyear <= WY_END) %>%
  select(wyear, NAO) %>%
  mutate(NAO = standardize_index(NAO))

enso <- enso %>%
  rename(ENSO = ONDJF_ONI) %>%
  filter(wyear >= WY_START, wyear <= WY_END) %>%
  select(wyear, ENSO) %>%
  mutate(ENSO = standardize_index(ENSO))

amm_value <- setdiff(names(amm),"wyear")
if (length(amm_value) != 1) stop("Expected one AMM value column.")

amm <- amm %>%
  rename(AMM = all_of(amm_value)) %>%
  filter(wyear >= WY_START, wyear <= WY_END) %>%
  select(wyear, AMM) %>%
  mutate(AMM = standardize_index(AMM))

# Water-level coverage by station and water year
date_col <- names(wl)[1]
dates <- parse_dates(wl[[date_col]])
wyear <- as.integer(format(dates,"%Y")) + as.integer(format(dates,"%m") >= "10")

coverage <- bind_rows(lapply(setdiff(names(wl),date_col), function(col) {
  id <- regmatches(col, regexpr("[0-9]{5}",col))
  if (length(id) == 0 || id == "") return(NULL)
  x <- tapply(!is.na(wl[[col]]), wyear, sum)
  data.frame(
    station = paste0("Daily_",id),
    wyear = as.integer(names(x)),
    valid_days = as.integer(x)
  )
}))

keep <- coverage %>%
  filter(
    station %in% STATIONS,
    wyear >= WY_START,
    wyear <= WY_END,
    valid_days >= MIN_VALID_DAYS
  ) %>%
  select(station,wyear)

df_cc <- flood %>%
  filter(
    threshold == THRESHOLD,
    station %in% STATIONS,
    wyear >= WY_START,
    wyear <= WY_END
  ) %>%
  select(station,wyear,All_events,all_of(CATEGORIES)) %>%
  left_join(nao,by="wyear") %>%
  left_join(enso,by="wyear") %>%
  left_join(amm,by="wyear") %>%
  inner_join(keep,by=c("station","wyear")) %>%
  mutate(
    All_events = as.numeric(All_events),
    across(all_of(CATEGORIES),as.numeric)
  ) %>%
  filter(if_all(c(All_events,all_of(CATEGORIES),NAO,ENSO,AMM), ~ !is.na(.)))

category_sum <- rowSums(as.matrix(df_cc[,CATEGORIES]))
if (any(df_cc$All_events != category_sum)) {
  stop("All_events does not equal the sum of the five categories.")
}

df_cc$station <- factor(df_cc$station,levels=STATIONS)

saveRDS(df_cc,file.path(OUTDIR,paste0("df_cc_",RUN_TAG,".rds")))
write_csv(df_cc,file.path(OUTDIR,paste0("df_cc_",RUN_TAG,".csv")))

cat("Saved common analysis panel:",nrow(df_cc),"station-years\n")
