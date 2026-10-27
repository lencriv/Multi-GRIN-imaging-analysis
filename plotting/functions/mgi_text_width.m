function width = mgi_text_width(label,fontSize)
%MGI_TEXT_WIDTH Approximate rendered width (inches) of a TeX label in Arial.
    visible = regexprep(label,'\\color\[rgb\]\{[^}]*\}','');
    visible = regexprep(visible,'\\color\{[^}]*\}','');
    visible = regexprep(visible,'\\fontsize\{[^}]*\}','');
    visible = regexprep(visible,'\\[a-zA-Z]+','');
    visible = strrep(strrep(visible,'{',''),'}','');
    em = zeros(1,numel(visible));
    for k = 1:numel(visible)
        c = visible(k);
        if any(c == 'MW'), em(k) = 0.85;
        elseif any(c == 'Iijl.,:;!|'''), em(k) = 0.25;
        elseif any(c == 'ft '), em(k) = 0.3;
        elseif any(c == 'rJ()-'), em(k) = 0.36;
        elseif any(c == '*'), em(k) = 0.42;
        elseif c >= 'A' && c <= 'Z', em(k) = 0.7;
        elseif any(c == 'mw'), em(k) = 0.8;
        else, em(k) = 0.56;
        end
    end
    width = sum(em)*fontSize/72;
end
