function entry = mgi_event_summary(region,pooled,labels,timeSeconds,frameRate,cfg)
%MGI_EVENT_SUMMARY Population traces, peak order and epoch-AUC statistics of one region.
%   entry = mgi_event_summary(region,{vl,tp},{'VL','TP'},timeSeconds,frameRate,cfg)
%   pooled{c} holds the neurons of condition c pooled across mice
%   (mgi_event_activity outputs with mouse, globalMouseIndex,
%   conditionIndex and neuron). Neurons without any event window are left
%   out.
%   entry.(label)  per condition:
%     peakColumn, order     time of each neuron's peak; neurons sorted by it
%     meanTrace, semTrace   mean and s.e.m. (s.d./sqrt(neurons)) across neurons
%     meanTraceSmoothed, semTraceSmoothed
%                           centered moving mean over cfg.events.meanSmoothSeconds
%     nNeurons, nMice, mice
%   entry.mean, .sem, .n    conditions x epochs (control, pre, post) of the
%                           neuron AUC values; s.e.m. = s.d./sqrt(n neurons)
%   entry.P, .P_BH, .z      two-sided Wilcoxon rank-sum, labels{2} vs
%                           labels{1} at each epoch, Benjamini-Hochberg
%                           across the three epochs (z > 0: labels{2} higher)
    smoothFrames = 2*round(cfg.events.meanSmoothSeconds*frameRate/2) + 1;
    epochs = {'control','pre','post'};
    entry = struct('region',region,'timeSeconds',timeSeconds,'labels',{labels},'epochs',{epochs});
    values = cell(2,3);
    for c = 1:2
        d = pooled{c};
        keep = any(isfinite(d.trace),2);
        d = selectRows(d,keep);
        n = size(d.trace,1);
        peak = zeros(n,1);
        for i = 1:n
            row = d.trace(i,:);
            row(~isfinite(row)) = -Inf;
            [~,peak(i)] = max(row);
        end
        [~,order] = sortrows([peak (1:n)']);
        [meanTrace,semTrace] = columnMeanSem(d.trace);
        meanSmoothed = mgi_movmean(meanTrace,smoothFrames)';
        semSmoothed = mgi_movmean(semTrace,smoothFrames)';
        meanSmoothed(~isfinite(meanTrace)) = NaN;
        semSmoothed(~isfinite(semTrace)) = NaN;
        d.peakColumn = peak;
        d.order = order;
        d.meanTrace = meanTrace;
        d.semTrace = semTrace;
        d.meanTraceSmoothed = meanSmoothed;
        d.semTraceSmoothed = semSmoothed;
        d.mice = unique(d.mouse(:)');
        d.nNeurons = n;
        d.nMice = numel(d.mice);
        entry.(labels{c}) = d;
        values(c,:) = {d.control, d.preAUC, d.postAUC};
    end
    entry.mean = NaN(2,3); entry.sem = NaN(2,3); entry.n = zeros(2,3);
    for c = 1:2
        for x = 1:3
            v = values{c,x}(isfinite(values{c,x}));
            entry.n(c,x) = numel(v);
            if isempty(v), continue; end
            entry.mean(c,x) = mean(v);
            if numel(v) > 1, entry.sem(c,x) = std(v)/sqrt(numel(v)); end
        end
    end
    entry.P = NaN(1,3); entry.z = NaN(1,3);
    for x = 1:3
        [entry.P(x),entry.z(x)] = mgi_ranksum(values{2,x},values{1,x});
    end
    entry.P_BH = mgi_padjust(entry.P,'bh');
    entry.test = sprintf('two-sided Wilcoxon rank-sum on neurons, %s vs %s, Benjamini-Hochberg across epochs', ...
        labels{2},labels{1});
end

function d = selectRows(d,keep)
    names = fieldnames(d);
    for k = 1:numel(names)
        value = d.(names{k});
        if size(value,1) == numel(keep)
            d.(names{k}) = value(keep,:);
        end
    end
end

function [m,s] = columnMeanSem(X)
    finite = isfinite(X);
    counts = sum(finite,1);
    values = X; values(~finite) = 0;
    m = sum(values,1)./counts;
    deviation = (X - m).^2;
    deviation(~finite) = 0;
    s = sqrt(sum(deviation,1)./(counts - 1))./sqrt(counts);
    m(counts == 0) = NaN;
    s(counts < 2) = NaN;
end
