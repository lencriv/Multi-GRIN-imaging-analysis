function base = mgi_merge_struct(base,override)
%MGI_MERGE_STRUCT Recursively replace fields of base with those of override.
    if isempty(override), return; end
    names = fieldnames(override);
    for k = 1:numel(names)
        value = override.(names{k});
        if isstruct(value) && isscalar(value) && isfield(base,names{k}) && ...
                isstruct(base.(names{k})) && isscalar(base.(names{k}))
            base.(names{k}) = mgi_merge_struct(base.(names{k}),value);
        else
            base.(names{k}) = value;
        end
    end
end
