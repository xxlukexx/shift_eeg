function [suc, oc, ops, data_seg, tab_tasks] = PSILAUT_01_doPreproc(path_eeg, path_out, ops)
% PSILAUT_01_doPreproc Preprocess EEG data for PSILAUT project.
%
% This function preprocesses EEG data by loading raw data, sanitizing events,
% segmenting the data based on task presence, and saving the segmented data
% to specified output paths.
%
% Parameters:
%   path_eeg (string): Path to the raw EEG data file.
%   path_out (string): Directory where the preprocessed data and summary files will be saved.
%   ops (struct): Optional. A structure containing various processing options and parameters.
%                 If not provided, a default operations structure is created.
%
% Returns:
%   suc (logical): Success flag. Returns true if the preprocessing was successful, false otherwise.
%   oc (string): Outcome message. Provides information about the success or failure of the operation.
%   ops (struct): Updated operations structure with additional processing details.
%   data_seg (cell array): Segmented EEG data for each identified task.
%   tab_tasks (table): Summary table containing details about task segmentation, including
%                      task names, event indices, number of events, and segment durations.
%
% The function performs the following steps:
% 1. Initializes output variables and checks for the presence of necessary input arguments.
% 2. Extracts the PSILAUT ID from the EEG file path.
% 3. Ensures the output directory exists, creating it if necessary.
% 4. Checks for the existence of a summary file to avoid redundant processing.
% 5. Initializes the FieldTrip toolbox for EEG processing.
% 6. Loads the raw EEG data and logs its duration.
% 7. Loads and sanitizes event markers.
% 8. Edits and converts event markers to a consistent format.
% 9. Identifies the presence of tasks based on event markers.
% 10. Segments the EEG data by task and saves the segmented data to disk.
% 11. Updates the summary table with segmentation details and saves it to disk.
%
% If any step fails, the function returns early with an appropriate error message.
%
% Example usage:
%   [suc, oc, ops, data_seg, tab_tasks] = PSILAUT_01_doPreproc('path/to/eeg/file.set', 'path/to/output/dir', ops);

    % default output vars in case of unhandled error
    suc = false;
    oc = 'unknown error';
    data_seg = [];
    tab_tasks = table;
    
    % if not passed, make a default operations struct
    if ~exist('ops', 'var') || isempty(ops)
        ops = operationsContainer;
    end
    
    % extract filename, which is the PSILAUT ID
    [~, id] = fileparts(path_eeg);
    ops.id = id;    
    
    % check output path exists
    if ~exist(path_out, 'dir') 
        tryToMakePath(path_out)
        if ~exist(path_out, 'dir')
            suc = false;
            oc = sprintf('cannot create output path: %s', path_out);
            return
        end
    end
    
    % make summary output path
    path_out_smry = fullfile(path_out, '_summary');    
    tryToMakePath(path_out_smry);
    file_out_smry = fullfile(path_out_smry, sprintf('%s_summary.mat', id));
    
    % skip if summary file exists for this dataset
    if exist(file_out_smry, 'file')
        suc = false;
        oc = 'file exists -- skipping';
%         return
    end
    
    % check fieldtrip is installed and init 
    try
        ft_defaults
    catch ERR
        suc = false;
        oc = sprintf('Error initialising fieldtrip toolbox: %s', ERR.message);
        return
    end
    
    % load raw data
    cfg = [];
    cfg.dataset = path_eeg;
    data = ft_preprocessing(cfg);
    fprintf('Loaded raw EEG with duration %s [from %s]\n',...
        datestr(data.time{1}(end) / 86400, 'HH:MM:SS'), path_eeg)
    ops.eeg_duration = data.time{1}(end);
    if ops.eeg_duration < 300
        ops.AddWarning('EEG duration < 5 mins');
    elseif ops.eeg_duration > 3600
        ops.AddWarning('EEG duration > 60 mins');
    end
    
    % load events
    event = ft_read_event(path_eeg);
    if isempty(event)
        suc = false;
        oc = 'no event markers';
        return
    end
    event = PSILAUT_santiseRawEEGEvents(event);
    fprintf('Loaded %d events\n', length(event));
    
    % convert consat events to a better range 
    [suc_editMarker, oc_editMarker, event] =...
        PSILAUT_consat_editRawEEGMarkerValues(event);
    fprintf('CONSAT TASK: %s\n', oc_editMarker);
    ops.consat_edit_markers_success = suc_editMarker;
    ops.consat_edit_markers_outcome = oc_editMarker;
    if ~suc_editMarker
        ops.AddWarning(...
            sprintf('Error converting consat event values: %s', oc_editMarker));
    end

    % get task presence from events
    [tp_suc, tp_oc, ops, tab_tp, tab_ev] = PSILAUT_taskPresence(event, ops);
    if ~tp_suc
        suc = false;
        oc = sprintf('Error getting task presence: %s', tp_oc);
        return
    end
    
    % segment into continuous data by task
    
        % find task names
        [task_u, ~, task_s] = unique(tab_tp.task);
        numTasks = length(task_u);
        data_seg = cell(numTasks, 1);   
        
        % build output summary table
        tab_tasks = table;
        tab_tasks.task = task_u;

        % loop through tasks and find indices of first (s1) and last (s2)
        % events for each
        idx_s1 = nan(numTasks, 1);
        idx_s2 = nan(numTasks, 1);
        for t = 1:numTasks
            
            % find indices
            tmp = tab_tp(task_s == t, :);
            fld = sprintf('task_%s_found', task_u{t});
            numTrialsFound = sum(tmp.trial_n);
            ops.(fld) = numTrialsFound ~= 0;
            
            % if no data for this task, log a warning and move to next
            % task
            if numTrialsFound == 0
                ops.AddWarning(sprintf('%s: no data found', task_u{t}));
                continue
            end
            allCodes = horzcat(tmp.code{:});
            idx = ismember(tab_ev.value, allCodes);
            idx_s1(t) = find(idx, 1, 'first');
            idx_s2(t) = find(idx, 1, 'last');
            
            % find events
            ev_s1 = event(idx_s1(t)).value;
            ev_s2 = event(idx_s2(t)).value;
            
            % find raw EEG sample indices, subtract 20s on either side to
            % avoid filter artefacts etc
            padding_secs = 20;
            padding_samps = padding_secs * data.fsample;
            eeg_s1 = event(idx_s1(t)).sample - padding_samps;
            eeg_s2 = event(idx_s2(t)).sample + padding_samps;
            tab_tasks.padding(t) = padding_secs;
            
            % update summary table
            tab_tasks.first_event_index(t) = idx_s1(t);
            tab_tasks.last_event_index(t) = idx_s2(t);
            tab_tasks.first_event(t) = ev_s1;
            tab_tasks.last_event(t) = ev_s2;
            numEvents = idx_s2(t) - idx_s1(t) + 2;
            tab_tasks.num_events(t) = numEvents;
            fld = sprintf('%s_num_events', task_u{t});
            ops.(fld) = numEvents;

            % ensure markers are monotonic
            if idx_s2(t) - idx_s1(t) < 1
                tab_tasks.segment_success = false;
                tab_tasks.segment_outcome = 'failed to pair first and last task markers';
                continue
            end
            
            % segment
            cfg = [];
            cfg.trl = [eeg_s1, eeg_s2, 0];
            data_seg{t} = ft_redefinetrial(cfg, data);
            fld = sprintf('task_%s_num_segments', task_u{t});
            ops.(fld) = length(data_seg{t}.trial);

            % Adjust the event sample indices to be relative to the start of the segment
            adjusted_events = event(idx_s1(t):idx_s2(t));
            first_event_sample = adjusted_events(1).sample - padding_samps;
            for i = 1:length(adjusted_events)
                adjusted_events(i).sample = adjusted_events(i).sample - first_event_sample + 1;
            end
            data_seg{t}.event = adjusted_events;

            % update task summary table
            duration = (eeg_s2 - eeg_s1) / data.fsample;
            str_duration = datestr(duration / 86400, 'HH:MM:SS');
            tab_tasks.duration{t} = str_duration;
            fld = sprintf('%s_duration', task_u{t});
            ops.(fld) = duration;
            fld = sprintf('%s_duration_formatted', task_u{t});
            ops.(fld) = str_duration;
            
            % make output paths
            path_out_task = fullfile(path_out, task_u{t});
            tryToMakePath(path_out_task);
            
            % save
            file_out = fullfile(path_out_task,...
                sprintf('%s_%s_raw.mat', id, task_u{t}));
            saveSegmentedData(file_out, data_seg{t});
            fld = sprintf('task_%s_output_file', task_u{t});
            ops.(fld) = strrep(file_out, path_out, '/preproc');
            fprintf('\n\n<strong>%s: Saved segmented data to: %s</strong>\n', upper(task_u{t}), file_out);
            
        end
        
        save(file_out_smry, 'tab_tasks', 'ops');
        ops.file_out_summary = file_out_smry;
        
    suc = true;
    oc = '';
    
end

function saveSegmentedData(file_out, data)
    save(file_out, 'data', '-v7.3')
end