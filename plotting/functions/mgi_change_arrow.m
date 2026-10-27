function mgi_change_arrow(fig,position,description,cfg)
%MGI_CHANGE_ARROW Vertical green-to-red double arrow with higher/lower labels.
%   mgi_change_arrow(fig,[left bottom width height] (inches),description,cfg)
    ax = axes('Parent',fig,'Units','inches','Position',position,'XLim',[0 1], ...
        'YLim',[0 1],'Visible','off');
    hold(ax,'on');
    top = cfg.colors.arrowTop; bottom = cfg.colors.arrowBottom;
    shaft = [0.08 0.92];
    w = 0.09; head = 0.07;
    patch(ax,[0.5-w 0.5+w 0.5+w 0.5-w],[shaft(1) shaft(1) shaft(2) shaft(2)],[0 0 0], ...
        'FaceVertexCData',[bottom; bottom; top; top],'FaceColor','interp','EdgeColor','none');
    patch(ax,[0.5-2.2*w 0.5+2.2*w 0.5],[shaft(2) shaft(2) shaft(2)+head],top,'EdgeColor','none');
    patch(ax,[0.5-2.2*w 0.5+2.2*w 0.5],[shaft(1) shaft(1) shaft(1)-head],bottom,'EdgeColor','none');
    style = {'FontName',cfg.figures.font,'FontSize',cfg.figures.fontSize};
    text(ax,0.75,shaft(2) + 0.02,'higher','Color',cfg.colors.higher,'Rotation',-45, ...
        'HorizontalAlignment','left','VerticalAlignment','middle',style{:});
    text(ax,0.75,shaft(1) - 0.02,'lower','Color',cfg.colors.lower,'Rotation',-45, ...
        'HorizontalAlignment','left','VerticalAlignment','middle',style{:});
    text(ax,1.5,0.47,description,'Rotation',-90,'HorizontalAlignment','center', ...
        'VerticalAlignment','middle',style{:});
end
