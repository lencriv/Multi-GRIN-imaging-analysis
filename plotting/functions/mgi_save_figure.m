function files = mgi_save_figure(fig,folder,name,cfg)
%MGI_SAVE_FIGURE Save a figure in every format of cfg.figures.formats and close it.
    if exist(folder,'dir') ~= 7, mkdir(folder); end
    files = {};
    isOctave = exist('OCTAVE_VERSION','builtin') ~= 0;
    for k = 1:numel(cfg.figures.formats)
        kind = lower(cfg.figures.formats{k});
        file = fullfile(folder,[name '.' kind]);
        switch kind
            case 'png'
                print(fig,file,'-dpng',sprintf('-r%d',cfg.figures.resolution));
            case 'svg'
                print(fig,file,'-dsvg');
            case 'pdf'
                print(fig,file,'-dpdf');
            case 'fig'
                if isOctave, continue; end
                set(fig,'CreateFcn','set(gcbo,''Visible'',''on'')');
                savefig(fig,file);
            otherwise
                error('MGI:figureFormat','Unknown format %s.',kind);
        end
        files{end+1} = file;
    end
    close(fig);
end
