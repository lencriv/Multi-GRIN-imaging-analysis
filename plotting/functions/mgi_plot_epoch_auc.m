function files = mgi_plot_epoch_auc(entry,cfg,folder)
%MGI_PLOT_EPOCH_AUC Mean epoch AUC of the neurons of one region for VL and TP.
%   Shift control, pre-movement and post-movement epochs; mean +/- s.e.m.
%   across neurons. Stars give the rank-sum test between conditions at
%   each epoch, Benjamini-Hochberg corrected across the three epochs.
    labels = entry.labels;
    fs = cfg.figures.fontSize;
    e = cfg.events.epochSeconds;
    fig = mgi_new_figure(cfg,1.75,2.25);
    ax = mgi_new_axes(fig,[0.6 0.72 1.0 1.2],cfg);
    top = entry.mean + entry.sem;
    bottom = entry.mean - entry.sem;
    top(~isfinite(top)) = entry.mean(~isfinite(top));
    bottom(~isfinite(bottom)) = entry.mean(~isfinite(bottom));
    finite = [top(isfinite(top)); bottom(isfinite(bottom))];
    if isempty(finite), finite = [0; 1]; end
    low = min([finite; 0]); high = max([finite; 0]);
    span = max(high - low,eps);
    for c = 1:2
        color = cfg.colors.(labels{c});
        plot(ax,1:3,entry.mean(c,:),'-','Color',color,'LineWidth',1.25);
        for x = 1:3
            if isfinite(entry.sem(c,x))
                plot(ax,[x x],[bottom(c,x) top(c,x)],'-','Color',color,'LineWidth',1.5);
            end
        end
    end
    for x = 1:3
        y = max(top(:,x));
        if ~isfinite(y), continue; end
        text(ax,x,y + 0.05*span,mgi_stars(entry.P_BH(x)),'HorizontalAlignment','center', ...
            'VerticalAlignment','bottom','FontSize',fs);
    end
    step = mgi_nice_step(1.2*span,8);
    yl = [low - 0.06*span, step*ceil((high + 0.2*span)/step)];
    set(ax,'XLim',[0.6 3.4],'YLim',yl,'XTick',1:3,'XTickLabel',{});
    mgi_set_ticks(ax,'Y',step*(ceil(yl(1)/step):floor(yl(2)/step)),'%g');
    perInch = diff(yl)/1.2;
    names = {{sprintf('Non-%s -%s',labels{2},labels{1}),'control'}, ...
        {sprintf('Pre-%s / %s',labels{2},labels{1}),sprintf('-%gs - 0s',e)}, ...
        {sprintf('Post-%s / %s',labels{2},labels{1}),sprintf('0s - %gs',e)}};
    for x = 1:3
        text(ax,x + 0.12,yl(1) - 0.07*perInch,names{x},'Rotation',45,'Interpreter','none', ...
            'HorizontalAlignment','right','VerticalAlignment','middle','FontSize',fs,'Clipping','off');
    end
    ylabel(ax,'Z-scored activity AUC');
    title(ax,mgi_tex_color(entry.region,cfg.colors.(entry.region)),'Interpreter','tex', ...
        'FontWeight','normal','FontSize',fs + 2);
    files = mgi_save_figure(fig,folder,sprintf('vl_tp_epoch_auc_%s',entry.region),cfg);
end
