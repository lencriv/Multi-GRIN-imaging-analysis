function map = mgi_heatmap_colormap(n)
%MGI_HEATMAP_COLORMAP parula with n colors (viridis where parula is not available).
    if exist('parula','file') ~= 0
        map = parula(n);
    else
        map = viridis(n);
    end
end
