# AMO-AMM correlation over the modeled period

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

WY_START <- 1960
WY_END <- 2020
OUTDIR <- "final_outputs"

amo <- read_csv("AMO_annual_wateryear.csv",show_col_types=FALSE)
amm <- read_csv("AMM_annual_wateryear.csv",show_col_types=FALSE)

names(amo)[1:2] <- c("wyear","AMO")
names(amm)[1:2] <- c("wyear","AMM")

x <- inner_join(amo,amm,by="wyear") %>%
  filter(wyear >= WY_START,wyear <= WY_END) %>%
  filter(!is.na(AMO),!is.na(AMM))

test <- cor.test(x$AMO,x$AMM,method="pearson")

out <- data.frame(
  WY_start=WY_START,
  WY_end=WY_END,
  n=nrow(x),
  correlation=unname(test$estimate),
  p_value=test$p.value
)

write.csv(out,file.path(OUTDIR,"AMO_AMM_correlation_WY1960_2020.csv"),row.names=FALSE)

print(out)
