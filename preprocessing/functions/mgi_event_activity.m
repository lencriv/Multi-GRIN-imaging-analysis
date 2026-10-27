function out = mgi_event_activity(Z,onsets,frameRate,cfg)
%MGI_EVENT_ACTIVITY Event-aligned activity, epoch AUC and shift control of the neurons of one region.
%   out = mgi_event_activity(Z,onsets,frameRate,cfg)
%   Z          neurons x frames z-scored activity
%   onsets     imaging-frame onsets of the events (mgi_event_onsets)
%   frameRate  imaging frame rate (Hz)
%
%   out.trace        neurons x (2*half+1) activity averaged over events,
%                    -halfWindowSeconds..+halfWindowSeconds (cfg.events)
%   out.preAUC       pre-movement epoch (frames onset-E..onset-1, E = epochSeconds x frameRate)
%   out.postAUC      post-movement epoch (frames onset..onset+E-1)
%                    AUC = mean activity x epoch duration for each event
%                    (>= minValidFraction finite frames), averaged over
%                    events; NaN with fewer than minEvents valid events
%   out.validEvents  neurons x 2, events with a valid pre / post AUC
%   out.controlPre, out.controlPost
%                    pre / post AUC of one draw chosen at random among the
%                    finite draws of the neuron's event-shift null
%                    (mgi_event_shift_null: the whole onset train shifted
%                    circularly by >= minShiftSeconds, shuffles draws)
%   out.control      mean of controlPre and controlPost
%   Random numbers come from the global stream: the null lags, then one
%   draw per neuron.
    o = cfg.events;
    half = round(o.halfWindowSeconds*frameRate);
    epochFrames = round(o.epochSeconds*frameRate);
    epochSeconds = epochFrames/frameRate;
    minShift = max(1,round(o.minShiftSeconds*frameRate));
    n = size(Z,1);

    trace = mgi_event_average(Z,onsets,half);
    windows = mgi_event_windows(Z,onsets,epochFrames);
    pre = mgi_epoch_auc(windows(:,1:epochFrames,:),epochSeconds,o.minValidFraction);
    post = mgi_epoch_auc(windows(:,epochFrames + 1:2*epochFrames,:),epochSeconds,o.minValidFraction);
    validEvents = [sum(isfinite(pre),2), sum(isfinite(post),2)];
    preAUC = eventMean(pre);
    postAUC = eventMean(post);
    preAUC(validEvents(:,1) < o.minEvents) = NaN;
    postAUC(validEvents(:,2) < o.minEvents) = NaN;

    [nullPre,nullPost] = mgi_event_shift_null(Z,onsets,epochFrames,epochSeconds, ...
        o.shuffles,minShift,o.minEvents,o.minValidFraction);
    controlPre = NaN(n,1);
    controlPost = NaN(n,1);
    finite = isfinite(nullPre) & isfinite(nullPost);
    for i = 1:n
        eligible = find(finite(i,:));
        if isempty(eligible), continue; end
        d = eligible(randi(numel(eligible)));
        controlPre(i) = nullPre(i,d);
        controlPost(i) = nullPost(i,d);
    end
    out = struct('trace',trace,'preAUC',preAUC,'postAUC',postAUC,'validEvents',validEvents, ...
        'controlPre',controlPre,'controlPost',controlPost,'control',(controlPre + controlPost)/2);
end

function m = eventMean(auc)
    finite = isfinite(auc);
    values = auc;
    values(~finite) = 0;
    m = sum(values,2)./sum(finite,2);
    m(sum(finite,2) == 0) = NaN;
end
