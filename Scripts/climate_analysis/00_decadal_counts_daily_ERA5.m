%% Decadal counts for ERA5 classification

clear
clc

DATADIR = fullfile("classification_output","Long_record_ERA5");

load(fullfile(DATADIR, ...
    'Series_byStation_byPercentile_ERA5_daily.mat'));

stations = {'Daily_01300','Daily_01320','Daily_01340','Daily_01400','Daily_01480'};
percentiles = [80 85 90 95];

categories = { ...
    'Compound_extreme', ...
    'River_only', ...
    'Coast_only', ...
    'Compound_moderate', ...
    'Non_extreme'};

decade_starts = 1950:10:2020;
decade_labels = {'1950s','1960s','1970s','1980s', ...
                 '1990s','2000s','2010s','2020s'};

results = {};

for si = 1:length(stations)

    st = stations{si};

    for P = percentiles

        pfield = ['p' num2str(P)];

        for ci = 1:length(categories)

            cat = categories{ci};

            TT = Series_daily_with_era5_bias_corrected_5cat. ...
                (st).(pfield).(cat);

            years = year(TT.Properties.RowTimes);

            for di = 1:length(decade_starts)

                dec_start = decade_starts(di);
                dec_end = dec_start + 9;

                count = sum(years >= dec_start & years <= dec_end);

                results(end+1,:) = { ...
                    st,P,cat,decade_labels{di},count};
            end
        end
    end
end

outTable = cell2table(results, ...
    'VariableNames',{'Station','Percentile','Category','Decade','Count'});

writetable(outTable, ...
    fullfile(DATADIR,'decadal_counts_daily_ERA5.csv'));

disp('Decadal counts saved')
