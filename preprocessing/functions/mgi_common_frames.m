function inputs = mgi_common_frames(Z,behavior,minFrames)
%MGI_COMMON_FRAMES Standardized activity and movement on shared valid frames.
%   inputs = mgi_common_frames(Z,behavior,minFrames)
%   Frames are kept when orofacial speed is valid and every region's
%   activity is finite. Neurons constant over those frames are dropped.
%   inputs.Y{r}       frames x neurons, each column standardized
%   inputs.movement   frames x 1 standardized orofacial speed
%   inputs.neurons{r} indices of the retained neurons
%   inputs.valid      logical mask over the session's imaging frames
    speed = double(behavior.speed(:));
    valid = isfinite(speed) & logical(behavior.valid(:));
    for r = 1:numel(Z)
        if size(Z{r},2) ~= numel(speed)
            error('MGI:timebase','Activity and behavior lengths differ.');
        end
        valid = valid & all(isfinite(Z{r}),1)';
    end
    if nnz(valid) < minFrames
        error('MGI:validFrames','Only %d common valid frames.',nnz(valid));
    end
    inputs = struct('Y',{cell(1,numel(Z))},'movement',standardize(speed(valid)), ...
        'neurons',{cell(1,numel(Z))},'valid',valid','nFrames',nnz(valid));
    for r = 1:numel(Z)
        X = Z{r}(:,valid);
        keep = std(X,0,2) > 0;
        inputs.neurons{r} = find(keep);
        inputs.Y{r} = standardize(X(keep,:)');
    end
end

function X = standardize(X)
    X = X - mean(X,1);
    scale = std(X,1,1);
    scale(scale == 0) = 1;
    X = X./scale;
end
