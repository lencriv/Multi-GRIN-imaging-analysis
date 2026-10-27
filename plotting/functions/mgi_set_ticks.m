function mgi_set_ticks(ax,axisName,ticks,format)
%MGI_SET_TICKS Tick positions with formatted labels.
    labels = arrayfun(@(t) sprintf(format,t),ticks,'UniformOutput',false);
    labels(abs(ticks) < 1e-12) = {sprintf(format,0)};
    set(ax,[axisName 'Tick'],ticks,[axisName 'TickLabel'],labels);
end
