function mgi_legend_brackets(overlay,labels,pLabels,cfg)
%MGI_LEGEND_BRACKETS Significance brackets joining three legend rows.
%   mgi_legend_brackets(overlay,labels,{p12,p23,p13},cfg) draws an inner
%   bracket between rows 1-2 and rows 2-3 and an outer bracket between rows
%   1-3, each labeled with its significance text.
    position = get(overlay,'Position');
    right = zeros(1,3); y = zeros(1,3);
    for k = 1:3
        at = get(labels{k},'Position');
        right(k) = at(1) + mgi_text_width(get(labels{k},'String'),get(labels{k},'FontSize'))/position(3);
        y(k) = at(2);
    end
    gap = 0.03;
    inner = max(right) + gap;
    starWidth = mgi_text_width('***',cfg.figures.fontSize + 1)/position(3);
    outer = inner + starWidth + 2*gap;
    style = {'Color','k','LineWidth',0.5,'Clipping','off'};
    textStyle = {'FontName',cfg.figures.font,'FontSize',cfg.figures.fontSize + 1, ...
        'VerticalAlignment','middle','HorizontalAlignment','left','Clipping','off'};
    for k = 1:3
        line(overlay,[right(k) + gap/2, inner],[y(k) y(k)],style{:});
    end
    line(overlay,[inner inner],[y(1) y(3)],style{:});
    text(overlay,inner + gap/2,mean(y(1:2)),pLabels{1},textStyle{:});
    text(overlay,inner + gap/2,mean(y(2:3)),pLabels{2},textStyle{:});
    line(overlay,[inner outer outer inner],[y(1) y(1) y(3) y(3)],style{:});
    text(overlay,outer + gap/2,y(2),pLabels{3},textStyle{:});
end
