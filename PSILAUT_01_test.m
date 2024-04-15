addpath('/Users/luke/code/Experiments/pipelines/PSILAUT/')
path_eeg = '/Volumes/projects/PSILAUT/raw_eeg';
path_out = '//Volumes/projects/PSILAUT/preproc';
[suc, oc, data_seg, tab_tasks, ops] = PSILAUT_01_preproc_jm(path_eeg, path_out);