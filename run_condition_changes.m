function results = run_condition_changes(overrides)
%RUN_CONDITION_CHANGES Load, preprocess and plot the Baseline-TD and TD-TBZ comparisons.
%   results = run_condition_changes()            uses config/mgi_config.m
%   results = run_condition_changes(overrides)   e.g. struct('verbose',false)
    mgi_setup();
    if nargin < 1, overrides = struct(); end
    cfg = mgi_config(overrides);
    results = mgi_preprocess_condition_changes(cfg);
    results.files = mgi_plot_condition_changes(results,cfg);
end
