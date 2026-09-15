# Drivers of high-water levels in the Lower Mississippi River

## Overview

This repository contains the analysis workflow used to identify and classify high-water-level events along the Lower Mississippi River and to evaluate their spatial and temporal variability and associations with large-scale climate variability.

The analysis combines Mississippi River water-level observations, river discharge, coastal water-level and storm-surge information, and large-scale climate indices. High-water-level events are classified according to the relative influence of riverine and coastal forcing, and changes in flood-day frequency and composition are evaluated across five river gauges.

# Workflow

## 1. Water-Level Processing

Mississippi River water-level records are processed to remove the long-term water-level trend and deterministic astronomical tides while retaining variability associated with river discharge and coastal forcing.

For the hourly records, the relationship between river water level and Tarbert Landing discharge is estimated using a moving regression. The discharge-corrected water-level series is then used to estimate the long-term linear trend and astronomical tide using UTide.

The final residual water level is calculated from the original observed water level after removing the estimated long-term trend and astronomical tide.

For the daily USACE records, the same long-term trend is estimated from the discharge-corrected daily series. The astronomical tide predicted from the hourly harmonic analysis is sampled at the daily observation time.

Grand Isle water-level observations are also processed using harmonic tidal analysis to obtain daily maximum storm-surge residuals.

## 2. Flood-Day Classification

High-water-level days are identified independently at each Mississippi River gauge using water-level percentile thresholds.

Each flood day is classified according to river discharge and coastal surge into one of five categories:

- **River-only**
- **Coast-only**
- **Compound-extreme**
- **Compound-moderate**
- **Non-extreme**

The classification is evaluated using both the shorter observational coastal-surge records and the longer bias-corrected ERA5/GTSM surge record.

The analysis is repeated for the 80th, 85th, 90th, and 95th percentile water-level thresholds.

## 3. Temporal Changes in Flooding

Classified flood days are aggregated to examine changes in both the total number of flood days and the relative occurrence of the five flood-day categories.

Event counts are summarized by water year and by non-overlapping 10-year periods. This allows changes in overall flood frequency and flood-generating mechanisms to be compared through time and among river gauges.

## 4. Climate-Index Processing

Four large-scale climate indices are considered:

- North Atlantic Oscillation (**NAO**)
- El Niño–Southern Oscillation (**ENSO**), represented by the Oceanic Niño Index
- Atlantic Meridional Mode (**AMM**)
- Atlantic Multidecadal Oscillation (**AMO**)

NAO is represented by the December–March mean and lagged by one year. ENSO is represented by the October–February mean ONI. AMM and AMO are averaged over the October–September water year.

For the statistical models, NAO, ENSO, and AMM are restricted to the common WY1960–2020 analysis period and standardized using their unique annual values **before** they are merged with the station-year flood records. This ensures that a one-standard-deviation change has the same meaning at every station.

AMO is retained for comparison with AMM but is not included in the final hurdle models.

## 5. Climate and Flood-Frequency Models

Negative-binomial hurdle models are used to examine associations between climate variability and annual flood-day counts.

The primary model separates:

- the probability that a water year contains any flood days, associated with ENSO; and
- the number of flood days in years with flooding, associated with NAO and AMM.

The same framework is also applied separately to the five flood-day categories.

Additional single-driver models evaluate NAO and AMM separately, and alternative hurdle-model specifications are used as sensitivity analyses.

## 6. Flood-Day Composition and Decomposition

A Dirichlet-multinomial model is used to examine whether NAO and AMM are associated with changes in the relative composition of the five flood-day categories while accounting for the total number of flood days.

The hurdle and composition models are then combined using a Kitagawa decomposition. For changes in NAO and AMM, the change in the expected number of days in each flood category is separated into:

- a **frequency contribution**, caused by changes in the total number of flood days; and
- a **composition contribution**, caused by changes in the relative distribution of flood days among categories.

Bootstrap confidence intervals are used to quantify uncertainty in the decomposition.

## 7. Figures

The MATLAB and R scripts in this repository generate the processed datasets and statistical-model outputs used in the study.

Final manuscript and supplementary figures are generated separately in **Python** from these outputs. These include figures showing:

- spatial differences in flood-generating mechanisms;
- changes in flood-day frequency and category composition;
- comparisons between daily and hourly classifications;
- climate-model effect estimates;
- single-driver sensitivity results; and
- NAO and AMM Kitagawa decompositions.
