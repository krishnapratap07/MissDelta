%% Annual flood-day counts by water year

clear
clc

load('Series_byStation_byPercentile_ERA5_daily.mat');

S = Series_daily_with_era5_bias_corrected_5cat;

stations = {'Daily_01300','Daily_01320','Daily_01340','Daily_01400','Daily_01480'};
thresholds = {'p80','p85','p90','p95'};

categories = { ...
    'All_events', ...
    'Coast_only', ...
    'River_only', ...
    'Compound_extreme', ...
    'Compound_moderate', ...
    'Non_extreme'};

water_years = 1951:2024;
get_water_year = @(t) year(t) + double(month(t) >= 10);

rows = {};

for si = 1:length(stations)

    station = stations{si};

    for ti = 1:length(thresholds)

        threshold = thresholds{ti};
        stru = S.(station).(threshold);

        for yi = 1:length(water_years)

            wy = water_years(yi);
            row = {station,threshold,wy};

            for ci = 1:length(categories)

                category = categories{ci};
                dates = stru.(category).Properties.RowTimes;
                event_wy = get_water_year(dates);

                row{end+1} = sum(event_wy == wy);
            end

            rows(end+1,:) = row;
        end
    end
end

column_names = [{'station','threshold','water_year'}, categories];

water_year_table = cell2table(rows, ...
    'VariableNames',column_names);

water_year_table = sortrows(water_year_table, ...
    {'station','threshold','water_year'});

classified_total = ...
    water_year_table.Coast_only + ...
    water_year_table.River_only + ...
    water_year_table.Compound_extreme + ...
    water_year_table.Compound_moderate + ...
    water_year_table.Non_extreme;

if any(water_year_table.All_events ~= classified_total)
    error('All_events does not equal the sum of the five categories.')
end

writetable(water_year_table, ...
    'flood_annual_counts_water_year_5_cat.csv');

disp('Annual flood-day counts saved')
