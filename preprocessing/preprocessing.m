% ============================================================================================
% AUTOMATED PREPROCESSIG PIPELINE
% Protocol
% ----------------------------------
% for AI-Art Pilot Study
% ----------------------------------
% written by
% /
% Jinwoo Lee (SNU Connectome Lab)
% e-mail : adem1997@snu.ac.kr
% webpage: jinwoo-lee.com
% ----------------------------------
% 2024.11
% SNU Connectome Lab
% ----------------------------------
% REFERENCE
% Paper: Delorme, A. (2023). EEG is better left alone. Scientific reports, 13(1), 2372.
% GitHub: https://github.com/sccn/eeg_pipelines/blob/master/eeglab/process_eeglab_template.m
% ===========================================================================================

%% Getting Start with EEGLAB!
addpath(genpath('/Users/Jinwoo_1/Desktop/connectome/eeglab2023.0'));
eeglab;

fprintf('@@@ EEGLAB was successfully executed. Here we go!')

%% Variable Settings
sub_list = {'sub-01', 'sub-02', 'sub-03', 'sub-04', 'sub-05', ...
            'sub-06', 'sub-07', 'sub-08', 'sub-09', 'sub-10'};

working_dir = '/Users/Jinwoo_1/Desktop/ai_art/exp/';

low_filt = 0.5;
start_time = 0;
reject_prob = 0.90;

%% Main Preprocessing for TASK signals

for sub = 1:length(sub_list)
    target_sub = char(sub_list(sub)); 
    filename = strcat(working_dir, target_sub, '/raw/', strcat(target_sub, '_task.easy'));
    
    % ---------------------------------------------------
    % STEP 0. LOADING RAW DATA
    % ---------------------------------------------------
    % Loading .easy data
    EEG = pop_easy(filename, 0, 0, []);

    % Editing channel locations
    EEG = pop_chanedit(EEG, 'lookup', ...
        '/Users/Jinwoo_1/Desktop/connectome/eeglab2023.0/plugins/dipfit/standard_BEM/elec/standard_1005.elc');
    EEG = eeg_checkset(EEG);

    EEG.setname = 'rawdata';
    eeglab redraw;
    
    % ---------------------------------------------------
    % STEP I. TIME SLICING
    % ---------------------------------------------------
    mkdir([working_dir, target_sub, '/pped']);
    
    % I-1. setting the event marker (assuming 5 for now, modify as needed)
    start_idx = 7;
    finish_idx = 9;
    
    event_latencies = [EEG.event.latency]; 
    start_latency = event_latencies(start_idx); 
    finish_latency = event_latencies(finish_idx);
    time_interval = finish_latency - start_latency;
    
    EEG = pop_epoch(EEG, {num2str(start_idx)}, [start_time time_interval], 'newname', ...
        'rawdata', 'epochinfo', 'yes');
    
    % I-3. saving the epoched data
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 2, 'savenew', ...
        strcat(working_dir, target_sub, '/pped/', strcat(target_sub, '_task_pped-step1.set'), 'overwrite', 'on', 'gui', 'off'));
    eeglab redraw;

    % ----------------------------------------------------
    % STEP II. BASIC PREPROCESSING
    % ----------------------------------------------------
    % II-1. high pass filtering (0.5 Hz)
    EEG = pop_eegfiltnew(EEG, 'locutoff', low_filt);
    
    % II-2. removing the ECG channel
    EEG = pop_select(EEG, 'nochannel', {'EXT'});
    chanlocs = EEG.chanlocs;
    
    % II-3. applying 'clean_rawdata' function to reject artifacts
    EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion', 4, 'ChannelCriterion', 0.85, ...
        'LineNoiseCriterion', 4, 'Highpass', 'off', 'BurstCriterion', 'off', ...
        'WindowCriterion', 'off', 'BurstRejection', 'off', 'Distance', 'Euclidian');
    
    % II-4. saving the preprocessed output
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 3, 'setname', ...
        'rawdata', 'savenew', ...
        strcat(working_dir, target_sub, '/pped/', strcat(target_sub, '_task_pped-step2.set'), 'gui', 'off'));
    eeglab redraw;
    
    % ------------------------------------------------------
    % PART III. ICA Artefact Rejection and Interpolation
    % ------------------------------------------------------
    
    % III-1. running ICA
    EEG = pop_runica(EEG, 'icatype', 'picard', 'maxiter', 500);
    
    % III-2. labeling components with ICLabel
    EEG = pop_iclabel(EEG, 'default');
    
    % III-3. removing components with artifact probability > 90%
    EEG = pop_icflag(EEG, [NaN NaN; 0.9 1.0; 0.9 1.0; 0.9 1.0; 0.9 1.0; 0.9 1.0; 0.9 1.0]);
    EEG = pop_subcomp(EEG, [], 0);
    
    % III-4. interpolating removed channels
    EEG = pop_interp(EEG, chanlocs);
    
    % III-5. saving the cleaned data
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 4, 'setname', ...
        'rawdata', 'savenew', ...
        strcat(working_dir, target_sub, '/pped/', strcat(target_sub, '_task_pped-step3.set'), 'gui', 'off'));
    eeglab redraw;
    
    % -----------------------------------------------------
    % RESET
    % -----------------------------------------------------
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'gui','off'); 
    STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[];
    eeglab redraw;
    
    fprintf('finish!');

end


%% Main Preprocessing for BASELINE signals

for sub = 1:length(sub_list)
    target_sub = char(sub_list(sub)); 
    filename = strcat(working_dir, target_sub, '/raw/', strcat(target_sub, '_task.easy'));
    
    % ---------------------------------------------------
    % STEP 0. LOADING RAW DATA
    % ---------------------------------------------------
    % Loading .easy data
    EEG = pop_easy(filename, 0, 0, []);

    % Editing channel locations
    EEG = pop_chanedit(EEG, 'lookup', ...
        '/Users/Jinwoo_1/Desktop/connectome/eeglab2023.0/plugins/dipfit/standard_BEM/elec/standard_1005.elc');
    EEG = eeg_checkset(EEG);

    EEG.setname = 'rawdata';
    eeglab redraw;
    
    % ---------------------------------------------------
    % STEP I. TIME SLICING
    % ---------------------------------------------------
    mkdir([working_dir, target_sub, '/pped']);
    
    % I-1. setting the event marker 
    start_idx = 7;
    finish_time = 117;

    EEG = pop_epoch(EEG, {num2str(start_idx)}, [start_time finish_time], 'newname', ...
        'rawdata', 'epochinfo', 'yes');
    
    % I-3. saving the epoched data
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 2, 'savenew', ...
        strcat(working_dir, target_sub, '/pped/', strcat(target_sub, '_base_pped-step1.set'), 'overwrite', 'on', 'gui', 'off'));
    eeglab redraw;

    % ----------------------------------------------------
    % STEP II. BASIC PREPROCESSING
    % ----------------------------------------------------
    % II-1. high pass filtering (0.5 Hz)
    EEG = pop_eegfiltnew(EEG, 'locutoff', low_filt);
    
    % II-2. removing the ECG channel
    EEG = pop_select(EEG, 'nochannel', {'EXT'});
    chanlocs = EEG.chanlocs;
    
    % II-3. applying 'clean_rawdata' function to reject artifacts
    EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion', 4, 'ChannelCriterion', 0.85, ...
        'LineNoiseCriterion', 4, 'Highpass', 'off', 'BurstCriterion', 'off', ...
        'WindowCriterion', 'off', 'BurstRejection', 'off', 'Distance', 'Euclidian');
    
    % II-4. saving the preprocessed output
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 3, 'setname', ...
        'rawdata', 'savenew', ...
        strcat(working_dir, target_sub, '/pped/', strcat(target_sub, '_base_pped-step2.set'), 'gui', 'off'));
    eeglab redraw;
    
    % ------------------------------------------------------
    % PART III. ICA Artefact Rejection and Interpolation
    % ------------------------------------------------------
    
    % III-1. running ICA
    EEG = pop_runica(EEG, 'icatype', 'picard', 'maxiter', 500);
    
    % III-2. labeling components with ICLabel
    EEG = pop_iclabel(EEG, 'default');
    
    % III-3. removing components with artifact probability > 90%
    EEG = pop_icflag(EEG, [NaN NaN; 0.9 1.0; 0.9 1.0; 0.9 1.0; 0.9 1.0; 0.9 1.0; 0.9 1.0]);
    EEG = pop_subcomp(EEG, [], 0);
    
    % III-4. interpolating removed channels
    EEG = pop_interp(EEG, chanlocs);
    
    % III-5. saving the cleaned data
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 4, 'setname', ...
        'rawdata', 'savenew', ...
        strcat(working_dir, target_sub, '/pped/', strcat(target_sub, '_base_pped-step3.set'), 'gui', 'off'));
    eeglab redraw;
    
    % -----------------------------------------------------
    % RESET
    % -----------------------------------------------------
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'gui','off'); 
    STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[];
    eeglab redraw;
    
    fprintf('finish!');

end


