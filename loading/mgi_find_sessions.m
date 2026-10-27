function [rows,info] = mgi_find_sessions(condition,cfg,varargin)
%MGI_FIND_SESSIONS Select sessions of a condition by cohort, mouse or index.
%   rows = mgi_find_sessions('DW',cfg,'Cohort','WT')
%   rows = mgi_find_sessions('BLS',cfg,'Mouse',{'Pan_11','Pan_12'})
%   rows = mgi_find_sessions('BLS',cfg,'Session',[1 4],'ExcludeMice',{'Pan_4'})
%   Cohort is 'all' or a field of the file's cohortDefinitions (WT, TBZ,
%   D1, D2, CHAT); membership is by global mouse index.
    p = inputParser;
    addParameter(p,'Cohort','all');
    addParameter(p,'Mouse',{});
    addParameter(p,'Session',[]);
    addParameter(p,'ExcludeMice',{});
    parse(p,varargin{:});
    o = p.Results;
    o.Cohort = char(o.Cohort);
    [rows,info] = mgi_session_index(condition,cfg);
    keep = true(1,numel(rows));
    if ~strcmpi(o.Cohort,'all')
        if ~isfield(info.cohortDefinitions,o.Cohort)
            error('MGI:cohort','Unknown cohort %s.',o.Cohort);
        end
        members = double(info.cohortDefinitions.(o.Cohort)(:));
        keep = keep & ismember([rows.globalMouseIndex],members);
    end
    mice = cellstr(o.Mouse);
    if ~isempty(mice)
        keep = keep & ismember({rows.mouse},mice);
    end
    if ~isempty(o.Session)
        keep = keep & ismember([rows.conditionIndex],o.Session);
    end
    excluded = cellstr(o.ExcludeMice);
    if ~isempty(excluded)
        keep = keep & ~ismember({rows.mouse},excluded);
    end
    rows = rows(keep);
end
