function files = mgi_plot_baseline(results,cfg)
%MGI_PLOT_BASELINE Baseline-session figures from mgi_preprocess_baseline output.
%   files = mgi_plot_baseline(results,cfg)
%   results may be the struct returned by mgi_preprocess_baseline or the
%   path of the saved baseline.mat. Figures are written to
%   <figures>/baseline:
%     movement_correlation_cdf             single-neuron R^2 with orofacial movement
%     movement_significant_proportion      neurons significantly correlated with movement
%     correlation_matrix_<mouse>           R^2 matrix of one session across regions
%     intra_region_partial_correlation_cdf pairwise within-region partial R^2
%     inter_region_partial_correlation_scatter  signed partial r with target regions
%     region_preference_proportion         neurons with a single-region preference
    if nargin < 2, cfg = mgi_config(); end
    if ischar(results) || isstring(results)
        contents = load(char(results),'results');
        results = contents.results;
    end
    folder = fullfile(cfg.paths.figures,'baseline');
    b = results.baseline;
    files = [mgi_plot_movement_cdf(b,cfg,folder), ...
        mgi_plot_movement_proportion(b,cfg,folder), ...
        mgi_plot_correlogram(results.correlation,cfg,folder,cfg.figures.correlogramMouse), ...
        mgi_plot_intra_partial_cdf(b,cfg,folder), ...
        mgi_plot_inter_partial_scatter(b,cfg,folder), ...
        mgi_plot_preference_proportion(b,cfg,folder)];
end
