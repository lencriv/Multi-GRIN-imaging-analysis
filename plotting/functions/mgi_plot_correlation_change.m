function files = mgi_plot_correlation_change(comparison,kind,cfg,folder)
%MGI_PLOT_CORRELATION_CHANGE Mouse-averaged CDF difference (before - after) of pairwise R^2.
%   kind 'inter' draws region pairs (line styles cfg.figures.interLineStyles);
%   'intra' draws regions in region colors. Legend stars give the pooled
%   two-sample KS tests with Benjamini-Hochberg correction.
    changes = comparison.(kind);
    labelBefore = comparison.before.label;
    labelAfter = comparison.after.label;
    fig = mgi_new_figure(cfg,3.45,2.3);
    ax = mgi_new_axes(fig,[0.6 0.55 1.95 1.6],cfg);
    x = changes(1).grid.x;
    plot(ax,[x(1) x(end)],[0 0],'k-','LineWidth',0.5);
    entries = struct('label',{},'color',{},'lineStyle',{},'lineWidth',{},'fontSize',{});
    for k = 1:numel(changes)
        if strcmp(kind,'inter')
            color = [0.15 0.15 0.15];
            style = cfg.figures.interLineStyles{k};
            name = mgi_region_label(changes(k).label,cfg);
        else
            color = cfg.colors.(changes(k).label);
            style = '-';
            name = mgi_tex_color(changes(k).label,color);
        end
        plot(ax,x,changes(k).difference,style,'Color',color,'LineWidth',1);
        entries(end+1) = struct('label',sprintf('%s {\\color{black}%s}',name,mgi_stars(changes(k).P_BH)), ...
            'color',color,'lineStyle',style,'lineWidth',1,'fontSize',cfg.figures.fontSize + 1);
    end
    values = [changes.difference];
    step = 0.05;
    if max(values) - min(values) > 0.3, step = 0.1; end
    if max(values) - min(values) > 0.8, step = 0.2; end
    low = min(-2*step,floor(min(values)/step)*step);
    high = max(2*step,ceil(max(values)/step)*step);
    if high - max(values) < 0.4*step, high = high + step; end
    set(ax,'YLim',[low high]);
    mgi_set_ticks(ax,'Y',round((low:step:high)/step)*step,'%g');
    mgi_asinh_axis(ax,cfg,0);
    ylabel(ax,sprintf('\\DeltaCDF (%s - %s)',labelBefore,labelAfter));
    if strcmp(kind,'inter')
        xlabel(ax,'pairwise inter-region correlation (R^2)');
    else
        xlabel(ax,'pairwise intra-region correlation (R^2)');
    end
    overlay = mgi_overlay_axes(ax);
    mgi_line_legend(overlay,entries,[0.56 0.93 0.1 0.13],cfg);
    mgi_change_arrow(fig,[2.72 0.5 0.18 1.7],splitDescription(comparison.changeDescription),cfg);
    files = mgi_save_figure(fig,folder,sprintf('%s_%s_region_correlation_change',comparison.name,kind),cfg);
end

function lines = splitDescription(text)
    words = strsplit(text,' ');
    half = ceil(numel(words)/2);
    lines = {strjoin(words(1:half),' '),strjoin(words(half + 1:end),' ')};
end
