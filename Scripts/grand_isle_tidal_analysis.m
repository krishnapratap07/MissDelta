%% Grand Isle tidal analysis and storm-surge calculation

clear;
clc;

%% 1. Read Grand Isle hourly water-level data

grandisle = readtable("8761724_water_level_data1980_2024.csv");

% Create datetime vector
datetime_vals = datetime(grandisle.Year, grandisle.Month, grandisle.Day) ...
    + hours(grandisle.Time - 1);

% Create a continuous hourly time series
start_date = min(datetime_vals);
end_date   = max(datetime_vals);

full_datetime = start_date:hours(1):end_date;
full_WL = NaN(size(full_datetime));

[~, original_indices] = ismember(datetime_vals, full_datetime);

full_WL(original_indices(original_indices > 0)) = grandisle.WL;

grandisle_datetime = full_datetime';
grandisle_wl = full_WL';


%% 2. Remove the 30-day moving-average baseline

window_size = 30 * 24;

movingSum = movsum(grandisle_wl, window_size, 'omitnan');
validCount = movsum(~isnan(grandisle_wl), window_size);

baseline = movingSum ./ validCount;

% Baseline is retained only when more than 50% of the window has data
baseline(validCount <= window_size/2) = NaN;

% Detrended water level
detrended_wl = grandisle_wl - baseline;


%% 3. Perform yearly tidal analysis using UTide

lat = 29.263333333333332;
fracCoverage = 0.75;

uniqueYears = unique(year(grandisle_datetime));

tidalPrediction = NaN(size(detrended_wl));
stormSurge = NaN(size(detrended_wl));

for y = uniqueYears'

    idxYear = year(grandisle_datetime) == y;

    yearData = detrended_wl(idxYear);
    yearTime = grandisle_datetime(idxYear);

    % Skip years with less than 75% data coverage
    if sum(~isnan(yearData))/numel(yearData) < fracCoverage
        warning('Year %d has insufficient data - skipping.', y);
        continue
    end

    % UTide harmonic analysis
    tDays = datenum(yearTime);

    coef = ut_solv(tDays, yearData, [], lat, 'auto');

    [recon, ~] = ut_reconstr(tDays, coef);

    % Tidal prediction
    tidalPrediction(idxYear) = recon;

    % Storm-surge residual
    stormSurge(idxYear) = yearData - recon;

end


%% 4. Save hourly tidal-analysis results

GI_tidalResults.Datetime = grandisle_datetime;
GI_tidalResults.WaterLevel = grandisle_wl;
GI_tidalResults.TrendBaseline = baseline;
GI_tidalResults.TidalPrediction = tidalPrediction;
GI_tidalResults.StormSurge = stormSurge;

save('Grand_Isle_Tidal_analysis.mat', 'GI_tidalResults');


%% 5. Extract daily maximum storm surge

t = GI_tidalResults.Datetime;
s = GI_tidalResults.StormSurge;

% Ignore NaNs when calculating daily maximum
s2 = s;
s2(isnan(s2)) = -inf;

TT = timetable(t, s2, 'VariableNames', {'StormSurge'});

% Daily maximum storm surge
D = retime(TT, 'daily', 'max');

dailyMax = D.StormSurge;

% Convert days containing no valid observations back to NaN
dailyMax(isinf(dailyMax)) = NaN;


%% 6. Save daily maximum storm surge

out = table( ...
    D.Properties.RowTimes, ...
    dailyMax, ...
    'VariableNames', {'Date','DailyMaxStormSurge'});

writetable(out, 'GrandIsle_DailyMax_StormSurge.csv');

save('GrandIsle_DailyMax_StormSurge.mat', 'out');