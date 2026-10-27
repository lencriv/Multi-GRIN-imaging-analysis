function matrix = mgi_correlation_matrix(Z,cfg)
%MGI_CORRELATION_MATRIX Neuron x neuron R^2 matrix of one session, clustered within region.
%   matrix = mgi_correlation_matrix(Z,cfg)
%   Within each region, neurons are grouped by hierarchical clustering of
%   their z-scored traces (Euclidean distance, cfg.correlation.linkage,
%   cfg.correlation.clusters clusters) and ordered by cluster. R^2 is the
%   squared Pearson correlation over every frame finite in all regions.
%   matrix.R2       single, all neurons in region order
%   matrix.order{r} original neuron indices of region r in display order
%   matrix.counts   neurons per region
    o = cfg.correlation;
    finite = true(1,size(Z{1},2));
    for r = 1:numel(Z)
        finite = finite & all(isfinite(Z{r}),1);
    end
    order = cell(1,numel(Z));
    blocks = cell(numel(Z),1);
    for r = 1:numel(Z)
        X = Z{r}(:,finite);
        if size(X,1) > o.clusters
            tree = linkage(distances(X),o.linkage);
            labels = cluster(tree,'maxclust',o.clusters);
            [~,order{r}] = sort(labels);
            order{r} = order{r}(:)';
        else
            order{r} = 1:size(X,1);
        end
        blocks{r} = X(order{r},:);
    end
    X = cat(1,blocks{:})';
    X = X - mean(X,1);
    d = sqrt(sum(X.^2,1));
    d(d == 0) = 1;
    X = X./d;
    matrix = struct('R2',single(min(1,(X'*X).^2)),'order',{order}, ...
        'counts',cellfun(@numel,order),'nFrames',nnz(finite));
end

function d = distances(X)
    if exist('OCTAVE_VERSION','builtin') == 0 && exist('pdist','file') == 2
        d = pdist(X,'euclidean');
        return;
    end
    G = X*X';
    squared = diag(G);
    D = sqrt(max(squared + squared' - 2*G,0));
    d = D(tril(true(size(D)),-1))';
end
