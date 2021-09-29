% *************************************
%
% MAIN SETTNGS BELOW FOR NFBLAB_PROCESS
%
% *************************************
%

% LSL parameters
% --------------
p = fileparts(which('nfblab_options.m'));
g.input.streamFile = fullfile(p, 'eeglab_data.set'); % if not empty stream a file instead of using LSL
g.input.streamFile = ''; % if not empty stream a file instead of using LSL
g.input.lsltype = 'EEG'; % use empty if you cannot connect to your system
g.input.lslname = ''; % this is the name of the stream that shows in Lab Recorder
g.input.srateHardware = 250; % sampling rate of the hardware
% lslname = 'WS-default'; % this is the name of the stream that shows in Lab Recorder
              % if empty, it will only use the type above
              % USE lsl_resolve_byprop(lib, 'type', lsltype, 'name', lslname) 
              % to connect to the stream. If you cannot connect
              % nfblab won't be able to connect either.
g.input.chans         = [1:4]; % indices of data channels
g.input.chanmask      = zeros(1,4); chanmask(1) = 1; % spatial filter for feedback (channel 1 here)
g.input.srate         = 250; % sampling rate for processing data (must divide srateHardware)
g.input.windowSize    = 250; % length of window size for FFT (if equal to srate then 1 second)
g.input.windowInc     = 75;  % window increment - in this case update every 0.3 second

% data acquisition parameters
% ---------------------------

% session parameters (use montage section later in this script to tune parameters)
% --------------------------
g.session.runmode       = 'slave';
g.session.warnsrate     = false; % issue warning when actual sampling rate differs from the one above
g.session.TCPIP         = false;   % send feedback to client through TCP/IP socket
g.session.TCPport       = 9789;
g.session.pauseSecond    = 0.2;  % pause between each loop (to give the time for LSL to acquire data) could be 0 but then filtering is applied on each sample potentially slowing down computation
g.session.baselineSessionDuration = 60; % duration of baseline in second (the baseline is used to train the artifact removal ASR function)
g.session.sessionDuration = 60*60; % regular (trial) sessions - here 1 hour
% sessions parameters for baseline and actual session in second
% baseline only need to be run once to set ASR filter parameters
% if not using ASR, baseline can be skipped

% data filtering, see more filter settings at the end of this file
% ----------------------------------------------------------------
g.preproc.filtFlag = false; % filter data true or false
g.preproc.averefFlag = false; % compute average reference before chanmask below
g.preproc.asrFlag  = true;  % use Artifact Subspace Reconstruction using baseline calibration data
g.preproc.icaFlag  = false;

% measure parameters
% -------------------
g.measure.nfft           = 250; % length of FFT - allows FFT padding if necessary
g.measure.freqrange      = { [3.5 6.5] }; % Frequency ranges of interest
g.measure.freqdb         = true;  % convert power to dB                  
g.measure.freqprocess.thetaChan1 = @(x)x; % identity simply use theta power of the unique selected channel    
g.measure.loretaFlag = false;
g.measure.loreta_file = '';

% feedback parameters
% -------------------
g.feedback.capdBchange    = [10];      % Maximum dB change from one block to the next           
                            % Set to 1000 to disable feature
g.feedback.feedbackMode = 'dynrange'; % see below

% feedbackMode = 'threshold';
% parameters for threshold change. The threshold mode simply involve
% activity going above or below a threshold and parameter for how this
% threshold evolve. The output is binary
g.feedback.threshold = 10; % intial value for threshold
g.feedback.thresholdMem  = 0;    % i.e. new_threshold = current_value * 0.25 + old_threshold * 0.75
g.feedback.thresholdWin  = 180;  % window to compute threshold in second, use NaN if you do not want to use a window
g.feedback.thresholdPer  = 0.8;  % set threshold to percentage of value in the window above
g.feedback.thresholdMode = 'go'; % can be 'go' (1 when above threshold, 0 otherwise) or 'stop' (1 when below threshold, 0 otherwise)

% feedbackMode = 'dynrange';
% parameters for dynamic range change. In this mode, the output is continuous
% between 0 and 1 (position in the range). Parameters control how the range
% change
g.feedback.maxChange      = 0.05;      % Cap for change in feedback between processed, windows every 1/4 sec. feedback is between 0 and 1, so this is 5% here
g.feedback.dynRange       = [16 29];   % Initial power range in dB
g.feedback.dynRangeInc    = 0.0333;    % Increase in dynamical range in percent if the, power value is outside the range (every 1/4 sec)
g.feedback.dynRangeDec    = 0.01;      % Decrease in dynamical range in percent if the, power value is within the range (every 1/4 sec)
        
% visual feedback or output
% -------------------------
g.feedback.psychoToolbox  = false;  % Toggle to false for testing without psych toolbox
g.feedback.simplePlot     = true;   % Simple plot of spectral power
                            
% ***************************
%
% MORE ADVANCED SETTNGS BELOW
%
% ***************************

% input and output file name
g.session.fileNameAsr = sprintf('asr_filter_%s.mat',  datestr(now, 'yyyy-mm-dd_HH-MM'));
g.session.fileNameOut = sprintf('data_nfblab_%s.mat',  datestr(now, 'yyyy-mm-dd_HH-MM'));
g.session.fileNameAsrDefault = g.session.fileNameAsr;

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
if true %g.preproc.filtFlag
    nyq      = g.input.srateHardware/2; % Nyquist frequency
    hicutoff = 1;      % low cutoff
    trans_bw = 0.5;    % transition bandwidth
    rp=0.05;           % Ripple in the passband 0.0025
    rs=20;             % Ripple in the stopband 40
    ws=(hicutoff-trans_bw)/nyq;
    wp=(hicutoff)/nyq;
    [N,wn] = ellipord(wp,ws,rp,rs);
    fprintf('HPF has cutoff of %1.1f Hz, transition bandwidth of %1.1f Hz and its order is %1.1f\n',hicutoff, trans_bw,N);
    [g.preproc.B,g.preproc.A]=ellip(N,rp,rs,wn, 'high');
end

if ~isdeployed
    nfblabPath = fileparts(which('nfblab_options.m'));
    addpath(fullfile(nfblabPath, 'misc')); % for asr_calibrate
    addpath(fullfile(nfblabPath, 'liblsl-Matlab'));
    addpath(fullfile(nfblabPath, 'liblsl-Matlab', 'bin'));
    addpath(fullfile(nfblabPath, 'asr-matlab-2012-09-12')); % not required if copied the files above
end
