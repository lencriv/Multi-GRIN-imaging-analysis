function results = mgi_preprocess_baseline(cfg)
%MGI_PREPROCESS_BASELINE Baseline-session preprocessing (BLS).
%   results = mgi_preprocess_baseline(cfg)
%   Loads each baseline session once and computes
%     - movement coupling, within-region partial R^2, between-region
%       signed partial r and region preference (cfg.baseline cohort)
%     - clustered R^2 correlation matrices (cfg.correlation cohort)
%   Saves <preprocessed>/baseline.mat and statistics tables.
%   results.baseline     mgi_baseline_summary output
%   results.correlation  one correlation matrix per session
    if nargin < 1, cfg = mgi_config(); end
    couplingRows = mgi_find_sessions(cfg.baseline.condition,cfg,'Cohort',cfg.baseline.cohort);
    matrixRows = mgi_find_sessions(cfg.correlation.condition,cfg,'Cohort',cfg.correlation.cohort);
    tasks = taskList(cfg.baseline.condition,couplingRows,cfg.correlation.condition,matrixRows);

    sessions = struct([]);
    correlation = struct([]);
    for k = 1:numel(tasks)
        task = tasks(k);
        if cfg.verbose
            fprintf('%s session %d/%d: %s\n',task.condition,k,numel(tasks),task.row.mouse);
        end
        session = mgi_load_session(task.condition,task.row,cfg);
        if task.coupling
            inputs = mgi_session_inputs(session,cfg);
            sessions = appendElement(sessions,mgi_baseline_session(inputs,cfg));
            clear inputs
        end
        if task.matrix
            matrix = mgi_correlation_matrix(mgi_zscore_activity(session,cfg.regions),cfg);
            matrix.condition = task.condition;
            matrix.mouse = task.row.mouse;
            matrix.conditionIndex = task.row.conditionIndex;
            matrix.cohort = task.row.cohort;
            matrix.dmsCellType = task.row.dmsCellType;
            matrix.regions = cfg.regions;
            correlation = appendElement(correlation,matrix);
        end
        clear session
    end
    results = struct('baseline',mgi_baseline_summary(sessions,cfg), ...
        'correlation',correlation,'config',cfg);
    saveResults(results,cfg);
end

function tasks = taskList(couplingCondition,couplingRows,matrixCondition,matrixRows)
    tasks = struct('condition',{},'row',{},'coupling',{},'matrix',{});
    for k = 1:numel(couplingRows)
        tasks(end+1) = struct('condition',couplingCondition,'row',couplingRows(k), ...
            'coupling',true,'matrix',false);
    end
    for k = 1:numel(matrixRows)
        match = strcmp({tasks.condition},matrixCondition) & ...
            arrayfun(@(t) t.row.conditionIndex == matrixRows(k).conditionIndex,tasks);
        if any(match)
            tasks(find(match,1)).matrix = true;
        else
            tasks(end+1) = struct('condition',matrixCondition,'row',matrixRows(k), ...
                'coupling',false,'matrix',true);
        end
    end
end

function list = appendElement(list,element)
    if isempty(list), list = element; else, list(end+1) = element; end
end

function saveResults(results,cfg)
    if exist(cfg.paths.preprocessed,'dir') ~= 7, mkdir(cfg.paths.preprocessed); end
    file = fullfile(cfg.paths.preprocessed,'baseline.mat');
    if exist('OCTAVE_VERSION','builtin') ~= 0
        save(file,'results','-v7');
    else
        save(file,'results','-v7.3');
    end
    folder = cfg.paths.statistics;
    b = results.baseline;
    mgi_write_csv(fullfile(folder,'baseline_movement_cdf_tests.csv'),b.stats.movementCDF);
    mgi_write_csv(fullfile(folder,'baseline_intra_partial_cdf_tests.csv'),b.stats.intraCDF);
    mgi_write_csv(fullfile(folder,'baseline_inter_partial_centroid_tests.csv'),b.stats.interCentroid);
    summary = struct('region',cfg.regions(:), ...
        'recordedNeurons',num2cell(sum(b.movement.recorded,1)'), ...
        'analyzableNeurons',num2cell(arrayfun(@(r) nnz(b.movement.neurons.region == r),1:numel(cfg.regions))'), ...
        'movementSignificant',num2cell(b.movement.significantCounts'), ...
        'movementSignificantFraction',num2cell(b.movement.significantFraction'), ...
        'movementUncorrectedFraction',num2cell(b.movement.uncorrectedFraction'), ...
        'preferTargetA',num2cell(b.inter.preferenceCounts(1,:)'), ...
        'preferTargetB',num2cell(b.inter.preferenceCounts(2,:)'), ...
        'preferNeither',num2cell(b.inter.preferenceCounts(3,:)'), ...
        'targetA',cellfun(@(t) cfg.regions{t(1)},b.targets(:),'UniformOutput',false), ...
        'targetB',cellfun(@(t) cfg.regions{t(2)},b.targets(:),'UniformOutput',false));
    mgi_write_csv(fullfile(folder,'baseline_region_summary.csv'),summary);
    movement = b.movement.neurons;
    movement.mouse = b.mice(movement.mouse)';
    movement.region = cfg.regions(movement.region)';
    mgi_write_csv(fullfile(folder,'baseline_movement_neurons.csv'),movement);
    inter = b.inter.neurons;
    targetA = cellfun(@(t) cfg.regions{t(1)},b.targets(inter.seed),'UniformOutput',false);
    targetB = cellfun(@(t) cfg.regions{t(2)},b.targets(inter.seed),'UniformOutput',false);
    preferred = repmat({'none'},numel(inter.seed),1);
    preferred(inter.preference == 1) = targetA(inter.preference == 1);
    preferred(inter.preference == 2) = targetB(inter.preference == 2);
    inter.mouse = b.mice(inter.mouse)';
    inter.seed = cfg.regions(inter.seed)';
    inter.targetA = targetA(:);
    inter.targetB = targetB(:);
    inter.preference = preferred;
    mgi_write_csv(fullfile(folder,'baseline_inter_partial_neurons.csv'),inter);
end
