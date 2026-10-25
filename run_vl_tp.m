function results = run_vl_tp(overrides)
%RUN_VL_TP Load, preprocess and plot activity around voluntary licks (BLL) and tongue protrusions (DW).
%   results = run_vl_tp()            uses config/mgi_config.m
%   results = run_vl_tp(overrides)   e.g. struct('events',struct('shuffles',200))
    mgi_setup();
    if nargin < 1, overrides = struct(); end
    cfg = mgi_config(overrides);
    results = mgi_preprocess_vl_tp(cfg);
    results.files = mgi_plot_vl_tp(results,cfg);
end
