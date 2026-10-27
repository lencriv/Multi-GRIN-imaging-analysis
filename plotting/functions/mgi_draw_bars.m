function mgi_draw_bars(ax,x,heights,colors,width)
%MGI_DRAW_BARS Filled bars (one color per bar) without edges.
    for k = 1:numel(x)
        patch(ax,x(k) + width/2*[-1 1 1 -1],[0 0 heights(k) heights(k)],colors(k,:), ...
            'EdgeColor','none');
    end
end
