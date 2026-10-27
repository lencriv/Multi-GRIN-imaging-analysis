function mgi_write_csv(file,data)
%MGI_WRITE_CSV Write a struct array (one row per element) or a struct of equal-length columns.
    folder = fileparts(file);
    if ~isempty(folder) && exist(folder,'dir') ~= 7, mkdir(folder); end
    names = fieldnames(data);
    if isColumnTable(data,names)
        n = numel(data.(names{1}));
        columns = cellfun(@(f) data.(f)(:),names,'UniformOutput',false);
    else
        n = numel(data);
        columns = cellfun(@(f) {data.(f)}',names,'UniformOutput',false);
    end
    fid = fopen(file,'w');
    if fid < 0, error('MGI:csv','Cannot write %s.',file); end
    fprintf(fid,'%s\n',strjoin(names',','));
    for i = 1:n
        cells = cell(1,numel(names));
        for j = 1:numel(names)
            value = columns{j}(i);
            if iscell(value), value = value{1}; end
            cells{j} = textOf(value);
        end
        fprintf(fid,'%s\n',strjoin(cells,','));
    end
    fclose(fid);
end

function tf = isColumnTable(data,names)
    tf = isscalar(data) && ~isempty(names);
    if ~tf, return; end
    lengths = cellfun(@(f) numel(data.(f)),names);
    kinds = cellfun(@(f) ~ischar(data.(f)),names);
    tf = all(kinds) && all(lengths == lengths(1)) && lengths(1) ~= 1;
end

function s = textOf(v)
    if ischar(v)
        s = v;
        if any(s == ',') || any(s == '"'), s = ['"' strrep(s,'"','""') '"']; end
    elseif isempty(v)
        s = '';
    elseif isnumeric(v) || islogical(v)
        v = double(v);
        if isscalar(v)
            if isnan(v), s = 'NaN';
            elseif v == round(v) && abs(v) < 1e15, s = sprintf('%d',v);
            else, s = sprintf('%.10g',v);
            end
        else
            s = ['"' strjoin(arrayfun(@(x) sprintf('%.10g',x),v(:)','UniformOutput',false),';') '"'];
        end
    else
        s = class(v);
    end
end
