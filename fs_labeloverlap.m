function overlapTable = fs_labeloverlap(labels, outputPath, subjList)
% This function calcualtes the overlapping between two labels
%
% Inputs:
%   labelList           a list (matrix) of label names (could be more than 
%                       2). The labels in the same row will be compared
%                       with each other. (each row is another cell)
%   subjCode            subject code in $SUBJECTS_DIR
%   output_path         where the output file will be saved
% Output
%   overlap_table       a table contains the overlapping information
%
% Created by Haiyang Jin (11/12/2019)

FS = fs_subjdir;

if nargin < 2 || isempty(outputPath)
    outputPath = '.';
end
outputPath = fullfile(outputPath, 'Label_Overlapping');
if ~exist(outputPath, 'dir'); mkdir(outputPath); end

if nargin < 3 || isempty(subjList)
    subjList = FS.subjList;
elseif ischar(subjList)
    subjList = {subjList};
end

nSubj = FS.nSubj;
nLabelGroup = size(labels, 1);

n = 0;
overlapStr = struct;

for iSubj = 1:nSubj
    
    subjCode = subjList{iSubj};
%     labelPath = fullfile(FS.subjects, subjCode, 'label');
    
    
    for iLabel = 1:nLabelGroup
        
        theseLabels = labels{iLabel, :};
        
        nLabel = numel(theseLabels);
        if nLabel < 2
            warning('The number of labels should be more than one.');
            continue;
        end
        
        c = nchoosek(1:nLabel, 2); % combination matrix
        nC = size(c, 1); % number of combinations
        
        for iC = 1:nC
            
            theseLabel = theseLabels(c(iC, :));
            
            % skip if at least one label is not available
            if ~fs_checklabel(theseLabel, subjCode)
                continue;
            end
            
            % load the two label files
            matCell = cellfun(@(x) fs_readlabel(subjCode, x), theseLabel, 'UniformOutput', false);
            
            % check if there is overlapping between the two labels
            matLabel1 = matCell{1};
            matLabel2 = matCell{2};
            isoverlap = ismember(matLabel1, matLabel2);
            overlapVer = matLabel1(isoverlap(:, 1));
            nOverVer = numel(overlapVer);
            
            % save information to the structure
            n = n + 1;
            overlapStr(n).SubjCode = {subjCode};
            overlapStr(n).Label = theseLabel;
            overlapStr(n).nOverlapVer = nOverVer;
            overlapStr(n).OverlapVer = {overlapVer'};
            
        end
    end
    
end
clear n

overlapTable = struct2table(overlapStr); % convert structure to table
overlapTable = rmmissing(overlapTable, 1); % remove empty rows
writetable(overlapTable, fullfile(outputPath, 'Label_Overlapping.xlsx'));

end