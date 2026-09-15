%% 03 Long-term trend and tidal analysis

clear all
clc

load wl_without_discharge_data.mat

latitudeData = readtable("latitude.xlsx");
lati = latitudeData.Latitude;

datetimeVector = stage_without_disc.DateTime;
variableNames = stage_without_disc.Properties.VariableNames(2:end);

tidalResults = struct();

if isempty(datetimeVector.TimeZone)
    datetimeVector.TimeZone = 'UTC';
end

timeInDays_obs = datenum(datetimeVector);

%% Extended hourly time for tidal prediction

tz = datetimeVector.TimeZone;

datetime_full = ...
    (datetime(1950,1,1,0,0,0,'TimeZone',tz):hours(1): ...
     datetime(2024,12,31,23,0,0,'TimeZone',tz))';

timeInDays_full = datenum(datetime_full);

%% Process each gauge

for i = 1:length(variableNames)

    siteName = variableNames{i};
    siteData_raw = stage_without_disc.(siteName);

    %% Monthly means and linear long-term trend

    TT = timetable(datetimeVector,siteData_raw, ...
        'VariableNames',{'WaterLevel'});

    monthly = retime(TT,'monthly','mean');

    x_month = datenum(monthly.Properties.RowTimes);
    valid = ~isnan(monthly.WaterLevel);

    p = polyfit(x_month(valid),monthly.WaterLevel(valid),1);

    trend = polyval(p,datenum(datetimeVector));

    siteData = siteData_raw - trend;

    %% Harmonic tidal analysis

    lat = lati(i);

    coef = ut_solv( ...
        timeInDays_obs,siteData,[],lat, ...
        'auto','nodiagn','white');

    [tidalPrediction_obs,~] = ...
        ut_reconstr(timeInDays_obs,coef);

    [tidalPrediction_full,~] = ...
        ut_reconstr(timeInDays_full,coef);

    %% Save results

    fieldName = ['S' siteName];

    tidalResults.(fieldName).Datetime_obs = datetimeVector;
    tidalResults.(fieldName).Datetime_full = datetime_full;

    tidalResults.(fieldName).WaterLevel_dis_corr = siteData_raw;
    tidalResults.(fieldName).Trend = trend;

    tidalResults.(fieldName).TidalPrediction_obs = tidalPrediction_obs;
    tidalResults.(fieldName).TidalPrediction_full = tidalPrediction_full;

end

save('tidal_analysis_results.mat','tidalResults');

disp('Tidal analysis complete')
