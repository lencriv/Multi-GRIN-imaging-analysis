function [rate,eventCount] = mgi_transient_rate(S,frameRate)
%MGI_TRANSIENT_RATE Gain-normalized Ca2+ transient rate per neuron.
%   [rate,eventCount] = mgi_transient_rate(S,frameRate)
%   S is neurons x frames of CNMF-E deconvolved signal. For each neuron the
%   signal is summed over the session, divided by its median non-zero event
%   amplitude and by the session duration (typical events per second).
%   eventCount is the number of frames with S > 0. Neurons without events
%   return NaN.
    S = double(S);
    n = size(S,1);
    rate = NaN(n,1);
    eventCount = zeros(n,1);
    for i = 1:n
        v = S(i,isfinite(S(i,:)));
        events = v(v > 0);
        eventCount(i) = numel(events);
        if isempty(events), continue; end
        gain = median(events);
        if gain > 0
            rate(i) = sum(v)/gain/numel(v)*frameRate;
        end
    end
end
