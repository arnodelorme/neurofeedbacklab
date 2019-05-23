psychoToolbox  = true; % Toggle to false for testing without psych toolbox
adrBoard       = false; % Toggle to true if using ADR101 board to send events to the
                        % EEG amplifier

lsltype = ''; % put to empty if you cannot connect to your system
lslname = 'EEG-DK-D0OD'; % this is the name of the stream that shows in Lab Recorder
              % if empty, it will only use the type above
              % USE lsl_resolve_byprop(lib, 'type', lsltype, 'name',
              % lslname) to connect to the stream. If you cannot connect
              % nfblab won't be able to connect either.

% sessions parameters
baselineSessionDuration = 60; % duration of baseline in second (the baseline is used
                              % to train the artifact removal ASR function)
sessionDuration = 60*5; % regular sessions - here 5 minutes
ntrials = 8; % number of trials per day
ndays   = 8; % number of days of training
              
% data acquisition parameters
nchans  = 8; % number of channels with data
chans   = 1:8; % indices of channels with data
mask    = [1;0;0;0;0;0;0;0]; % spatial filter for feedback (here used channel 1)

% data processing parameters
srateHardware = 512; % sampling rate of the hardware
srate         = 256; % sampling rate for processing data (must divide srateHardware)
windowSize = 256;    % length of window size for FFT (if equal to srate then 1 second)
nfft       = 256;    % length of FFT - allows FFT padding if necessary
windowInc  = 64;     % window increment - in this case update every 1/4 second

% feedback parameters
theta          = [3.5 6.5]; % Frequency range of interest. This program does
                            % not allow inhibition at other frequencies
                            % although it could be modified to do so
maxChange      = 0.05;      % Cap for change in feedback between processed 
                            % windows every 1/4 sec. feedback is between 0 and 1
                            % so this is 5% here
dynRange       = [16 29];   % Initial power range in dB
dynRangeInc    = 0.0333;    % Increase in dynamical range in percent if the
                            % power value is outside the range (every 1/4 sec)
dynRangeDec    = 0.01;      % Decrease in dynamical range in percent if the
                            % power value is within the range (every 1/4 sec)
                            