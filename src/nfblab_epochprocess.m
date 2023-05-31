% Process data epochs
% extract ERP within specific time window in real time and compute ERP amplitude
% which is then used for feedback
%
% See nfblab_process options

function [evt,epochFeedback] = nfblab_epochprocess(EEG, evt, verbose)

if nargin < 3
    verbose = true;
end

% data epoch extraction and processing
% event channels _activity, _level, _marker, _result1, _result2
% see src/renderer/plugins/eeg/lsl/LslActivityManager.js for
%
epochFeedback = [];
if ~isempty(evt)
    if evt.epochSpacing >= evt.epochMinSpacing
        newEpoch = false;
        for iEventVal = 1:length(evt.eventVals)
            epochMatch = find( abs(EEG.data(evt.eventChan,:) - evt.eventVals(iEventVal)) < 1e-8 ); % search for value
            if ~isempty(epochMatch)
                epochBeg = epochMatch(1)+round(evt.epochLimits(1)*EEG.srate/1000);
                epochEnd = epochMatch(1)+round(evt.epochLimits(2)*EEG.srate/1000);
                if epochBeg > 0 && epochEnd < size(EEG.data,2)
                    if verbose
                        fprintf('New epoch found of type %1.4f',  evt.eventVals(iEventVal));
                    end
                    
                    % check if epoch is correct or not
                    respFound = false;
                    for iResp = 1:length(evt.respVals)
                        if any(EEG.data(evt.respChan,epochBeg:epochEnd) == evt.respVals(iResp))
                            respFound = true;
                            if verbose, fprintf('-> response %d\n', evt.respVals(iResp)); end
                            if ~isnan(evt.epochBaseline)
                                epochBaseBeg = epochMatch(1)+round(evt.epochBaseline(1)*EEG.srate/1000);
                                epochBaseEnd = epochMatch(1)+round(evt.epochBaseline(2)*EEG.srate/1000);
                                epochTmp = evt.epochMask*bsxfun(@minus, EEG.data(:,epochBeg:epochEnd), mean(EEG.data(:,epochBaseBeg:epochBaseEnd),2));
                            else
                                epochTmp = evt.epochMask*EEG.data(:,epochBeg:epochEnd);
                            end
                            evt.epochN(iResp) = evt.epochN(iResp)+1;
                            evt.epochDataSingleTrials{iResp}{end+1} = epochTmp;
                            if evt.epochN(iResp) >= 1/(1-evt.epochMemory(iResp))
                                % weight using memory factor
                                evt.epochData(iResp,:) = evt.epochMemory(iResp)*evt.epochData(iResp,:) + (1-evt.epochMemory(iResp))*epochTmp;
                            elseif evt.epochN(iResp) > 1
                                % average with previous epoch until reaching epochMinN
                                evt.epochData(iResp,:) = (evt.epochData(iResp,:)*(evt.epochN(iResp)-1) + epochTmp)/evt.epochN(iResp);
                            else
                                evt.epochData(iResp,:) = epochTmp;
                            end
                            newEpoch = true;
                        end
                    end
                    if ~respFound
                        if verbose, fprintf('-> no response in range\n'); end
                    end
                    evt.epochSpacing = 0; % reset epoch spacing
                end
            end
        end
        if newEpoch && all(evt.epochN >= evt.epochMinN)
            epochDiff = evt.epochFormula*evt.epochData;
            epochLatBeg = round((evt.epochRange(1)-evt.epochLimits(1))/diff(evt.epochLimits)*(length(epochDiff)-1))+1;
            epochLatEnd = round((evt.epochRange(2)-evt.epochLimits(1))/diff(evt.epochLimits)*(length(epochDiff)-1))+1;
            epochDiffLat = mean(epochDiff(epochLatBeg:epochLatEnd));
            epochFeedback = epochDiffLat; % FEEDBACK
            if verbose, fprintf('Epoch feedback to send: %1.4f\n',  epochDiffLat); end
        end
    else
        evt.epochSpacing = evt.epochSpacing+1;
    end
    
end

