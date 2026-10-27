function r = mgi_lme_ri(y,X,cluster,method)
%MGI_LME_RI Linear mixed-effects model with a random intercept per cluster.
%   r = mgi_lme_ri(y,X,cluster,'ML'|'REML')
%   y = X*beta + u(cluster) + e. X includes the intercept column. Fixed
%   effects are tested by two-sided t-tests on n - p degrees of freedom
%   (fitlme defaults). fitlme is used when available; otherwise the
%   likelihood is profiled over tau2/sigma2.
%   r.beta, r.se, r.t, r.df, r.P, r.sigma2, r.tau2, r.icc
    if nargin < 4, method = 'ML'; end
    method = upper(method);
    y = double(y(:)); X = double(X);
    keep = isfinite(y) & all(isfinite(X),2);
    y = y(keep); X = X(keep,:); cluster = cluster(keep);
    [~,~,g] = unique(cluster(:));
    n = numel(y); k = size(X,2);
    r = struct('beta',NaN(k,1),'se',NaN(k,1),'t',NaN(k,1),'df',NaN,'P',NaN(k,1), ...
        'sigma2',NaN,'tau2',NaN,'icc',NaN,'n',n,'nClusters',max([g;0]));
    if n <= k || max([g;0]) < 2 || rank(X) < k, return; end
    if exist('OCTAVE_VERSION','builtin') == 0 && exist('fitlme','file') == 2
        r = fitWithFitlme(y,X,g,method,r);
        if all(isfinite(r.P)), return; end
    end
    r = fitProfile(y,X,g,method,r);
end

function r = fitWithFitlme(y,X,g,method,r)
    try
        k = size(X,2);
        names = [{'y'}, arrayfun(@(j) sprintf('x%d',j),1:k-1,'UniformOutput',false)];
        tbl = array2table([y X(:,2:end)],'VariableNames',names);
        tbl.cluster = categorical(g);
        if k > 1
            formula = ['y ~ ' strjoin(names(2:end),' + ') ' + (1|cluster)'];
        else
            formula = 'y ~ 1 + (1|cluster)';
        end
        model = fitlme(tbl,formula,'FitMethod',method);
        c = model.Coefficients;
        r.beta = double(c.Estimate(:)); r.se = double(c.SE(:));
        r.t = double(c.tStat(:)); r.P = double(c.pValue(:)); r.df = double(c.DF(1));
        [psi,mse] = covarianceParameters(model);
        r.tau2 = psi{1}(1,1); r.sigma2 = mse;
        r.icc = min(max(r.tau2/(r.tau2 + r.sigma2),0),1);
    catch
        r.P(:) = NaN;
    end
end

function r = fitProfile(y,X,g,method,r)
    n = numel(y); k = size(X,2); G = max(g);
    ni = accumarray(g,1,[G 1]);
    Sx = zeros(G,k);
    for j = 1:k, Sx(:,j) = accumarray(g,X(:,j),[G 1]); end
    Sy = accumarray(g,y,[G 1]);
    XtX = X'*X; Xty = X'*y; yty = y'*y;
    objective = @(phi) -logLik(exp(phi),ni,Sx,Sy,XtX,Xty,yty,n,k,method);
    grid = -25:1:15;
    values = arrayfun(@(phi) -objective(phi),grid);
    [~,best] = max(values);
    options = optimset('TolX',1e-12,'Display','off');
    [phi,f] = fminbnd(objective,grid(max(best - 1,1)),grid(min(best + 1,numel(grid))),options);
    if logLik(0,ni,Sx,Sy,XtX,Xty,yty,n,k,method) >= -f
        theta = 0;
    else
        theta = exp(phi);
    end
    [~,beta,XtWX,Q] = logLik(theta,ni,Sx,Sy,XtX,Xty,yty,n,k,method);
    if strcmp(method,'REML'), sigma2 = Q/(n - k); else, sigma2 = Q/n; end
    se = sqrt(max(diag(sigma2*(XtWX\eye(k))),0));
    r.beta = beta; r.se = se; r.t = beta./se; r.df = n - k;
    r.P = 2*mgi_tcdf(-abs(r.t),r.df);
    r.sigma2 = sigma2; r.tau2 = theta*sigma2;
    r.icc = min(max(r.tau2/(r.tau2 + r.sigma2),0),1);
end

function [ll,beta,XtWX,Q] = logLik(theta,ni,Sx,Sy,XtX,Xty,yty,n,k,method)
    c = theta./(1 + theta*ni);
    XtWX = XtX - Sx'*(Sx.*c);
    XtWy = Xty - Sx'*(c.*Sy);
    beta = XtWX\XtWy;
    Q = max(yty - sum(c.*Sy.^2) - beta'*XtWy,realmin);
    logDetV = sum(log(1 + theta*ni));
    if strcmp(method,'REML')
        m = n - k;
        [R,flag] = chol(XtWX);
        if flag ~= 0, ll = -Inf; return; end
        ll = -0.5*(m*log(2*pi*Q/m) + logDetV + 2*sum(log(diag(R))) + m);
    else
        ll = -0.5*(n*log(2*pi*Q/n) + logDetV + n);
    end
end
