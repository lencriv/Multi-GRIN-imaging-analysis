function files = mgi_plot_correlogram(correlation,cfg,folder,mouse)
%MGI_PLOT_CORRELOGRAM R^2 correlation matrix of one session across regions.
%   files = mgi_plot_correlogram(correlation,cfg,folder,'Pan_11')
%   Regions in cfg.figures.correlogramRegionOrder, neurons clustered within
%   region, jet color scale over cfg.figures.correlogramLimits.
    if nargin < 4, mouse = cfg.figures.correlogramMouse; end
    entry = correlation(find(strcmp({correlation.mouse},mouse),1));
    if isempty(entry)
        error('MGI:correlogramMouse','No correlation matrix for %s.',mouse);
    end
    regionOrder = cfg.figures.correlogramRegionOrder;
    offsets = [0 cumsum(entry.counts)];
    index = [];
    for r = regionOrder
        index = [index, offsets(r) + (1:entry.counts(r))];
    end
    R2 = double(entry.R2(index,index));
    counts = entry.counts(regionOrder);
    names = entry.regions(regionOrder);
    N = sum(counts);
    edges = [0 cumsum(counts)];

    fig = mgi_new_figure(cfg,3.25,2.45);
    side = 1.75;
    ax = axes('Parent',fig,'Units','inches','Position',[0.32 0.38 side side]);
    imagesc(ax,R2,cfg.figures.correlogramLimits);
    colormap(ax,jet(256));
    hold(ax,'on');
    for k = 2:numel(counts)
        plot(ax,[0.5 N + 0.5],edges(k)*[1 1] + 0.5,'w-','LineWidth',0.4);
        plot(ax,edges(k)*[1 1] + 0.5,[0.5 N + 0.5],'w-','LineWidth',0.4);
    end
    set(ax,'XTick',[],'YTick',[],'XLim',[0.5 N + 0.5],'YLim',[0.5 N + 0.5],'YDir','reverse', ...
        'Box','off','XColor','none','YColor','none');
    style = {'FontName',cfg.figures.font,'FontSize',cfg.figures.fontSize + 2};
    top = axes('Parent',fig,'Units','inches','Position',[0.32 0.38 + side + 0.02 side 0.06], ...
        'XLim',[0.5 N + 0.5],'YLim',[0 1],'Visible','off');
    left = axes('Parent',fig,'Units','inches','Position',[0.22 0.38 0.06 side], ...
        'XLim',[0 1],'YLim',[0.5 N + 0.5],'YDir','reverse','Visible','off');
    hold(top,'on'); hold(left,'on');
    for k = 1:numel(counts)
        color = cfg.colors.(names{k});
        span = [edges(k) edges(k + 1)] + 0.5;
        patch(top,span([1 2 2 1]),[0 0 1 1],color,'EdgeColor','none');
        patch(left,[0 0 1 1],span([1 2 2 1]),color,'EdgeColor','none');
        text(top,mean(span),1.3,names{k},'Color',color,'HorizontalAlignment','center', ...
            'VerticalAlignment','bottom','Clipping','off',style{:});
        text(left,-0.6,mean(span),names{k},'Color',color,'Rotation',90, ...
            'HorizontalAlignment','center','VerticalAlignment','bottom','Clipping','off',style{:});
        text(ax,N + 0.5 + 0.015*N,edges(k) + 1,'1','HorizontalAlignment','left', ...
            'VerticalAlignment','top','Clipping','off',style{:});
        text(ax,N + 0.5 + 0.015*N,edges(k + 1),sprintf('%d',counts(k)),'HorizontalAlignment','left', ...
            'VerticalAlignment','bottom','Clipping','off',style{:});
    end
    text(ax,N*1.2,N/2,'Neurons','Rotation',-90,'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom','Clipping','off',style{:});
    scale = axes('Parent',fig,'Units','inches','Position',[0.32 + side + 0.36, 0.38, 0.55, 0.09]);
    imagesc(scale,linspace(0,1,256));
    colormap(scale,jet(256));
    set(scale,'XTick',[],'YTick',[],'Box','on','XColor','k','YColor','k','LineWidth',0.4);
    limits = cfg.figures.correlogramLimits;
    text(scale,0.5,1.75,sprintf('%g',limits(1)),'Rotation',-45,'HorizontalAlignment','left', ...
        'VerticalAlignment','middle','Clipping','off',style{:});
    text(scale,256.5,1.75,sprintf('%g',limits(2)),'Rotation',-45,'HorizontalAlignment','left', ...
        'VerticalAlignment','middle','Clipping','off',style{:});
    text(scale,128,1.65,'R^2','HorizontalAlignment','center','VerticalAlignment','top', ...
        'Clipping','off',style{:});
    files = mgi_save_figure(fig,folder,sprintf('correlation_matrix_%s',mouse),cfg);
end
