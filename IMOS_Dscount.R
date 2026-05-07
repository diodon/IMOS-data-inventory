library(readr)
library(dplyr)
library(lubridate)
library(tidyr)
library(ggplot2)

df <- read_csv("Code/IMOS_datasets_20251106.csv")
currentYear <- 2025

df$tExtBegin <- ymd_hms(df$tempExtentBegin)
df$yearStart <- year(df$tExtBegin)
df$tExtEnd <- ymd_hms(df$tempExtentEnd)
df$yearEnd <- ifelse(is.na(df$tExtEnd), currentYear, year(df$tExtEnd))


## split the keywords column into multiple rows
df_keywords <- df |> 
  mutate(keywords = strsplit(as.character(keyword), ",")) 

df_keywords <- df_keywords |>
  unnest(keywords) |>
  mutate(keywords = trimws(keywords)) 


yearCount <- data.frame(year = integer(),
                        count = integer())
for (i in 1:nrow(df)){ 
  if (!is.na(df$yearStart[i])){
    years <- seq(df$yearStart[i], df$yearEnd[i])
    yearCount <- bind_rows(yearCount,
                               data.frame(year = years,
                                          count = rep(1, length(years))))
  }
}
yearly_summary <- yearCount %>%
  group_by(year) %>%
  summarise(count = sum(count)) %>%
  arrange(year)

## make the plot
p <- ggplot(yearly_summary, aes(x = year, y = count)) +
  geom_line(color = "blue") +
  geom_point(color = "red") +
  labs(title = "Number of Active Datasets per Year (as metadata records)",
       x = "Year",
       y = "Number of Active Datasets") +
  theme_bw()
p
