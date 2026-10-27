function out = mgi_inter_partial_r(Y,PCs,population,seed,targets,mode)
%MGI_INTER_PARTIAL_R Signed partial r of seed neurons with target-region mean activity.
%   out = mgi_inter_partial_r(Y,PCs,population,seed,[a b],mode)
%   rA: each seed neuron versus region a's mean activity, both residualized
%   on the conditioning set of region b; rB symmetrically. mode 'pcs' uses
%   the leading PCs of the other target region, 'mean' its mean activity.
    a = targets(1); b = targets(2);
    Qa = mgi_conditioning_basis(b,PCs,population,mode);
    Qb = mgi_conditioning_basis(a,PCs,population,mode);
    xa = population{a} - Qa*(Qa'*population{a});
    xb = population{b} - Qb*(Qb'*population{b});
    if norm(xa) <= 1e-12 || norm(xb) <= 1e-12
        error('MGI:targetVariance','Target mean activity has no residual variance.');
    end
    out = struct('rA',partialR(Y{seed},Qa,xa),'rB',partialR(Y{seed},Qb,xb), ...
        'Qa',Qa,'Qb',Qb,'xa',xa,'xb',xb);
end

function r = partialR(Y,Q,target)
    residual = Y - Q*(Q'*Y);
    denominator = sqrt(sum(residual.^2,1))*norm(target);
    r = max(-1,min(1,(target'*Y)./max(denominator,1e-12)))';
end
