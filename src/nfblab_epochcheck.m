% check event information
function [evt,nonEventChans] = nfblab_epochcheck(evt, chans, windowSize, windowInc, srateHardware, srate)

if isempty(evt)
    nonEventChans = chans;
else
    nonEventChans = setdiff(chans, evt.eventChan);
    if diff(evt.epochLimits)/1000 > (windowSize-windowInc)/srate
        error('window size is too small to extract epochs; decrease epoch limits');
    end
    if evt.epochBaseline(1) < evt.epochLimits(1)
        error('Baseline must be comprised within the data epoch');
    end
    if srateHardware ~= srate
        error('Decimation not possible when using event extraction');
    end
    evt.epochN        = zeros(1, length(evt.respVals));
    evt.epochData     = [];
    evt.epochDataSingleTrials = cell(1,length(evt.respVals));
    evt.epochMinSpacing  = ceil(diff(evt.epochLimits)/1000*srate/windowInc); % minium of number of windows to wait before extracting new epoch
    evt.epochSpacing  = evt.epochMinSpacing;
end
