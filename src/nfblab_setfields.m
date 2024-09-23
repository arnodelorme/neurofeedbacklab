% This function contains all the default parameters
% Use
% nfblab_process('help', true)

function g = nfblab_setfields(g, varargin)

% measure parameters
% -------------------
% allow field set to empty if they do not exist
allowedFields = { 
    'session'   'runmode'        ''     '"baseline" to record a baseline "trial" for normal feedback, "slave" when controled through TCPIP or empty to query user.';
    'session'   'warnsrate'      false  'Issue warning when actual sampling rate differs from the stream (0 or 1).';
    'session'   'fileNameAsr'    ''     'ASR file name.';
    'session'   'fileNameOut'    ''     'Name of the output Matlab file.';
    'session'   'fileNameRaw'    ''     'Name of the raw data file.';
    'session'   'fileNameAsrDefault' '' '';
    'session'   'TCPIP'          false  'Send feedback to client through TCP/IP socket (0 for false, 1 for true).';
    'session'   'TCPport'        9789   'Port to use to connect through TCP/IP.';
    'session'   'pauseSecond'    []     'Pause between each loop (to give the time for LSL to acquire data). If 0 (no pause) very small data chucks are processed, slowing down computation. Default is to calculated from sampling rate.';
    'session'   'baselineSessionDuration' 60 'Duration of baseline in second (the baseline is used to train the artifact removal ASR function).';
    'session'   'sessionDuration' 60*60 'Regular (trial) sessions in seconds.';
    'session'   'help'            false  'Show help message (0 for false, 1 for true).';
    'session'   'checkglobalmsg'  ''     'Variable name in global workspace to check for message. Used for GUI interaction.';
    ...
    'input'     'streamFile'     ''      'If not empty stream a file instead of using LSL.';
    'input'     'lsltype'        'EEG'   'This is the type of the LSL stream. Use empty if you cannot connect to your hardware.';
    'input'     'lslname'        ''      'This is the name of the stream that shows in Lab Recorder.';
    'input'     'chans'          []      'Indices of data channels to process. Default is [] or all.';
    'input'     'srate'          250     'Sampling rate';
    'input'     'chanlocs'       []      'Optional channel location for bad channel rejection and ICLabel';
    'input'     'srateHardware'  ''      'Sampling rate of the hardware (will default to sampling rate above if empty). Use a multiple to downsample the data (e.g. with 500, every other sample is ignored).';
    'input'     'windowSize'     []      'Length of window size for FFT (by default empty and set equal to srate, so 1 second).';
    'input'     'windowInc'      0.25    'Window increment/frequency of feedback in fraction of second or samples, default is 0.25 second.';
    'input'     'chanmask'       []      'Spatial filter for feedback (one row per channel). For example [1 -1; 0 0] will compute channel 1 minus 2. Default is "eye" or square matrix with ones on the diagonal ([1 0; 0 1] for 2 channels).';
    'input'     'chanlabels'     ''      '';
    ...
    'preproc'   'subFirstSample' false   'Subtract first sample to avoid ripples at the beggining of the data';
    'preproc'   'precision'      'double' 'Data precision, single or double (some non-linear filters require double precision to be stable)';
    'preproc'   'filtFlag'       true    'Filter data (true or false)';
    'preproc'   'badchanFlag'    false   'Bad channel detection and interpolation (true or false). Require baseline file.';
    'preproc'   'A'              []      '';
    'preproc'   'B'              []      '';
    'preproc'   'asrFlag'        false   'Use Artifact Subspace Reconstruction using baseline calibration data  (true or false). Require baseline file.';
    'preproc'   'asrCutoff'      20      'ASR BurstCriterion cut off value';
    'preproc'   'icaFlag'        false   'ICA flag to run ICA and automatically reject components (true or false). Require baseline file.';
    'preproc'   'averefFlag'     false   'Compute average reference (true or false). Default is false but forced to true if eLoreta is used';
    'preproc'   'chanCorr'       0.65    'Minimum channel correlation ChannelCriterion for rejecting bad channels. Require baseline file.';
    'preproc'   'badChans'       []      '';     % indices of bad channels, overwriten by baseline file when badchanFlag is true.
    ...
    'measure'   'freqrange'      { [3.5 6.5] } 'Frequency ranges of interest.';
    'measure'   'freqdb'         true      'Convert power to dB scale (true or false).'; % convert power to dB
    'measure'   'freqprocess'    struct('thetaChan1', @(x)x(1)) 'Structure with function in each field. Default is theta power of channel 1.';
    'measure'   'addfreqprocess' ''        '';
    'measure'   'loretaFlag'     false     'Flag to compute eLoreta (beta).';
    'measure'   'loreta_file'    ''        'Loreta file to provide as input.';
    'measure'   'freqloreta'     []        'Function to compute Loreta.';
    'measure'   'normfile'       ''        'File containing normative value per age range.';
    'measure'   'normagerange'   []        'Age range of the person being tested.';
    'measure'   'evt'            ''        '';
    'measure'   'nfft'           []        'Length of FFT - allows FFT padding if necessary.';
    'measure'   'connectprocess' []        'Structure with function in each field.';
    'measure'   'preset'         'default' 'Preset type of feedback, ''default'' is theta, ''allfreqs'' is all frequencies for all channels.';
    ...
    'feedback'  'feedbackMode'   'dynrange' '"bounded" for 0 to 1 output, "dynrange" for dynamic continuous range or "threshold" for crossing threshold mode.';
    'feedback'  'initialvalue'   1         'Initial value for feedback';
    'feedback'  'threshold'      ''        'Threshold value at startup';
    'feedback'  'thresholdMem'   ''        'Threshold memory. A memory of 75% is new_threshold = current_value * 0.25 + old_threshold * 0.75.';
    'feedback'  'thresholdMode'  'go'      'Can be "go" (1 when above threshold, 0 otherwise) or "stop" (1 when below threshold, 0 otherwise).';
    'feedback'  'thresholdWin'   180       'Window to compute threshold in second, use NaN if you do not want to use a window.';
    'feedback'  'thresholdPer'   0.8       'Set threshold to percentage of value in the window above.';
    'feedback'  'boundedfactorh' 0.6       'Memory of previous feedback if cdf of z-score (betwoeen 0 and 1) is above previous feedback (use 0 for no memory)';
    'feedback'  'boundedfactorl' 0.6       'Memory of previous feedback if cdf of z-score (betwoeen 0 and 1) is below previous feedback';
    'feedback'  'boundedfactorinc' 0       'Bias factor to increase values toward 1 (use 0 for no bias)';
    'feedback'  'boundedgamma'   0.5       'Gamma correction to apply to final output value (use 1 for no correction)';
    'feedback'  'dynRange'       [16 29]   'Power range at startup in dB.';
    'feedback'  'dynRangeInc'    0.0333    'Increase in dynamical range in percent if the, power value is outside the range (every window increment).';
    'feedback'  'dynRangeDec'    0.01      'Decrease in dynamical range in percent if the, power value is outside the range (every window increment).';
    'feedback'  'maxChange'      0.05      'Cap for change in feedback between processed, windows every 1/4 sec. Dynamic range only. Feedback is between 0 and 1, so this is 5% here.';    
    'feedback'  'capdBchange'    1000      'Maximum dB change from one block to the next for the raw spectral value used to compute feedback. 1000 means disabled.';
    'feedback'  'feedbackfield'  ''        'Field to use for feedback (see freqprocess output; default is to use the first field of the freqprocess output).';
    'feedback'  'diary'          ''        'Field to save the log.';
    'feedback'  'funcinit'       ''        'Feedback output initialization function.';
    'feedback'  'funcfeedback'   'nfblab_feedback_simpleplot'        'Feedback output (audio, visualization) function (takes one feedback parameter as input). Default is to plot power.';
    'feedback'  'funcend'        ''        'Feedback output termination function.';
    'feedback'  'simplePlot'     true      ''; % legacy
    ...
    'custom'    'field'          ''        ''
    'custom'    'func'           ''        ''
    };

if ~isfield(g, 'session'),  g.session = []; end
if ~isfield(g, 'input'),    g.input = []; end
if ~isfield(g, 'preproc'),  g.preproc = []; end
if ~isfield(g, 'measure'),  g.measure = []; end
if ~isfield(g, 'feedback'), g.feedback = []; end
if ~isfield(g, 'custom'),   g.custom = []; end

% check for missing fields
for iField = 1:length(allowedFields)
    if ~isfield(g.(allowedFields{iField,1}), allowedFields{iField,2})
        g.(allowedFields{iField,1}).(allowedFields{iField,2}) = allowedFields{iField,3};
    end
end

% decode input parameters and overwrite defaults
options = varargin;
for iOpt = 1:length(options)
    if iscell(options{iOpt})
        options{iOpt} = options(iOpt);
    end
end
% find duplicate and keep the last one
options = removedup(options);
params = struct(options{:});
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
        if ~contains(paramsFields{iField}, 'custom')
            if ~isempty(g.custom.field) && isequal(paramsFields{iField}, g.custom.field)
                disp('Custom field detected, ignoring its content')
            else
                error('Unknown option %s', paramsFields{iField})
            end
        else
            g.custom.(paramsFields{iField}) = params.(paramsFields{iField});
        end
    end
end

% dynamical default
% -----------------
if ~isempty(g.input.streamFile) && isstruct(g.input.streamFile) && isfield(g.input.streamFile, 'srate')
    fprintf(2, 'Overwriting sampling rate with the sampling rate of the file\n');
    g.input.srate = g.input.streamFile.srate;
end
if isempty(g.measure.nfft)        g.measure.nfft = g.input.srate; end
if isempty(g.input.windowSize)    g.input.windowSize = g.input.srate; end
if isempty(g.input.srateHardware) g.input.srateHardware = g.input.srate; end
if g.input.windowInc < 1 % fraction of second, convert to samples
	g.input.windowInc  = round(g.input.windowSize*g.input.windowInc); 
end
if isempty(g.session.pauseSecond)
    if isempty(g.input.streamFile)
        g.session.pauseSecond = g.input.windowInc/g.input.windowSize*0.52; % pause for half a window increment
    else
        g.session.pauseSecond = 0;
    end
end
if isempty(g.session.fileNameAsr),        g.session.fileNameAsr        = sprintf('data_nfblab_%s_asr_filter.mat',  datestr(now, 'yyyy-mm-dd_HH-MM')); end
if isempty(g.session.fileNameOut),        g.session.fileNameOut        = sprintf('data_nfblab_%s.mat', datestr(now, 'yyyy-mm-dd_HH-MM')); end
if isempty(g.session.fileNameRaw),        g.session.fileNameRaw        = sprintf('data_nfblab_%s_raw.set', datestr(now, 'yyyy-mm-dd_HH-MM')); end
if isempty(g.session.fileNameAsrDefault), g.session.fileNameAsrDefault = sprintf('data_nfblab_%s_asr_filter.mat',  datestr(now, 'yyyy-mm-dd_HH-MM')); end
if isempty(g.input.chanmask), g.input.chanmask = 1; end
if ~isempty(g.measure.freqprocess) && isempty(g.feedback.feedbackfield), tmpFields = fieldnames(g.measure.freqprocess); g.feedback.feedbackfield = tmpFields{end}; end

% load normalization file
if ischar(g.measure.normfile) && ~isempty(g.measure.normfile)
    g.measure.normfile = load('-mat', g.measure.normfile);
    fields = fieldnames(g.measure.normfile);
    if length(fields) == 1 && isstruct(g.measure.normfile.(fields{1}))
        g.measure.normfile = g.measure.normfile.(fields{1});
    end
end

% check field compatibility
if ~g.session.TCPIP && strcmpi(g.session.runmode, 'slave')
    g.session.runmode = [];
end
if g.preproc.asrFlag 
    disp('Note: default ASR instroduces a delay - in our experience 1/4 second)');
end

% ask for the type of session
if isempty(g.session.runmode) && ~g.session.help
    g.session.TCPIP = false;
    s = input('Do you want to run a baseline now (y/n)?', 's');
    if strcmpi(s, 'y'), g.session.runmode = 'baseline';
    elseif strcmpi(s, 'n'), g.session.runmode = 'trial';
    else error('Unknown option');
    end
end

if strcmpi(g.measure.preset, 'default')
elseif strcmpi(g.measure.preset, 'allfreqs')
    g.measure.freqrange      = {};
    g.measure.freqprocess    = [];
    for iFreq = 1:30
        g.measure.freqrange{iFreq} = [iFreq-0.5 iFreq+0.49999999];
        g.measure.freqprocess.(sprintf('f%d', iFreq)) = eval(sprintf('@(x)x(:,%d);', iFreq));
    end
    g.feedback.feedbackfield = '';
else
    error('Unknown preset computation');
end

% fir filter below (preserve phase but long delay)
% minimum phase filter (which are usefull in realtime 
% applications, can be designed using
% BCILAB or FIRFILT plugin for EEGLAB
% -----------------------------------
if 0
    cutoff = 1; % 1 Hz
    df = 4;     % transition bandwidth (this makes the filter relatively short)
    m  = firwsord('hamming', srateHardware, df); 
    fprintf('Filter delay: %d samples or %1.1f second\n', ceil((m+1)/2), ceil((m+1)/2)/srateHardware);
    B  = firws(m, cutoff / (srate / 2), 'high', windows('hamming', m + 1));
    A  = 1;
end

% elipical filter (short delay but phase distortion - phase distortion does not matter much here
% since we are only computing power - except for potential delays)
if isempty(g.preproc.A) %g.preproc.filtFlag
    nyq      = g.input.srate/2; % Nyquist frequency
    hicutoff = 1;      % low cutoff
    trans_bw = 0.5;    % transition bandwidth
    rp=0.05;           % Ripple in the passband 0.0025
    rs=20;             % Ripple in the stopband 40
    ws=(hicutoff-trans_bw)/nyq;
    wp=(hicutoff)/nyq;
    [N,wn] = ellipord(wp,ws,rp,rs);
    if ~g.session.help
        fprintf('HPF has cutoff of %1.1f Hz, transition bandwidth of %1.1f Hz and its order is %1.1f\n',hicutoff, trans_bw,N);
    end
    [g.preproc.B,g.preproc.A]=ellip(N,rp,rs,wn, 'high');
end

% Print options on command line
% -----------------------------
currentHead = '';
for iField = 1:length(allowedFields)
    curVal = g.(allowedFields{iField,1}).(allowedFields{iField,2});
    if ~isequal(currentHead, allowedFields{iField,1}) && ~isequal( allowedFields{iField,1}, 'custom')
        currentHead = allowedFields{iField,1};
        header = sprintf('* %s parameters *', currentHead);
        footer = char(ones(1,length(header))*42);
        fprintf('%s\n%s\n%s\n', footer, header, footer);
    end
    if g.session.help
        if ~isempty(allowedFields{iField,4})
            if ~isempty(allowedFields{iField,3})
                strval = vararg2str(allowedFields{iField,3});
            elseif isnumeric(allowedFields{iField,3})
                strval = '[]';
            else
                strval = '''''';
            end
            fprintf('    %-24s %s Default value is %s.\n', allowedFields{iField,2}, allowedFields{iField,4}, strval);
        end
    else
        if strcmpi(allowedFields{iField,2}, 'streamFile')
            if ~isempty(curVal)
                fprintf('    %-24s %s\n', allowedFields{iField,2}, 'File or data provided as input' );
            end
        elseif strcmpi(allowedFields{iField,2}, 'freqprocess') || strcmpi(allowedFields{iField,2}, 'connectprocess') || strcmpi(allowedFields{iField,2}, 'freqloreta')
            if ~isempty(curVal)
                fprintf('    %-24s %d functions to compute on frequencies provided\n', allowedFields{iField,2}, length(fieldnames(curVal)) );
            end
        elseif ~isempty(allowedFields{iField,4})
            fprintf('    %-24s %s\n', allowedFields{iField,2}, vararg2str(curVal));
        end
    end
end
if g.session.help
    g = [];
end

if ~isdeployed
    nfblabPath = fileparts(which('nfblab_setfields.m'));
    % addpath(fullfile(nfblabPath, 'misc')); % for asr_calibrate
    addpath(fullfile(nfblabPath, 'liblsl-Matlab'));
    addpath(fullfile(nfblabPath, 'liblsl-Matlab', 'bin'));
    % addpath(fullfile(nfblabPath, 'asr-matlab-2012-09-12')); % not required if copied the files above
end

% remove duplicates in the list of parameters
% -------------------------------------------
function cella = removedup(cella)
    allFields = cella(1:2:end);
    [tmp, indices, X] = unique_bc(allFields);
    if length(tmp) ~= length(allFields)
        Y = hist(X,unique(X));
        fieldDuplicates = allFields(Y > 1);
        fprintf(2,'Warning: duplicate ''%s'' parameter(s), keeping the last one(s)\n', fieldDuplicates{1});
    end
    cella = cella(sort(union(indices*2-1, indices*2)));