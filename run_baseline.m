function results = run_baseline(overrides)
%RUN_BASELINE Load, preprocess and plot the baseline-session analyses.
%   results = run_baseline()            uses config/mgi_config.m
%   results = run_baseline(overrides)   e.g. struct('paths',struct('data','D:\exported_imaging'))
    mgi_setup();
    if nargin < 1, overrides = struct(); end
    cfg = mgi_config(overrides);
    results = mgi_preprocess_baseline(cfg);
    results.files = mgi_plot_baseline(results,cfg);
end
