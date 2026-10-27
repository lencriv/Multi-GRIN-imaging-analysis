function counts = mgi_cdf_on_grid(values,grid)
%MGI_CDF_ON_GRID Number of values <= each grid point.
    values = sort(double(values(:)));
    values = values(isfinite(values));
    counts = zeros(1,numel(grid));
    if isempty(values), return; end
    thresholds = grid(:)' + eps(1);
    [~,position] = sort([values; thresholds(:)]);
    isGrid = position > numel(values);
    running = cumsum(~isGrid);
    counts(position(isGrid) - numel(values)) = running(isGrid);
end
