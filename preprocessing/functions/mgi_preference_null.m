function out = mgi_preference_null(Y,inter,lags,batchSize,chunkSize)
%MGI_PREFERENCE_NULL Circular-shift null of a seed neuron's target preference.
%   out = mgi_preference_null(Y,inter,lags,batchSize,chunkSize)
%   Y is frames x seed neurons; inter is the output of mgi_inter_partial_r.
%   Each neuron is circularly shifted by every lag; the partial r with
%   both targets is recomputed for each shift. The preference statistic is
%   rB - rA; P is two-sided around the neuron's null mean.
%   out.P, out.nullMeanA, out.nullMeanB, out.nullMeanDelta (neurons x 1)
    [T,n] = size(Y);
    Q = numel(lags);
    index = mod(-lags(:),T) + 1;
    fa = conj(fft([inter.xa,inter.Qa],[],1));
    fb = conj(fft([inter.xb,inter.Qb],[],1));
    na = norm(inter.xa); nb = norm(inter.xb);
    out = struct('P',zeros(n,1),'nullMeanA',zeros(n,1),'nullMeanB',zeros(n,1), ...
        'nullMeanDelta',zeros(n,1));
    for first = 1:batchSize:n
        cols = first:min(n,first + batchSize - 1);
        fy = fft(Y(:,cols),[],1);
        energy = sum(Y(:,cols).^2,1);
        ra = allLags(fy,fa,energy,na);
        rb = allLags(fy,fb,energy,nb);
        sumA = zeros(numel(cols),1); sumB = sumA;
        for start = 1:chunkSize:Q
            q = index(start:min(Q,start + chunkSize - 1));
            sumA = sumA + sum(ra(q,:),1)';
            sumB = sumB + sum(rb(q,:),1)';
        end
        meanA = sumA/Q; meanB = sumB/Q;
        meanDelta = meanB - meanA;
        observed = (inter.rB(cols) - inter.rA(cols)) - meanDelta;
        exceed = zeros(numel(cols),1);
        for start = 1:chunkSize:Q
            q = index(start:min(Q,start + chunkSize - 1));
            delta = (rb(q,:) - ra(q,:))';
            exceed = exceed + sum(abs(delta - meanDelta) >= abs(observed),2);
        end
        out.P(cols) = (1 + exceed)/(Q + 1);
        out.nullMeanA(cols) = meanA;
        out.nullMeanB(cols) = meanB;
        out.nullMeanDelta(cols) = meanDelta;
    end
end

function r = allLags(fy,fCovariates,energy,targetNorm)
    cross = real(ifft(fCovariates(:,1).*fy,[],1));
    projection = zeros(size(cross));
    for j = 2:size(fCovariates,2)
        projection = projection + real(ifft(fCovariates(:,j).*fy,[],1)).^2;
    end
    r = max(-1,min(1,cross./(sqrt(max(energy - projection,1e-12))*targetNorm)));
end
