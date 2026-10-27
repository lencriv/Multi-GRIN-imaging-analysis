function files = mgi_plot_inter_partial_scatter(baseline,cfg,folder)
%MGI_PLOT_INTER_PARTIAL_SCATTER Signed partial r of each neuron with its two target regions.
%   One panel per seed region; diamonds are within-mouse medians; the title
%   gives the one-sample t-test of centroid residuals (Holm).
    regions = cfg.regions;
    neurons = baseline.inter.neurons;
    fig = mgi_new_figure(cfg,6.4,2.45);
    for r = 1:numel(regions)
        ax = mgi_new_axes(fig,[0.6 + (r - 1)*2.08, 0.55, 1.45, 1.45],cfg);
        targets = baseline.targets{r};
        a = regions{targets(1)}; b = regions{targets(2)};
        in = neurons.seed == r;
        x = neurons.rA(in); y = neurons.rB(in);
        limit = max(0.5,ceil((max(abs([x; y])) + 0.01)*20)/20);
        plot(ax,[-limit limit],[0 0],'-','Color',[0.35 0.35 0.35],'LineWidth',0.75);
        plot(ax,[0 0],[-limit limit],'-','Color',[0.35 0.35 0.35],'LineWidth',0.75);
        mgi_scatter_points(ax,x,y,cfg.colors.(regions{r}),7,0.5);
        plot(ax,[-limit limit],[-limit limit],'--','Color',[0.4 0.4 0.4],'LineWidth',0.75);
        plot(ax,baseline.inter.centroidA(:,r),baseline.inter.centroidB(:,r),'d','Color','k', ...
            'MarkerSize',6,'LineWidth',0.9,'MarkerFaceColor','none');
        set(ax,'XLim',[-limit limit],'YLim',[-limit limit]);
        mgi_set_ticks(ax,'X',[-0.5 0 0.5],'%.1f');
        if limit >= 0.6
            mgi_set_ticks(ax,'Y',-0.6:0.2:0.6,'%.1f');
        else
            mgi_set_ticks(ax,'Y',[-0.5 0 0.5],'%.1f');
        end
        xlabel(ax,sprintf('Partial {\\itr} with %s  |  %s',a,b));
        ylabel(ax,sprintf('Partial {\\itr} with %s  |  %s',b,a));
        mgi_hide_axis_lines(ax);
        stars = mgi_stars(baseline.stats.interCentroid(r).P_Holm);
        if strcmp(stars,'ns'), stars = '(ns)'; end
        titleSize = cfg.figures.fontSize + 4;
        half = mgi_text_width(regions{r},titleSize)/1.45/2;
        text(ax,0.5,1.06,regions{r},'Units','normalized','Color',cfg.colors.(regions{r}), ...
            'FontSize',titleSize,'HorizontalAlignment','center','VerticalAlignment','bottom');
        text(ax,0.5 + half + 0.04,1.08,stars,'Units','normalized','FontSize',cfg.figures.fontSize + 1, ...
            'HorizontalAlignment','left','VerticalAlignment','bottom');
    end
    files = mgi_save_figure(fig,folder,'inter_region_partial_correlation_scatter',cfg);
end
