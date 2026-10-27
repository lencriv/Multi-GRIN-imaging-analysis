function [index,info] = mgi_session_index(condition,cfg)
%MGI_SESSION_INDEX Sessions stored in one exported condition file.
%   [index,info] = mgi_session_index('BLS',cfg)
%   index  struct array, one element per session (sessionIndex of the file)
%   info   condition, cohortDefinitions, schemaVersion and file path
    file = fullfile(cfg.paths.data,[upper(char(condition)) '.mat']);
    if exist(file,'file') ~= 2
        error('MGI:conditionFile','%s not found.',file);
    end
    contents = load(file,'sessionIndex','cohortDefinitions','condition','schemaVersion');
    index = contents.sessionIndex(:)';
    info = struct('condition',upper(condition),'file',file, ...
        'cohortDefinitions',contents.cohortDefinitions, ...
        'schemaVersion',char(contents.schemaVersion));
end
