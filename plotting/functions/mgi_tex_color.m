function text = mgi_tex_color(text,color)
%MGI_TEX_COLOR Wrap text in a TeX color command.
    text = sprintf('{\\color[rgb]{%.4f,%.4f,%.4f}%s}',color(1),color(2),color(3),text);
end
