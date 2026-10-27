function label = mgi_stars(p)
%MGI_STARS Significance label: *** P < 0.001, ** P < 0.01, * P < 0.05, ns otherwise.
    if ~isfinite(p), label = 'n/a';
    elseif p < 0.001, label = '***';
    elseif p < 0.01, label = '**';
    elseif p < 0.05, label = '*';
    else, label = 'ns';
    end
end
