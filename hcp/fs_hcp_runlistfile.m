function fs_hcp_runlistfile(boldPath, locString)
% This function reads the run_info.txt generated by fs_hcp_prepro and 
% creates the run list files.
% 
% If there are more than one type of task names (i.e., the folder names 
% without the run number at the end). The task name containing
% locString will be regarded as the localizer runs.
%
% if there is only one task names, the folder name (including the run
% number) containing locString will be regarded as the localizer runs.
%
% Input:
%    boldPath       <string> path to the bold folder
%    locString      <string> or <cell of string> folder names containing
%                   locString will be regarded as loc (localizer) runs.
% Output:
%    run list files in the bold/ folder
%
% Created by Haiyang Jin (6-Jan-2020)

if nargin < 1 || isempty(boldPath)
    boldPath = pwd;
end

if nargin < 2 || isempty(locString)
    locString = 'loc';
end

% load run_info.txt
runInfo = readtable(fullfile(boldPath, 'run_info.txt'), 'Delimiter', ',',...
    'Format','%s%s');

%% find unique task names and numbers
% the unique strings of run names (as the task name)
runNums = cellfun(@(x) regexp(x, '\d+', 'match'), runInfo.RunName);
[taskNames, ~, groupNum] = unique(cellfun(@(x, y) erase(x, y), runInfo.RunName, runNums, 'uni', false));

% classify runs into different types (loc and main(s))
nTask = numel(taskNames);

if nTask > 1 % when there are more than one types of task names
    
    mainCell = cell(nTask-1, 1);
    mainNum = 0;
    
    for iTask = 1:nTask
        
        thisTaskName = taskNames{iTask};
        if contains(thisTaskName, locString, 'IgnoreCase', true)
            % runs are treated as loc runs if the run names contains 'loc'
            locList = groupNum == iTask;
        else
            % other runs are treated as main runs
            mainNum = mainNum + 1;
            mainCell(mainNum, 1) = {groupNum == iTask};
        end
        
    end
    
elseif nTask == 1 % when there is only one task name
    
    mainNum = 1;
    locList = contains(runInfo.RunName, locString);
    
    mainCell{1, 1} = ~locList;
    
end

%% Create run list files
% backup directory
wdBackup = pwd;
cd(boldPath);

% loc runs
createrunlistfile('run_loc', runInfo, locList);

% main runs
if mainNum == 1 % if there is only one task (main) run
    
    createrunlistfile('run_main', runInfo, mainCell{1, 1});
    
elseif mainNum > 1 % if there are more than one tasks
    
    arrayfun(@(x) createrunlistfile(sprintf('task%d_run_main', x), ...
        runInfo, mainCell{x, 1}), 1:mainNum, 'uni', false);
end

% change back to the backup working directory
cd(wdBackup);

end


function createrunlistfile(runType, runInfo, logicalList) 

% create run list files for each run separately
arrayfun(@(x,y) fs_createfile([runType num2str(x) '.txt'],...
    y), 1:sum(logicalList), runInfo{logicalList, 'RunCode'}', 'uni', false);

% create run list file for all runs together
fs_createfile([runType '.txt'], runInfo{logicalList, 'RunCode'});

end
