function files = mgi_plot_condition_changes(results,cfg)
%MGI_PLOT_CONDITION_CHANGES Transient-rate and correlation-change figures for each comparison.
%   files = mgi_plot_condition_changes(results,cfg)
%   results may be the struct returned by mgi_preprocess_condition_changes
%   or the path of the saved condition_changes.mat. For each comparison
%   (folder <figures>/<comparison name>):
%     <name>_transient_rate_<region>          Ca2+ transient-rate distributions
%     <name>_inter_region_correlation_change  CDF difference of inter-region pairwise R^2
%     <name>_intra_region_correlation_change  CDF difference of intra-region pairwise R^2
    if nargin < 2, cfg = mgi_config(); end
    if ischar(results) || isstring(results)
        contents = load(char(results),'results');
        results = contents.results;
    end
    files = {};
    for c = 1:numel(results.comparisons)
        comparison = results.comparisons(c);
        folder = fullfile(cfg.paths.figures,comparison.name);
        files = [files, mgi_plot_transient_rate(comparison,cfg,folder), ...
            mgi_plot_correlation_change(comparison,'inter',cfg,folder), ...
            mgi_plot_correlation_change(comparison,'intra',cfg,folder)];
    end
end
