function [inputs,Z,behavior] = mgi_session_inputs(session,cfg)
%MGI_SESSION_INPUTS Digestible activity and movement of one exported session.
%   [inputs,Z,behavior] = mgi_session_inputs(session,cfg)
%   Z         z-scored denoised activity per region (mgi_zscore_activity)
%   behavior  orofacial speed on the imaging time base (mgi_orofacial_speed)
%   inputs    standardized activity and movement on shared valid frames
%             (mgi_common_frames), plus session identity and frame rate
    Z = mgi_zscore_activity(session,cfg.regions);
    behavior = mgi_orofacial_speed(session,size(Z{1},2),cfg);
    inputs = mgi_common_frames(Z,behavior,max(100,20*cfg.baseline.nPC));
    inputs.frameRate = double(session.meta.neuralFrameRateHz);
    inputs.mouse = char(session.meta.mouse);
    inputs.conditionIndex = double(session.meta.conditionIndex);
    inputs.globalMouseIndex = double(session.meta.globalMouseIndex);
    inputs.recorded = cellfun(@(z) size(z,1),Z);
    inputs.fracValid = behavior.fracValid;
    inputs.fsNeural = behavior.fsNeural;
end
