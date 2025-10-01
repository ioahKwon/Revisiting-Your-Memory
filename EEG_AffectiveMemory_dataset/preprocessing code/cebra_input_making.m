% =========================================================================
% CEBRA INPUT-MAKER
% ----------------------------------
% for AI-Art Study
% ----------------------------------
% written by
% /
% Jinwoo Lee (SNU Connectome Lab)
% e-mail : adem1997@snu.ac.kr
% webpage: jinwoo-lee.com
% ----------------------------------
% 2024.11
% SNU Connectome Lab
% =========================================================================

%% Getting Start with EEGLAB!
addpath(genpath('/Users/Jinwoo_1/Desktop/connectome/eeglab2023.0'));
eeglab;

fprintf('@@@ EEGLAB was successfully executed. Here we go!')

%% Variable Settings                                                
sub_list = {'sub-01', 'sub-02', 'sub-03', 'sub-04', 'sub-05', ...
            'sub-06', 'sub-07', 'sub-08', 'sub-09', 'sub-10'};

working_dir = '/Users/Jinwoo_1/Desktop/ai_art/exp/';   
min_interval = 1000;

%% Converting .set to .csv CEBRA format!

for sub = 1:length(sub_list)
    
    target_sub = char(sub_list(sub));
    
    % ---------------------------------------------------------------------
    % STEP I. LOADING BASELINE FOR NORMALIZATION
    % ---------------------------------------------------------------------
    % I-1. loading baseline epoch
    filename = strcat(working_dir, target_sub, '/pped/', ...
        target_sub, '_base_pped-step3.set');                    
    EEG = pop_loadset(filename);
    EEG.setname = strcat(target_sub, '_base');
    
    eeglab redraw
    
    % I-2. calculating average potential of every channel
    EEG.dataT = transpose(EEG.data);
    EEG.dataT = array2table(EEG.dataT);
   
    labels = {EEG.chanlocs.labels}.';
    labels = transpose(labels);
   
    EEG.dataT.Properties.VariableNames = labels;
    
    base_avg = [];                                                         % empty array to append average potentials per channel
    
    for chan = 1:width(labels)
        chan_avg = mean(EEG.dataT{:, chan});
        base_avg = [base_avg; chan_avg];
    end
    
    base_avg = transpose(base_avg);
    
    % ---------------------------------------------------------------------
    % PART II. LABEL CONFIGURATION WITH EEG-TIMESERIES
    % ---------------------------------------------------------------------
    mkdir([working_dir, target_sub, '/cebra_input']);
    
    % II-1. loading the epoch
    filename = strcat(working_dir, target_sub, '/pped/', ...
        target_sub, '_task_pped-step3.set');  
    EEG = pop_loadset(filename);
    EEG.setname = strcat(target_sub, '_task');
    
    eeglab redraw
        
    % II-2. to create 'EEG.dataT' and 'labels' to merge them
    EEG.dataT = transpose(EEG.data);
    EEG.dataT = array2table(EEG.dataT);
        
    labels = {EEG.chanlocs.labels}.';                                      % the name of channels
    labels = transpose(labels);                                        
        
    EEG.dataT.Properties.VariableNames = labels;
    EEG.dataT.latency = (1:size(EEG.dataT, 1))';
        
    % II-3. to merge them into 'integrate' including EEG and valence
    event = table({EEG.event.type}.', [EEG.event.latency].', ...
        'VariableNames', {'type', 'latency'});
    event(1, :) = [];                                                      % to remove the first row (i.e., clip marker)
                                                                           % this can be controverisal, but this is the only possible option...
    integrate = outerjoin(event, EEG.dataT, 'MergeKeys', true);
        
    % II-4. to make 'chunk' table from 'event' table
    log = [];                                                              % to create empty 'log' vector
    chunk = table();                                                       % to create empty 'chunk' table
    
    for i = 1:height(event)                                            
        % CASE 1: the first event
        if i == 1
            log = [log; event.latency(i)];                                 % to append latency of the first event to 'log'
                
        % CASE 2: the last event
        elseif i == height(event)
            new_row = {event.type(i), min(log), event.latency(i)};
            chunk = [chunk; new_row];                                      % to create the last chunk
            
        % CASE 3: the same chunk
        elseif (isequal(event.type(i), event.type(i-1)) == 1) && ...
                (event.latency(i) - event.latency(i-1) < 1000)
            log = [log; event.latency(i)];                                 % to append latency of the event i to 'log'
            
        % CASE 4: the same event-type, but different chunk
        % cf) the criteria of 'different' chunk: 2s (= min_interval)
        elseif (isequal(event.type(i), event.type(i-1)) == 1) && ...
                (event.latency(i) - event.latency(i-1) >= 1000)
            new_row = {event.type(i-1), min(log), max(log)};
            chunk = [chunk; new_row];                                      % to create the new chunk
            log = [];                                                      % to reset 'log'
            log = [log; event.latency(i)];                                 % to append latency of the event i to 'log' 
                                                                           % i.e., this latency will be the start point of the new chunk!
                                                                           
        % CASE 5: the different event-type
        elseif isequal(event.type(i), event.type(i-1)) == 0
            new_row = {event.type(i-1), min(log), max(log)};
            chunk = [chunk; new_row];                                      % to create the new chunk
            log = [];                                                      % to reset 'log'
            log = [log; event.latency(i)];                                 % to append latency of the event i to 'log'
                                                                           % i.e., this latency will be the start point of the new chunk!
        end
    end
    
    % II-5. to fill valence frame in 'integrate' table
    if height(chunk) ~= 0
        chunk.Properties.VariableNames = {'type', 'start', 'finish'};      % to define column names of 'chunk' table
        chunk.duration = chunk.finish - chunk.start;
        
        for num_chunk = 1:height(chunk)
            chunk_range = chunk{num_chunk, 'start'}:chunk{num_chunk, 'finish'};
            integrate(chunk_range, 'type') = chunk{num_chunk, 'type'};
        end
        
        integrate(ismissing(integrate), 1) = {'0'};                        % to replace not-reported valence (i.e., neutral) to zero
    
    elseif height(chunk) == 0
        for row = 1:size(integrate, 1)
            integrate(row, 'type') = {'0'};
        end
    end
    
    % -----------------------------------------------------------------
    % PART III. NORMALIZATION WITH AVERAGED BASELINE
    % -----------------------------------------------------------------
    % III-1. normalization
    norm_integrate = integrate;
    
    for chan = 1:width(labels)
        norm_integrate{:, chan+2} = norm_integrate{:, chan+2} - base_avg(chan);
    end
    
    writetable(norm_integrate, ...
        strcat(working_dir, target_sub, '/cebra_input/', ...
        target_sub, '-norm-CEBRA.csv'));
    
    fprintf(strcat("@@@ ", target_sub,"'s preprocessed data was successsfully converted to CEBRA input format!"))
    
end

        
        
