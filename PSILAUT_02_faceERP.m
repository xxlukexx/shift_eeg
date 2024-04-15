function [suc, oc, erps] = PSILAUT_02_faceERP(path_preproc, path_task_analyses)

    suc = false;
    oc = 'unknown error';
    smry = [];
    erps = [];
    
    set(0,'defaultAxesFontSize',20)    

    % find and check task folders in preproc output
    path_tasks = PSILAUT_discoverPreprocessedTasks(path_preproc);
    if isempty(path_tasks)
        suc = false;
        oc = sprintf('no data found in path: %s', path_preproc);
        return
    end
    if isempty(path_tasks('face_erp'))
        suc = false;
        oc = sprintf('no face ERP data found in path: %s', path_preproc);
        return
    end
    
    % find all files to process
    d = dir([path_tasks('face_erp'), filesep, '*.mat']);
    numFiles = length(d);
    
    % build output paths
    path_face_erp = fullfile(path_task_analyses, 'faceerp');
    tryToMakePath(path_face_erp);
    path_faceerp_preproc = fullfile(path_face_erp, '01_preproc');
    tryToMakePath(path_faceerp_preproc);
    path_faceerp_clean = fullfile(path_face_erp, '02_clean');
    tryToMakePath(path_faceerp_clean);
    path_faceerp_avg = fullfile(path_face_erp, '03_avg');
    tryToMakePath(path_faceerp_avg);
    
    % analyse
    erps = cell(numFiles, 1);
    for f = 1:numFiles
        
        path_in = fullfile(d(f).folder, d(f).name);
        [~, fil, ~] = fileparts(path_in);
        parts = strsplit(fil, '_');
        id = sprintf('%s_%s', parts{1}, parts{2});
        
        % preproc
        [~, file_faceerp_preproc, ops] = LEAP_EEG_faces_01_doPreProc(...
            [], path_in, 'KCL', id, path_faceerp_preproc, 30, 1);
        
        % clean
        file_faceerp_preproc = fullfile(path_faceerp_preproc, file_faceerp_preproc);
        [~, file_faceerp_clean, ops] = LEAP_EEG_faces_02_doClean(...
            ops, file_faceerp_preproc, id, path_faceerp_clean);
        
        % avg
        [erps{f}, ops] = LEAP_EEG_faces_03_doAverage(...
            file_faceerp_clean, path_faceerp_avg);
        
    end
        
%         % plot
%         
%             idx_p7 = strcmpi(erps{f}.face_up.label, 'P7');
%             idx_p8 = strcmpi(erps{f}.face_up.label, 'P8');
%         
%             fig = figure('color', 'w', 'name', id);
%                         
%             % p7 / left hemi
%             subplot(1, 2, 1)
%             plot(erps{f}.face_up.time, erps{f}.face_up.avg(idx_p7, :), 'LineWidth', 3)
%             hold on
%             plot(erps{f}.face_inv.time, erps{f}.face_inv.avg(idx_p7, :), 'LineWidth', 3)
%             xlabel('Time (s)')
%             ylabel('µV')
%             title('P7 / left hemi')
%             legend('upright', 'inverted')                        
%             
%             % p8 / right hemi
%             subplot(1, 2, 2)
%             plot(erps{f}.face_up.time, erps{f}.face_up.avg(idx_p8, :), 'LineWidth', 3)
%             hold on
%             plot(erps{f}.face_inv.time, erps{f}.face_inv.avg(idx_p8, :), 'LineWidth', 3)        
%             xlabel('Time (s)')
%             ylabel('µV')
%             title('P8 / right hemi')
%             legend('upright', 'inverted')                        
%                     
%     end
        
    









end