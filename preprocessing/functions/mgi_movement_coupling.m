function out = mgi_movement_coupling(Y,movement,lags,batchSize)
%MGI_MOVEMENT_COUPLING Neuron R^2 with orofacial speed and its circular-shift null.
%   out = mgi_movement_coupling(Y,movement,lags,batchSize)
%   Y is frames x neurons (standardized); movement is frames x 1. The null
%   circularly shifts each neuron against movement by every lag in lags;
%   P = (1 + #{null R^2 >= observed})/(numel(lags) + 1).
%   out.R2, out.P, out.nullMeanR2 (neurons x 1)
    [T,n] = size(Y);
    x = movement - mean(movement);
    x = x/norm(x);
    norms = sqrt(sum(Y.^2,1));
    observed = min(1,max(0,((x'*Y)./norms).^2))';
    index = mod(-lags(:),T) + 1;
    fx = conj(fft(x));
    P = zeros(n,1);
    nullMean = zeros(n,1);
    for first = 1:batchSize:n
        cols = first:min(n,first + batchSize - 1);
        cross = real(ifft(fx.*fft(Y(:,cols),[],1),[],1))./norms(cols);
        values = min(1,max(0,cross(index,:)'.^2));
        nullMean(cols) = mean(values,2);
        P(cols) = (1 + sum(values >= observed(cols),2))/(numel(lags) + 1);
    end
    out = struct('R2',observed,'P',P,'nullMeanR2',nullMean);
end
