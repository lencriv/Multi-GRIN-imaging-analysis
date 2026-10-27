function [sessions,rows] = mgi_load_sessions(condition,cfg,varargin)
%MGI_LOAD_SESSIONS Load every session matching a selection.
%   [sessions,rows] = mgi_load_sessions('BLS',cfg,'Cohort','WT')
%   Accepts the selection options of mgi_find_sessions.
    rows = mgi_find_sessions(condition,cfg,varargin{:});
    sessions = cell(1,numel(rows));
    for k = 1:numel(rows)
        sessions{k} = mgi_load_session(condition,rows(k),cfg);
    end
end
