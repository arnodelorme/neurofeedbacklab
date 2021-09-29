function g = nfblab_setfields(g, varargin)


% allow field set to empty if they do not exist
allowedFields = { 
    'session'   'runmode'; 
    'session'   'fileNameAsr';
    'session'   'fileNameOut';
    'session'   'fileNameRaw';
    'session'   'TCPIP';
    'session'   'pauseSecond';
    ...
    'input'     'streamFile';
    'input'     'lsltype';
    'input'     'lslname';
    'input'     'chans';
    'input'     'chanmask';
    'input'     'chanlabels';
    ...
    'preproc'   'filtFlag';
    'preproc'   'asrFlag';
    'preproc'   'icaFlag';
    'preproc'   'averefFlag';
    ...
    'measure'   'freqrange';
    'measure'   'freqdb';
    'measure'   'freqprocess';
    'measure'   'addfreqprocess';
    'measure'   'loreta_flag';
    'measure'   'loretaFlag';
    'measure'   'normfile';
    'measure'   'evt';
    ...
    'feedback'  'threshold';
    'feedback'  'thresholdMem';
    'feedback'  'thresholdMode';
    'feedback'  'maxChange';
    'feedback'  'dynRange';
    'feedback'  'dynRangeDec';
    'feedback'  'dynRangeInc';
    'feedback'  'capdBchange';
    'feedback'  'feedbackMode';
    'feedback'  'thresholdPer';
    'feedback'  'thresholdWin' };

% check for missing fields
for iField = 1:length(allowedFields)
    if ~isfield(g.(allowedFields{iField,1}), allowedFields{iField,2})
        g.(allowedFields{iField,1}).(allowedFields{iField,2}) = '';
    end
end

% decode input parameters and overwrite defaults
params = struct(varargin{:});
paramsFields = fieldnames(params);
for iField = 1:length(paramsFields)
    posInd = strmatch(paramsFields{iField}, allowedFields(:,2), 'exact');
    if ~isempty(posInd)
        if length(posInd) == 1
            g.(allowedFields{posInd,1}).(allowedFields{posInd,2}) = params.(paramsFields{iField});
            
            % renamed field
            if isequal(paramsFields{iField}, 'loreta_flag')
                g.measure.loretaFlag = g.measure.loreta_flag;
            end
        else
            error('');
        end
    else
        error('Unknown option %s', paramsFields{iField})
    end
end
                
if isempty(g.measure.loretaFlag)
    g.measure.loretaFlag = 0;
end
g.measure = rmfield(g.measure, 'loreta_flag');