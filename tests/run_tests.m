function run_tests(workDir)
%RUN_TESTS Unit checks and an end-to-end run on synthetic exported data.
%   run_tests()          uses a temporary folder
%   run_tests(workDir)   keeps the synthetic data, results and figures
    here = fileparts(mfilename('fullpath'));
    addpath(fileparts(here)); addpath(here);
    mgi_setup();
    if nargin < 1, workDir = tempname; end
    dataDir = mgi_make_test_data(fullfile(workDir,'data'));
    cfg = mgi_config(struct('verbose',false, ...
        'paths',struct('data',dataDir,'results',fullfile(workDir,'results'), ...
            'preprocessed',fullfile(workDir,'results','preprocessed'), ...
            'statistics',fullfile(workDir,'results','statistics'), ...
            'figures',fullfile(workDir,'results','figures')), ...
        'baseline',struct('movementShuffles',200,'preferenceShuffles',300), ...
        'events',struct('shuffles',200)));
    cfg.figures.formats = {'png'};
    cfg.figures.resolution = 150;

    checks = {@() checkLoading(cfg), @() checkSpeed(cfg), @() checkNulls(cfg), ...
        @() checkPrimitives(), @() checkEventAnalysis(cfg), @() checkBaseline(cfg), ...
        @() checkConditionChanges(cfg), @() checkVlTp(cfg)};
    names = {'loading','orofacial speed','circular-shift nulls','primitives', ...
        'event-aligned activity and event-shift null','baseline pipeline', ...
        'condition-change pipeline','VL/TP pipeline'};
    failed = 0;
    for k = 1:numel(checks)
        try
            checks{k}();
            fprintf('PASS %s\n',names{k});
        catch problem
            failed = failed + 1;
            fprintf('FAIL %s: %s\n',names{k},problem.message);
        end
    end
    if failed > 0
        error('MGI:tests','%d check(s) failed.',failed);
    end
end

function checkLoading(cfg)
    rows = mgi_find_sessions('BLS',cfg,'Cohort','WT');
    assert(numel(rows) == 7);
    rows = mgi_find_sessions('DW',cfg,'Cohort','TBZ');
    assert(isequal({rows.mouse},{'Pan_11','Pan_12','Pan_13','Pan_14'}));
    rows = mgi_find_sessions('BLS',cfg,'Cohort','WT','ExcludeMice',{'Pan_4'});
    assert(numel(rows) == 6 && ~any(strcmp({rows.mouse},'Pan_4')));
    a = mgi_load_session('TBZ','Pan_12',cfg);
    b = mgi_load_session('TBZ',2,cfg);
    assert(isequal(a.neural.M1.denoised,b.neural.M1.denoised));
    sessions = mgi_load_sessions('BLS',cfg,'Mouse',{'Pan_5','Pan_6'});
    assert(numel(sessions) == 2 && strcmp(sessions{2}.meta.mouse,'Pan_6'));
    rows = mgi_find_sessions('BLL',cfg,'Cohort','WT');
    assert(numel(rows) == 7 && all(strcmp({rows.cohort},'WT')));
    session = mgi_load_session('BLL','Pan_6',cfg);
    assert(strcmp(session.behavior.camera,'spout') && size(session.behavior.xy,3) == 6);
    [onsets,nFrames] = mgi_event_onsets(session);
    starts = session.behavior.tongueProtrusion.startNeuralFrame;
    assert(nFrames == session.meta.syncedNeuralFrames && nFrames < session.meta.neuralFrames);
    assert(isequal(onsets,starts(isfinite(starts))) && numel(onsets) == numel(starts) - 1);
end

function checkSpeed(cfg)
    session = mgi_load_session('TBZ',1,cfg);
    Z = mgi_zscore_activity(session,cfg.regions);
    behavior = mgi_orofacial_speed(session,size(Z{1},2),cfg);
    xy = session.behavior.xy;
    keypoints = cfg.speed.keypoints;
    raw = zeros(size(xy,1) - 1,numel(keypoints));
    for k = 1:numel(keypoints)
        track = xy(:,:,keypoints(k))';
        raw(:,k) = sqrt(sum(diff(track,1,2).^2,1))';
    end
    composite = zeros(size(raw,1),1);
    for t = 1:size(raw,1)
        v = raw(t,isfinite(raw(t,:)));
        if isempty(v), composite(t) = NaN; else, composite(t) = mean(v); end
    end
    T = size(Z{1},2);
    edges = round(session.behavior.neuralFrameLocs(1:T + 1));
    binned = zeros(T,1);
    for f = 1:T
        v = composite(edges(f):edges(f + 1) - 1);
        binned(f) = mean(v(isfinite(v)));
        if mean(isfinite(v)) < 0.5, binned(f) = NaN; end
    end
    filled = mgi_fill_gaps(binned,round(0.25*20));
    smooth = mgi_movmean(filled,20);
    smooth(~isfinite(filled)) = NaN;
    ok = isfinite(smooth);
    reference = (smooth - mean(smooth(ok)))/std(smooth(ok),1);
    assert(isequal(isfinite(reference(:)'),behavior.valid));
    assert(max(abs(reference(ok)' - behavior.speed(ok))) < 1e-10);
    sigma = std(session.neural.DMS.denoised(3,:));
    expected = (session.neural.DMS.denoised(3,:) - mean(session.neural.DMS.denoised(3,:)))/sigma;
    assert(max(abs(expected - Z{2}(3,:))) < 1e-12);
end

function checkNulls(cfg)
    session = mgi_load_session('BLS',3,cfg);
    inputs = mgi_session_inputs(session,cfg);
    [PCs,population] = mgi_region_pcs(inputs.Y,cfg.baseline.nPC);
    lags = [120 517 1400 2900];
    for r = 1:3
        coupling = mgi_movement_coupling(inputs.Y{r},inputs.movement,lags,5);
        partial = mgi_inter_partial_r(inputs.Y,PCs,population,r,cfg.baseline.targets{r},'pcs');
        null = mgi_preference_null(inputs.Y{r},partial,lags,5,3);
        for i = 1:size(inputs.Y{r},2)
            y = inputs.Y{r}(:,i);
            observed = pearson(y,inputs.movement)^2;
            shifted = arrayfun(@(L) pearson(circshift(y,L),inputs.movement)^2,lags);
            assert(abs(observed - coupling.R2(i)) < 1e-10);
            assert(abs((1 + sum(shifted >= observed - 1e-12))/5 - coupling.P(i)) < 1e-12);
            assert(abs(partialR(y,partial.Qa,partial.xa) - partial.rA(i)) < 1e-10);
            delta = zeros(numel(lags),1);
            for q = 1:numel(lags)
                ys = circshift(y,lags(q));
                delta(q) = partialR(ys,partial.Qb,partial.xb) - partialR(ys,partial.Qa,partial.xa);
            end
            excess = (partial.rB(i) - partial.rA(i)) - mean(delta);
            p = (1 + sum(abs(delta - mean(delta)) >= abs(excess) - 1e-12))/5;
            assert(abs(mean(delta) - null.nullMeanDelta(i)) < 1e-10);
            assert(abs(p - null.P(i)) < 1e-12);
        end
    end
end

function checkPrimitives()
    rng(3,'twister');
    A = randn(500,6); B = randn(500,4);
    R = corrcoef([A B]);
    within = R(1:6,1:6);
    v = mgi_pairwise_r2(A);
    assert(max(abs(sort(v) - sort(within(triu(true(6),1)).^2))) < 1e-12);
    v = mgi_pairwise_r2(A,B);
    assert(max(abs(sort(v) - sort(reshape(R(1:6,7:10),[],1).^2))) < 1e-12);
    x = rand(1000,1); grid = linspace(0,1,37);
    assert(isequal(mgi_cdf_on_grid(x,grid),arrayfun(@(g) sum(x <= g),grid)));
    a = randn(200,1); b = randn(150,1) + 0.4;
    [D,P] = mgi_kstest2(a,b);
    points = [a; b];
    reference = max(abs(arrayfun(@(t) mean(a <= t),points) - arrayfun(@(t) mean(b <= t),points)));
    assert(abs(D - reference) < 1e-12 && P > 0 && P < 0.05);
    S = [0 2 0 4 0 0 6; 0 0 0 0 0 0 0];
    [rate,events] = mgi_transient_rate(S,20);
    assert(abs(rate(1) - 12/4/7*20) < 1e-12 && isnan(rate(2)) && isequal(events,[3; 0]));
    q = mgi_padjust([0.01 0.04 0.03],'bh');
    assert(max(abs(q - [0.03 0.04 0.04])) < 1e-12);
    q = mgi_padjust([0.01 0.04 0.03],'holm');
    assert(max(abs(q - [0.03 0.06 0.06])) < 1e-12);
    [~,P] = mgi_signflip_test(ones(5,3));
    assert(abs(P - 2/32) < 1e-12);
    assert(abs(mgi_prctile(1:10,50) - 5.5) < 1e-12);
    [P,z,W] = mgi_ranksum(1:5,6:10);
    assert(W == 15 && abs(z + 12/sqrt(25*11/12)) < 1e-12 && abs(P - erfc(12/sqrt(25*11/12)/sqrt(2))) < 1e-15);
    a = [1 2 2 3 7]; b = [2 3 4 4 5 6];
    [~,~,W] = mgi_ranksum(a,b);
    U = sum(sum(a(:) > b(:)')) + 0.5*sum(sum(a(:) == b(:)'));
    assert(W == U + numel(a)*(numel(a) + 1)/2);
    [P1,z1] = mgi_ranksum(a,b); [P2,z2] = mgi_ranksum(b,a);
    assert(abs(P1 - P2) < 1e-15 && abs(z1 + z2) < 1e-12);
end

function checkEventAnalysis(cfg)
    rng(5,'twister');
    T = 700; fps = 20; half = 300; epoch = 60;
    Z = randn(3,T);
    Z(2,100:105) = NaN;
    onsets = [40; 150; 330; 480; 690];
    cfg.events.shuffles = 7;
    rng(11,'twister');
    out = mgi_event_activity(Z,onsets,fps,cfg);
    rng(11,'twister');
    lags = randi([200,T - 200],1,7);
    nullPre = NaN(3,7); nullPost = NaN(3,7);
    for i = 1:3
        rows = NaN(numel(onsets),2*half + 1);
        pre = NaN(numel(onsets),1); post = pre;
        for e = 1:numel(onsets)
            frames = onsets(e) + (-half:half);
            inside = frames >= 1 & frames <= T;
            rows(e,inside) = Z(i,frames(inside));
            pre(e) = epochAUC(Z(i,:),onsets(e) - epoch:onsets(e) - 1);
            post(e) = epochAUC(Z(i,:),onsets(e):onsets(e) + epoch - 1);
        end
        expected = NaN(1,2*half + 1);
        for k = 1:2*half + 1
            v = rows(:,k); v = v(isfinite(v));
            if ~isempty(v), expected(k) = mean(v); end
        end
        assert(isequal(isnan(expected),isnan(out.trace(i,:))));
        assert(max(abs(expected(isfinite(expected)) - out.trace(i,isfinite(expected)))) < 1e-12);
        assert(sameValue(eventMean(pre),out.preAUC(i)) && sameValue(eventMean(post),out.postAUC(i)));
        for q = 1:7
            shifted = mod(onsets + lags(q) - 1,T) + 1;
            a = NaN(numel(shifted),1); b = a;
            for e = 1:numel(shifted)
                if shifted(e) > epoch && shifted(e) <= T - epoch + 1
                    a(e) = epochAUC(Z(i,:),shifted(e) - epoch:shifted(e) - 1);
                    b(e) = epochAUC(Z(i,:),shifted(e):shifted(e) + epoch - 1);
                end
            end
            nullPre(i,q) = eventMean(a); nullPost(i,q) = eventMean(b);
        end
    end
    for i = 1:3
        eligible = find(isfinite(nullPre(i,:)) & isfinite(nullPost(i,:)));
        if isempty(eligible)
            assert(isnan(out.control(i)));
            continue;
        end
        d = eligible(randi(numel(eligible)));
        assert(abs(out.controlPre(i) - nullPre(i,d)) < 1e-12 && abs(out.controlPost(i) - nullPost(i,d)) < 1e-12);
        assert(abs(out.control(i) - (nullPre(i,d) + nullPost(i,d))/2) < 1e-12);
    end
end

function auc = epochAUC(z,frames)
    inside = frames >= 1 & frames <= numel(z);
    v = NaN(1,numel(frames));
    v(inside) = z(frames(inside));
    auc = NaN;
    if sum(isfinite(v)) >= ceil(0.8*numel(frames)), auc = mean(v(isfinite(v)))*numel(frames)/20; end
end

function m = eventMean(values)
    values = values(isfinite(values));
    m = NaN;
    if numel(values) >= 3, m = mean(values); end
end

function tf = sameValue(a,b)
    tf = (isnan(a) && isnan(b)) || abs(a - b) < 1e-12;
end

function checkBaseline(cfg)
    results = mgi_preprocess_baseline(cfg);
    b = results.baseline;
    assert(numel(b.mice) == 7 && numel(results.correlation) == 9);
    assert(isequal(size(b.intra.mouseCDF),[7 3 cfg.grid.points]));
    last = b.intra.mouseCDF(:,:,end);
    assert(all(abs(last(:) - 1) < 1e-12));
    assert(isequal(sum(b.movement.recorded,1),arrayfun(@(r) nnz(b.movement.neurons.region == r),1:3)));
    assert(b.movement.significantFraction(3) > b.movement.significantFraction(1));
    assert(all(b.intra.mouseMean(:,2) > b.intra.mouseMean(:,1)));
    assert(all(abs(sum(b.inter.preferenceFraction,1) - 1) < 1e-12));
    assert(numel(b.stats.movementCDF) == 3 && numel(b.stats.interCentroid) == 3);
    matrix = results.correlation(1);
    assert(size(matrix.R2,1) == sum(matrix.counts) && all(abs(diag(matrix.R2) - 1) < 1e-5));
    files = mgi_plot_baseline(fullfile(cfg.paths.preprocessed,'baseline.mat'),cfg);
    assert(numel(files) == 6 && all(cellfun(@(f) exist(f,'file') == 2,files)));
end

function checkConditionChanges(cfg)
    results = mgi_preprocess_condition_changes(cfg);
    td = results.comparisons(1);
    tbz = results.comparisons(2);
    assert(~any(strcmp(td.transientRate(1).mouseBefore,'Pan_4')));
    assert(numel(unique(td.transientRate(1).mouseBefore)) == 6);
    assert(isequal(td.inter(1).mice,{'Pan_4','Pan_5','Pan_6','Pan_11','Pan_12','Pan_13','Pan_14'}));
    assert(isequal(tbz.inter(1).mice,{'Pan_11','Pan_12','Pan_13','Pan_14'}));
    assert(all([td.transientRate.estimate] > 0));
    assert(min(td.intra(2).difference) < -0.1 && max(tbz.intra(2).difference) > 0.1);
    assert(max(abs(sum([td.transientRate(1).proportionBefore]) - ...
        mean(td.transientRate(1).valuesBefore <= td.transientRate(1).xmax))) < 1e-12);
    change = td.inter(3);
    assert(max(abs(change.difference - mean(change.cdfBefore - change.cdfAfter,1))) < 1e-12);
    files = mgi_plot_condition_changes(fullfile(cfg.paths.preprocessed,'condition_changes.mat'),cfg);
    assert(numel(files) == 10 && all(cellfun(@(f) exist(f,'file') == 2,files)));
end

function checkVlTp(cfg)
    results = mgi_preprocess_vl_tp(cfg);
    vlRows = mgi_find_sessions('BLL',cfg,'Cohort','WT');
    tpRows = mgi_find_sessions('DW',cfg,'Cohort','WT');
    assert(numel(results.sessions) == 14);
    assert(all([results.sessions.analyzedEvents] == [results.sessions.supervisedBouts] - 1));
    short = results.sessions(strcmp({results.sessions.label},'VL') & strcmp({results.sessions.mouse},'Pan_6'));
    assert(short.analyzedFrames == short.neuralFrames - 300);
    for r = 1:3
        e = results.regions(r);
        vlNeurons = arrayfun(@(row) row.neurons(r),vlRows);
        tpNeurons = arrayfun(@(row) row.neurons(r),tpRows);
        assert(e.VL.nNeurons == sum(vlNeurons) && e.TP.nNeurons == sum(tpNeurons));
        assert(e.VL.nMice == 7 && e.TP.nMice == 7);
        assert(isequal(e.n,[e.VL.nNeurons*[1 1 1]; e.TP.nNeurons*[1 1 1]]));
        assert(abs(e.mean(2,2) - mean(e.TP.preAUC)) < 1e-12);
        assert(abs(e.sem(1,3) - std(e.VL.postAUC)/sqrt(e.VL.nNeurons)) < 1e-12);
        column = e.TP.trace(:,301);
        assert(abs(e.TP.meanTrace(301) - mean(column)) < 1e-12);
        assert(abs(e.TP.semTrace(301) - std(column)/sqrt(numel(column))) < 1e-12);
        [~,peak] = max(e.VL.trace(e.VL.order,:),[],2);
        assert(all(diff(peak) >= 0));
        assert(all(abs(e.P_BH - mgi_padjust(e.P,'bh')) < 1e-15));
    end
    dms = results.regions(2);
    assert(dms.mean(2,2) > dms.mean(1,2) && dms.P_BH(2) < 0.05);
    assert(dms.mean(1,3) > dms.mean(1,1));
    files = mgi_plot_vl_tp(fullfile(cfg.paths.preprocessed,'vl_tp.mat'),cfg);
    assert(numel(files) == 6 && all(cellfun(@(f) exist(f,'file') == 2,files)));
end

function r = pearson(a,b)
    a = a - mean(a); b = b - mean(b);
    r = (a'*b)/sqrt((a'*a)*(b'*b));
end

function r = partialR(y,Q,target)
    residual = y - Q*(Q'*y);
    r = (target'*y)/(norm(residual)*norm(target));
end
