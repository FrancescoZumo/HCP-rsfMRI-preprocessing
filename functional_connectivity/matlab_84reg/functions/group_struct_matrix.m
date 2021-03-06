function [] = group_struct_matrix()
% GROUP_STRUCT_MATRIX Groups within a struct
%   This function groups the outcomes of the functional analysis within a
%   struct and export a file .mat

%% PREPARING STRUCTURES

% folders containing workspaces used
ws_folders = {'1200', 'retest'};

% names used for structure
ws_pattern = '[0-9]+';

% check control of the names
folder_names = ws_folders;
for m = 1:numel(ws_folders)
    if numel(regexp(ws_folders{m}, ws_pattern)) ~= 0
        folder_names{1} = strcat('s_', folder_names{1});
        folder_names{2} = strcat('s_', folder_names{2});
        break
    end
end

% temp cell array
c = cell(length(folder_names),1);

% creating structures
conn_measures = cell2struct(c,folder_names);
group_substruct = conn_measures;

% subjects contained in one folder
nSubjects = 45;

% for each folder contained in ws_folders ...
for m = 1:numel(ws_folders)
    
    conn_measures.(folder_names{m}) = cell(nSubjects, 1);
    net_substruct.(folder_names{m}) = cell(nSubjects, 1);
    
    % save name of each file contained in folder that matches pattern
    % 'ws_*.mat'
    ws_path = dir(strcat(pwd,'/functional_connectivity/matlab_84reg/workspace_84reg_800_norm/', ws_folders{m}, '/ws_*.mat'));
    
    if size(ws_path, 1) == 0
        error('directory not found, check your current directory');
    end
    
    % for each file contained in ws_path ...
    k = 1;
    for i = 1:size(ws_path, 1)
        
        % complete check with regexp, so I only use files with specific
        % name
        ws_pattern = 'ws_[0-9]+_norm.mat';
        matches = regexp(ws_path(i).name, ws_pattern);
        if numel(matches) == 0
            continue;
        end
        
        % load subject workspace
        conn_measures.(folder_names{m}){k} = load(strcat(ws_path(i).folder, '/', ws_path(i).name));
        k = k + 1;
    end
end

% Salviamo
path_save = strcat(pwd, '/functional_connectivity/connectivity_measures.mat');
save(path_save, 'conn_measures');

end

