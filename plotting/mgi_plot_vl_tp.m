function files = mgi_plot_vl_tp(results,cfg)
%MGI_PLOT_VL_TP Figures of activity around voluntary licks (VL) and tongue protrusions (TP).
%   files = mgi_plot_vl_tp(results,cfg)
%   results may be the struct returned by mgi_preprocess_vl_tp or the path
%   of the saved vl_tp.mat. For each region (folder <figures>/vl_tp):
%     vl_tp_activity_<region>    mean activity and peak-sorted heatmaps around VL and TP onset
%     vl_tp_epoch_auc_<region>   shift-control, pre- and post-epoch AUC for VL and TP
    if nargin < 2, cfg = mgi_config(); end
    if ischar(results) || isstring(results)
        contents = load(char(results),'results');
        results = contents.results;
    end
    folder = fullfile(cfg.paths.figures,'vl_tp');
    files = {};
    for r = 1:numel(results.regions)
        files = [files, mgi_plot_vl_tp_activity(results.regions(r),cfg,folder), ...
            mgi_plot_epoch_auc(results.regions(r),cfg,folder)]; %#ok<AGROW>
    end
end
