function label = mgi_region_label(names,cfg,separator)
%MGI_REGION_LABEL TeX label of one region or a region pair in region colors.
%   mgi_region_label('DMS',cfg)  or  mgi_region_label({'DMS','M1'},cfg)
    if nargin < 3, separator = '-'; end
    names = cellstr(names);
    parts = cellfun(@(n) mgi_tex_color(n,cfg.colors.(n)),names,'UniformOutput',false);
    label = strjoin(parts,separator);
end
