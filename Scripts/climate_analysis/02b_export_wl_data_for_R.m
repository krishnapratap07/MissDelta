%% Export daily residual water level for R coverage filtering

clear
clc

load daily_data_trend_tides_remove_clean.mat

writetimetable( ...
    daily_data_trend_tides_removed_clean, ...
    'wl_data.csv');

disp('wl_data.csv saved')
