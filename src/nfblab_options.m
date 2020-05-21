% *************************************
%
% MAIN SETTNGS BELOW FOR NFBLAB_PROCESS
%
% *************************************
runmode = 'slave';

% LSL parameters
% --------------
p = fileparts(which('nfblab_options.m'));
streamFile = fullfile(p, 'eeglab_data.set'); % if not empty stream a file instead of using LSL
lsltype = 'EEG'; % use empty if you cannot connect to your system
lslname = ''; % this is the name of the stream that shows in Lab Recorder
% lslname = 'WS-default'; % this is the name of the stream that shows in Lab Recorder
              % if empty, it will only use the type above
              % USE lsl_resolve_byprop(lib, 'type', lsltype, 'name', lslname) 
              % to connect to the stream. If you cannot connect
              % nfblab won't be able to connect either.
pauseSecond    = 0.2;  % pause between each loop (to give the time for LSL to acquire data)
                        % could be 0 but then filtering is applied on each
                        % sample potentially slowing down computation

% sessions parameters for baseline and actual session in second
% baseline only need to be run once to set ASR filter parameters
% if not using ASR, baseline can be skipped
% -----------------------------------------
baselineSessionDuration = 60; % duration of baseline in second (the baseline is used
                              % to train the artifact removal ASR function)
sessionDuration = 60*0.5; % regular (trial) sessions - here 5 minutes

% data acquisition parameters
% ---------------------------
chans      = [1:4]; % indices of data channels
averefflag = false; % compute average reference before chanmask below
chanmask = zeros(1,4); chanmask(1) = 1; % spatial filter for feedback (channel 1 here)
eLoretaFlag = false;

% data processing parameters (use montage section later in this script to tune parameters)
% --------------------------
srateHardware = 250; % sampling rate of the hardware
srate         = 250; % sampling rate for processing data (must divide srateHardware)
windowSize    = 250; % length of window size for FFT (if equal to srate then 1 second)
nfft          = 250; % length of FFT - allows FFT padding if necessary
windowInc     = 75;  % window increment - in this case update every 0.3 second
warnsrate     = false; % issue warning when actual sampling rate differs from the one above

% data filtering, see more filter settings at the end of this file
% ----------------------------------------------------------------
filtFlag = false; % filter data true or false
asrFlag  = true;  % use Artifact Subspace Reconstruction using baseline calibration data

% feedback parameters
% -------------------
freqrange      = { [3.5 6.5] }; % Frequency ranges of interest
freqdb         = true;  % convert power to dB                  
freqprocess.thetaChan1 = @(x)x; % identity simply use theta power of the unique selected channel                          
capdBchange    = [10];      % Maximum dB change from one block to the next           
                            % Set to 1000 to disable feature
feedbackMode = 'dynrange'; % see below

% feedbackMode = 'threshold';
    % parameters for threshold change. The threshold mode simply involve
    % activity going above or below a threshold and parameter for how this
    % threshold evolve. The output is binary
    threshold = 10; % intial value for threshold
    thresholdMem = 0.75; % i.e. new_threshold = current_value * 0.25 + old_threshold * 0.75 
    thresholdMode = 'go'; % can be 'go' (1 when above threshold, 0 otherwise) 
                          % or 'stop' (1 when below threshold, 0 otherwise) 

% feedbackMode = 'dynrange';
    % parameters for dynamic range change. In this mode, the output is continuous
    % between 0 and 1 (position in the range). Parameters control how the range
    % change
    maxChange      = 0.05;      % Cap for change in feedback between processed 
                                % windows every 1/4 sec. feedback is between 0 and 1
                                % so this is 5% here
    dynRange       = [16 29];   % Initial power range in dB
    dynRangeInc    = 0.0333;    % Increase in dynamical range in percent if the
                                % power value is outside the range (every 1/4 sec)
    dynRangeDec    = 0.01;      % Decrease in dynamical range in percent if the
                                % power value is within the range (every 1/4 sec)
        
% visual feedback or output
% -------------------------
psychoToolbox  = false;  % Toggle to false for testing without psych toolbox
adrBoard       = false;  % Toggle to true if using ADR101 board to send events to the
                         % EEG amplifier
TCPIP          = true;  % send feedback to client through TCP/IP socket
TCPport        = 9789;
TCPformat      = 'json'; % 'binstatechange' send state change only (when above of below threshold)
                         % 'json' sends a json strings with more information
                            
% ***************************
%
% MORE ADVANCED SETTNGS BELOW
%
% ***************************

% input and output file name
fileNameAsr = sprintf('asr_filter_%s.mat',  datestr(now, 'yyyy-mm-dd_HH-MM'));
fileNameOut = sprintf('data_nfblab_%s.mat',  datestr(now, 'yyyy-mm-dd_HH-MM'));
defaultNameAsr = fileNameAsr;

% meta-parameters not used by nfblab_process (used by nfblab_run)
ntrials = 8; % number of trials per day
ndays   = 8; % number of days of training

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
if filtFlag
    nyq      = srateHardware/2; % Nyquist frequency
    hicutoff = 1;      % low cutoff
    trans_bw = 0.5;    % transition bandwidth
    rp=0.05;           % Ripple in the passband 0.0025
    rs=20;             % Ripple in the stopband 40
    ws=(hicutoff-trans_bw)/nyq;
    wp=(hicutoff)/nyq;
    [N,wn] = ellipord(wp,ws,rp,rs);
    fprintf('HPF has cutoff of %1.1f Hz, transition bandwidth of %1.1f Hz and its order is %1.1f\n',hicutoff, trans_bw,N);
    [B,A]=ellip(N,rp,rs,wn, 'high');
end

% path to BCILAB toolbox 
% if it cannot be found, try to infer it
BCILABpath     = 'Z:\data\matlab\BCILAB'; 
if ~isdeployed
    if ~exist(BCILABpath, 'dir')
        p = fileparts(which('nbflab_options'));
        BCILABpath = fullfile(p, '..', 'BCILAB');
        if ~exist(BCILABpath, 'dir')
            BCILABpath = fullfile(p, '..', '..', 'BCILAB');
            if ~exist(BCILABpath, 'dir')
               error('Cannot find BCILAB - set path manually in file nfblab_options.m');
            end
        end
    end

    addpath(fullfile(BCILABpath, 'code', 'misc')); % for asr_calibrate
    addpath(fullfile(BCILABpath, 'dependencies', 'liblsl-Matlab'));
    addpath(fullfile(BCILABpath, 'dependencies', 'liblsl-Matlab', 'bin'));
    addpath(fullfile(BCILABpath, 'dependencies', 'liblsl-Matlab', 'mex', 'build-Christian-PC')); % PC
    addpath(fullfile(BCILABpath, 'dependencies', 'liblsl-Matlab', 'mex', 'build-seeding.ucsd.edu')); % Mac
    addpath(fullfile(BCILABpath, 'dependencies', 'liblsl-Matlab', 'mex', 'build-Jordan')); % Ubuntu
    addpath(fullfile(BCILABpath, 'dependencies', 'liblsl-Matlab', 'mex', 'build-juggling-0-1.local')); % Ubuntu
    addpath(fullfile(BCILABpath, 'dependencies', 'liblsl-Matlab', 'mex', 'build-Nedas-MacBook-Pro.local'));
    addpath(fullfile(BCILABpath, 'dependencies', 'asr-matlab-2012-09-12')); % not required if copied the files above
end
