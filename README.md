# NYC Child Care Capacity and Demand
### A Study of NYC child care capacity, demand, and where care is needed most

**Author:** Allen Harris
**Course:** DAV 640 — Data Analysis and Visualization
**Date:** Spring 2026

---

## Overview

This repository contains the analysis for a study of New York City's child care capacity crisis across three analytical threads:

1. **Supply-side time series** — Longitudinal trends in licensed child care capacity in NYC from 2015 to 2025 by program modality, using data from the NY State Office of Children and Family Services (OCFS).
2. **Demand-side modeling** — Poisson regression models estimating racial and ethnic disparities in the number of children under age 5 among NYC adults, using 2024 ACS PUMS data accessed via the IPUMS API.
3. **Spatial analysis** — A bivariate Lee's L spatial association test comparing Hispanic child population density against child care center capacity at the PUMA level, conducted in ArcGIS Pro.

---

## Data Sources

### NYC Child Care Capacity Over a Decade — OCFS

> Available at: https://ocfs.ny.gov/programs/childcare/data/ or included in this repository under `data/raw/`

The NY State Office of Children and Family Services publishes annual Child Care Facts and Figures reports tracking the number and capacity of licensed and registered child care programs statewide. Records were filtered to NYC providers and aggregated by year and program modality. The original data does not come structured for year-over-year analysis and was restructured using OpenRefine before analysis.

**Modality codes used throughout:**

| Code | Program Type |
|------|-------------|
| DCC | Day Care Center |
| FDC | Family Day Care |
| GFDC | Group Family Day Care |
| SACC | School-Age Child Care |

---

### Active NYC Health Code Regulated Child Care Programs — NYC Open Data

> Available at: https://data.cityofnewyork.us/Health/Active-Child-Care-Programs/dsg6-ifza or included in this repository under `data/raw/`

Point-level locations of active, health code regulated child care programs across all five boroughs. Used in conjunction with the OCFS capacity data to spatially join provider locations to PUMA polygons in ArcGIS Pro.

---

### ACS PUMS 2024 — IPUMS API

> Available at: https://usa.ipums.org/usa/

Individual-level population microdata from the 2024 ACS 1-Year Public Use Microdata Sample, accessed programmatically via the IPUMS API using the `ipumsr` R package. No manual download is required. The script submits an extract request, downloads the result, and caches it locally to avoid repeat API calls.

**Variables pulled:** `PUMA`, `AGE`, `SEX`, `RACE`, `HISPAN`, `INCTOT`, `POVERTY`, `NCHLT5`, `PERWT`

**Filters applied:** NYC PUMAs (2020 definitions), adults aged 18–50

To use the API, register for a free key at https://developer.ipums.org/docs/v2/get-started/ and store it in your `.Renviron` file:

```
IPUMS_API_KEY=your_key_here
```

---

## Analysis Script

`Model Results.R` runs the IPUMS API call, data cleaning pipeline, and Poisson regression models.

> **Note:** The spatial analysis (Lee's L bivariate choropleth) was conducted in ArcGIS Pro and is not reproducible via R alone.

---

## Required R Packages

```r
install.packages(c(
  "ipumsr", "tidyverse", "readxl", "modelsummary",
  "scales", "here", "BayesFactor", "rstanarm", "olsrr"
))
```

---

## Key Findings

- NYC licensed child care capacity peaked at ~20,000 slots in 2015, fell to 17,161 in 2021, and recovered to 18,883 by 2025 — still ~5% below peak.
- The post-2021 recovery is driven almost entirely by Group Family Day Care (GFDC). Family Day Care (FDC) has declined from ~4,700 to ~2,100 slots since 2015.
- Poisson regression (N = 40,153) shows all racial/ethnic minority groups have significantly fewer children under 5 than White non-Hispanic adults, with Black non-Hispanic adults showing the largest gap (IRR = 0.482, ~52% fewer).
- Income and poverty partially mediate but do not eliminate racial disparities.
- Lee's L spatial association test (R² ≈ 0, p > .05) finds no statistically significant spatial co-clustering between Hispanic child density and child care center capacity at the PUMA level.

---

## License

MIT License — see [LICENSE](LICENSE) for details.
