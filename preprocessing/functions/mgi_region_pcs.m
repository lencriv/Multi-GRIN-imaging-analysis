function [PCs,population] = mgi_region_pcs(Y,nPC)
%MGI_REGION_PCS Leading temporal principal components and mean activity per region.
%   [PCs,population] = mgi_region_pcs(Y,nPC)
%   PCs{r} frames x nPC scores of region r; population{r} frames x 1 mean
%   of the region's standardized neurons.
    PCs = cell(1,numel(Y));
    population = cell(1,numel(Y));
    for r = 1:numel(Y)
        k = min([nPC,size(Y{r},2),size(Y{r},1) - 1]);
        if k < 1
            PCs{r} = zeros(size(Y{r},1),0);
        else
            [V,D] = eig(Y{r}'*Y{r});
            [~,order] = sort(diag(D),'descend');
            PCs{r} = Y{r}*V(:,order(1:k));
        end
        population{r} = mean(Y{r},2);
    end
end
