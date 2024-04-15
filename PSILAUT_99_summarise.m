function tab_smry = PSILAUT_99_summarise(path_preproc)

    path_smry = fullfile(path_preproc, '_summary');
    if ~exist(path_smry, 'dir')
        error('Summary path not found: %s', path_smry);
    end
    
    d = dir([path_smry, filesep, '*.mat']);
    numFiles = length(d);
    
    res = {};
    for f = 1:numFiles
        
        path_oneFile = fullfile(d(f).folder, d(f).name);
        tmp = load(path_oneFile);
        parts = strsplit(d(f).name, '_');
        id = parts{1};
        visit = parts{2};
        tmp.tab_tasks.id = repmat({id}, height(tmp.tab_tasks), 1);
        tmp.tab_tasks.visit = repmat({visit}, height(tmp.tab_tasks), 1);
        s = table2struct(tmp.tab_tasks);
        res = [res; structArray2cellArrayOfStructs(s)'];
        
    end
    
    tab = teLogExtract(res);
    tab.present = tab.num_events > 0;
    tab = movevars(tab, {'id', 'visit', 'task', 'present', 'num_events'}, 'Before', 1);
    
    id_vis = makeSig(tab, {'id', 'visit'});
    [task_u, ~, task_s] = unique(tab.task);
    [id_vis_u, ~, id_vis_s] = unique(id_vis);
    m = accumarray([id_vis_s, task_s], tab.num_events, [], @sum);
    tab_smry = array2table(m, 'VariableNames', task_u);
    parts = cellfun(@(x) strsplit(x, '#'), id_vis_u, 'UniformOutput', false);
    tab_smry.id = cellfun(@(x) x{1}, parts, 'UniformOutput', false);
    tab_smry.visit = cellfun(@(x) x{2}, parts, 'UniformOutput', false);
    tab_smry = movevars(tab_smry, {'id', 'visit'}, 'Before', 1);
    bar(m)



end