# Final climate/statistical analysis scripts

Run in this order:

0. `00_decadal_counts_daily_ERA5.m` (for the decadal-composition analysis)
1. `01_annual_flood_counts_water_year.m`
2. `02_preprocess_climate_indices.m`
2b. `02b_export_wl_data_for_R.m`
3. `03_prepare_analysis_panel.R`
4. `04_hurdle_total_flood_days.R`
5. `05_dirichlet_multinomial_composition.R`
6. `06_dm_relative_effects.R`
7. `07_kitagawa_decomposition.R`
8. `08_per_category_hurdle.R`
9. `09_single_driver_hurdle.R`
10. `10_hurdle_specification_sensitivity.R`
11. `11_amo_amm_correlation.R`

## Important standardization rule

NAO, ENSO, and AMM are standardized once on their unique annual values over
WY1960-WY2020 **before** they are joined to the station-year flood panel.

This is the corrected approach from the revised Part 1 and Part 2 scripts.
All later R scripts read the same saved `df_cc` panel, so the scaling cannot
change from one analysis to another.

## Required inputs

- `Series_byStation_byPercentile_ERA5_daily.mat`
- `NOA_data.csv`
- `oni.csv`
- `amm.csv`
- `AMO_data.txt`
- `wl_data.csv`

The first two MATLAB scripts additionally create:

- `flood_annual_counts_water_year_5_cat.csv`
- `processed_noa.csv`
- `processed_enso_ondjf.csv`
- `AMM_annual_wateryear.csv`
- `AMO_annual_wateryear.csv`

## Outputs

All R results are written to `final_outputs/`.

Python plotting scripts can read the resulting CSV files separately.
