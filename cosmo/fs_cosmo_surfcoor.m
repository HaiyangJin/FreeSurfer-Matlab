function [vtxCell, faceCell] = fs_cosmo_surfcoor(subjCode, surfType, combineHemi)
% [vtxCell, faceCell] = fs_cosmo_surfcoor(subjCode, surfCoorFile, combineHemi)
% 
% This function converts ?h.inflated (or white or pial) into ASCII file and
% then load them into Matlab. Vertices (faces) for both hemispheres could
% be merged together. 
%
% Inputs: 
%    subjCode           <string> subject code in $SUBJECTS_DIR.
%    surfCoorFile       <string> coordinate file for vertices ('inflated', 
%                        'white', 'pial') (default is 'inflated').
%    combineHemi        <logical> whether the data of two hemispheres will 
%                       be combined (default is no).
%
% Outputs:
%    vtxCell            <cell> vertex cell. each row is for each surface 
%                        file in surfCoorFile. The first column is for left
%                        hemisphere. The second column is for the right
%                        hemisphere. The third column (if there is) is for 
%                        the merged hemispheres.
%    faceCell           <cell> face cell. Same structure as vtxCell.
%
% Dependency:
%    FreeSurfer Matlab functions.
%
% Created by Haiyang Jin (8-Dec-2019)

if nargin < 2 || isempty(surfType)
    surfType = {'inflated'};
end
if nargin < 3 || isempty(combineHemi)
    combineHemi = 0;
end

% FreeSurfer setup
FS = fs_subjdir;
surfPath = fullfile(FS.structPath, subjCode, 'surf');
hemis = {'lh', 'rh'};
nHemi = 2;

% which of the surface files will be loaded
if ~iscell(surfType)
    surfType = {surfType}; % convert to cell if necessary
end
surfExt = {'white', 'pial', 'inflated'};
whichSurfcoor = ismember(surfType, surfExt);
if ~any(whichSurfcoor)
    error('The surface coordinate system (%s) is not supported by this function.\n',...
        surfExt{1, whichSurfcoor});
end
nSurfFile = numel(surfType);

% Create a cell for saving ASCII filenames for both hemisphere
vCell = cell(nSurfFile, nHemi + combineHemi); % left, right, and (merged)
fCell = cell(nSurfFile, nHemi + combineHemi); % left, right, and (merged)

% Convert surface file to ASCII (with functions in FreeSurfer)
for iSurf = 1:nSurfFile
    
    for iHemi = 1:nHemi
        
        % the surface and its asc filename
        thisSurfFile = [hemis{iHemi} '.' surfType{iSurf}];
        thisSurfPath = fullfile(surfPath, thisSurfFile);
     
        % read FreeSurfer surface files (with FreeSurfer Matlab functions).
        [vCell{iSurf, iHemi}, fCell{iSurf, iHemi}] = fs_readsurf(thisSurfPath);
        
    end
    
    if combineHemi
        % Combine the vertex coordinates for both hemispheres
        vCell{iSurf, 3} = vertcat(vCell{iSurf, [1,2]});
        
        % Combine the faces of vertices for both hemispheres
        nVtxLeft = size(vCell{1, 1}, 1);
        fCell{iSurf, 3} = vertcat(fCell{iSurf, 1}, fCell{iSurf, 2} + nVtxLeft);
        
    end
    
end

% save the output
vtxCell = vCell;
faceCell = fCell;

end