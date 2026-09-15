# Single-driver hurdle sensitivity models
#
# outcome ~ NAO | ENSO
# outcome ~ AMM | ENSO

suppressPackageStartupMessages({
  library(dplyr)
  library(pscl)
})

STATIONS <- c("Daily_01300","Daily_01320","Daily_01340","Daily_01400","Daily_01480")

CATEGORIES <- c(
  "Coast_only","River_only","Compound_extreme",
  "Compound_moderate","Non_extreme"
)

OUTCOMES <- c("All_events",CATEGORIES)
DRIVERS <- c("NAO","AMM")

RUN_TAG <- "p85_WY1960_2020_mindays5_zeroENSO"
OUTDIR <- "final_outputs"

N_POS_MIN <- 15
N_ZERO_MIN <- 4
CI_Z <- 1.645

df_cc <- readRDS(file.path(OUTDIR,paste0("df_cc_",RUN_TAG,".rds")))

extract <- function(tab,term) {
  if (is.null(tab) || !term %in% rownames(tab)) return(rep(NA_real_,4))
  b <- tab[term,"Estimate"]; s <- tab[term,"Std. Error"]; p <- tab[term,"Pr(>|z|)"]
  c(exp(b),exp(b-CI_Z*s),exp(b+CI_Z*s),p)
}

rows <- list()
fits <- list()

for (stn in STATIONS) {

  d <- df_cc %>% filter(station == stn)

  for (outcome in OUTCOMES) {

    y <- d[[outcome]]
    npos <- sum(y > 0)
    nzero <- sum(y == 0)

    for (driver in DRIVERS) {

      if (npos < N_POS_MIN || nzero < N_ZERO_MIN) {
        rows[[length(rows)+1]] <- data.frame(
          station=stn,outcome=outcome,driver=driver,
          n_positive=npos,n_zero=nzero,
          driver_irr=NA,driver_lo=NA,driver_hi=NA,driver_p=NA,
          fit_status="not_estimable"
        )
        next
      }

      d$y <- y
      f <- as.formula(paste("y ~",driver,"| ENSO"))

      fit <- tryCatch(
        hurdle(f,data=d,dist="negbin",zero.dist="binomial"),
        error=function(e) NULL
      )

      key <- paste(stn,outcome,driver,sep="__")
      fits[[key]] <- fit

      if (is.null(fit)) {
        rows[[length(rows)+1]] <- data.frame(
          station=stn,outcome=outcome,driver=driver,
          n_positive=npos,n_zero=nzero,
          driver_irr=NA,driver_lo=NA,driver_hi=NA,driver_p=NA,
          fit_status="fit_failed"
        )
        next
      }

      e <- extract(summary(fit)$coefficients$count,driver)

      rows[[length(rows)+1]] <- data.frame(
        station=stn,outcome=outcome,driver=driver,
        n_positive=npos,n_zero=nzero,
        driver_irr=e[1],driver_lo=e[2],driver_hi=e[3],driver_p=e[4],
        fit_status="fit_ok"
      )
    }
  }
}

write.csv(
  bind_rows(rows),
  file.path(OUTDIR,paste0("part4b_single_driver_hurdle_",RUN_TAG,"_CI90.csv")),
  row.names=FALSE
)

saveRDS(
  fits,
  file.path(OUTDIR,paste0("part4b_single_driver_hurdle_fits_",RUN_TAG,"_CI90.rds"))
)

cat("Single-driver hurdle models complete\n")
