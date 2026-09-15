# DM category effects relative to Non-extreme
# RRR = exp(beta_category - beta_Non-extreme)

suppressPackageStartupMessages({
  library(dplyr)
  library(MGLM)
})

STATIONS <- c("Daily_01300","Daily_01320","Daily_01340","Daily_01400","Daily_01480")

CATEGORIES <- c(
  "Coast_only","River_only","Compound_extreme",
  "Compound_moderate","Non_extreme"
)

PREDICTORS <- c("NAO","AMM")
REFERENCE <- "Non_extreme"

RUN_TAG <- "p85_WY1960_2020_mindays5_zeroENSO"
OUTDIR <- "final_outputs"

N_BOOT <- 500
CI_LEVEL <- 0.90
set.seed(42)

df_cc <- readRDS(file.path(OUTDIR,paste0("df_cc_",RUN_TAG,".rds")))
dm_fits <- readRDS(file.path(OUTDIR,paste0("dm_fits_",RUN_TAG,".rds")))

fit_dm <- function(d) {
  d <- d %>% filter(All_events > 0) %>% mutate(logN=log(All_events))
  Y <- as.matrix(d[,CATEGORIES])
  storage.mode(Y) <- "numeric"
  colnames(Y) <- CATEGORIES
  fit <- MGLMreg(Y ~ NAO + AMM + logN,data=d,dist="DM")
  B <- fit@coefficients
  if (is.null(rownames(B))) rownames(B) <- colnames(model.matrix(~ NAO + AMM + logN,data=d))
  if (is.null(colnames(B))) colnames(B) <- CATEGORIES
  fit@coefficients <- B
  fit
}

rrr <- function(B,pred) {
  b <- B[pred,]
  exp(b-b[REFERENCE])
}

qci <- function(x) {
  a <- (1-CI_LEVEL)/2
  quantile(x,c(a,1-a),na.rm=TRUE,names=FALSE)
}

rows <- list()

for (stn in STATIONS) {

  d <- df_cc %>% filter(station == stn)
  point_fit <- dm_fits[[stn]]
  B <- point_fit@coefficients

  dpos <- d %>% filter(All_events > 0) %>% mutate(logN=log(All_events))
  if (is.null(rownames(B))) rownames(B) <- colnames(model.matrix(~ NAO + AMM + logN,data=dpos))
  if (is.null(colnames(B))) colnames(B) <- CATEGORIES

  boot <- lapply(PREDICTORS,function(x) matrix(NA_real_,N_BOOT,length(CATEGORIES),dimnames=list(NULL,CATEGORIES)))
  names(boot) <- PREDICTORS

  ok <- 0

  for (b in seq_len(N_BOOT)) {
    id <- sample(seq_len(nrow(d)),nrow(d),replace=TRUE)
    f <- tryCatch(fit_dm(d[id,,drop=FALSE]),error=function(e) NULL)
    if (is.null(f)) next
    ok <- ok+1
    for (p in PREDICTORS) boot[[p]][ok,] <- rrr(f@coefficients,p)
  }

  for (p in PREDICTORS) {
    rp <- rrr(B,p)
    for (cat in setdiff(CATEGORIES,REFERENCE)) {
      ci <- qci(boot[[p]][seq_len(ok),cat])
      rows[[length(rows)+1]] <- data.frame(
        station=stn,predictor=p,category=cat,
        reference_category=REFERENCE,
        RRR_vs_ref=rp[cat],RRR_lo=ci[1],RRR_hi=ci[2],
        boot_ok=ok,ci_level=CI_LEVEL
      )
    }
  }
}

write.csv(bind_rows(rows),
  file.path(OUTDIR,paste0("part2_dm_effects_",RUN_TAG,"_CI90.csv")),
  row.names=FALSE)

cat("DM relative effects complete\n")
