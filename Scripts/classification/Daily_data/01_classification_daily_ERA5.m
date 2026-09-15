%% Daily classification using bias-corrected ERA5 surge

clear all
clc

tz = 'UTC';

%% Load Tarbert Landing discharge

tarbert_dis = readtable("Tarbert_corrected.csv");

badDate = datetime(2010,12,23);
tarbert_dis(tarbert_dis.Date == badDate,:) = [];

TT_dailyq = table2timetable( ...
    tarbert_dis(:,{'Date','Flow_CFS_'}), ...
    'RowTimes','Date');

TT_dailyq = TT_dailyq(:, 'Flow_CFS_');
TT_dailyq.Properties.VariableNames = {'Q'};

TT_dailyq.Properties.RowTimes.TimeZone = 'America/Chicago';
TT_dailyq.Properties.RowTimes.TimeZone = tz;
TT_dailyq.Properties.RowTimes = ...
    dateshift(TT_dailyq.Properties.RowTimes,'start','day');

TT_dailyq = sortrows(TT_dailyq);


%% Load daily residual water level

load daily_data_trend_tides_remove_clean.mat

daily_data_trend_tides_removed_clean.Properties.VariableNames = ...
    {'Daily_01300','Daily_01320','Daily_01340','Daily_01400','Daily_01480'};

TT_daily = daily_data_trend_tides_removed_clean;

TT_daily = sortrows(TT_daily);
TT_daily.Properties.RowTimes = ...
    dateshift(TT_daily.Properties.RowTimes,'start','day');


%% Load bias-corrected ERA5 surge

daily_max_surge_era_bias_corrected = ...
    readtable("ERA5_BiasCorrected.csv");

out_bias_corrected = table( ...
    daily_max_surge_era_bias_corrected.Date, ...
    daily_max_surge_era_bias_corrected.ERA5_corrected_ft, ...
    'VariableNames',{'Date','DailyMaxStormSurge'});

TT_dailys = table2timetable( ...
    out_bias_corrected, ...
    'RowTimes','Date');

TT_dailys = TT_dailys(:, 'DailyMaxStormSurge');
TT_dailys.Properties.VariableNames = {'S'};

TT_dailys.Properties.RowTimes.TimeZone = 'UTC';
TT_dailys.Properties.RowTimes = ...
    dateshift(TT_dailys.Properties.RowTimes,'start','day');

TT_dailys = sortrows(TT_dailys);


%% Synchronize water level, discharge, and ERA5 surge

TT_dailyall_bias_corrected_5cat = synchronize( ...
    TT_daily,TT_dailyq,TT_dailys,'intersection');


%% Output folder

OUTDIR = fullfile("classification_output","Long_record_ERA5");

if ~exist(OUTDIR,'dir')
    mkdir(OUTDIR);
end

save(fullfile(OUTDIR,'TT_dailyall_bias_corrected_5cat.mat'), ...
    'TT_dailyall_bias_corrected_5cat');


%% Driver thresholds

WL_PCTS = [80 85 90 95];

allVars = TT_dailyall_bias_corrected_5cat.Properties.VariableNames;
W_stations = allVars(~ismember(allVars,{'S','Q'}));
W_stations = cellstr(W_stations);

S = TT_dailyall_bias_corrected_5cat.S;
Q = TT_dailyall_bias_corrected_5cat.Q;

tauS_hi = prctile(S(~isnan(S)),90);
tauQ_hi = prctile(Q(~isnan(Q)),90);

tauS_lo = prctile(S(~isnan(S)),80);
tauQ_lo = prctile(Q(~isnan(Q)),80);

S90 = S >= tauS_hi & ~isnan(S);
Q90 = Q >= tauQ_hi & ~isnan(Q);

S80 = S >= tauS_lo & ~isnan(S);
Q80 = Q >= tauQ_lo & ~isnan(Q);

Smod = S80 & ~S90;
Qmod = Q80 & ~Q90;

Slow = ~S80;
Qlow = ~Q80;

validBoth = ~isnan(S) & ~isnan(Q);


%% 5-category classification

cat = struct();

cat.HighCoast_any = S90;
cat.HighRiver_any = Q90;

cat.Compound_extreme = S90 & Q90 & validBoth;
cat.River_only = Q90 & Slow & validBoth;
cat.Coast_only = S90 & Qlow & validBoth;

cat.Compound_moderate = ...
    ((Smod & Qmod) | (S90 & Qmod) | (Smod & Q90)) & validBoth;

cat.Non_extreme = ...
    ((Smod & Qlow) | (Qmod & Slow) | (Slow & Qlow)) & validBoth;


%% Classify high-water-level events

Counts_daily_with_era5_bias_corrected_5cat = struct();
Series_daily_with_era5_bias_corrected_5cat = struct();

tt_time = TT_dailyall_bias_corrected_5cat.Properties.RowTimes;

makeTT = @(idx,W) timetable( ...
    tt_time(idx),W(idx),S(idx),Q(idx), ...
    'VariableNames',{'WL','S','Q'});

catNamesPlot = { ...
    'N_compound_extreme', ...
    'N_river_only', ...
    'N_coast_only', ...
    'N_compound_moderate', ...
    'N_Non_extreme'};

for P = WL_PCTS

    Ypct = zeros(5,length(W_stations));

    for si = 1:length(W_stations)

        st = W_stations{si};
        sf = matlab.lang.makeValidName(st);
        W = TT_dailyall_bias_corrected_5cat.(st);

        thrW = prctile(W(~isnan(W)),P);
        Ev = W >= thrW & ~isnan(W);

        nExt = nnz(Ev & cat.Compound_extreme);
        nRiv = nnz(Ev & cat.River_only);
        nCoa = nnz(Ev & cat.Coast_only);
        nMod = nnz(Ev & cat.Compound_moderate);
        nNon = nnz(Ev & cat.Non_extreme);

        nVal = nnz(Ev & validBoth);
        nEv = nnz(Ev);

        Counts_daily_with_era5_bias_corrected_5cat.(sf).(['p' num2str(P)]) = table( ...
            nEv,nVal, ...
            nnz(Ev & cat.HighCoast_any), ...
            nnz(Ev & cat.HighRiver_any), ...
            nRiv,nCoa,nExt,nMod,nNon, ...
            'VariableNames',{ ...
            'N_events', ...
            'N_events_valid', ...
            'N_highcoast_any', ...
            'N_highriver_any', ...
            'N_river_only', ...
            'N_coast_only', ...
            'N_compound_extreme', ...
            'N_compound_moderate', ...
            'N_Non_extreme'});

        Sstruct = struct();

        Sstruct.All_events = makeTT(Ev,W);
        Sstruct.HighCoast_any = makeTT(Ev & cat.HighCoast_any,W);
        Sstruct.HighRiver_any = makeTT(Ev & cat.HighRiver_any,W);
        Sstruct.Compound_extreme = makeTT(Ev & cat.Compound_extreme,W);
        Sstruct.River_only = makeTT(Ev & cat.River_only,W);
        Sstruct.Coast_only = makeTT(Ev & cat.Coast_only,W);
        Sstruct.Compound_moderate = makeTT(Ev & cat.Compound_moderate,W);
        Sstruct.Non_extreme = makeTT(Ev & cat.Non_extreme,W);

        Sstruct.WL_threshold_P = struct( ...
            'pct',P, ...
            'value',thrW);

        Series_daily_with_era5_bias_corrected_5cat.(sf).(['p' num2str(P)]) = ...
            Sstruct;

        Ypct(:,si) = 100 * [nExt;nRiv;nCoa;nMod;nNon] / max(nVal,1);

    end


    %% Plot percentages

    f = figure('Color','w');

    xcats = categorical( ...
        catNamesPlot,catNamesPlot,'Ordinal',true);

    bar(xcats,Ypct,'grouped')
    grid on
    box on

    ylabel('Percent of valid WL events (%)')
    ylim([0 100])

    title(sprintf( ...
        'WL P%d events by 5-category driver classification: Bias-corrected ERA5 daily',P))

    legend(W_stations, ...
        'Interpreter','none', ...
        'Location','bestoutside')

    set(gca, ...
        'TickLabelInterpreter','none', ...
        'XTickLabelRotation',15)

    savefig(f,fullfile(OUTDIR, ...
        sprintf('ERA5_daily_BAR_AllStations_P%d.fig',P)));

    exportgraphics(f,fullfile(OUTDIR, ...
        sprintf('ERA5_daily_BAR_AllStations_P%d.png',P)), ...
        'Resolution',250);

    close(f)

end


%% Save classification results

save(fullfile(OUTDIR, ...
    'Counts_byStation_byPercentile_ERA5_daily.mat'), ...
    'Counts_daily_with_era5_bias_corrected_5cat');

save(fullfile(OUTDIR, ...
    'Series_byStation_byPercentile_ERA5_daily.mat'), ...
    'Series_daily_with_era5_bias_corrected_5cat');

disp('ERA5 daily classification complete')
