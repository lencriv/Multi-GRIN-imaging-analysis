function files = mgi_plot_transient_rate(comparison,cfg,folder)
%MGI_PLOT_TRANSIENT_RATE Distributions of single-neuron Ca2+ transient rates in two conditions.
%   One figure per region: before (solid) and after (dashed) proportions
%   on 0..97.5th percentile of the pooled rates; stars give the
%   mixed-effects test with mouse as a random intercept.
    files = {};
    labelBefore = comparison.before.label;
    labelAfter = comparison.after.label;
    colorBefore = cfg.colors.(labelBefore);
    colorAfter = cfg.colors.(labelAfter);
    nameBefore = displayName(labelBefore);
    nameAfter = displayName(labelAfter);
    for r = 1:numel(comparison.transientRate)
        entry = comparison.transientRate(r);
        region = entry.region;
        if ~isfinite(entry.xmax) || entry.xmax <= 0, continue; end
        fig = mgi_new_figure(cfg,2.9,2.0);
        ax = mgi_new_axes(fig,[0.5 0.5 2.1 1.1],cfg);
        plot(ax,entry.centers,entry.proportionBefore,'-','Color',colorBefore,'LineWidth',1.5);
        plot(ax,entry.centers,entry.proportionAfter,'--','Color',colorAfter,'LineWidth',1.5);
        peak = max([entry.proportionBefore entry.proportionAfter]);
        [~,at] = max(max([entry.proportionBefore; entry.proportionAfter],[],1));
        set(ax,'XLim',[0 entry.xmax],'XTick',[0 entry.xmax], ...
            'XTickLabel',{'0',sprintf('%.1f',entry.xmax)},'YLim',[0 max(eps,peak*1.25)]);
        text(ax,entry.centers(at),peak*1.06,mgi_stars(entry.P),'HorizontalAlignment','center', ...
            'VerticalAlignment','bottom','FontSize',cfg.figures.fontSize);
        ylabel(ax,'Proportion');
        xlabel(ax,'Ca^{2+} transient rate (typical events s^{-1})');
        overlay = mgi_overlay_axes(ax);
        entries = struct('label',{mgi_tex_color(nameBefore,colorBefore), ...
            mgi_tex_color(nameAfter,colorAfter)},'color',{colorBefore,colorAfter}, ...
            'lineStyle',{'-','--'},'lineWidth',1.5,'fontSize',cfg.figures.fontSize + 2);
        if strcmp(labelBefore,'Baseline')
            mgi_line_legend(overlay,entries,[0.08 0.92 0.13 0.12],cfg);
        else
            mgi_line_legend(overlay,entries,[0.7 0.92 0.11 0.12],cfg);
        end
        regionText = mgi_tex_color(region,cfg.colors.(region));
        if strcmp(comparison.rateTitle,'activity')
            titleText = sprintf('%s neuron activity during %s and %s',regionText, ...
                mgi_tex_color(nameBefore,colorBefore),mgi_tex_color(nameAfter,colorAfter));
        else
            titleText = sprintf('%s neurons',regionText);
        end
        title(ax,titleText,'Interpreter','tex','FontWeight','normal','FontSize',cfg.figures.fontSize + 1.5);
        files = [files, mgi_save_figure(fig,folder,sprintf('%s_transient_rate_%s',comparison.name,region),cfg)];
    end
end

function name = displayName(label)
    name = label;
    if strcmp(label,'Baseline'), name = 'baseline'; end
end
