function mgi_hide_axis_lines(ax,which)
%MGI_HIDE_AXIS_LINES Replace axis lines by free-standing ticks and tick labels.
%   mgi_hide_axis_lines(ax)        both axes
%   mgi_hide_axis_lines(ax,'x')    x axis only ('y' for the y axis only)
%   Call after limits, ticks and axis labels are set.
    if nargin < 2, which = 'xy'; end
    doX = any(lower(which) == 'x');
    doY = any(lower(which) == 'y');
    xt = get(ax,'XTick'); yt = get(ax,'YTick');
    xl = get(ax,'XLim'); yl = get(ax,'YLim');
    xLabels = cellstr(get(ax,'XTickLabel'));
    yLabels = cellstr(get(ax,'YTickLabel'));
    units = get(ax,'Units');
    set(ax,'Units','inches');
    position = get(ax,'Position');
    set(ax,'Units',units);
    perInchX = diff(xl)/position(3);
    perInchY = diff(yl)/position(4);
    fontName = get(ax,'FontName'); fontSize = get(ax,'FontSize');
    style = {'Color','k','LineWidth',0.5,'Clipping','off'};
    textStyle = {'FontName',fontName,'FontSize',fontSize,'Clipping','off'};
    if doX
        for k = 1:numel(xt)
            line(ax,[xt(k) xt(k)],yl(1) - [0.03 0]*perInchY,style{:});
            text(ax,xt(k),yl(1) - 0.05*perInchY,xLabels{k},'HorizontalAlignment','center', ...
                'VerticalAlignment','top',textStyle{:});
        end
        set(ax,'XColor','none');
        set(get(ax,'XLabel'),'Color','k','Units','data', ...
            'Position',[mean(xl), yl(1) - (0.07 + 1.4*fontSize/72)*perInchY, 0], ...
            'VerticalAlignment','top','HorizontalAlignment','center');
    end
    if doY
        for k = 1:numel(yt)
            line(ax,xl(1) - [0.03 0]*perInchX,[yt(k) yt(k)],style{:});
            text(ax,xl(1) - 0.05*perInchX,yt(k),yLabels{k},'HorizontalAlignment','right', ...
                'VerticalAlignment','middle',textStyle{:});
        end
        widest = max(cellfun(@(s) mgi_text_width(s,fontSize),yLabels));
        set(ax,'YColor','none');
        set(get(ax,'YLabel'),'Color','k','Units','data', ...
            'Position',[xl(1) - (0.1 + widest)*perInchX, mean(yl), 0], ...
            'VerticalAlignment','bottom','HorizontalAlignment','center');
    end
end
