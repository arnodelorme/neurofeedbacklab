These are the different instalation steps.

# Installs
- On a Windows computer
- Install Matlab. You may use a student version of Matlab.
- Install BCILAB https://github.com/sccn/BCILAB and add to Matlab path (go to the root folder and type "bcilab")
- Install the Psychophysics toolbox http://psychtoolbox.org/download/ (select download ZIP file) (go to the root folder and type "PsychDefaultSetup(2)")
- Install the Lab Streaming Layer https://github.com/sccn/labstreaminglayer binaries. **Do not clone the project or download the zip for the Github project**. Instead use the binary repository (ftp://sccn.ucsd.edu/pub/software/LSL/). Download ZIP files for the *labrecorder* (App folder), the program that can interface your EEG system (App folder - for example *Biosemix.xx.zip* if you have a BIOSEMI system) and all the LSL librairies (SDK folder *liblsl-ALL-languages-x.xx.zip*). Familiarize yourself with LSL. You need to be able to connect to your EEG hardware and use the LabRecorder to save data from your hardware, then open and inspect that data under the EEGLAB software (for example). When ready, add the path to Matlab driver to your Matlab path (*liblsl-All-Languages-x.xx/liblsl-Matlab* folder).

# Computer settings
- Set up your screen resolution and screen settings. This program is made to be run on 2 screens, one screen for the subject and one screen for the expertimenter. For technical reasons, it is always better to set your primary screen as the screen for the subject (otherwise the psychophysics toolbox might not work properly).
- Disable visual buffering in Matlab. Create an icon on the desktop for Matlab. Look at properties - compatibility tab. Disable "Desktop composition" and "Disable display scaling on high DPI setttings".
- Go to your graphic card properties (display settings and select your graphic card). If you do not have graphic properties, then do not worry about this step. Disable tripple buferring, double buffering and any other fancy option (3-D etc...).

# Program settings
Program settings are contained in the file nfblab_option.m, the content of which is copied below

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
                            
