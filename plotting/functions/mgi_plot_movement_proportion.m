function files = mgi_plot_movement_proportion(baseline,cfg,folder)
%MGI_PLOT_MOVEMENT_PROPORTION Proportion of recorded neurons significantly correlated with orofacial movement.
    fig = mgi_new_figure(cfg,1.35,1.95);
    ax = mgi_new_axes(fig,[0.55 0.45 0.72 1.35],cfg);
    regions = cfg.regions;
    colors = cell2mat(cellfun(@(r) 0.8*cfg.colors.(r) + 0.2,regions(:),'UniformOutput',false));
    fraction = baseline.movement.significantFraction;
    mgi_draw_bars(ax,1:numel(regions),fraction,colors,0.78);
    top = max(0.1,ceil((max(fraction) + 0.05)*10)/10);
    set(ax,'XLim',[0.4 numel(regions) + 0.6],'YLim',[0 top],'XTick',1:numel(regions), ...
        'XTickLabel',regions,'XTickLabelRotation',45);
    mgi_set_ticks(ax,'Y',0:0.1:top,'%.1f');
    ylabel(ax,{'proportion of neurons','correlated with orof. mov.'});
    files = mgi_save_figure(fig,folder,'movement_significant_proportion',cfg);
end
