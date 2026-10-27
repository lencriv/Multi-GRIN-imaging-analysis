function cfg = mgi_config(overrides)
%MGI_CONFIG Paths, cohorts, analysis parameters and figure style.
%   cfg = mgi_config() returns the defaults.
%   cfg = mgi_config(overrides) merges a (nested) struct of overrides.
%   paths.preprocessed, paths.statistics and paths.figures default to
%   subfolders of paths.results.
    root = fileparts(fileparts(mfilename('fullpath')));
    cfg = struct();
    cfg.verbose = true;

    cfg.paths.root = root;
    cfg.paths.data = fullfile('G:','My Drive','MGI','MGI_data_export','exported_imaging');
    cfg.paths.results = fullfile(root,'results');
    cfg.paths.preprocessed = '';
    cfg.paths.statistics = '';
    cfg.paths.figures = '';

    cfg.regions = {'M1','DMS','VLT'};
    cfg.regionPairs = [1 2; 1 3; 2 3];
    cfg.regionPairLabels = {{'DMS','M1'},{'VLT','M1'},{'DMS','VLT'}};

    cfg.speed.keypoints = [1 2 3 4 5 8];
    cfg.speed.behaviorFrameRate = 80;
    cfg.speed.minFracValid = 0.5;
    cfg.speed.maxGapSeconds = 0.25;
    cfg.speed.smoothSeconds = 1;

    cfg.grid.points = 501;
    cfg.grid.asinhScale = 0.002;

    cfg.baseline.condition = 'BLS';
    cfg.baseline.cohort = 'WT';
    cfg.baseline.nPC = 5;
    cfg.baseline.intraConditioning = 'pcs';
    cfg.baseline.interConditioning = 'pcs';
    cfg.baseline.targets = {[2 3],[1 3],[1 2]};
    cfg.baseline.movementShuffles = 1000;
    cfg.baseline.preferenceShuffles = 20000;
    cfg.baseline.minShiftSeconds = 5;
    cfg.baseline.alpha = 0.05;
    cfg.baseline.movementCorrection = 'bh';
    cfg.baseline.preferenceCorrection = 'bh';
    cfg.baseline.seed = 0;
    cfg.baseline.neuronBatchSize = 32;
    cfg.baseline.lagChunkSize = 512;

    cfg.correlation.condition = 'BLS';
    cfg.correlation.cohort = 'all';
    cfg.correlation.linkage = 'ward';
    cfg.correlation.clusters = 4;

    cfg.transientRate.minEvents = 10;
    cfg.transientRate.nBins = 30;
    cfg.transientRate.xLimitPercentile = 97.5;
    cfg.transientRate.lmeFitMethod = 'ML';
    cfg.transientRate.iccFitMethod = 'ML';

    cfg.comparisons = struct( ...
        'name',{'baseline_td','td_tbz'}, ...
        'before',{struct('condition','BLS','cohort','WT','label','Baseline'), ...
                  struct('condition','DW','cohort','TBZ','label','TD')}, ...
        'after',{struct('condition','DW','cohort','WT','label','TD'), ...
                 struct('condition','TBZ','cohort','TBZ','label','TBZ')}, ...
        'transientRateExcludeMice',{{'Pan_4'},{}}, ...
        'correlationExcludeMice',{{},{}}, ...
        'rateTitle',{'activity','neurons'}, ...
        'changeDescription',{'TD state correlation relative to baseline', ...
                             'TBZ correlation relative to TD state'});

    cfg.events.vl = struct('condition','BLL','cohort','WT','label','VL');
    cfg.events.tp = struct('condition','DW','cohort','WT','label','TP');
    cfg.events.halfWindowSeconds = 15;
    cfg.events.epochSeconds = 3;
    cfg.events.minValidFraction = 0.8;
    cfg.events.minEvents = 3;
    cfg.events.shuffles = 1000;
    cfg.events.minShiftSeconds = 10;
    cfg.events.seed = 0;
    cfg.events.meanSmoothSeconds = 1;

    cfg.colors.M1 = [63 37 244]/255;
    cfg.colors.DMS = [255 0 0]/255;
    cfg.colors.VLT = [176 123 255]/255;
    cfg.colors.Baseline = [11 209 255]/255;
    cfg.colors.TD = [255 29 239]/255;
    cfg.colors.TBZ = [165 76 2]/255;
    cfg.colors.VL = [250 175 64]/255;
    cfg.colors.TP = [255 29 239]/255;
    cfg.colors.VLTrace = [255 158 0]/255;
    cfg.colors.TPTrace = [255 0 230]/255;
    cfg.colors.headerBackground = [224 224 224]/255;
    cfg.colors.epochShading = [240 240 240]/255;
    cfg.colors.higher = [0 161 75]/255;
    cfg.colors.lower = [236 28 36]/255;
    cfg.colors.arrowTop = [107 182 79]/255;
    cfg.colors.arrowBottom = [236 28 36]/255;

    cfg.figures.font = 'Arial';
    cfg.figures.fontSize = 7;
    cfg.figures.formats = {'png','svg','pdf','fig'};
    cfg.figures.resolution = 600;
    cfg.figures.visible = 'off';
    cfg.figures.correlogramMouse = 'Pan_11';
    cfg.figures.correlogramRegionOrder = [1 2 3];
    cfg.figures.correlogramLimits = [0 0.1];
    cfg.figures.preferenceBars = {1,[3 2]; 2,[3 1]; 3,[1 2]};
    cfg.figures.interLineStyles = {'--','-.','-'};
    cfg.figures.eventHeatmapLimits = [-0.5 1];

    if nargin > 0 && ~isempty(overrides)
        cfg = mgi_merge_struct(cfg,overrides);
    end
    names = fieldnames(cfg.paths);
    for k = 1:numel(names)
        cfg.paths.(names{k}) = char(cfg.paths.(names{k}));
    end
    derived = {'preprocessed','statistics','figures'};
    for k = 1:numel(derived)
        if isempty(cfg.paths.(derived{k}))
            cfg.paths.(derived{k}) = fullfile(cfg.paths.results,derived{k});
        end
    end
end
