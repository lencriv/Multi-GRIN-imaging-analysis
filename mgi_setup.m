function root = mgi_setup()
%MGI_SETUP Add the repository folders to the path.
    root = fileparts(mfilename('fullpath'));
    folders = {'config','loading','preprocessing',fullfile('preprocessing','functions'), ...
        'plotting',fullfile('plotting','functions')};
    for k = 1:numel(folders)
        addpath(fullfile(root,folders{k}));
    end
    addpath(root);
    if exist('OCTAVE_VERSION','builtin') ~= 0
        try
            state = warning('off','all');
            pkg('load','statistics');
            warning(state);
        catch
        end
    end
end
