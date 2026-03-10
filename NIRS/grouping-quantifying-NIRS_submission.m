%% SIGNAL QUANTIFICATION

clear; clc;

%% Paths
path_scripts = '/Users/.../My_scripts_NIRS';
addpath(genpath(path_scripts));

path_outcome = '/Users/.../outcome_viejo/outcome_files';
addpath(genpath(path_outcome));

toolbox_path = '/Users/.../nirs-toolbox-master';
addpath(genpath(toolbox_path));

%% Excluded participants
outYoung = {};   % excluded young subjects
outOld   = {};   % excluded old subjects

groups = {'Young','Old'};

files_young = {};
files_old   = {};

%% Collect files
for g = 1:length(groups)

    group = groups{g};
    path_group = fullfile(path_outcome,group);

    cd(path_group)

    subject_files = dir('*_1.mat');
    subject_files([subject_files.isdir]) = [];

    files = {subject_files.name};

    % Remove excluded subjects
    if g == 1
        files(contains(files,outYoung)) = [];
        files_young = files;
    else
        files(contains(files,outOld)) = [];
        files_old = files;
    end

end

%% Combine groups
files_all = [files_young files_old];

% Group labels (0 = Young, 1 = Old)
gr_all = ones(1,length(files_all));
gr_all(1:length(files_young)) = 0;

cd(path_outcome)
save('files_all.mat','files_all')
save('gr_all.mat','gr_all')

%% Load epoched data
data_struct = load(files_all{1});
raw = data_struct.epoched_conc_OD_tddr;

for k = 1:length(files_all)

    file_data = load(files_all{k});
    raw(k) = file_data.epoched_conc_OD_tddr;

end

%% SUBJECT-LEVEL GLM AFTER GROUPING DATA
% Input: raw (array of epoched NIRS objects)

clear; clc;

%% Path to save results
path_outcome = '/Users/irenearrietasagredo/Desktop/BCBL/Thesis-blablacara/Blablacara-data/outcome_files';
cd(path_outcome)

%% -------------------------
%% 1. FIR MODEL (TIME RESPONSE) (resulting in the time response seen in Supplementary material 7)
%% -------------------------

job = nirs.modules.GLM();

basis = nirs.design.basis.FIR();
basis.binwidth = 1;     % temporal resolution (s)

job.basis('default') = basis;

SubjStats_FIR = job.run(raw);

save('Subj_stats_FIR.mat','SubjStats_FIR','-v7.3')


%% -------------------------
%% 2. CANONICAL HRF MODEL (resulting on the beta values introduced in the group level statistics)
%% -------------------------

job = nirs.modules.GLM();

basis = nirs.design.basis.Canonical();

job.basis('default') = basis;

SubjStats_canonical = job.run(raw);

save('Subj_stats_canonical.mat','SubjStats_canonical','-v7.3')


