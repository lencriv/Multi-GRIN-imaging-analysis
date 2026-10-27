function files = mgi_plot_vl_tp_activity(entry,cfg,folder)
%MGI_PLOT_VL_TP_ACTIVITY Activity of one region aligned to VL and TP onset.
%   Top: mean z-scored activity +/- s.e.m. across neurons for VL and TP
%   (display-smoothed), with the pre and post epochs shaded. Middle and
%   bottom: event-averaged activity of every neuron for VL and TP, sorted
%   by time to peak within each condition.
    labels = entry.labels;
    t = entry.timeSeconds;
    epoch = cfg.events.epochSeconds;
    fs = cfg.figures.fontSize;
    regionColor = cfg.colors.(entry.region);
    labelColors = {cfg.colors.(labels{1}), cfg.colors.(labels{2})};
    traceColors = {cfg.colors.([labels{1} 'Trace']), cfg.colors.([labels{2} 'Trace'])};
    left = 0.55; width = 2.1; height = 0.62;
    fig = mgi_new_figure(cfg,2.9,4.05);
    set(fig,'Colormap',mgi_heatmap_colormap(256));

    header = sprintf('%s neuron activity during %s and %s',mgi_tex_color(entry.region,regionColor), ...
        mgi_tex_color(labels{2},labelColors{2}),mgi_tex_color(labels{1},labelColors{1}));
    boxWidth = mgi_text_width(header,fs + 2) + 0.2;
    center = left + width/2;
    headerAxes = axes('Parent',fig,'Units','inches','Position',[center - boxWidth/2 3.73 boxWidth 0.22], ...
        'XLim',[0 1],'YLim',[0 1],'Visible','off');
    patch(headerAxes,[0 1 1 0],[0 0 1 1],cfg.colors.headerBackground,'EdgeColor','none');
    text(headerAxes,0.5,0.5,header,'Interpreter','tex','HorizontalAlignment','center', ...
        'VerticalAlignment','middle','FontName',cfg.figures.font,'FontSize',fs + 2);

    ax = mgi_new_axes(fig,[left 2.98 width height],cfg);
    bands = cell(1,2);
    for c = 1:2
        d = entry.(labels{c});
        bands{c} = [d.meanTraceSmoothed - d.semTraceSmoothed; d.meanTraceSmoothed + d.semTraceSmoothed];
    end
    values = [bands{:}];
    values = values(isfinite(values));
    if isempty(values), values = [-1 1]; end
    low = min([values(:); 0]); high = max([values(:); 0]);
    span = max(high - low,eps);
    yl = [low - 0.06*span, high + 0.3*span];
    step = mgi_nice_step(high - low,5);
    shadeTop = high + 0.26*span;
    patch(ax,[-epoch 0 0 -epoch],[yl(1) yl(1) shadeTop shadeTop],cfg.colors.epochShading,'EdgeColor','none');
    patch(ax,[0 epoch epoch 0],[yl(1) yl(1) shadeTop shadeTop],cfg.colors.epochShading,'EdgeColor','none');
    for c = 1:2
        ok = isfinite(bands{c}(1,:)) & isfinite(bands{c}(2,:));
        x = t(ok);
        if isempty(x), continue; end
        band = 0.2*traceColors{c} + 0.8;
        patch(ax,[x fliplr(x)],[bands{c}(2,ok) fliplr(bands{c}(1,ok))],band,'EdgeColor','none');
    end
    plot(ax,[t(1) t(end)],[0 0],'-','Color','k','LineWidth',0.5);
    for c = 1:2
        d = entry.(labels{c});
        plot(ax,t,d.meanTraceSmoothed,'-','Color',traceColors{c},'LineWidth',1);
    end
    labelY = high + 0.18*span;
    plot(ax,[0 0],[yl(1) shadeTop],'--','Color','k','LineWidth',0.75);
    text(ax,-0.3,labelY,'pre','HorizontalAlignment','right','VerticalAlignment','middle','FontSize',fs);
    text(ax,0.3,labelY,'post','HorizontalAlignment','left','VerticalAlignment','middle','FontSize',fs);
    text(ax,0.03,0.98,labels{1},'Units','normalized','Color',labelColors{1}, ...
        'VerticalAlignment','top','HorizontalAlignment','left','FontSize',fs + 1.5);
    text(ax,0.03,0.68,labels{2},'Units','normalized','Color',labelColors{2}, ...
        'VerticalAlignment','top','HorizontalAlignment','left','FontSize',fs + 1.5);
    set(ax,'XLim',[t(1) t(end)],'YLim',yl,'XTick',timeTicks(t));
    mgi_set_ticks(ax,'Y',step*(ceil(low/step):floor(high/step)),'%g');
    ylabel(ax,'Z-score');
    mgi_hide_axis_lines(ax,'x');

    bottoms = [1.92 0.86];
    for c = 1:2
        d = entry.(labels{c});
        heat = mgi_new_axes(fig,[left bottoms(c) width height],cfg);
        set(heat,'TickDir','in','Box','on','LineWidth',0.75,'YDir','reverse');
        n = max(1,d.nNeurons);
        if d.nNeurons > 0
            imagesc(heat,t,1:d.nNeurons,d.trace(d.order,:));
        end
        set(heat,'CLim',cfg.figures.eventHeatmapLimits,'XLim',[t(1) t(end)],'YLim',[0.5 n + 0.5], ...
            'XTick',timeTicks(t));
        plot(heat,[0 0],[0.5 n + 0.5],'--','Color','k','LineWidth',0.75);
        perInch = n/height;
        plot(heat,0,0.5 - 0.035*perInch,'v','MarkerSize',3.5,'MarkerFaceColor','k', ...
            'MarkerEdgeColor','k','Clipping','off');
        text(heat,0,0.5 - 0.075*perInch,labels{c},'Color',labelColors{c},'FontSize',fs + 2, ...
            'HorizontalAlignment','center','VerticalAlignment','bottom','Clipping','off');
        rowStep = max(1,mgi_nice_step(n,9));
        ticks = unique([1, rowStep:rowStep:n, n]);
        tickLabels = repmat({''},1,numel(ticks));
        tickLabels{1} = '1';
        tickLabels{end} = sprintf('%d',n);
        set(heat,'YTick',ticks,'YTickLabel',tickLabels);
        ylabel(heat,'Neurons');
        if c == 2, xlabel(heat,'Time (s)'); end
    end

    limits = cfg.figures.eventHeatmapLimits;
    scale = axes('Parent',fig,'Units','inches','Position',[left + width - 1.0 0.3 1.0 0.09], ...
        'XLim',[0.5 256.5],'YLim',[0.5 1.5],'XTick',[],'YTick',[],'Box','on','LineWidth',0.5, ...
        'Layer','top','CLim',[1 256]);
    hold(scale,'on');
    image(scale,1:256,1,reshape(mgi_heatmap_colormap(256),1,256,3));
    set(scale,'XLim',[0.5 256.5],'YLim',[0.5 1.5]);
    text(scale,0.5,0.4,sprintf('%g',limits(1)),'HorizontalAlignment','left','VerticalAlignment','top','FontSize',fs);
    text(scale,256.5,0.4,sprintf('%g',limits(2)),'HorizontalAlignment','right','VerticalAlignment','top','FontSize',fs);
    text(scale,128.5,0.4,'Z-score','HorizontalAlignment','center','VerticalAlignment','top','FontSize',fs);

    files = mgi_save_figure(fig,folder,sprintf('vl_tp_activity_%s',entry.region),cfg);
end

function ticks = timeTicks(t)
    edge = floor(max(abs([t(1) t(end)]))/5)*5;
    ticks = -edge:5:edge;
end
