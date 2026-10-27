function behavior = mgi_orofacial_speed(session,nFrames,cfg)
%MGI_OROFACIAL_SPEED Composite orofacial speed on the imaging time base.
%   behavior = mgi_orofacial_speed(session,nFrames,cfg)
%   1. Speed of each orofacial keypoint (cfg.speed.keypoints) as the
%      frame-to-frame displacement of behavior.xy (pixels per camera frame),
%      averaged across tracked keypoints.
%   2. Mean over the camera frames spanned by each imaging frame
%      (behavior.neuralFrameLocs bin edges); frames with < minFracValid
%      tracked samples are invalid.
%   3. Linear interpolation of gaps <= maxGapSeconds, centered moving mean
%      over smoothSeconds, z-score over valid frames.
%   behavior.speed (1 x nFrames, NaN where invalid), .valid, .fsNeural,
%   .fracValid, .composite (camera-rate composite speed).
    o = cfg.speed;
    xy = double(session.behavior.xy);
    keypoints = o.keypoints(o.keypoints <= size(xy,3));
    steps = sqrt(sum(diff(xy(:,:,keypoints),1,1).^2,2));
    steps = reshape(steps,size(steps,1),numel(keypoints));
    tracked = isfinite(steps);
    steps(~tracked) = 0;
    composite = sum(steps,2)./sum(tracked,2);
    composite(sum(tracked,2) == 0) = NaN;

    fsBehavior = o.behaviorFrameRate;
    if isfield(session,'meta') && isfield(session.meta,'behaviorFrameRateHz')
        fsBehavior = double(session.meta.behaviorFrameRateHz);
    end
    edges = round(double(session.behavior.neuralFrameLocs(:)));
    edges = min(max(edges,1),numel(composite));
    if numel(edges) < nFrames + 1 || any(diff(edges(1:nFrames + 1)) <= 0)
        error('MGI:frameEdges','%d frame edges cannot bound %d imaging frames.', ...
            numel(edges),nFrames);
    end
    edges = edges(1:nFrames + 1);
    [binned,fraction] = binMean(composite,edges);
    fsNeural = nFrames/((edges(end) - edges(1))/fsBehavior);
    binned(fraction < o.minFracValid) = NaN;
    filled = mgi_fill_gaps(binned,max(1,round(o.maxGapSeconds*fsNeural)));
    valid = isfinite(filled);
    if ~any(valid)
        error('MGI:noBehavior','No valid behavior frames.');
    end
    smoothed = mgi_movmean(filled,max(1,round(o.smoothSeconds*fsNeural)));
    smoothed(~valid) = NaN;
    scale = std(smoothed(valid),1);
    if ~isfinite(scale) || scale == 0
        error('MGI:constantBehavior','Orofacial speed has no variance.');
    end
    speed = (smoothed - mean(smoothed(valid)))/scale;
    behavior = struct('speed',speed(:)','valid',valid(:)','fsNeural',fsNeural, ...
        'fracValid',mean(valid),'composite',composite(:)');
end

function [values,fraction] = binMean(x,edges)
    ok = isfinite(x);
    z = x; z(~ok) = 0;
    cs = [0; cumsum(z)];
    cn = [0; cumsum(double(ok))];
    first = edges(1:end-1);
    last = max(edges(2:end) - 1,first);
    sums = cs(last + 1) - cs(first);
    counts = cn(last + 1) - cn(first);
    values = sums./counts;
    values(counts == 0) = NaN;
    fraction = counts./(last - first + 1);
end
