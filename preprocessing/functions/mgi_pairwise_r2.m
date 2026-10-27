function values = mgi_pairwise_r2(A,B)
%MGI_PAIRWISE_R2 Squared Pearson correlations between neuron pairs.
%   values = mgi_pairwise_r2(A)     every unique within-region pair of A
%   values = mgi_pairwise_r2(A,B)   every pair of one neuron of A and one of B
%   A and B are frames x neurons.
    Ua = unitColumns(A);
    if nargin < 2 || isempty(B)
        C = Ua'*Ua;
        values = C(triu(true(size(C)),1));
    else
        C = Ua'*unitColumns(B);
        values = C(:);
    end
    values = min(1,max(0,values.^2));
end

function U = unitColumns(Y)
    Y = Y - mean(Y,1);
    d = sqrt(sum(Y.^2,1));
    d(d == 0) = 1;
    U = Y./d;
end
