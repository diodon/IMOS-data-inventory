## calculate tempoiral extent

# load packages
library(readr)
library(dplyr)
library(lubridate)

# load data
df <- read_csv("GIS/hexcov.csv")

df$tBegin_min <- ymd_hms(df$tBegin_min)
df$tBegin_max <- ymd_hms(df$tBegin_max)
df$tEnd_min <- ymd_hms(df$tEnd_min)
df$tEnd_max <- ymd_hms(df$tEnd_max)

df$tExtent <- as.numeric(pmax(df$tBegin_min, df$tBegin_max, df$tEnd_min, df$tEnd_max, na.rm=T) - pmin(df$tBegin_min, df$tBegin_max, df$tEnd_min, df$tEnd_max, na.rm=T))/(60*60*24*365.25)



