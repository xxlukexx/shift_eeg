function [suc, oc, data_seg, tab_tasks, ops] = PSILAUT_01_preproc_jm(path_eeg, path_out)
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
    
    j = tepJobManager;
    
    % loop through and send processing jobs to worker
    for f = 1:numFiles
        
        path_in_one = fullfile(d(f).folder, d(f).name);        
        ops{f} = operationsContainer;
        ops{f}.path_raw = path_in_one;
        
        j.AddJob(@PSILAUT_01_doPreproc, 5, [], path_in_one, path_out, ops{f});

    end
    
    j.RunJobs;

end


 