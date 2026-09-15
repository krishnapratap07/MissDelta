# Two-stage Kitagawa decomposition for NAO and AMM
#
# Uses:
#   total-count hurdle model
#   Dirichlet-multinomial composition model
#
# Climate contrast:
#   -1 SD to +1 SD
#
# Bootstrap:
#   5-water-year moving-block bootstrap

suppressPackageStartupMessages({
  library(dplyr)
  library(pscl)
  library(MGLM)
})

STATIONS <- c("Daily_01300","Daily_01320","Daily_01340","Daily_01400","Daily_01480")

CATEGORIES <- c(
  "Coast_only","River_only","Compound_extreme",
  "Compound_moderate","Non_extreme"
)

DRIVERS <- c("NAO","AMM")

RUN_TAG <- "p85_WY1960_2020_mindays5_zeroENSO"
PART3_TAG <- paste0(RUN_TAG,"_stdUniqueWY_moving_block_L5")

OUTDIR <- "final_outputs"

X_LO <- -1
X_HI <- 1
ENSO_REF <- 0
N_BOOT <- 500
BLOCK_LENGTH <- 5
CI_LEVEL <- 0.90

set.seed(42)

df_cc <- readRDS(file.path(OUTDIR,paste0("df_cc_",RUN_TAG,".rds")))
hurdle_fits <- readRDS(file.path(OUTDIR,paste0("hurdle_fits_",RUN_TAG,".rds")))
dm_fits <- readRDS(file.path(OUTDIR,paste0("dm_fits_",RUN_TAG,".rds")))

moving_block_sample <- function(d,L) {
  d <- d[order(d$wyear),,drop=FALSE]
  n <- nrow(d)
  starts <- seq_len(max(1,n-L+1))
  out <- integer(0)
  while (length(out) < n) {
    s <- sample(starts,1)
    out <- c(out,s:min(s+L-1,n))
  }
  d[out[seq_len(n)],,drop=FALSE]
}

name_dm <- function(fit,d) {
  dp <- d %>% filter(All_events > 0) %>% mutate(logN=log(All_events))
  B <- fit@coefficients
  if (is.null(rownames(B))) rownames(B) <- colnames(model.matrix(~ NAO + AMM + logN,data=dp))
  if (is.null(colnames(B))) colnames(B) <- CATEGORIES
  fit@coefficients <- B
  fit
}

fit_both <- function(d) {
  hf <- hurdle(All_events ~ NAO + AMM | ENSO,data=d,dist="negbin",zero.dist="binomial")

  dp <- d %>% filter(All_events > 0) %>% mutate(logN=log(All_events))
  Y <- as.matrix(dp[,CATEGORIES])
  storage.mode(Y) <- "numeric"
  colnames(Y) <- CATEGORIES

  df <- MGLMreg(Y ~ NAO + AMM + logN,data=dp,dist="DM")
  df <- name_dm(df,d)

  list(hurdle=hf,dm=df)
}

dm_share <- function(B,NAO,AMM,logN) {
  x <- c("(Intercept)"=1,NAO=NAO,AMM=AMM,logN=logN)
  eta <- as.numeric(t(x[rownames(B)]) %*% B)
  a <- exp(pmax(pmin(eta,700),-700))
  setNames(a/sum(a),CATEGORIES)
}

decomp <- function(d,hfit,dfit,driver) {

  dfit <- name_dm(dfit,d)
  B <- dfit@coefficients

  ref_logN <- mean(log(d$All_events[d$All_events > 0]))

  new_low <- data.frame(
    NAO=ifelse(driver=="NAO",X_LO,0),
    AMM=ifelse(driver=="AMM",X_LO,0),
    ENSO=ENSO_REF
  )

  new_high <- data.frame(
    NAO=ifelse(driver=="NAO",X_HI,0),
    AMM=ifelse(driver=="AMM",X_HI,0),
    ENSO=ENSO_REF
  )

  N_low <- as.numeric(predict(hfit,newdata=new_low,type="response"))
  N_high <- as.numeric(predict(hfit,newdata=new_high,type="response"))

  p_low <- dm_share(
    B,
    ifelse(driver=="NAO",X_LO,0),
    ifelse(driver=="AMM",X_LO,0),
    ref_logN
  )

  p_high <- dm_share(
    B,
    ifelse(driver=="NAO",X_HI,0),
    ifelse(driver=="AMM",X_HI,0),
    ref_logN
  )

  dNc <- N_high*p_high - N_low*p_low
  freq <- (N_high-N_low)*(p_low+p_high)/2
  comp <- (p_high-p_low)*(N_low+N_high)/2

  list(dNc=dNc,freq=freq,comp=comp,N_low=N_low,N_high=N_high)
}

qci <- function(x) {
  a <- (1-CI_LEVEL)/2
  quantile(x,c(a,1-a),na.rm=TRUE,names=FALSE)
}

for (driver in DRIVERS) {

  rows <- list()
  diagnostics <- list()

  for (stn in STATIONS) {

    d <- df_cc %>% filter(station == stn)

    point <- decomp(
      d,
      hurdle_fits[[stn]],
      dm_fits[[stn]],
      driver
    )

    bd <- matrix(NA_real_,N_BOOT,length(CATEGORIES),dimnames=list(NULL,CATEGORIES))
    bf <- bd
    bc <- bd

    ok <- 0

    for (b in seq_len(N_BOOT)) {

      db <- moving_block_sample(d,BLOCK_LENGTH)

      fits <- tryCatch(fit_both(db),error=function(e) NULL)
      if (is.null(fits)) next

      z <- tryCatch(decomp(db,fits$hurdle,fits$dm,driver),error=function(e) NULL)
      if (is.null(z)) next

      ok <- ok+1
      bd[ok,] <- z$dNc[CATEGORIES]
      bf[ok,] <- z$freq[CATEGORIES]
      bc[ok,] <- z$comp[CATEGORIES]
    }

    for (cat in CATEGORIES) {

      dci <- qci(bd[seq_len(ok),cat])
      fci <- qci(bf[seq_len(ok),cat])
      cci <- qci(bc[seq_len(ok),cat])

      rows[[length(rows)+1]] <- data.frame(
        station=stn,
        driver=driver,
        category=cat,
        N_low=point$N_low,
        N_high=point$N_high,
        dNc=point$dNc[cat],dNc_lo=dci[1],dNc_hi=dci[2],
        freq=point$freq[cat],freq_lo=fci[1],freq_hi=fci[2],
        comp=point$comp[cat],comp_lo=cci[1],comp_hi=cci[2],
        boot_ok=ok,ci_level=CI_LEVEL
      )
    }

    diagnostics[[stn]] <- data.frame(
      station=stn,driver=driver,
      n_boot_requested=N_BOOT,n_boot_successful=ok,
      block_length=BLOCK_LENGTH
    )
  }

  write.csv(
    bind_rows(rows),
    file.path(OUTDIR,paste0(
      "part3_twostage_kitagawa_",driver,"_",PART3_TAG,"_CI90.csv"
    )),
    row.names=FALSE
  )

  write.csv(
    bind_rows(diagnostics),
    file.path(OUTDIR,paste0(
      "part3_bootstrap_diagnostics_",driver,"_",PART3_TAG,"_CI90.csv"
    )),
    row.names=FALSE
  )
}

cat("Kitagawa decomposition complete for NAO and AMM\n")
