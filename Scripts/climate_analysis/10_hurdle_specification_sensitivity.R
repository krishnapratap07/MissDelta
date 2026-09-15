# Hurdle-model specification sensitivity analysis
#
# Primary:
#   All_events ~ NAO + AMM | ENSO
#
# Alternative 1:
#   All_events ~ NAO + AMM + ENSO | ENSO
#
# Alternative 2:
#   All_events ~ NAO + AMM | ENSO + NAO + AMM
#
# Alternative 3:
#   All_events ~ NAO + AMM + ENSO | ENSO + NAO + AMM

suppressPackageStartupMessages({
  library(dplyr)
  library(pscl)
})

STATIONS <- c("Daily_01300","Daily_01320","Daily_01340","Daily_01400","Daily_01480")

RUN_TAG <- "p85_WY1960_2020_mindays5_zeroENSO"
OUTDIR <- "final_outputs"

df_cc <- readRDS(file.path(OUTDIR,paste0("df_cc_",RUN_TAG,".rds")))

models <- list(
  primary = All_events ~ NAO + AMM | ENSO,
  add_ENSO_count = All_events ~ NAO + AMM + ENSO | ENSO,
  add_NAO_AMM_zero = All_events ~ NAO + AMM | ENSO + NAO + AMM,
  all_three_both = All_events ~ NAO + AMM + ENSO | ENSO + NAO + AMM
)

rows <- list()

for (stn in STATIONS) {

  d <- df_cc %>% filter(station == stn)

  for (nm in names(models)) {

    fit <- tryCatch(
      hurdle(models[[nm]],data=d,dist="negbin",zero.dist="binomial"),
      error=function(e) NULL
    )

    if (is.null(fit)) {
      rows[[length(rows)+1]] <- data.frame(
        station=stn,specification=nm,AIC=NA,logLik=NA,fit_status="fit_failed"
      )
      next
    }

    rows[[length(rows)+1]] <- data.frame(
      station=stn,
      specification=nm,
      AIC=AIC(fit),
      logLik=as.numeric(logLik(fit)),
      fit_status="fit_ok"
    )
  }
}

write.csv(
  bind_rows(rows),
  file.path(OUTDIR,paste0("hurdle_specification_sensitivity_",RUN_TAG,".csv")),
  row.names=FALSE
)

cat("Hurdle specification sensitivity analysis complete\n")
