%% 02 Combine discharge-corrected water levels

clear all
clc

folderPath = 'C:\Users\kr875036\OneDrive - University of Central Florida\missdelta\Aug_2025\discharge corrected tide gauge';
fileList = dir(fullfile(folderPath,'*.csv'));

dataStruct = struct();
colNames = {};
allDateTimes = datetime.empty(0,1);
allDateTimes.TimeZone = 'UTC';

%% Read and clean each gauge

for k = 1:length(fileList)

    fileName = fileList(k).name;
    T = readtable(fullfile(folderPath,fileName));

    dtStr = strcat(string(T.Date)," ",string(T.Time));

    try
        dt = datetime(dtStr, ...
            'InputFormat','yyyy-MM-dd HH:mm:ss', ...
            'TimeZone','America/Chicago');
    catch
        dt = datetime(dtStr, ...
            'InputFormat','yyyy-MM-dd HH:mm', ...
            'TimeZone','America/Chicago');
    end

    dt.TimeZone = 'UTC';

    good = ~isnat(dt);
    dt = dt(good);
    T = T(good,:);

    [dt,ord] = sort(dt);
    syntheticTide = T.SyntheticTide(ord);

    [dt,ia] = unique(dt,'stable');
    syntheticTide = syntheticTide(ia);

    [~,name,~] = fileparts(fileName);

    dataStruct.(name) = table(dt,syntheticTide, ...
        'VariableNames',{'DateTime','SyntheticTide'});

    colNames{end+1,1} = name;

    allDateTimes = union(allDateTimes,dt);
end

%% Put all gauges on one time axis

syntheticTideMatrix = NaN(length(allDateTimes),length(colNames));

for j = 1:length(colNames)

    name = colNames{j};
    T = dataStruct.(name);

    [tf,idx] = ismember(allDateTimes,T.DateTime);

    x = NaN(length(allDateTimes),1);
    x(tf) = T.SyntheticTide(idx(tf));

    syntheticTideMatrix(:,j) = x;
end

syntheticTideTable = array2table( ...
    syntheticTideMatrix, ...
    'VariableNames',colNames);

stage_without_disc = ...
    [table(allDateTimes,'VariableNames',{'DateTime'}) syntheticTideTable];

save(fullfile(folderPath,'wl_without_discharge_data.mat'), ...
    'stage_without_disc');

disp('Combined discharge-corrected water levels saved')
