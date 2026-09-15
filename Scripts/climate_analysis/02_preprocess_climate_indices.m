%% Climate-index preprocessing

clear
clc

%% NAO: December-March mean and 1-year lag

nao = readtable('NOA_data.csv');

TT = table2timetable(nao,'RowTimes','Datetime');
TT = TT(:, "noa_value");

yr = year(TT.Datetime);
mo = month(TT.Datetime);

seasonYear = yr;
seasonYear(mo == 12) = yr(mo == 12) + 1;

idx = ismember(mo,[12 1 2 3]);

TT_DJFM = TT(idx,:);
seasonYear_DJFM = seasonYear(idx);

[G,yearsOut] = findgroups(seasonYear_DJFM);

djfmMean = splitapply(@(x) mean(x,'omitnan'), ...
    TT_DJFM.noa_value,G);

NAO_DJFM = table(yearsOut,djfmMean, ...
    'VariableNames',{'Year','NAO_DJFM_mean'});

NAO_DJFM.NAO_DJFM_lag1 = ...
    [NaN; NAO_DJFM.NAO_DJFM_mean(1:end-1)];

writetable(NAO_DJFM,'processed_noa.csv');


%% ENSO: October-February ONI mean

oni = readtable('oni.csv');

TT = table2timetable(oni,'RowTimes','Date');
TT = TT(:, "ONI");

yr = year(TT.Date);
mo = month(TT.Date);

seasonYear = yr;
seasonYear(ismember(mo,[10 11 12])) = ...
    yr(ismember(mo,[10 11 12])) + 1;

idx = ismember(mo,[10 11 12 1 2]);

TT_ONDJF = TT(idx,:);
seasonYear_ONDJF = seasonYear(idx);

[G,yearsOut] = findgroups(seasonYear_ONDJF);

ondjfMean = splitapply(@(x) mean(x,'omitnan'), ...
    TT_ONDJF.ONI,G);

ENSO_ONDJF = table(yearsOut,ondjfMean, ...
    'VariableNames',{'Year','ONDJF_ONI'});

writetable(ENSO_ONDJF,'processed_enso_ondjf.csv');


%% AMM: October-September water-year mean

amm = readtable("amm.csv");

wy_amm = year(amm.Date) + double(month(amm.Date) >= 10);

[G,yearsOut] = findgroups(wy_amm);

amm_wy_mean = splitapply(@(x) mean(x,'omitnan'), ...
    amm.SSTAMM,G);

AMM_annual_wateryear = table(yearsOut,amm_wy_mean, ...
    'VariableNames',{'WaterYear','AMM_wateryear_mean'});

writetable(AMM_annual_wateryear, ...
    'AMM_annual_wateryear.csv');


%% AMO: October-September water-year mean

AMOdata = readtable("AMO_data.txt");

yrs = AMOdata.Var1;
monthly_vals = AMOdata{:,2:13};

monthly_vals(monthly_vals < -90) = NaN;

valid_rows = isfinite(yrs) & mod(yrs,1) == 0;

yrs = yrs(valid_rows);
monthly_vals = monthly_vals(valid_rows,:);

nYears = length(yrs);

yearCol = repelem(yrs,12);
monthCol = repmat((1:12)',nYears,1);
amoCol = reshape(monthly_vals',[],1);

Date = datetime(yearCol,monthCol,1);

AMO_monthly = table(Date,amoCol, ...
    'VariableNames',{'Date','AMO'});

wy_amo = year(AMO_monthly.Date) + ...
    double(month(AMO_monthly.Date) >= 10);

[G,yearsOut] = findgroups(wy_amo);

amo_wy_mean = splitapply(@(x) mean(x,'omitnan'), ...
    AMO_monthly.AMO,G);

AMO_annual_wateryear = table(yearsOut,amo_wy_mean, ...
    'VariableNames',{'WaterYear','AMO_wateryear_mean'});

writetable(AMO_annual_wateryear, ...
    'AMO_annual_wateryear.csv');

disp('Climate indices processed')
