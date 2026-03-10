%% PREPROCESSING

clear; clc;

%% Paths
toolbox_path = '/Users/.../nirs-toolbox-master';
addpath(genpath(toolbox_path));

path_wavelet = '/Users/.../BrainWavelet';
addpath(genpath(path_wavelet));

path_nirsGUI = '/Users/.../NIRS-GUI-master';
addpath(genpath(path_nirsGUI));

path_qt = '/Users/.../qt-nirs-master';
addpath(genpath(path_qt));

path_data = '/Users/.../Blablacara-data/data.nosync';
path_outcome = '/Users/.../outcome_files';
path_quality = '/Users/.../quality_assessment';

%% Parameters
group = 'Old';
prestim = 5;
thresh_sci = 0.7;
epoch_bad_thresh = 0.66;

%% Load subjects
path_group = fullfile(path_data,group);
cd(path_group)

num_subj = dir(path_group);
num_subj = num_subj(4:end);

loss_sci = [];
loss_epochs = [];
loss_total = [];

%% LOOP SUBJECTS
for i = 1:length(num_subj)

    subj = num_subj(i).name;

    path_nirs = fullfile(path_data,group,subj,'NIRS');
    path_et   = fullfile(path_data,group,subj,'ET');

    if ~exist(path_nirs,'dir')
        continue
    end

    cd(path_nirs)

    session_folder = dir('20*');
    cd(session_folder.name)

    iter_folders = dir('20*');

    for iteration = 1:length(iter_folders)

        %% LOAD NIRS
        path_file = fullfile(path_nirs,session_folder.name,iter_folders(iteration).name);
        raw = nirs.io.loadNIRx(path_file);

        if isempty(raw)
            continue
        end

        %% LOAD ET EVENTS
        edf_file = fullfile(path_et,[subj '.edf']);
        if ~exist(edf_file,'file')
            continue
        end

        edf = Edf2Mat(edf_file);
        msg = {edf.Events.Messages.info};
        time_ev = [edf.Events.Messages.time];

        %% CONDITION TIMESTAMPS
        idx_v  = find(contains(msg,'silence'));
        idx_av = find(contains(msg,'eguerdion_720'));
        idx_avd = find(contains(msg,'vocoder'));

        time_all = [time_ev(idx_av) time_ev(idx_avd) time_ev(idx_v)];
        cond_all = [ones(length(idx_av),1); 2*ones(length(idx_avd),1); 3*ones(length(idx_v),1)];

        [time_sorted, idx] = sort(time_all);
        cond_all = cond_all(idx);

        %% TRIGGERS FROM NIRS
        trig = raw.stimulus('channel_15').onset;
        trig_diff = diff(trig);

        onset_idx = find(trig_diff < 18.5 & trig_diff > 16);
        onset = trig(onset_idx);
        onset_dur = trig_diff(onset_idx);

        %% CREATE CONDITIONS
        V_idx  = cond_all == 3;
        AV_idx = cond_all == 1;
        AVd_idx = cond_all == 2;

        template = raw.stimulus('channel_15');

        raw.stimulus = raw.stimulus.remove(raw.stimulus.keys);

        raw.stimulus('channel_1') = template;
        raw.stimulus('channel_2') = template;
        raw.stimulus('channel_3') = template;

        raw.stimulus('channel_1').onset = onset(AV_idx);
        raw.stimulus('channel_2').onset = onset(AVd_idx);
        raw.stimulus('channel_3').onset = onset(V_idx);

        raw.stimulus('channel_1').dur = onset_dur(AV_idx);
        raw.stimulus('channel_2').dur = onset_dur(AVd_idx);
        raw.stimulus('channel_3').dur = onset_dur(V_idx);

        %% SIGNAL QUALITY (SCI)
        qt = nirs.modules.QT();
        qt.qThreshold = thresh_sci;
        qt.sciThreshold = thresh_sci;
        qt.pspThreshold = 0;

        quality = qt.run(raw);

        bad_chan = quality.qMats.bad_links;
        loss_sci(i) = length(bad_chan);

        raw.data(:,[bad_chan height(raw.probe.link)/2 + bad_chan]) = nan;

        %% OPTICAL DENSITY
        job = nirs.modules.OpticalDensity();
        OD = job.run(raw);

        %% MOTION CORRECTION
        tddr = nirs.modules.TDDR();
        OD = tddr.run(OD);

        %% HEMOGLOBIN CONVERSION
        job = nirs.modules.BeerLambertLaw();
        conc = job.run(OD);

        %% FILTERING
        lp = nirsGUI.modules.LowPassFilter();
        lp.CutOffFrequency = 0.25;
        conc = lp.run(conc);

        hp = nirsGUI.modules.HighPassFilter();
        hp.CutOffFrequency = 0.01;
        conc = hp.run(conc);

        %% EPOCH EXTRACTION
        epoch = nirsGUI.modules.EpochExtraction();
        epoch.PreStimTime = prestim;
        epoch.PostStimTime = mean(onset_dur)*2;
        epoch.BaselineCorrect = true;

        epoched = epoch.run(conc);

        %% EPOCH QUALITY
        epoch_quality = evaluate_epoch_quality_bb(epoched,mean(onset_dur)*2,[],1,onset);

        bad_epochs = epoch_quality(:,1) > epoch_bad_thresh;
        loss_epochs(i) = sum(bad_epochs);

        %% SAVE
        save(fullfile(path_outcome,group,[subj '_ite_' num2str(iteration) '.mat']),...
            'epoched','epoch_quality','bad_chan')

    end
end

%% SAVE LOSS SUMMARY
loss_table = table(loss_sci',loss_epochs');
save(fullfile(path_quality,['loss_table_' group '.mat']),'loss_table')