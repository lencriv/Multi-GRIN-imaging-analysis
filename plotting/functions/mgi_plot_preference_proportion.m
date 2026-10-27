function files = mgi_plot_preference_proportion(baseline,cfg,folder)
%MGI_PLOT_PREFERENCE_PROPORTION Proportion of neurons with a significant single-region preference.
%   Bars are grouped by source region (bottom labels) and colored by the
%   preferred target region; proportions are of all analyzed neurons.
    regions = cfg.regions;
    groups = cfg.figures.preferenceBars;
    fig = mgi_new_figure(cfg,2.45,2.35);
    ax = mgi_new_axes(fig,[0.62 0.72 1.7 1.45],cfg);
    positions = []; heights = []; colors = []; names = {};
    for g = 1:size(groups,1)
        seed = groups{g,1};
        shown = groups{g,2};
        targets = baseline.targets{seed};
        for k = 1:numel(shown)
            row = 1 + (shown(k) == targets(2));
            positions(end+1) = (g - 1)*2.35 + k;
            heights(end+1) = baseline.inter.preferenceFraction(row,seed);
            colors(end+1,:) = cfg.colors.(regions{shown(k)});
            names{end+1} = regions{shown(k)};
        end
    end
    mgi_draw_bars(ax,positions,heights,colors,0.72);
    top = max(0.1,ceil((max(heights) + 0.04)*10)/10);
    set(ax,'XLim',[positions(1) - 0.6, positions(end) + 0.6],'YLim',[0 top], ...
        'XTick',positions,'XTickLabel',names);
    mgi_set_ticks(ax,'Y',0:0.1:top,'%.1f');
    ylabel(ax,{'Proportion of neurons','with single region preference'});
    for r = 1:numel(regions)
        text(ax,0.06,0.97 - (r - 1)*0.085,regions{r},'Units','normalized','Color',cfg.colors.(regions{r}), ...
            'FontSize',cfg.figures.fontSize + 1.5,'HorizontalAlignment','left','VerticalAlignment','top');
    end
    span = top;
    unitWidth = 1.7/(positions(end) - positions(1) + 1.2);
    yTop = -0.13*span; yBottom = -0.23*span;
    style = {'Color','k','LineWidth',0.5,'Clipping','off'};
    for g = 1:size(groups,1)
        x1 = (g - 1)*2.35 + 1; x2 = x1 + 1; mid = (x1 + x2)/2;
        name = regions{groups{g,1}};
        half = mgi_text_width(name,cfg.figures.fontSize)/unitWidth/2 + 0.05;
        line(ax,[x1 x1],[yTop yBottom],style{:});
        line(ax,[x2 x2],[yTop yBottom],style{:});
        line(ax,[x1 mid - half],[yBottom yBottom],style{:});
        line(ax,[mid + half x2],[yBottom yBottom],style{:});
        arrowhead(ax,x1,yTop,span);
        arrowhead(ax,x2,yTop,span);
        text(ax,mid,yBottom,name,'HorizontalAlignment','center', ...
            'VerticalAlignment','middle','FontSize',cfg.figures.fontSize,'Clipping','off');
    end
    files = mgi_save_figure(fig,folder,'region_preference_proportion',cfg);
end

function arrowhead(ax,x,y,span)
    patch(ax,x + 0.06*[-1 1 0],y + span*[-0.025 -0.025 0.005],'k','EdgeColor','none','Clipping','off');
end
