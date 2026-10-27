function overlay = mgi_overlay_axes(ax)
%MGI_OVERLAY_AXES Invisible axes over ax with unit coordinates, for annotations.
    overlay = axes('Parent',get(ax,'Parent'),'Units',get(ax,'Units'), ...
        'Position',get(ax,'Position'),'XLim',[0 1],'YLim',[0 1],'Visible','off', ...
        'HitTest','off');
    hold(overlay,'on');
end
