%% 01 Discharge correction

clear all
clc

folderPath = 'C:\Users\kr875036\OneDrive - University of Central Florida\missdelta\Aug_2025\each_hour_values_extracted\01480_hourly_values';
fileList = dir(fullfile(folderPath,'*.mat'));

mkdir('output_data')

%% Load Tarbert Landing discharge

tarbert_dis = readtable("Tarbert_corrected.csv");

badDate = datetime(2010,12,23);
tarbert_dis(tarbert_dis.Date == badDate,:) = [];

dischargeTime = tarbert_dis.Date;
dischargeVal  = tarbert_dis.Flow_CFS_;

baseFlow = 100000;
windowYears = 3;
timeShiftDays = 1;
spillwayFlow = 0;

dischargeTime = dischargeTime + days(timeShiftDays);
dischargeVal  = dischargeVal - spillwayFlow;

%% Correct water level for discharge

for k = 1:length(fileList)

    fileName = fileList(k).name;

    if ~contains(fileName,'_value.mat')
        continue
    end

    data = load(fullfile(folderPath,fileName));
    hourlyData = data.hourlyData;

    stageTime = hourlyData.Time;

    siteID = split(fileName,'_');
    siteID = siteID{1};

    stageVal = hourlyData.(siteID);

    TT_stage = timetable(stageTime,stageVal,'VariableNames',{'Stage'});
    TT_flow  = timetable(dischargeTime,dischargeVal,'VariableNames',{'Discharge'});

    TT_stage.Properties.RowTimes = ...
        dateshift(TT_stage.Properties.RowTimes,'start','day');

    TT = synchronize(TT_stage,TT_flow,'intersection');

    TT.Slope = NaN(height(TT),1);
    TT.Intercept = NaN(height(TT),1);
    TT.SyntheticTide = NaN(height(TT),1);

    for i = 1:height(TT)

        currentDate  = TT.Properties.RowTimes(i);
        currentStage = TT.Stage(i);
        currentQ     = TT.Discharge(i);

        startDate = currentDate - calyears(windowYears);
        endDate   = currentDate + calyears(windowYears);

        inWindow = TT.Properties.RowTimes >= startDate & ...
                   TT.Properties.RowTimes <= endDate;

        x = TT.Discharge(inWindow);
        y = TT.Stage(inWindow);

        valid = ~isnan(x) & ~isnan(y);
        x = x(valid);
        y = y(valid);

        if length(x) < 2
            continue
        end

        p = polyfit(x,y,1);

        m = p(1);
        b = p(2);

        TT.Slope(i) = m;
        TT.Intercept(i) = b;

        expectedStage = m*currentQ + b;
        baseFlowStage = m*baseFlow + b;

        TT.SyntheticTide(i) = ...
            currentStage - (expectedStage - baseFlowStage);
    end

    writetimetable(TT, ...
        fullfile('output_data',[siteID '_' fileName '_output.csv']));

end

disp('Discharge correction complete')
