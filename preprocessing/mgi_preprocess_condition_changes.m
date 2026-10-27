function results = mgi_preprocess_condition_changes(cfg)
%MGI_PREPROCESS_CONDITION_CHANGES Transient rates and correlation changes between conditions.
%   results = mgi_preprocess_condition_changes(cfg)
%   For each entry of cfg.comparisons (default Baseline -> TD in WT mice and
%   TD -> TBZ in the TBZ cohort) every session involved is loaded once and
%   reduced to transient rates and pairwise R^2 (mgi_session_features).
%   results.comparisons(c).transientRate  per region, mgi_transient_rate_comparison
%   results.comparisons(c).intra          per region, mgi_correlation_change
%   results.comparisons(c).inter          per region pair, mgi_correlation_change
%   Saves <preprocessed>/condition_changes.mat and statistics tables.
    if nargin < 1, cfg = mgi_config(); end
    cache = struct();
    comparisons = struct([]);
    for c = 1:numel(cfg.comparisons)
        spec = cfg.comparisons(c);
        if cfg.verbose, fprintf('Comparison %s\n',spec.name); end
        [before,cache] = conditionFeatures(spec.before,cache,cfg);
        [after,cache] = conditionFeatures(spec.after,cache,cfg);
        entry = struct('name',spec.name,'before',spec.before,'after',spec.after, ...
            'beforeMice',{{before.mouse}},'afterMice',{{after.mouse}}, ...
            'transientRate',mgi_transient_rate_comparison(before,after,cfg,spec.transientRateExcludeMice), ...
            'intra',mgi_correlation_change(before,after,'intra',cfg,spec.correlationExcludeMice), ...
            'inter',mgi_correlation_change(before,after,'inter',cfg,spec.correlationExcludeMice), ...
            'transientRateExcludeMice',{spec.transientRateExcludeMice}, ...
            'correlationExcludeMice',{spec.correlationExcludeMice}, ...
            'rateTitle',spec.rateTitle,'changeDescription',spec.changeDescription);
        if isempty(comparisons), comparisons = entry; else, comparisons(end+1) = entry; end
    end
    results = struct('comparisons',comparisons,'config',cfg);
    saveResults(results,cfg);
end

function [features,cache] = conditionFeatures(side,cache,cfg)
    rows = mgi_find_sessions(side.condition,cfg,'Cohort',side.cohort);
    features = struct([]);
    for k = 1:numel(rows)
        key = sprintf('%s_%03d',side.condition,rows(k).conditionIndex);
        if ~isfield(cache,key)
            if cfg.verbose
                fprintf('  %s %s\n',side.condition,rows(k).mouse);
            end
            session = mgi_load_session(side.condition,rows(k),cfg);
            cache.(key) = mgi_session_features(session,cfg);
            clear session
        end
        if isempty(features), features = cache.(key); else, features(end+1) = cache.(key); end
    end
end

function saveResults(results,cfg)
    if exist(cfg.paths.preprocessed,'dir') ~= 7, mkdir(cfg.paths.preprocessed); end
    file = fullfile(cfg.paths.preprocessed,'condition_changes.mat');
    if exist('OCTAVE_VERSION','builtin') ~= 0
        save(file,'results','-v7');
    else
        save(file,'results','-v7.3');
    end
    for c = 1:numel(results.comparisons)
        comparison = results.comparisons(c);
        prefix = fullfile(cfg.paths.statistics,comparison.name);
        rates = comparison.transientRate;
        rows = struct('region',{rates.region}', ...
            'before',comparison.before.label,'after',comparison.after.label, ...
            'nNeuronsBefore',{rates.nBefore}','nNeuronsAfter',{rates.nAfter}', ...
            'nMice',{rates.nMice}', ...
            'meanBefore',arrayfun(@(e) e.designEffectBefore.mean,rates,'UniformOutput',false)', ...
            'semBefore',arrayfun(@(e) e.designEffectBefore.sem,rates,'UniformOutput',false)', ...
            'meanAfter',arrayfun(@(e) e.designEffectAfter.mean,rates,'UniformOutput',false)', ...
            'semAfter',arrayfun(@(e) e.designEffectAfter.sem,rates,'UniformOutput',false)', ...
            'estimate',{rates.estimate}','t',{rates.t}','df',{rates.df}','P',{rates.P}', ...
            'test',{rates.test}');
        mgi_write_csv([prefix '_transient_rate_tests.csv'],rows);
        changes = [comparison.intra, comparison.inter];
        labels = arrayfun(@(e) pairLabel(e.label),changes,'UniformOutput',false);
        rows = struct('kind',{changes.kind}','correlation',labels', ...
            'before',comparison.before.label,'after',comparison.after.label, ...
            'nMice',arrayfun(@(e) numel(e.mice),changes,'UniformOutput',false)', ...
            'nPairsBefore',{changes.nBefore}','nPairsAfter',{changes.nAfter}', ...
            'D',{changes.D}','P',{changes.P}','P_BH',{changes.P_BH}','test',{changes.test}');
        mgi_write_csv([prefix '_correlation_change_tests.csv'],rows);
    end
end

function label = pairLabel(label)
    if iscell(label), label = strjoin(label,'-'); end
end
