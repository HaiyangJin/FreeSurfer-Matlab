function [contraStruct, fscmd] = fs_mkcontrast(analysisList, contrasts, conditions, force)
% [contraStruct, fscmd] = fs_mkcontrast(analysisList, contrasts, conditions, force)
%
% This function creates contrast and run mkcontrast-sess in FreeSurfer.
%
% Inputs:
%    analysisList         <cell of string> a list of all analysis names;
%    contrasts            <cell> a cell of contrasts to be created. One row
%                          is one contrast; the conditions in the first cell
%                          is the activation condition; the conditions in the
%                          second cell is the control condition. (These will
%                          be used to set the contrast name later);
%    conditions           <cell of string> the full names of all conditions;
%    force                <logical> force to make contrast. 0: do not force 
%                          to re-make contrsat [default]; 1: force to 
%                          re-make contrast; 2: do not run fscmd. 
%
% Output:
%    contraStruct         <structure> a contrast structure which has three
%                          fieldnames. (analysisName: the ananlysis name;
%                          contrastName: the contrast name in format of a-vs-b;
%                          contrastCode: the commands to be used in
%                          FreeSurfer)
%                          contraStruct will also be saved as the Matlab
%                          file and its name will be the initials of all the
%                          conditions.
%    fscmd                <cell of strings> FreeSurfer commands run in the
%                          current session.
%
% Example:
% anaList [obtained from fs_mkanalysis.m]
% contrasts = {
%     'face', 'word';
%     'face', 'object';
%     'word', 'object';};
% conditions = {
%     'face';
%     'word';
%     'object'};
% force = 1;
% contraStruct = fs_mkcontrast(analysisList, contrasts, conditions, force);
%
% Next step: fs_selxavg3.m
%
% Created by Haiyang Jin (19-Dec-2019)

if nargin < 4 || isempty(force)
    force = 0;
end

if ischar(analysisList)
    analysisList = {analysisList};
end

% number of analysis names and contrasts
nAnalysis = numel(analysisList);
nContrast = size(contrasts, 1);

% use the string before '.' as the unique name
strCell = cellfun(@(x) split(x, {'_', '.'}), analysisList, 'uni', false);
extraStrs = cellfun(@(x) x{end-1, 1}, strCell, 'uni', false);
extraStr = unique(cellfun(@(x) regexp(x, '\D+', 'match'), extraStrs));
if numel(extraStr) ~= 1; extraStr = {'backup'}; end

% filename of the Matlab file to be saved later
contraFn = sprintf('Ana%d_Con%d_%s_%s.mat', nAnalysis, nContrast, ...
    cellfun(@(x) x(1), conditions), extraStr{1});

if exist(contraFn, 'file') && ~force
    load(contraFn, 'contraStruct');
    fscmd = '';
    fprintf('contraStruct is loaded.\n');
    return;
end

% empty structure for saving information
contraStruct = struct;
n = 0;

% empty cell for saving FreeSurfer commands
fscmd = cell(nAnalysis, nContrast);

for iAnalysis = 1:nAnalysis
    
    % this analysis name
    analysisName = analysisList{iAnalysis};
    
    for iCon = 1:nContrast
        
        n = n + 1;
        
        % this contrast
        thisCon = contrasts(iCon, :);
        
        % the number of activation and control condition
        conditionNum = cellfun(@(x) find(startsWith(conditions, x)), thisCon, 'uni', false);
        
        % save the information
        contraStruct(n).analysisName = analysisName;
        
        % levels of activation and control
        nLevels = cellfun(@numel, conditionNum);
        
        %% Activation conditions
        if iscell(thisCon{1})
            actCon = thisCon{1};
        else
            actCon = thisCon(1);
        end
        % first part of contrast name
        contrNameAct = sprintf(['%s' repmat('-%s', 1, nLevels(1)-1) '-vs-'], actCon{:});
        % first part of contrast code
        contrCodeAct = [' -a %d' repmat(' -a %d', 1, nLevels(1)-1)];
        
        %% Control conditions
        if nLevels(2) == 0
            % if there is no control condition [NULL will be used as
            % control condition]
            conditionNum = conditionNum(1);
            contrCodeCon = '';
        else
            if iscell(thisCon{2})
                baseCon = thisCon{2};
            else
                baseCon = thisCon(2);
            end
            % second part of contrast name
            contrNameCon = sprintf(['%s' repmat('-%s', 1, nLevels(2)-1)], baseCon{:});
            % second part of contrast code
            contrCodeCon = [' -c %d' repmat(' -c %d', 1, nLevels(2)-1)];
        end
        
        %% Combine activation and control
        contrName = [contrNameAct, contrNameCon];
        contrCode = [contrCodeAct, contrCodeCon];
        
        % create the contrast names and contrast codes
        contraStruct(n).contrastName = contrName;
        contraStruct(n).contrastCode = sprintf(contrCode, conditionNum{:});
        
        % created the commands
        thisfscmd = sprintf('mkcontrast-sess -analysis %s -contrast %s %s', ...
            analysisName, contraStruct(n).contrastName, contraStruct(n).contrastCode);
        fscmd{iAnalysis, iCon} = thisfscmd;
        
        if force ~= 2
            isnotok = system(thisfscmd);
        else
            isnotok = 0;
        end
        assert(~isnotok, 'Command (%s) failed.', thisfscmd);
        
    end  % iCon
    
end  % iAnalysis

fscmd = reshape(fscmd, [], 1);

% save contraStr as Matlab file
save(contraFn, 'contraStruct', '-v7.3');
fprintf('contraStruct is saved in %s.\n', contraFn)

end