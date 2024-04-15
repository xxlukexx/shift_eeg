function [suc, oc, data_seg, tab_tasks, ops] = PSILAUT_01_preproc(path_eeg, path_out, doSerial)
% this batch processes a whole folder of EEG data, calling the helper
% function PSILAUT_01_doPreproc on each single data file

    % by default, use the parallel computing toolbox to speed up
    % processing. Optionally disable this for easier debugging. 
    if ~exist('doSerial', 'var') || isempty(doSerial)
        doSerial = false;
    end

    % find all *.eeg files
    d = dir([path_eeg, filesep, '*.eeg']);
    numFiles = length(d);
    suc = false(numFiles, 1);
    oc = cell(numFiles, 1);
    data_seg = cell(numFiles, 1);
    tab_tasks = cell(numFiles, 1);
    ops = cell(numFiles, 1);
    
    fprintf('<strong>PSILAUT_01_preproc</strong>: found %d files to process.\n',...
        numFiles);
    
    % loop through and send processing jobs to worker
    clear future
    futureCounter = 0;
    for f = 1:numFiles
        
        path_in_one = fullfile(d(f).folder, d(f).name);        
        ops{f} = operationsContainer;
        ops{f}.path_raw = path_in_one;
        
        switch doSerial
            
            case false
                
                % process in parallel
       
                fprintf('<strong>PSILAUT_01_preproc</strong>: Sent dataset %d to worker...\n', f);
                futureCounter = futureCounter + 1;
                future(futureCounter) = parfeval(...
                    @PSILAUT_01_doPreproc, 5, path_in_one, path_out, ops{f});
                
            case true
                
                % process serially
                
                [suc(f), oc{f}, ops{f}, data_seg{f}, tab_tasks{f}] =...
                    PSILAUT_01_doPreproc(path_in_one, path_out, ops{f});
                
        end
        
    end
    
    % if processing serially, we are done. 
    if doSerial, return, end
    
    fprintf('<strong>PSILAUT_01_preproc</strong>: Waiting for first job to complete...\n');
    
    % collect finished jobs from workers
    for f = 1:futureCounter
        
        % retrieve finished job. We don't yet know which job this is, so
        % store all output vars in temp vars for now
        [idx, tmp_suc, tmp_oc, tmp_ops, tmp_data_seg, tmp_tab_tasks] = fetchNext(future);
        
        % use the returned index to place the temp vars into their proper
        % order
        suc(idx) = tmp_suc;
        oc{idx} = tmp_oc;
        data_seg{idx} = tmp_data_seg;
        tab_tasks{idx} = tmp_tab_tasks;
        ops{idx} = tmp_ops;
        
        fprintf('<strong>PSILAUT_01_preproc</strong>: Received dataset %d from worker...\n', f);
        
    end

end


 