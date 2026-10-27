function Q = mgi_conditioning_basis(regions,PCs,population,mode)
%MGI_CONDITIONING_BASIS Orthonormal nuisance basis for partial correlations.
%   Q = mgi_conditioning_basis([2 3],PCs,population,'pcs')  intercept + top PCs
%   Q = mgi_conditioning_basis(3,PCs,population,'mean')     intercept + mean activity
    T = size(population{1},1);
    switch lower(mode)
        case 'pcs'
            covariates = PCs(regions);
        case 'mean'
            covariates = population(regions);
        otherwise
            error('MGI:conditioning','Unknown conditioning %s.',mode);
    end
    Q = mgi_orth_basis([ones(T,1), covariates{:}]);
end
