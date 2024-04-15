function path_task = PSILAUT_discoverPreprocessedTasks(path_preproc)

    path_task = teCollection;
    d = dir(path_preproc);
    idx = [d.isdir] & ~ismember({d.name}, {'.', '..'});
    d(~idx) = [];
    
    for i = 1:length(d)
        path_task(d(i).name) = fullfile(d(i).folder, d(i).name);
    end

end