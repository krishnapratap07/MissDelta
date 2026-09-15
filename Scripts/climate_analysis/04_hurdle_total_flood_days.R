# Hurdle model for total annual flood-day counts
# All_events ~ NAO + AMM | ENSO

suppressPackageStartupMessages({
  library(dplyr)
  library(pscl)
})

STATIONS <- c("Daily_01300","Daily_01320","Daily_01340","Daily_01400","Daily_01480")
RUN_TAG <- "p85_WY1960_2020_mindays5_zeroENSO"
OUTDIR <- "final_outputs"
CI_Z <- 1.645

df_cc <- readRDS(file.path(OUTDIR,paste0("df_cc_",RUN_TAG,".rds")))

effect <- function(tab,term) {
  b <- tab[term,"Estimate"]
  s <- tab[term,"Std. Error"]
  p <- tab[term,"Pr(>|z|)"]
  c(est=exp(b),lo=exp(b-CI_Z*s),hi=exp(b+CI_Z*s),p=p)
}

lrt_p <- function(full,reduced) {
  a <- logLik(full); b <- logLik(reduced)
  df <- attr(a,"df") - attr(b,"df")
  stat <- 2*(as.numeric(a)-as.numeric(b))
  pchisq(stat,df=df,lower.tail=FALSE)
}

hurdle_fits <- list()
rows <- list()

for (stn in STATIONS) {

  d <- df_cc %>% filter(station == stn)

  full <- hurdle(
    All_events ~ NAO + AMM | ENSO,
    data=d,dist="negbin",zero.dist="binomial"
  )

  reduced_count <- hurdle(
    All_events ~ 1 | ENSO,
    data=d,dist="negbin",zero.dist="binomial"
  )

  reduced_zero <- hurdle(
    All_events ~ NAO + AMM | 1,
    data=d,dist="negbin",zero.dist="binomial"
  )

  hurdle_fits[[stn]] <- full

  ctab <- summary(full)$coefficients$count
  ztab <- summary(full)$coefficients$zero

  nao <- effect(ctab,"NAO")
  amm  <- effect(ctab,"AMM")
  enso <- effect(ztab,"ENSO")

  rows[[stn]] <- data.frame(
    station=stn,
    n=nrow(d),
    NAO_irr=nao["est"],NAO_lo=nao["lo"],NAO_hi=nao["hi"],NAO_p=nao["p"],
    AMM_irr=amm["est"],AMM_lo=amm["lo"],AMM_hi=amm["hi"],AMM_p=amm["p"],
    ENSO_zero_OR=enso["est"],ENSO_zero_lo=enso["lo"],ENSO_zero_hi=enso["hi"],ENSO_zero_p=enso["p"],
    p_count_NAO_AMM=lrt_p(full,reduced_count),
    p_zero_ENSO=lrt_p(full,reduced_zero)
  )
}

result <- bind_rows(rows)

saveRDS(hurdle_fits,file.path(OUTDIR,paste0("hurdle_fits_",RUN_TAG,".rds")))
write.csv(result,file.path(OUTDIR,paste0("part1_hurdle_all_events_",RUN_TAG,".csv")),row.names=FALSE)

cat("Total-count hurdle models complete\n")
