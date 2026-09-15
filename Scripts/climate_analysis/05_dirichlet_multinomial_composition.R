# Dirichlet-multinomial composition model
# cbind(5 categories) ~ NAO + AMM + logN

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(MGLM)
})

STATIONS <- c("Daily_01300","Daily_01320","Daily_01340","Daily_01400","Daily_01480")

CATEGORIES <- c(
  "Coast_only","River_only","Compound_extreme",
  "Compound_moderate","Non_extreme"
)

RUN_TAG <- "p85_WY1960_2020_mindays5_zeroENSO"
OUTDIR <- "final_outputs"

df_cc <- readRDS(file.path(OUTDIR,paste0("df_cc_",RUN_TAG,".rds")))

name_coef <- function(B,d) {
  rn <- colnames(model.matrix(~ NAO + AMM + logN,data=d))
  if (is.null(rownames(B))) rownames(B) <- rn
  if (is.null(colnames(B))) colnames(B) <- CATEGORIES
  B
}

model_df <- function(m) {
  x <- attr(logLik(m),"df")
  if (!is.null(x)) return(as.numeric(x))
  length(as.numeric(m@coefficients))
}

lrt <- function(full,reduced) {
  lf <- logLik(full); lr <- logLik(reduced)
  df <- model_df(full)-model_df(reduced)
  stat <- 2*(as.numeric(lf)-as.numeric(lr))
  c(LRT=stat,df=df,p=pchisq(stat,df=df,lower.tail=FALSE))
}

dm_fits <- list()
coef_rows <- list()
lrt_rows <- list()
pred_rows <- list()

for (stn in STATIONS) {

  d <- df_cc %>%
    filter(station == stn,All_events > 0) %>%
    mutate(logN=log(All_events))

  Y <- as.matrix(d[,CATEGORIES])
  storage.mode(Y) <- "numeric"
  colnames(Y) <- CATEGORIES

  fit <- MGLMreg(Y ~ NAO + AMM + logN,data=d,dist="DM")
  B <- name_coef(fit@coefficients,d)
  fit@coefficients <- B
  dm_fits[[stn]] <- fit

  coef_rows[[stn]] <- as.data.frame(B) %>%
    mutate(predictor=rownames(B),station=stn) %>%
    pivot_longer(all_of(CATEGORIES),names_to="category",values_to="coefficient")

  fit_no_nao <- MGLMreg(Y ~ AMM + logN,data=d,dist="DM")
  fit_no_amm <- MGLMreg(Y ~ NAO + logN,data=d,dist="DM")
  fit_no_clim <- MGLMreg(Y ~ logN,data=d,dist="DM")

  a <- lrt(fit,fit_no_nao)
  b <- lrt(fit,fit_no_amm)
  c <- lrt(fit,fit_no_clim)

  lrt_rows[[stn]] <- data.frame(
    station=stn,
    NAO_LRT=a["LRT"],NAO_df=a["df"],NAO_p=a["p"],
    AMM_LRT=b["LRT"],AMM_df=b["df"],AMM_p=b["p"],
    NAO_AMM_LRT=c["LRT"],NAO_AMM_df=c["df"],NAO_AMM_p=c["p"]
  )

  refN <- median(d$All_events)
  xscen <- data.frame(
    scenario=c("mean_climate","NAO_plus1SD","AMM_plus1SD","NAO_AMM_plus1SD"),
    NAO=c(0,1,0,1),
    AMM=c(0,0,1,1),
    logN=log(refN)
  )

  pred_rows[[stn]] <- bind_rows(lapply(seq_len(nrow(xscen)),function(i) {
    x <- c("(Intercept)"=1,NAO=xscen$NAO[i],AMM=xscen$AMM[i],logN=xscen$logN[i])
    eta <- as.numeric(t(x[rownames(B)]) %*% B)
    alpha <- exp(pmax(pmin(eta,700),-700))
    data.frame(
      station=stn,
      scenario=xscen$scenario[i],
      category=CATEGORIES,
      predicted_proportion=alpha/sum(alpha),
      reference_N=refN
    )
  }))
}

saveRDS(dm_fits,file.path(OUTDIR,paste0("dm_fits_",RUN_TAG,".rds")))

write.csv(bind_rows(coef_rows),
  file.path(OUTDIR,paste0("part2_dm_coefficients_long_",RUN_TAG,".csv")),
  row.names=FALSE)

write.csv(bind_rows(lrt_rows),
  file.path(OUTDIR,paste0("part2_dm_lrt_",RUN_TAG,".csv")),
  row.names=FALSE)

write.csv(bind_rows(pred_rows),
  file.path(OUTDIR,paste0("part2_dm_predicted_composition_",RUN_TAG,".csv")),
  row.names=FALSE)

cat("Dirichlet-multinomial models complete\n")
