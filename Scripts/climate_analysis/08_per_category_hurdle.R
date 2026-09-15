# Per-category hurdle models
# Category_count ~ NAO + AMM | ENSO

suppressPackageStartupMessages({
  library(dplyr)
  library(pscl)
})

STATIONS <- c("Daily_01300","Daily_01320","Daily_01340","Daily_01400","Daily_01480")

CATEGORIES <- c(
  "Coast_only","River_only","Compound_extreme",
  "Compound_moderate","Non_extreme"
)

RUN_TAG <- "p85_WY1960_2020_mindays5_zeroENSO"
OUTDIR <- "final_outputs"

N_POS_MIN <- 15
N_ZERO_MIN <- 5
CI_Z <- 1.645

df_cc <- readRDS(file.path(OUTDIR,paste0("df_cc_",RUN_TAG,".rds")))

extract <- function(tab,term) {
  if (is.null(tab) || !term %in% rownames(tab)) return(rep(NA_real_,4))
  b <- tab[term,"Estimate"]; s <- tab[term,"Std. Error"]; p <- tab[term,"Pr(>|z|)"]
  c(exp(b),exp(b-CI_Z*s),exp(b+CI_Z*s),p)
}

rows <- list()

for (stn in STATIONS) {

  d <- df_cc %>% filter(station == stn)

  for (cat in CATEGORIES) {

    y <- d[[cat]]
    npos <- sum(y > 0)
    nzero <- sum(y == 0)

    if (npos < N_POS_MIN || nzero < N_ZERO_MIN) {
      rows[[length(rows)+1]] <- data.frame(
        station=stn,category=cat,
        n_years=nrow(d),n_positive=npos,n_zero=nzero,
        NAO_irr=NA,NAO_lo=NA,NAO_hi=NA,NAO_p=NA,
        AMM_irr=NA,AMM_lo=NA,AMM_hi=NA,AMM_p=NA,
        fit_status="not_estimable"
      )
      next
    }

    d$y <- y

    fit <- tryCatch(
      hurdle(y ~ NAO + AMM | ENSO,data=d,dist="negbin",zero.dist="binomial"),
      error=function(e) NULL
    )

    if (is.null(fit)) {
      rows[[length(rows)+1]] <- data.frame(
        station=stn,category=cat,
        n_years=nrow(d),n_positive=npos,n_zero=nzero,
        NAO_irr=NA,NAO_lo=NA,NAO_hi=NA,NAO_p=NA,
        AMM_irr=NA,AMM_lo=NA,AMM_hi=NA,AMM_p=NA,
        fit_status="fit_failed"
      )
      next
    }

    tab <- summary(fit)$coefficients$count
    nao <- extract(tab,"NAO")
    amm <- extract(tab,"AMM")

    rows[[length(rows)+1]] <- data.frame(
      station=stn,category=cat,
      n_years=nrow(d),n_positive=npos,n_zero=nzero,
      NAO_irr=nao[1],NAO_lo=nao[2],NAO_hi=nao[3],NAO_p=nao[4],
      AMM_irr=amm[1],AMM_lo=amm[2],AMM_hi=amm[3],AMM_p=amm[4],
      fit_status="fit_ok"
    )
  }
}

write.csv(
  bind_rows(rows),
  file.path(OUTDIR,paste0("part4_percategory_hurdle_",RUN_TAG,"_CI90.csv")),
  row.names=FALSE
)

cat("Per-category hurdle models complete\n")
