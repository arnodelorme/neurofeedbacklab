% Compute and plot Event-Related spectral perturbation 
% This is done by sending the neurofeedback command 'plotERSP'

function nfblab_epochersp(evt, srate)

if isempty(evt)
    disp('No event channel, cannot compute ERSP');
else
    figure('position', [560   632   560   316], 'menubar', 'none', 'name', 'ERSP results', 'numbertitle', false);
    caxisval = [];
    for iCond = 1:length(evt.epochDataSingleTrials)
        subplot(1, length(evt.epochDataSingleTrials), iCond);
        
        % get frames x trials for this condition
        dataTmp = reshape([evt.epochDataSingleTrials{1}{:}], length(evt.epochDataSingleTrials{1}{1}), length(evt.epochDataSingleTrials{1}));
        [ersp,~,~,times,freqs] = newtimef(dataTmp, size(dataTmp,1), evt.epochLimits, srate, [1 0.5], 'freqs', [8 50], 'plotersp', 'off', 'plotitc', 'off', 'padratio', 4);
        
        tftopo(ersp, times, freqs);
        if isempty(caxisval)
            caxisval = caxis;
        else
            caxis(caxisval);
        end
        title(sprintf('Response %d', evt.respVals(iCond)));
    end
    cbar;
end
