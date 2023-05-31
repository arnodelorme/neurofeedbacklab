% Run nfblab for an old MUSE device 
% You device needs to stream on LSL
% ---------------------------------
addpath(fullfile(pwd, '..','..'));

options = { ...
    'chans'                  [1:4] ...
    'chanmask'               eye(4) ...
    'srate'                  250 ...
    'runmode'               'trial' ...
    'pauseSecond'            0.2 ...
    'badchanFlag'            false ...
    'icaFlag'                false ...
    'asrFlag'                false ...
    'freqrange'              { [4 8] [8 12] [8 10] [10 12] [18 22] [4 10] [12 15] [20 30] } ...
    'simplePlot'             true ...
    'feedbackMode'           'dynrange' };

nfblab_process(options{:});