function mgi_scatter_points(ax,x,y,color,sizePoints,alpha)
%MGI_SCATTER_POINTS Filled, edge-free, semi-transparent scatter points.
    try
        scatter(ax,x,y,sizePoints,color,'filled','MarkerFaceAlpha',alpha, ...
            'MarkerEdgeColor','none');
    catch
        blended = alpha*color + (1 - alpha);
        plot(ax,x,y,'o','MarkerSize',sqrt(sizePoints),'MarkerFaceColor',blended, ...
            'MarkerEdgeColor','none','LineStyle','none');
    end
end
