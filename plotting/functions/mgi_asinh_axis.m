function mgi_asinh_axis(ax,cfg,rotation)
%MGI_ASINH_AXIS R^2 axis on the asinh(R^2/scale) display scale.
    if nargin < 3, rotation = 0; end
    ticks = [0 0.002 0.01 0.05 0.2 0.5 1];
    scale = cfg.grid.asinhScale;
    set(ax,'XLim',[0 asinh(1/scale)],'XTick',asinh(ticks/scale), ...
        'XTickLabel',{'0','0.002','0.01','0.05','0.2','0.5','1'});
    if rotation ~= 0
        set(ax,'XTickLabelRotation',rotation);
    end
end
