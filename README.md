# Drivers of high-water levels in the Lower Mississippi River

## Overview

This repository contains the workflow used to identify and classify high-water-level events along the Lower Mississippi River and to evaluate their spatial and temporal variability and associations with large-scale climate variability.

The analysis combines Mississippi River water-level observations, river discharge, coastal water-level and storm-surge information, and large-scale climate indices. High-water-level events are classified according to the relative influence of riverine and coastal forcing, and changes in flood-day frequency and composition are evaluated across multiple gauges.


# Workflow

## 1. Data Preparation

The first step prepares the hydrologic and coastal datasets used throughout the analysis.

### Input data

- Mississippi River water-level observations from USACE gauges

- Mississippi River discharge at Tarbert Landing

- Grand Isle tide-gauge water level from NOAA

- GTSM v3.0 coastal water-level and storm-surge data forced by ERA5

- Large-scale climate indices:

    - NAO

    - ONI / ENSO

    - AMM

    -  AMO

### Procedure

1. Import daily or hourly water-level observations for each Mississippi River gauge.

2. Import Tarbert Landing discharge.

3. Import Grand Isle coastal water-level observations.

4. Import ERA5-forced GTSM coastal water-level and storm-surge data.

5. Standardize dates, units, station identifiers, and missing-value conventions.

6. Restrict the analysis to the common study period.

7. Create analysis-ready daily datasets for each station.

### Outputs

Typical processed outputs include:

- cleaned river water-level time series

- discharge time series

- coastal water-level time series

- station-specific merged analysis tables

### 2. Water-Level and Discharge Processing

This step characterizes the relationship between Mississippi River water level and discharge and prepares the riverine component used in the flood-driver analysis.

### Procedure

1. Match river water-level observations with Tarbert Landing discharge.

2. Examine the stage-discharge relationship at each station.

3. Estimate the expected river water level associated with discharge.

4. Separate river-driven variability from downstream coastal influence where required.

5. Generate processed water-level components used in subsequent analyses.

### Outputs

- stage-discharge relationships

- river-related water-level component

- coastal or residual water-level component

- diagnostic plots used in the manuscript

### 3. Identification of High-Water-Level Days

High-water-level days are identified independently at each Mississippi River gauge.

### Procedure

1. Define station-specific water-level thresholds.

2. Identify days exceeding the selected threshold.

3. Retain the corresponding riverine and coastal forcing values for each high-water-level day.

4. Construct a station-level event table containing the information needed for classification.

### Outputs

- daily high-water-level event tables

- annual high-water-level counts

- station-specific event summaries

### 4. Classification of Flood-Generating Mechanisms

Each high-water-level day is classified according to the magnitude of riverine and coastal forcing.

### Categories

- **River-only**

- **Coast-only**

- **Compound-extreme**

- **Compound-moderate**

- **Non-extreme**

### Procedure

1. Define thresholds for riverine and coastal forcing.

2. Compare the forcing values associated with each high-water-level day with the corresponding thresholds.

3. Assign each day to one flood-day category.

4. Repeat the classification at all Mississippi River gauges.

5. Calculate the number and percentage of days in each category.

### Outputs

- classified flood-day tables

- category counts by station

- category percentages

- spatial comparison of flood-generating mechanisms

### 5. Temporal Changes in Flood-Day Frequency and Composition

This step evaluates how total flood occurrence and the composition of flood-generating mechanisms change through time.

### Procedure

1. Aggregate classified flood days by water year.

2. Calculate annual counts for:

  - total flood days

  - river-only days

  - coast-only days

  - compound-extreme days

  - compound-moderate days

  - non-extreme days

3. Aggregate counts into non-overlapping decadal periods where required.

4. Compare temporal changes among stations and categories.

### Outputs

- annual flood-day counts

- decadal category counts

- temporal-composition figures

### 6. Climate-Index Processing

Large-scale climate indices are processed to evaluate their association with flood-day occurrence.

### Climate indices

- North Atlantic Oscillation (**NAO**)

- El Niño–Southern Oscillation represented by the Oceanic Niño Index (**ONI**)

- Atlantic Meridional Mode (**AMM**)

- Atlantic Multidecadal Oscillation (**AMO**)

### Procedure

1. Download monthly climate-index values from NOAA.

2. Aggregate the indices to the seasonal or water-year definitions used in the study.

3. Match climate-index values with annual flood-day counts.

4. Standardize predictors for regression analyses.

### Outputs

- merged flood-count and climate-index datasets

### 7. Hurdle-Model Analysis

Negative-binomial hurdle models are used to evaluate associations between large-scale climate variability and annual flood-day counts.

### Procedure

1. Fit a hurdle model that separates:

  - the occurrence of any flood days in a water year

  - the number of flood days conditional on a positive count

3. Fit models for total flood days and individual flood-day categories.

4. Evaluate NAO, AMM, and ENSO effects according to the model specification used in the manuscript.

5. Convert regression coefficients to incidence-rate ratios or odds ratios where appropriate.

6. Calculate confidence intervals and prepare station-specific summaries.

### Outputs

hurdle-model coefficient tables

incidence-rate-ratio summaries

odds-ratio summaries

station-specific forest plots

8. Single-Driver Climate Models

Single-driver hurdle models are used as a complementary analysis to evaluate the direction and consistency of individual climate associations.

Procedure

Fit separate models for individual climate indices.

Repeat the analysis for total flood days and each flood-day category.

Compare the direction of the single-driver associations with the multivariable model results.

Generate spatial forest plots for each climate driver.

Outputs

single-driver hurdle-model tables

NAO spatial forest plots

AMM spatial forest plots

9. Kitagawa Decomposition

A Kitagawa decomposition is used to separate changes in category-specific flood-day counts into contributions from overall flood frequency and flood-day composition.

Procedure

Estimate the expected total number of flood days under contrasting climate-index conditions.

Calculate the expected number of days in each flood category.

Decompose the category-specific change into:

frequency contribution

composition contribution

Verify the identity:

total category change = frequency contribution + composition contribution

Calculate uncertainty intervals using the bootstrap procedure used in the manuscript.

Repeat the analysis for NAO and AMM.

Outputs

NAO Kitagawa-decomposition tables

AMM Kitagawa-decomposition tables

frequency and composition contributions

bootstrap confidence intervals

decomposition figures

10. Figure Generation

The final step generates the manuscript and supplementary figures from the processed data and statistical-analysis outputs.

Main figure groups

study area and station locations

water-level and discharge relationships

water-level components

contrasting flood mechanisms

conditional probability distributions

flood-day category percentages

daily versus hourly classification comparison

decadal changes in flood-day categories

climate-model effect estimates

NAO Kitagawa decomposition

AMM Kitagawa decomposition

Supplementary figures

single-driver NAO hurdle-model results

single-driver AMM hurdle-model results

additional model diagnostics and sensitivity analyses
