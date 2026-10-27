function dataDir = mgi_make_test_data(dataDir,varargin)
%MGI_MAKE_TEST_DATA Synthetic BLS, DW, TBZ and BLL files in the exported format.
%   dataDir = mgi_make_test_data(dataDir,'Frames',4000)
%   Seven WT mice (global indices 1-7, TBZ cohort 4-7) plus one D1 and one
%   CHAT mouse at baseline and in BLL. Planted structure: VLT neurons follow
%   orofacial speed most strongly, DMS neurons share a strong common signal,
%   M1 neurons follow VLT activity more than DMS activity, and in TD
%   transient rates rise while DMS and DMS-VLT correlations fall (restored
%   by TBZ). Supervised tongue-protrusion bouts are added to BLL (voluntary
%   licks), DW and TBZ; DMS neurons respond before tongue-protrusion onset
%   and after voluntary-lick onset. One BLL session has fewer acquisition
%   locations than imaging frames.
    p = inputParser;
    addParameter(p,'Frames',4000);
    addParameter(p,'Neurons',[24 14 12]);
    addParameter(p,'Seed',1);
    parse(p,varargin{:});
    o = p.Results;
    if exist(dataDir,'dir') ~= 7, mkdir(dataDir); end
    rng(o.Seed,'twister');
    mice = {'Pan_4','Pan_5','Pan_6','Pan_11','Pan_12','Pan_13','Pan_14','Chat_GCAMP_2','D1_GCAMP_1'};
    cohorts = struct('D1',9,'D2',10,'CHAT',8,'TBZ',[4 5 6 7],'WT',1:7);
    tp = [-1 -1.5 0.5];
    vl = [1 2 1];
    writeCondition(dataDir,'BLS',1:9,mice,cohorts,o,struct('rate',1,'dms',0.8,'link',0.6,'latency',[]));
    writeCondition(dataDir,'DW',1:7,mice,cohorts,o,struct('rate',1.4,'dms',0.35,'link',0.25,'latency',tp));
    writeCondition(dataDir,'TBZ',4:7,mice,cohorts,o,struct('rate',1.2,'dms',0.7,'link',0.55,'latency',tp));
    writeCondition(dataDir,'BLL',1:9,mice,cohorts,o,struct('rate',1,'dms',0.8,'link',0.6,'latency',vl));
end

function writeCondition(dataDir,condition,ids,mice,cohorts,o,state)
    contents = struct();
    index = struct('conditionIndex',{},'globalMouseIndex',{},'mouse',{},'cohort',{}, ...
        'dmsCellType',{},'variableName',{},'sourceFile',{},'behaviorFrames',{}, ...
        'neuralFrames',{},'syncedNeuralFrames',{},'neurons',{},'tongueProtrusions',{}, ...
        'rewardStatus',{},'sourceBytes',{},'manifestBytes',{},'manifestSizeMatch',{});
    names = {'WT','D1','D2','CHAT'};
    cellTypes = {'not cell-type targeted','D1-MSN','D2-MSN','CIN'};
    for k = 1:numel(ids)
        id = ids(k);
        conditionIndex = k;
        if ~strcmp(condition,'TBZ'), conditionIndex = id; end
        member = cellfun(@(n) ismember(id,cohorts.(n)),names);
        cohort = names{find(member,1)};
        cellType = cellTypes{find(member,1)};
        neurons = o.Neurons + mod(id,3);
        options = struct('longVideo',strcmp(condition,'TBZ'),'spout',strcmp(condition,'BLL'), ...
            'synced',o.Frames);
        if strcmp(condition,'BLL') && id == 3, options.synced = o.Frames - 300; end
        session = makeSession(o.Frames,neurons,state,options);
        rewardStatus = 'notApplicable';
        tongue = NaN;
        if strcmp(condition,'BLL')
            rewardStatus = 'unavailable';
            session.behavior.rewardPulse = NaN(size(session.behavior.xy,1),1);
            session.behavior.rewardFrameIndices = zeros(0,1);
        end
        if isfield(session.behavior,'tongueProtrusion')
            tongue = numel(session.behavior.tongueProtrusion.startBehaviorFrame);
        end
        sourceFile = sprintf('MGI_%s_i%02d_%s.mat',condition,conditionIndex,mice{id});
        session.meta = struct('condition',condition,'conditionIndex',conditionIndex, ...
            'globalMouseIndex',id,'mouse',mice{id},'cohort',cohort,'dmsCellType',cellType, ...
            'sourceFile',sourceFile,'sourceBytes',0,'manifestBytes',0,'manifestSizeMatch',true, ...
            'behaviorFrameRateHz',80,'neuralFrameRateHz',20, ...
            'behaviorFrames',size(session.behavior.xy,1),'neuralFrames',o.Frames, ...
            'syncedNeuralFrames',options.synced,'neurons',neurons, ...
            'rewardStatus',rewardStatus,'rewardSource','','tongueProtrusions',tongue, ...
            'pulseDefinition','one behavior-frame sample at each imaging acquisition location');
        name = sprintf('session_%03d',conditionIndex);
        contents.(name) = session;
        index(end+1) = struct('conditionIndex',conditionIndex,'globalMouseIndex',id, ...
            'mouse',mice{id},'cohort',cohort,'dmsCellType',cellType,'variableName',name, ...
            'sourceFile',sourceFile,'behaviorFrames',session.meta.behaviorFrames, ...
            'neuralFrames',o.Frames,'syncedNeuralFrames',options.synced,'neurons',neurons, ...
            'tongueProtrusions',tongue,'rewardStatus',rewardStatus, ...
            'sourceBytes',0,'manifestBytes',0,'manifestSizeMatch',true);
    end
    contents.sessionIndex = index;
    contents.sessionCount = numel(index);
    contents.condition = condition;
    contents.cohortDefinitions = cohorts;
    contents.schemaVersion = 'MGI-imaging-condition-v3';
    save(fullfile(dataDir,[condition '.mat']),'-struct','contents','-v7');
end

function session = makeSession(T,neurons,state,options)
    fsB = 80; fsN = 20; ratio = 4;
    extra = 0;
    if options.longVideo, extra = round(0.25*T); end
    Tn = T + extra;
    drive = smoothNoise(Tn,40);
    drive = (drive - min(drive))/(max(drive) - min(drive));
    vlt = smoothNoise(Tn,10);
    m1Shared = 0.7*vlt + 0.3*smoothNoise(Tn,10);
    dms = smoothNoise(Tn,15);
    dmsShared = state.link*vlt + sqrt(max(0,1 - state.link^2))*dms;
    latent = {m1Shared + 0.4*drive, state.dms*dmsShared + 0.3*drive, vlt + 1.2*drive};
    weights = {0.6, 1.0, 0.9};
    regions = {'M1','DMS','VLT'};
    onsets = [];
    if ~isempty(state.latency)
        onsets = eventOnsets(options.synced,fsN);
    end
    for r = 1:3
        n = neurons(r);
        C = zeros(n,T); S = zeros(n,T);
        for i = 1:n
            w = weights{r}*(0.3 + rand);
            if r == 2, w = w*(1 + 0.5*rand); end
            signal = w*latent{r}(1:T) + 0.8*smoothNoise(T,6);
            probability = state.rate*0.02*(1 + max(signal,-0.9));
            events = (rand(1,T) < probability).*(0.5 + rand(1,T));
            S(i,:) = events;
            C(i,:) = filter(1,[1 -0.9],events) + 0.05*signal;
            if ~isempty(onsets) && rand < 0.6
                amplitude = 0.6*std(C(i,:))*(0.5 + rand);
                center = onsets + round((state.latency(r) + 0.4*randn)*fsN);
                frames = 1:T;
                for e = 1:numel(center)
                    C(i,:) = C(i,:) + amplitude*exp(-((frames - center(e))/(0.6*fsN)).^2/2);
                end
            end
        end
        session.neural.(regions{r}) = struct('denoised',C,'deconvolved',S, ...
            'deconvolvedSource','neuronS');
    end
    nB = Tn*ratio + 3;
    t = (0:nB-1)'/fsB;
    amplitude = interp1(1:Tn,drive(1:Tn),min(Tn,1 + (0:nB-1)'/ratio),'linear','extrap');
    nKeypoints = 8;
    if options.spout, nKeypoints = 6; end
    xy = zeros(nB,2,nKeypoints);
    for k = 1:nKeypoints
        phase = 2*pi*rand;
        xy(:,1,k) = 100 + 20*k + 3*amplitude.*sin(2*pi*6*t + phase) + 0.05*randn(nB,1);
        xy(:,2,k) = 200 + 2*amplitude.*cos(2*pi*6*t + phase) + 0.05*randn(nB,1);
    end
    dropout = rand(nB,1) < 0.01;
    xy(dropout,:,1) = NaN;
    locs = (1:ratio:(Tn*ratio + 1))';
    if options.synced < T, locs = locs(1:options.synced); end
    camera = 'front';
    if options.spout, camera = 'spout'; end
    session.behavior = struct('xy',xy,'keypointIndex',1:nKeypoints,'camera',camera, ...
        'tongueKeypoint',nKeypoints,'neuralFramePulse',false(nB,1),'neuralFrameLocs',locs);
    session.behavior.neuralFramePulse(locs(1:min(T,numel(locs)))) = true;
    if ~isempty(state.latency)
        pulses = locs(1:min(T,numel(locs)));
        startBehavior = pulses(onsets) + randi([-1 1],numel(onsets),1);
        startBehavior = [startBehavior; pulses(end) + 6 + (extra > 0)*40*ratio];
        endBehavior = startBehavior + randi([40 120],numel(startBehavior),1);
        endBehavior = min(endBehavior,nB);
        session.behavior.tongueProtrusion = struct('startBehaviorFrame',startBehavior, ...
            'endBehaviorFrame',endBehavior,'startNeuralFrame',nearest(startBehavior,pulses), ...
            'endNeuralFrame',nearest(endBehavior,pulses));
    end
end

function onsets = eventOnsets(T,fs)
    onsets = 30;
    next = onsets + round((12 + 10*rand)*fs);
    while next < T - 2*fs
        onsets(end+1,1) = next; %#ok<AGROW>
        next = next + round((12 + 10*rand)*fs);
    end
    onsets = onsets(:);
end

function frames = nearest(behaviorFrames,pulses)
    frames = NaN(size(behaviorFrames));
    for k = 1:numel(behaviorFrames)
        [distance,index] = min(abs(pulses - behaviorFrames(k)));
        if distance <= 4, frames(k) = index; end
    end
end

function x = smoothNoise(T,width)
    kernel = exp(-((-3*width:3*width)/width).^2/2);
    x = conv(randn(1,T + 6*width),kernel/sum(kernel),'same');
    x = x(3*width + (1:T));
    x = (x - mean(x))/std(x);
end
