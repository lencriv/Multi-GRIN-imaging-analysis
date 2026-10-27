function labels = mgi_line_legend(overlay,entries,anchor,cfg)
%MGI_LINE_LEGEND Line samples with colored TeX labels in an overlay axes.
%   labels = mgi_line_legend(overlay,entries,[x y dy length],cfg)
%   entries: struct array with fields label, color, lineStyle, lineWidth,
%   fontSize. The first row is at (x,y) and rows are dy apart (unit
%   coordinates of the overlay). Returns the label text handles.
    labels = cell(1,numel(entries));
    for k = 1:numel(entries)
        y = anchor(2) - (k - 1)*anchor(3);
        line(overlay,anchor(1) + [0 anchor(4)],[y y],'Color',entries(k).color, ...
            'LineStyle',entries(k).lineStyle,'LineWidth',entries(k).lineWidth,'Clipping','off');
        labels{k} = text(overlay,anchor(1) + anchor(4) + 0.015,y,entries(k).label, ...
            'Interpreter','tex','VerticalAlignment','middle','HorizontalAlignment','left', ...
            'FontName',cfg.figures.font,'FontSize',entries(k).fontSize,'Clipping','off');
    end
end
