%% 04 Hourly residual and daily maximum

clear all
clc

load original_wl.mat
load tidal_analysis_results.mat

%% Prepare original observed water levels

if ~istimetable(originalData)
    originalData = table2timetable(originalData,'RowTimes','DateTime');
end

originalData = sortrows(originalData);

originalData.Properties.RowTimes = ...
    dateshift(originalData.Properties.RowTimes,'start','hour');

[~,ia] = unique(originalData.Properties.RowTimes);
originalData = originalData(ia,:);

rawTimes = originalData.Properties.RowTimes;

siteFields = fieldnames(tidalResults);

TT_hourly = timetable(rawTimes);
TT_hourly = removevars(TT_hourly,TT_hourly.Properties.VariableNames);

TT_daily = timetable();

aggMax = @(x) max([x;NaN],[],'omitnan');

%% Calculate residual for each gauge

for k = 1:length(siteFields)

    fld = siteFields{k};

    siteName = extractAfter(fld,1);

    if ~ismember(siteName,originalData.Properties.VariableNames)
        warning('%s not found in original water-level data',siteName)
        continue
    end

    observed = timetable( ...
        rawTimes, ...
        originalData.(siteName), ...
        'VariableNames',{'Observed'});

    tS = tidalResults.(fld);

    tideTrend = timetable( ...
        tS.Datetime_obs, ...
        tS.TidalPrediction_obs, ...
        tS.Trend, ...
        'VariableNames',{'Tide','Trend'});

    tideTrend = sortrows(tideTrend);

    tideTrend.Properties.RowTimes = ...
        dateshift(tideTrend.Properties.RowTimes,'start','hour');

    [~,ia2] = unique(tideTrend.Properties.RowTimes);
    tideTrend = tideTrend(ia2,:);

    tideTrend = retime(tideTrend,rawTimes,'fillwithmissing');

    %% Residual = observed water level - trend - astronomical tide

    residual = ...
        observed.Observed - tideTrend.Trend - tideTrend.Tide;

    TT_hourly.(fld) = residual;

    %% Daily maximum residual

    TT = timetable(rawTimes,residual, ...
        'VariableNames',{'Residual'});

    D = retime(TT,'daily',aggMax);

    D.Properties.VariableNames = {fld};

    if isempty(TT_daily)
        TT_daily = D;
    else
        TT_daily = synchronize(TT_daily,D,'union');
    end
end

TT_daily.Properties.RowTimes.Format = 'yyyy-MM-dd';

writetimetable(TT_daily,'Daily_residuals.csv');

save('Daily_residuals.mat','TT_daily');
save('Hourly_residuals.mat','TT_hourly');

disp('Hourly residuals and daily maxima saved')
