# MGI imaging analysis

MATLAB code for the multi-GRIN imaging (M1, DMS, VLT) analyses 

## Requirements

MATLAB R2019b or later with the Statistics and Machine Learning Toolbox (`linkage` and `cluster` order the correlation matrices; `fitlme`, `kstest2` and `pdist` are used when available).

## Data

The condition files are not part of the repository. Set `cfg.paths.data` in `config/mgi_config.m` to the folder that holds them, or pass it at run time (see below). Results are written to `results/` inside the repository

## Run

```matlab
cd MGI_imaging_analysis               % repository folder
mgi_setup();
baseline = run_baseline();            % BLS: coupling, partial correlations, preference, correlation matrices
changes  = run_condition_changes();   % Baseline vs TD and TD vs TBZ: transient rates, correlation changes
vltp     = run_vl_tp();               % BLL (VL) and DW (TP): event-aligned activity, epoch AUC
```

Each run function loads the data, preprocesses it, saves the preprocessed results and statistics, and draws the figures. 

```matlab
cfg = mgi_config();
results = mgi_preprocess_baseline(cfg);                                        % preprocessing
mgi_plot_baseline(fullfile(cfg.paths.preprocessed,'baseline.mat'),cfg);         % plotting only
```

Settings are in `config/mgi_config.m`. Any of them can be overridden without editing the file:

```matlab
run_baseline(struct('paths',struct('data','D:\exported_imaging','results','D:\mgi_results'), ...
                    'baseline',struct('preferenceShuffles',2000)));
```

## Layout

```
run_baseline.m, run_condition_changes.m,
run_vl_tp.m                                load -> preprocess -> plot
mgi_setup.m                                adds the folders below to the path
config/          mgi_config (paths, cohorts, parameters, colors, figure style)
loading/         mgi_session_index, mgi_find_sessions, mgi_load_session, mgi_load_sessions
preprocessing/   preprocessing code: mgi_preprocess_baseline, mgi_preprocess_condition_changes,
                 mgi_preprocess_vl_tp
  functions/     preprocessing functions (raw session -> digestible variables -> analyses, statistics)
plotting/        plotting code: mgi_plot_baseline, mgi_plot_condition_changes, mgi_plot_vl_tp
  functions/     plotting functions (one per figure) and drawing helpers
tests/           synthetic data in the exported format and run_tests
results/         preprocessed/, statistics/, figures/ (created on first run)
```

## Loading

```matlab
cfg = mgi_config();
index    = mgi_session_index('BLS',cfg);                     % every session in BLS.mat
rows     = mgi_find_sessions('DW',cfg,'Cohort','WT');         % WT, TBZ, D1, D2, CHAT or 'all'
rows     = mgi_find_sessions('BLS',cfg,'Mouse',{'Pan_11'});
session  = mgi_load_session('BLS','Pan_11',cfg);              % by mouse, condition index or index row
sessions = mgi_load_sessions('TBZ',cfg,'Cohort','all');
```
