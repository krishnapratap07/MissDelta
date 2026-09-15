%% 5-category flood-day classification
clear all
clc

BASE_OUTDIR_5CAT = "classification_output";
if ~exist(BASE_OUTDIR_5CAT,'dir'); mkdir(BASE_OUTDIR_5CAT); end

EXPORT_PNG = true;
tz = 'UTC';

%% Tarbert Landing discharge
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
TT_dailyq.Properties.DimensionNames{1} = 'Date';


%% Load hourly-derived river residuals and CoDEC surge

load Daily_surges.mat
load codec_DailyMax_StormSurge.mat

TT_daily = sortrows(TT_daily);
TT_daily.Properties.RowTimes.TimeZone = tz;
TT_daily.Properties.RowTimes = ...
    dateshift(TT_daily.Properties.RowTimes,'start','day');

TT_dailys = table2timetable( ...
    out_codec(:,{'Date','DailyMaxStormSurge'}), ...
    'RowTimes','Date');

TT_dailys = TT_dailys(:, 'DailyMaxStormSurge');
TT_dailys.Properties.VariableNames = {'S'};

TT_dailys.Properties.RowTimes.TimeZone = tz;
TT_dailys.Properties.RowTimes = ...
    dateshift(TT_dailys.Properties.RowTimes,'start','day');

TT_dailys = sortrows(TT_dailys);


%% Synchronize water level, discharge, and surge

TT_dailyall = synchronize( ...
    TT_daily,TT_dailyq,TT_dailys,'intersection');

OUTDIR = fullfile(BASE_OUTDIR_5CAT,"hourly_with_CoDEC");
if ~exist(OUTDIR,'dir'); mkdir(OUTDIR); end

save(fullfile(OUTDIR,"TT_dailyall_hourly_with_codec.mat"), ...
    "TT_dailyall");

PLOT_TITLE = ...
    'WL P%d events by 5-category driver classification: hourly WL with CoDEC';

LEGEND_NAMES = strrep( ...
    TT_dailyall.Properties.VariableNames( ...
    ~ismember(TT_dailyall.Properties.VariableNames,{'S','Q'})), ...
    'Scorrected_','Hourly_');

PLOT_FIG_NAME = 'CoDEC_hourly_BAR_AllStations_P%d.fig';
PLOT_PNG_NAME = 'CoDEC_hourly_BAR_AllStations_P%d.png';

COUNTS_FILE = 'Counts_byStation_byPercentile_CoDEC_hourly.mat';
SERIES_FILE = 'Series_byStation_byPercentile_CoDEC_hourly.mat';


%% Driver thresholds

WL_PCTS = [80 85 90 95];

allVars = TT_dailyall.Properties.VariableNames;
W_stations = allVars(~ismember(allVars,{'S','Q'}));
W_stations = cellstr(W_stations);

S = TT_dailyall.S;
Q = TT_dailyall.Q;

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

cat = struct();

cat.HighCoast_any     = S90;
cat.HighRiver_any     = Q90;
cat.Compound_extreme  = S90 & Q90 & validBoth;
cat.River_only        = Q90 & Slow & validBoth;
cat.Coast_only        = S90 & Qlow & validBoth;

cat.Compound_moderate = ...
    ((Smod & Qmod) | (S90 & Qmod) | (Smod & Q90)) & validBoth;

cat.Non_extreme = ...
    ((Smod & Qlow) | (Qmod & Slow) | (Slow & Qlow)) & validBoth;


%% Classify high-water-level events

catNamesPlot = { ...
    'N_compound_extreme', ...
    'N_river_only', ...
    'N_coast_only', ...
    'N_compound_moderate', ...
    'N_Non_extreme'};

plotCats = { ...
    'Compound_extreme', ...
    'River_only', ...
    'Coast_only', ...
    'Compound_moderate', ...
    'Non_extreme'};

Counts = struct();
Series = struct();

tt_time = TT_dailyall.Properties.RowTimes;

makeTT = @(idx,W) timetable( ...
    tt_time(idx),W(idx),S(idx),Q(idx), ...
    'VariableNames',{'WL','S','Q'});

for P = WL_PCTS

    Ypct = zeros(numel(plotCats),numel(W_stations));
    Nev_vec = zeros(1,numel(W_stations));

    for si = 1:numel(W_stations)

        st = W_stations{si};
        sf = matlab.lang.makeValidName(st);
        W = TT_dailyall.(st);

        thrW = prctile(W(~isnan(W)),P);
        Ev = W >= thrW & ~isnan(W);

        nExt = nnz(Ev & cat.Compound_extreme);
        nRiv = nnz(Ev & cat.River_only);
        nCoa = nnz(Ev & cat.Coast_only);
        nMod = nnz(Ev & cat.Compound_moderate);
        nLow = nnz(Ev & cat.Non_extreme);

        nVal = nnz(Ev & validBoth);
        nEv  = nnz(Ev);

        Nev_vec(si) = nEv;

        Counts.(sf).(['p' num2str(P)]) = table( ...
            nEv,nVal, ...
            nnz(Ev & cat.HighCoast_any), ...
            nnz(Ev & cat.HighRiver_any), ...
            nRiv,nCoa,nExt,nMod,nLow, ...
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

        Sstruct.All_events        = makeTT(Ev,W);
        Sstruct.HighCoast_any     = makeTT(Ev & cat.HighCoast_any,W);
        Sstruct.HighRiver_any     = makeTT(Ev & cat.HighRiver_any,W);
        Sstruct.Compound_extreme  = makeTT(Ev & cat.Compound_extreme,W);
        Sstruct.River_only        = makeTT(Ev & cat.River_only,W);
        Sstruct.Coast_only        = makeTT(Ev & cat.Coast_only,W);
        Sstruct.Compound_moderate = makeTT(Ev & cat.Compound_moderate,W);
        Sstruct.Non_extreme       = makeTT(Ev & cat.Non_extreme,W);

        Sstruct.WL_threshold_P = struct( ...
            'pct',P, ...
            'value',thrW);

        Series.(sf).(['p' num2str(P)]) = Sstruct;

        vals = [nExt nRiv nCoa nMod nLow];
        Ypct(:,si) = 100 * vals(:) / max(nVal,1);

    end


    %% Plot category percentages

    f = figure('Color','w');

    xcats = categorical( ...
        catNamesPlot,catNamesPlot,'Ordinal',true);

    bar(xcats,Ypct,'grouped')
    grid on
    box on

    ylabel('Percent of valid WL events (%)')
    ylim([0 100])

    title(sprintf(PLOT_TITLE,P))

    legend(LEGEND_NAMES, ...
        'Interpreter','none', ...
        'Location','bestoutside')

    set(gca, ...
        'TickLabelInterpreter','none', ...
        'XTickLabelRotation',15)

    savefig(f, ...
        fullfile(OUTDIR,sprintf(PLOT_FIG_NAME,P)));

    if EXPORT_PNG
        exportgraphics(f, ...
            fullfile(OUTDIR,sprintf(PLOT_PNG_NAME,P)), ...
            'Resolution',250);
    end

    close(f)

end


%% Save classification results

save(fullfile(OUTDIR,COUNTS_FILE),'Counts');
save(fullfile(OUTDIR,SERIES_FILE),'Series');

disp('Classification complete')
