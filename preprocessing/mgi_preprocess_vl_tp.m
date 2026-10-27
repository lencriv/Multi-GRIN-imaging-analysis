function results = mgi_preprocess_vl_tp(cfg)
%MGI_PREPROCESS_VL_TP Activity around voluntary licks (VL) and tongue protrusions (TP).
%   results = mgi_preprocess_vl_tp(cfg)
%   VL are the supervised licking bouts of the BLL sessions and TP the
%   supervised tongue protrusions of the DW (TD state) sessions, both in
%   the WT (pan-neuronal) cohort (cfg.events.vl, cfg.events.tp). Event
%   onsets are the imaging frames of the bout starts (mgi_event_onsets).
%   For every session, region and condition (mgi_event_activity):
%   z-scored activity averaged over events from -15 to +15 s, pre-
%   (-3 to 0 s) and post-movement (0 to +3 s) epoch AUC, and the
%   event-shift control. Neurons are pooled across mice within each region
%   (mgi_event_summary).
%   results.regions(r)  one element per region of cfg.regions
%   results.sessions    supervised bouts, analyzed events and frames per session
%   Saves <preprocessed>/vl_tp.mat and statistics tables.
    if nargin < 1, cfg = mgi_config(); end
    sides = {cfg.events.vl, cfg.events.tp};
    labels = {sides{1}.label, sides{2}.label};
    rows = cell(1,2);
    for c = 1:2
        rows{c} = mgi_find_sessions(sides{c}.condition,cfg,'Cohort',sides{c}.cohort);
        if isempty(rows{c})
            error('MGI:events','No %s sessions in cohort %s.',sides{c}.condition,sides{c}.cohort);
        end
    end
    nRegions = numel(cfg.regions);
    pooled = cell(nRegions,2);
    sessions = struct([]);
    frameRate = [];
    previous = rng();
    rng(cfg.events.seed,'twister');
    for s = 1:max(numel(rows{1}),numel(rows{2}))
        inputs = cell(1,2);
        for c = 1:2
            if s > numel(rows{c}), continue; end
            session = mgi_load_session(sides{c}.condition,rows{c}(s),cfg);
            [onsets,nFrames] = mgi_event_onsets(session);
            rate = double(session.meta.neuralFrameRateHz);
            if isempty(frameRate)
                frameRate = rate;
            elseif rate ~= frameRate
                error('MGI:frameRate','%s %s is imaged at %g Hz, other sessions at %g Hz.', ...
                    sides{c}.condition,session.meta.mouse,rate,frameRate);
            end
            Z = mgi_zscore_activity(session,cfg.regions);
            for r = 1:nRegions, Z{r} = Z{r}(:,1:nFrames); end
            inputs{c} = struct('Z',{Z},'onsets',onsets,'mouse',session.meta.mouse, ...
                'globalMouseIndex',double(session.meta.globalMouseIndex), ...
                'conditionIndex',double(session.meta.conditionIndex));
            entry = struct('label',labels{c},'condition',sides{c}.condition, ...
                'mouse',session.meta.mouse,'conditionIndex',double(session.meta.conditionIndex), ...
                'supervisedBouts',numel(session.behavior.tongueProtrusion.startBehaviorFrame), ...
                'analyzedEvents',numel(onsets),'analyzedFrames',nFrames, ...
                'neuralFrames',double(session.meta.neuralFrames));
            if isempty(sessions), sessions = entry; else, sessions(end+1) = entry; end %#ok<AGROW>
            if cfg.verbose
                fprintf('  %s %s %s: %d events\n',labels{c},sides{c}.condition,session.meta.mouse,numel(onsets));
            end
            clear session Z
        end
        for r = 1:nRegions
            for c = 1:2
                if isempty(inputs{c}), continue; end
                part = mgi_event_activity(inputs{c}.Z{r},inputs{c}.onsets,frameRate,cfg);
                pooled{r,c} = appendNeurons(pooled{r,c},part,inputs{c});
            end
        end
    end
    rng(previous);
    half = round(cfg.events.halfWindowSeconds*frameRate);
    timeSeconds = (-half:half)/frameRate;
    regions = struct([]);
    for r = 1:nRegions
        entry = mgi_event_summary(cfg.regions{r},pooled(r,:),labels,timeSeconds,frameRate,cfg);
        if isempty(regions), regions = entry; else, regions(end+1) = entry; end %#ok<AGROW>
    end
    results = struct('regions',regions,'sessions',sessions,'labels',{labels}, ...
        'conditions',{sides},'frameRate',frameRate,'timeSeconds',timeSeconds,'config',cfg);
    saveResults(results,cfg);
end

function pool = appendNeurons(pool,part,source)
    n = size(part.trace,1);
    part.mouse = repmat({source.mouse},n,1);
    part.globalMouseIndex = repmat(source.globalMouseIndex,n,1);
    part.conditionIndex = repmat(source.conditionIndex,n,1);
    part.neuron = (1:n)';
    if isempty(pool), pool = part; return; end
    names = fieldnames(part);
    for k = 1:numel(names)
        pool.(names{k}) = [pool.(names{k}); part.(names{k})];
    end
end

function saveResults(results,cfg)
    if exist(cfg.paths.preprocessed,'dir') ~= 7, mkdir(cfg.paths.preprocessed); end
    file = fullfile(cfg.paths.preprocessed,'vl_tp.mat');
    if exist('OCTAVE_VERSION','builtin') ~= 0
        save(file,'results','-v7');
    else
        save(file,'results','-v7.3');
    end
    prefix = fullfile(cfg.paths.statistics,'vl_tp');
    mgi_write_csv([prefix '_sessions.csv'],results.sessions);
    labels = results.labels;
    rows = struct([]);
    for r = 1:numel(results.regions)
        e = results.regions(r);
        for x = 1:numel(e.epochs)
            row = struct('region',e.region,'epoch',e.epochs{x});
            for c = 1:2
                row.(['n' labels{c}]) = e.n(c,x);
                row.(['mean' labels{c}]) = e.mean(c,x);
                row.(['sem' labels{c}]) = e.sem(c,x);
            end
            row.z = e.z(x); row.P = e.P(x); row.P_BH = e.P_BH(x); row.test = e.test;
            if isempty(rows), rows = row; else, rows(end+1) = row; end %#ok<AGROW>
        end
    end
    mgi_write_csv([prefix '_epoch_auc_tests.csv'],rows);
    columns = struct('region',{{}},'condition',{{}},'mouse',{{}},'conditionIndex',[],'neuron',[], ...
        'controlAUC',[],'preAUC',[],'postAUC',[],'controlPreAUC',[],'controlPostAUC',[], ...
        'validPreEvents',[],'validPostEvents',[]);
    for r = 1:numel(results.regions)
        e = results.regions(r);
        for c = 1:2
            d = e.(labels{c});
            n = d.nNeurons;
            columns.region = [columns.region; repmat({e.region},n,1)];
            columns.condition = [columns.condition; repmat(labels(c),n,1)];
            columns.mouse = [columns.mouse; d.mouse];
            columns.conditionIndex = [columns.conditionIndex; d.conditionIndex];
            columns.neuron = [columns.neuron; d.neuron];
            columns.controlAUC = [columns.controlAUC; d.control];
            columns.preAUC = [columns.preAUC; d.preAUC];
            columns.postAUC = [columns.postAUC; d.postAUC];
            columns.controlPreAUC = [columns.controlPreAUC; d.controlPre];
            columns.controlPostAUC = [columns.controlPostAUC; d.controlPost];
            columns.validPreEvents = [columns.validPreEvents; d.validEvents(:,1)];
            columns.validPostEvents = [columns.validPostEvents; d.validEvents(:,2)];
        end
    end
    mgi_write_csv([prefix '_epoch_auc_neurons.csv'],columns);
end
