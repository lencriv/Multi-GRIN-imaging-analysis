function files = mgi_plot_intra_partial_cdf(baseline,cfg,folder)
%MGI_PLOT_INTRA_PARTIAL_CDF CDFs of pairwise within-region partial R^2, averaged across mice.
%   Brackets give the mouse-level sign-flip tests (Benjamini-Hochberg).
    fig = mgi_new_figure(cfg,2.15,2.3);
    ax = mgi_new_axes(fig,[0.5 0.66 1.45 1.5],cfg);
    regions = cfg.regions;
    for r = 1:numel(regions)
        plot(ax,baseline.grid.x,baseline.intra.groupCDF(r,:),'-','Color',cfg.colors.(regions{r}), ...
            'LineWidth',1.5);
    end
    mgi_asinh_axis(ax,cfg,45);
    set(ax,'YLim',[0 1]);
    mgi_set_ticks(ax,'Y',0:0.1:1,'%g');
    ylabel(ax,'cumulative distribution (proportion)');
    xlabel(ax,{'pairwise partialled','intra-region correlation (R^2)'});
    overlay = mgi_overlay_axes(ax);
    entries = struct('label',cellfun(@(r) mgi_tex_color(r,cfg.colors.(r)),regions,'UniformOutput',false), ...
        'color',cellfun(@(r) cfg.colors.(r),regions,'UniformOutput',false), ...
        'lineStyle','-','lineWidth',1.5,'fontSize',cfg.figures.fontSize + 2);
    labels = mgi_line_legend(overlay,entries,[0.40 0.22 0.09 0.13],cfg);
    stats = baseline.stats.intraCDF;
    mgi_legend_brackets(overlay,labels,arrayfun(@(s) mgi_stars(s.P_BH),stats(:)','UniformOutput',false),cfg);
    files = mgi_save_figure(fig,folder,'intra_region_partial_correlation_cdf',cfg);
end
