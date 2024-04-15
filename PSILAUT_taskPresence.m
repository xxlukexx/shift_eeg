function [suc, oc, ops, tab, tab_ev] = PSILAUT_taskPresence(event, ops)
% Takes a fieldtrip event struct and returns the name of present tasks
% ('tasks') and trial N (in the Matlab table 'tab')

    % default output vars in case of unhandled error
    suc = false;
    oc = 'unknown error';
    data = [];
    tab = [];
    tab_ev = [];
    
    if ~exist('ops', 'var') || isempty(ops)
        ops = operationsContainer;
    end
    
    % check event struct presence and format
    
        % ensure a variable was passed
        if ~exist('event', 'var') || isempty(event)
            suc = false; 
            oc = 'empty or no events';
            return
        end

        % ensure it has the right fields 
        reqEventFields = {'type', 'value', 'sample', 'offset'};
        if ~isstruct(event) ||...
                ~all(cellfun(@(x) isfield(event, x), reqEventFields))
            suc = false;
            oc = 'unrecognised event struct format';
            return
        end

        % ensure it is not empty
        if isempty(event) 
            suc = false;
            oc = 'empty event struct';
        end
        
        % make table for ease of indexing
        tab_ev = struct2table(event);
        ops.num_eeg_events = length(event);
        
    % define expected events by task
    
        expEvents = {...
            % code(s)                           task                        condition
            31,                                 'resting_state',            'onset_eyes_open'           ;...
            32,                                 'resting_state',            'offset_eyes_open'          ;...
            33,                                 'resting_state',            'onset_eyes_closed'         ;...
            34,                                 'resting_state',            'offset_eyes_closed'        ;...   
            [223, 224, 225],                    'face_erp',                 'face_upright'              ;...
            [226, 227, 228],                    'face_erp',                 'face_inverted'             ;...
            [21, 22, 23],                       'face_erp',                 'house_upright'             ;...
            40,                                 'contrast_saturation',      'task_onset'                ;...
            41,                                 'contrast_saturation',      'task_offset'               ;...            
            [301, 330, 399, 430, 499],          'contrast_saturation',      'trial_onset'               ;...
            201,                                'mmn',                      'std'                       ;...
            202,                                'mmn',                      'dev_dur'                   ;...
            203,                                'mmn',                      'dev_freq'                  ;...
            204,                                'mmn',                      'dev_comb'                  ;...
            };
        
    % count present events for each task/conditon, format as table
    
        for i = 1:height(expEvents)
            
            % find codes for this task/condition
            codes = expEvents{i, 1};
            
            % get indices of EEG codes that match this task/condition
            idx = ismember(tab_ev.value, codes);
            
            % count number of EEG codes (i.e. number of trials)
            expEvents{i, 4} = sum(idx);
            
        end
        
        tab = cell2table(expEvents(:, 2:end), 'VariableNames',...
            {'task', 'condition', 'trial_n'});
        tab.code = expEvents(:, 1);
        
            
        suc = true;
        oc = '';
        
end