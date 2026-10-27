function files = mgi_plot_movement_cdf(baseline,cfg,folder)
%MGI_PLOT_MOVEMENT_CDF CDFs of single-neuron R^2 with orofacial movement by region.
%   Pooled neurons; brackets give the pairwise two-sample KS tests.
    fig = mgi_new_figure(cfg,2.15,2.3);
    ax = mgi_new_axes(fig,[0.5 0.66 1.45 1.5],cfg);
    regions = cfg.regions;
    for r = 1:numel(regions)
        plot(ax,baseline.grid.x,baseline.movement.pooledCDF(r,:),'-','Color',cfg.colors.(regions{r}), ...
            'LineWidth',1.5);
    end
    mgi_asinh_axis(ax,cfg,45);
    set(ax,'YLim',[0 1],'YTick',[0 0.5 1],'YTickLabel',{'0','0.5','1'});
    minorTicks(ax,0:0.1:1);
    ylabel(ax,'cumulative distribution (proportion)');
    xlabel(ax,{'Single neuron correlation with','orofacial movement (R^2)'});
    overlay = mgi_overlay_axes(ax);
    labels = mgi_line_legend(overlay,regionEntries(cfg),[0.40 0.31 0.115 0.13],cfg);
    stats = baseline.stats.movementCDF;
    mgi_legend_brackets(overlay,labels,arrayfun(@(s) mgi_stars(s.P),stats(:)','UniformOutput',false),cfg);
    files = mgi_save_figure(fig,folder,'movement_correlation_cdf',cfg);
end

function entries = regionEntries(cfg)
    entries = struct('label',cellfun(@(r) mgi_tex_color(r,cfg.colors.(r)),cfg.regions,'UniformOutput',false), ...
        'color',cellfun(@(r) cfg.colors.(r),cfg.regions,'UniformOutput',false), ...
        'lineStyle','-','lineWidth',1.5,'fontSize',cfg.figures.fontSize + 2);
end

function minorTicks(ax,values)
    try
        ax.YAxis.MinorTick = 'on';
        ax.YAxis.MinorTickValues = values;
    catch
    end
end
