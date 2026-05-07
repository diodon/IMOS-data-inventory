## extract geometry from NESP MaC records

library(readr)
library(stringr)
library(dplyr)

## function to convert minLon, minLat, maxLon and maxLat to WKT POLYGON
bbox2Poly <- function(minLon, minLat, maxLon, maxLat, polygon=TRUE){
  if (polygon){
    return(paste0("POLYGON((", minLon, " ", minLat, ",", maxLon, " ", minLat, ",", maxLon, " ", maxLat, ",", minLon, " ", maxLat, ",", minLon, " ", minLat, "))"))
  } else {
    return(paste0(minLon, " ", minLat, ", ", maxLon, " ", minLat, ", ", maxLon, " ", maxLat, ", ", minLon, " ", maxLat, ",", minLon, " ", minLat))
  }
}

## function to convert a list of bboxes into a MULTIPOLYGON
bboxList2WKT <- function(bbox){
  bbox <- str_remove(str_remove(bbox, "\\["), "\\]")
  bboxes <- str_split(bbox, ",", simplify = TRUE)
  wkt <- ""
  for (i in 1:length(bboxes)){ 
    coords <- str_remove_all(bboxes[i], "\\'")
    coords <- str_split(coords, "\\|", simplify = TRUE)
    coords <- bbox2Poly(coords[1], coords[2], coords[3], coords[4], polygon=FALSE)
    wkt <- paste0(wkt, "((", coords, ")), ")
  }
  wkt <- str_remove(wkt, ", $")
  wkt <- paste0("MULTIPOLYGON(", wkt, ")")
  return(wkt)
}

pointList2WKT <- function(bbox){ 
  bbox <- str_remove(str_remove(bbox, "\\["), "\\]")
  bboxes <- str_split(bbox, ",", simplify = TRUE)
  wkt <- ""
  for (i in 1:length(bboxes)){ 
    coords <- bboxes[i]
    coords <- str_remove_all(coords, "\\'")
    coords <- str_remove_all(coords, "POINT")
    coords <- str_remove_all(coords, "\\(")
    coords <- str_remove_all(coords, "\\)")
    coords <- str_trim(coords)
    wkt <- paste0(wkt, "(", coords, "), ")
  }
  wkt <- str_remove(wkt, ", $")
  wkt <- paste0("MULTIPOINT(", wkt, ")")
  return(wkt)
}

# read in the data
NESP <- read_csv("NESP_MacHub/Code/NESP_datasets.csv")

## CLEAN geoPolygon
NESP$geoPolygon <- str_remove(NESP$geoPolygon, "\\[\\'")
NESP$geoPolygon <- str_remove(NESP$geoPolygon, "\\'\\]")
NESP$geoPolygon[NESP$geoPolygon == "MULTIPOLYGON EMPTY"] <- NA


NESP$WKT <- NA
## Copy geoPolygon
NESP$WKT <- ifelse(!is.na(NESP$geoPolygon), NESP$geoPolygon, NA)

## Process geoBox
for (i in 1:nrow(NESP)){
  if (is.na(NESP$WKT[i])){
    if (!grepl("\\[", NESP$geoBox[i])){
      coords <- as.numeric(str_split(NESP$geoBox[5], "\\|", simplify = TRUE))
      NESP$WKT[i] <- bbox2Poly(coords[1], coords[2], coords[3], coords[4])
    }
    if (grepl("\\[", NESP$geoBox[i])){
      NESP$WKT[i] <- bboxList2WKT(NESP$geoBox[i])
    }
    if (grepl("POINT", NESP$geoBox[i])){
      NESP$WKT[i] <- pointList2WKT(NESP$geoBox[i])
    }
  }
}
 
## save as CSV
## only MaC records
NESP <- NESP[grepl("MaC", NESP$title),] 
## add id
NESP$id <- 1:nrow(NESP)
NESP <-  NESP |> relocate(id)

## write to CSV
write_csv(NESP, "NESP_MacHub/Code/NESPMaC_datasets_wkt.csv")
 