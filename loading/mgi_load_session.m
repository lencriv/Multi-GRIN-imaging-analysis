function [session,row] = mgi_load_session(condition,key,cfg)
%MGI_LOAD_SESSION Load one exported session.
%   session = mgi_load_session('BLS',4,cfg)          % condition index
%   session = mgi_load_session('BLS','Pan_11',cfg)   % mouse name
%   session = mgi_load_session('BLS',row,cfg)        % row from mgi_find_sessions
    condition = upper(char(condition));
    if isstring(key), key = char(key); end
    if isstruct(key)
        row = key;
        file = fullfile(cfg.paths.data,[condition '.mat']);
    else
        [rows,info] = mgi_session_index(condition,cfg);
        file = info.file;
        if ischar(key)
            row = rows(strcmp({rows.mouse},key));
        else
            row = rows([rows.conditionIndex] == key);
        end
        if numel(row) ~= 1
            error('MGI:sessionKey','No unique %s session matches the request.',condition);
        end
    end
    contents = load(file,row.variableName);
    session = contents.(row.variableName);
end
