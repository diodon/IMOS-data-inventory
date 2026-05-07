# IMOS Data Inventory

Tools to inventory and characterise datasets available through the [IMOS](https://imos.org.au) (Integrated Marine Observing System) and [AODN](https://aodn.org.au) (Australian Ocean Data Network) GeoNetwork catalogues, developed in support of the [NESP Marine and Coastal Hub](https://nespmarinecoastal.edu.au) (MacHub) data uplift activities.

## Overview

The notebooks query the public GeoNetwork catalogue APIs to retrieve dataset metadata records, extract and normalise spatial geometries into WKT format, compute temporal extents, and flag records with invalid date ranges. Results are saved as CSV files for downstream analysis.

A parallel R Markdown implementation of the IMOS workflow is provided for users who prefer working in R.

## Repository structure

```
.
├── exploreIMOScatalogue.ipynb   # Python — queries the IMOS GeoNetwork catalogue
├── exploreAODNcatalogue.ipynb   # Python — queries the AODN GeoNetwork catalogue (NESP/MaC filter)
├── exploreIMOScatalogue.Rmd     # R Markdown — equivalent of the IMOS Python notebook
├── extractWKT.R                 # R — WKT geometry extraction from saved NESP datasets
├── IMOS_Dscount.R               # R — counts active IMOS datasets per year and plots the result
└── tempExtent_haxagons.R        # R — temporal extent calculations for hexagonal coverage grids
```

## Data sources

| Catalogue | API base URL |
|---|---|
| IMOS | `https://catalogue-imos.aodn.org.au/geonetwork/srv/eng/q` |
| AODN | `https://catalogue.aodn.org.au/geonetwork/srv/eng/q` |

Both APIs follow the GeoNetwork 3.x query interface. Responses are paginated at 100 records per page; the notebooks handle pagination automatically.

## Spatial geometry normalisation

Spatial extent in the GeoNetwork catalogue is stored across two separate fields — `geoPolygon` and `geoBox` — and neither is guaranteed to be present in every record:

- **`geoPolygon`** — polygon geometry as a WKT string or an array of WKT strings for records with multiple spatial extents.
- **`geoBox`** — bounding box encoded as `minlon|minlat|maxlon|maxlat`, used as a fallback when no polygon is available.

The notebooks produce a unified `wkt` column by applying the following priority logic:

1. If `geoPolygon` is present, use it directly (multiple polygons are merged into a `MULTIPOLYGON`).
2. Otherwise, construct a bounding-box polygon from `geoBox`.
3. If neither field is available, the record receives a null geometry.

## Output files

All output filenames include the run date as `YYYYMMDD`.

| File pattern | Contents |
|---|---|
| `IMOS_datasets_<date>.csv` | All IMOS catalogue records with selected metadata and WKT geometry |
| `IMOS_wrongTemporalExtent_<date>.csv` | IMOS records where `tempExtentEnd < tempExtentBegin` |
| `keywords_<date>.csv` | IMOS keyword column (one record per row, keywords `\|`-separated) |
| `NESP_datasets_<date>.csv` | All AODN/NESP catalogue records |
| `NESP_MaC_datasets_<date>.csv` | AODN records filtered to NESP Marine and Coastal Hub |
| `AODN_wrongTemporalExtent_<date>.csv` | AODN/NESP records where `tempExtentEnd < tempExtentBegin` |
| `keywords_AODN_<date>.csv` | AODN keyword column |

## Requirements

### Python

Requires Python ≥ 3.13. Install dependencies with [uv](https://github.com/astral-sh/uv):

```bash
uv sync
```

Key packages: `requests`, `pandas`, `folium`, `geopandas`, `shapely`.

### R

Key packages: `httr2`, `dplyr`, `purrr`, `lubridate`, `readr`, `ggplot2`.

Install from CRAN:

```r
install.packages(c("httr2", "dplyr", "purrr", "lubridate", "readr", "ggplot2", "tidyr"))
```

## Usage

### Python notebooks

Open with Jupyter and run all cells:

```bash
jupyter notebook exploreIMOScatalogue.ipynb
jupyter notebook exploreAODNcatalogue.ipynb
```

### R Markdown

Knit from RStudio or from the R console:

```r
rmarkdown::render("exploreIMOScatalogue.Rmd")
```

## Notes

- The AODN notebook filters records to those containing `"NESP"` in the title at query time and then further subsets to records containing `"MaC"` (Marine and Coastal Hub).
- The IMOS notebook retrieves all catalogue records with no title filter.
- Records with `temporalExtent < 0` indicate data entry errors in the catalogue (end date before start date) and are saved separately for review.
