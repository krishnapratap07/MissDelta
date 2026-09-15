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


## Required inputs
- `NOA.csv`
- `oni.csv`
- `amm.csv`
- `AMO.txt`
- `wl_data.csv`

