function [onsets,nFrames] = mgi_event_onsets(session)
%MGI_EVENT_ONSETS Imaging-frame onsets of the supervised tongue-protrusion bouts of a session.
%   [onsets,nFrames] = mgi_event_onsets(session)
%   onsets   behavior.tongueProtrusion.startNeuralFrame of every supervised
%            bout (voluntary licks in BLL, tongue protrusions in DW and TBZ)
%            that has an imaging frame, in session order
%   nFrames  imaging frames with behavior time (meta.syncedNeuralFrames);
%            event analyses use frames 1..nFrames
    if ~isfield(session.behavior,'tongueProtrusion')
        error('MGI:tongueProtrusion','%s %s has no behavior.tongueProtrusion; export it with the current MGI_data_export.', ...
            session.meta.condition,session.meta.mouse);
    end
    nFrames = double(session.meta.neuralFrames);
    if isfield(session.meta,'syncedNeuralFrames')
        nFrames = min(nFrames,double(session.meta.syncedNeuralFrames));
    end
    onsets = double(session.behavior.tongueProtrusion.startNeuralFrame(:));
    onsets = onsets(isfinite(onsets) & onsets >= 1 & onsets <= nFrames);
end
