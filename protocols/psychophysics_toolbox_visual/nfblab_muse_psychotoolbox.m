% Run nfblab for MUSE using psychotoolbox for visual feedback
% The psychophysics toolbox need to be installed
% The color of a square changes based on theta power
% -------------------------------------------------------
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
    'feedbackMode'           'dynrange' ...
    'funcinit'               'nfblab_feedback_psychootoolbox_init' ...
    'funcfeedback'           'nfblab_feedback_psychootoolbox_process' ...
    'funcend'                'nfblab_feedback_psychootoolbox_end' ...
    };

nfblab_process(options{:});