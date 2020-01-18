% nfblab_process() - function to perform neurofeedback using LSL steams,
%                    and the psychophysics toolbox. Support ICA component
%                    spatial filtering.
%
% Usage:
%    nfblab_process(key, val, ...)
%
% Parameters. See file nfblab_options for default values. Only the most 
% important parameters are indicated below but all parameters of this 
% file may be changed when calling the function.
%
%  'runmode' - 'trial' or 'baseline' a baseline must be run at the
%              beginning to assess baseline values and ASR rejection
%              thresholds
%  'fileNameAsr' - [string] in baseline mode, this file is writen. In trial
%              mode, it is read. Default is 'asr_baseline.mat'. Note that
%              this file might not exist if this is the first time you
%              are starting the program. In this case, you need to run 
%              baseline session first.
%  'fileNameOut' - [string] output file name. Default is
%              'session-datexxxxx.mat'. In this file all the information is
%               being saved after a session.
%  'fileNameOut' - [string] output file name. Default is
%              'session-datexxxxx.mat'. In this file all the information is
%               being saved after a session.
%  'chans'     - [array] channels to take into account. For example [1]
%               uses the first channel only (with the default reference).
%               To use a bipolar montage, select two channels here and a
%               chanmask below. To select a spatial filter such as ICA
%               select all channels and use ICA component topography as
%               mask.
%  'chanmask'  - [array] channel mask. For a bipolar montage, use [1 -1]
%               for example. For a single channel, use [1].
%  'freqrange' - [min max] frequency range in Hz. See nfblab_options for 
%               default value.

function nfblab_process(varargin)
nfblab_options;

% decode input parameters and overwrite defaults
for iArg = 1:2:length(varargin)
    if isstr(varargin{iArg+1})
        eval( [ varargin{iArg} ' = ' varargin{iArg} ] );
    else
        eval( [ varargin{iArg} ' = ' varargin{iArg} ] );
    end
end
if ~exist('runmode')
    s = input('Do you want to run a baseline now (y/n)?', 's');
    if strcmpi(s, 'y'), runmode = 'baseline';
    elseif strcmpi(s, 'n'), runmode = 'trial';
    else error('Unknown option');
    end
end
    
global serialPort;

% make sure the function can be run again
onCleanup(@() nfblab_cleanup);

if ~strcmpi(runmode, 'trial') && ~strcmpi(runmode, 'baseline') 
    error('Wrong run type')
elseif strcmpi(runmode, 'baseline')
    sessionDuration = baselineSessionDuration;
else
    if defaultNameAsr == fileNameAsr
        asrFiles = dir('asr_filter_*.mat');
        if isempty(asrFiles)
            error('No baseline file found in current folder, run baseline first');
        else
            fprintf('\nBaseline files available in current folder:\n');
            for iFile = 1:length(asrFiles)
                fprintf('%d - %s\n', iFile, asrFiles(iFile).name);
            end
            fprintf('------\n');
            iFile = input('Enter file number above to use for baseline:');
            fileNameAsr = asrFiles(iFile).name;
        end
    end
end

dataBuffer = zeros(length(chans), (windowSize*2)/srate*srateHardware);
dataBufferPointer = 1;

dataAccu = zeros(length(chans), (sessionDuration+3)*srate); % to save the data
dataAccuPointer = 1;
feedbackVal    = 0.5;       % initial feedback value

% set the paths
% addpath(fullfile(lslpath));
% addpath(fullfile(lslpath, 'bin'));
% addpath(fullfile(lslpath, 'mex'));
% addpath(fullfile(lslpath, 'mex', 'build-Christian-PC'));
% p = which('nfblab_process.m')
% addpath(fileparts(p));
% p = which('eeglab.m');
% if isempty(p)
%     error('Please install EEGLAB and start EEGLAB before calling that function');
% end
p = which('asr_process.m');
if isempty(p)
    error('Please install BCILAB and start BCILAB before calling that function');
end
% p = which('clean_artifacts.m');
% if isempty(p)
%     error('Please install clean_rawdata plugin in EEGLAB');
% end
% cd(fullfile(fileparts(p), 'private')); % we need to be in the private folder of
%                                        % clean_rawdata to access the
%                                        % functions in that folder

% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

% resolve a stream...
disp('Resolving an EEG stream...');
result = {};
result = nfblab_findlslstream(lib,lsltype,lslname);
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});
disp('Now receiving chunked data...');

% create TCP/IP socket
if TCPIP
    %kkSocket  = ServerSocket( TCPport );
    fprintf('Trying to accept connection from client (if program get stuck here, check client)...\n');
    %connectionSocket = kkSocket.accept();
end

% select calibration data
if strcmpi(runmode, 'trial')
    stateAsr = load('-mat', fileNameAsr);
    dynRange = stateAsr.dynRange;
    stateAsr = stateAsr.state;
    
    % create screen psycho toolbox
    % ----------------------------
    if psychoToolbox
        Screen('Preference', 'SkipSyncTests', 1);
        screenid = 2; % 1 = external screen
        Screen('resolution', screenid, 800, 600, 75);
        
        %imaging = kPsychNeedFastBackingStore;
        %Screen('Preference', 'VBLTimestampingMode', 1);
        displaysize=Screen('Rect', screenid);
        displaysize=[0 0 800 600];
        window=Screen('OpenWindow', 0, 255, displaysize);%, [], [], [], [], imaging);
        Screen('TextFont', window, 'Arial');
        Screen('TextSize', window, 16);
        Screen('TextStyle', window, 1);
        xpos1 = 200;
        ypos1 = 100;
        xpos2 = displaysize(3)-xpos1;
        ypos2 = displaysize(4)-ypos1;
        colArray = [ [10:250] [250:-1:128] [128:250] ];
    end
end

%EEG.icaact = [];
%disp('Training ASR, please wait...');
%stateAsr = asr_calibrate(EEG.data(:, 1:EEG.srate*60), EEG.srate);

% frequencies for spectral decomposition
freqs  = linspace(0, srate/2, floor(nfft/2));
freqs     = freqs(2:end); % remove DC (match the output of PSD)
freqRange = intersect( find(freqs >= freqrange(1)), find(freqs <= freqrange(2)) );

%% create a new inlet
tic;
totSamples = 0;
state = [];
statelp = [];
EEG = eeg_emptyset;
EEG.nbchan = length(chans);
EEG.srate  = srate;
EEG.xmin   = 0;
% tmp = load('-mat','chanlocs.mat');
% EEG.chanlocs = tmp.chanlocs;
winPerSec = windowSize/windowInc;
chunkSize = windowInc*srateHardware/srate; % at 512 so every 1/4 second is 128 samples
tic;

if adrBoard
    fwrite(serialPort, ['SPA11111111' char(13)]);
    pause(0.05);
    fwrite(serialPort, ['SPA00000000' char(13)]);
end

chunkMarker   = zeros(1, sessionDuration*10);
chunkPower    = zeros(1, sessionDuration*10);
chunkDynRange = zeros(2, sessionDuration*10);
chunkFeedback = zeros(1, sessionDuration*10);
chunkCount    = 1;

while toc < sessionDuration
    % get chunk from the inlet
    [chunk,stamps] = inlet.pull_chunk();
    
    % fill buffer
    if ~isempty(chunk) && size(chunk,2) > 1
        %fprintf('%d samples\n', size(chunk,2));

        if dataBufferPointer+size(chunk,2) > size(dataBuffer,2)
            disp('Buffer overrun');
            dataBuffer(:,dataBufferPointer:end) = chunk(chans,1:(size(dataBuffer,2)-dataBufferPointer+1));
            dataBufferPointer = size(dataBuffer,2);
        else
            dataBuffer(:,dataBufferPointer:dataBufferPointer+size(chunk,2)-1) = chunk(chans,:);
            dataBufferPointer = dataBufferPointer+size(chunk,2);
        end
    end
    
    if dataBufferPointer > chunkSize*winPerSec
        
        % Decimate
        if srateHardware == srate
            EEG.data = dataBuffer(:,1:chunkSize*winPerSec);            
        elseif srateHardware == 2*srate
            EEG.data = dataBuffer(:,1:2:chunkSize*winPerSec);
        elseif srateHardware == 4*srate
            EEG.data = dataBuffer(:,1:4:chunkSize*winPerSec);
        elseif srateHardware == 8*srate
            EEG.data = dataBuffer(:,1:8:chunkSize*winPerSec);
        else
            error('Cannot convert sampling rate');
        end
        
        % shift 1 block
        dataBuffer(:, 1:chunkSize*(winPerSec-1)) = dataBuffer(:, chunkSize+1:chunkSize*winPerSec);
        dataBufferPointer = dataBufferPointer-chunkSize;
        
        % filter data
        EEG.pnts = size(EEG.data,2);
        EEG.nchan = size(EEG.data,1);
        EEG.xmax = EEG.pnts/EEG.srate;
        %EEG = eeg_checkset(EEG);
        
        %[EEG, state] = hlp_scope({'disable_expressions',true},@flt_fir, 'signal', EEG, 'fspec', [0.5 1], 'fmode', 'highpass',  'ftype','minimum-phase', 'state', state);
        %[EEG state ] = exp_eval(flt_fir( 'signal',EEG, 'fspec', [0.9 1.1],'fmode','highpass', 'ftype','minimum-phase', 'state', state));
        
        % rereference
        %EEG.data = bsxfun(@minus, EEG.data,mean(EEG.data([24 61],:))); % P9 and P10
        if averefflag
            EEG.data = bsxfun(@minus, EEG.data,mean(EEG.data)); % average reference
        end
        
        % accumulate data if baseline mode
        if strcmpi(runmode, 'baseline')
            dataAccu(:, dataAccuPointer:dataAccuPointer+size(EEG.data,2)-1) = EEG.data;
        else
            % apply ASR and update state
            [EEG.data, stateAsr]= asr_process(EEG.data, EEG.srate, stateAsr);
            dataAccu(:, dataAccuPointer:dataAccuPointer+size(EEG.data,2)-1) = EEG.data;
        end
        dataAccuPointer = dataAccuPointer + size(EEG.data,2);
        chunkMarker(chunkCount) = dataAccuPointer;
        
        % Apply linear transformation (get channel Fz at that point)
        ICAact = chanmask*EEG.data;
        
        % Perform spectral decomposition
        % taper the data with hamming
        dataSpec = fft(ICAact .* hamming(length(ICAact)), nfft);
        dataSpec = dataSpec(freqRange);
        X        = mean(10*log10(abs(dataSpec).^2));
        chunkPower(chunkCount) = X;
        
        % compute feedback value between 0 and 1
        totalRange = dynRange(2)-dynRange(1);
        feedbackValTmp = (X-dynRange(1))/totalRange;
        if feedbackValTmp > 1, dynRange(2) = dynRange(2)+dynRangeInc*totalRange; feedbackValTmp = 1;
        else                   dynRange(2) = dynRange(2)-dynRangeDec*totalRange;
        end
        if feedbackValTmp < 0, dynRange(1) = dynRange(1)-dynRangeInc*totalRange; feedbackValTmp = 0;
        else                   dynRange(1) = dynRange(1)+dynRangeDec*totalRange;
        end
        if feedbackValTmp<feedbackVal
            if abs(feedbackValTmp-feedbackVal) > maxChange, feedbackVal = feedbackVal-maxChange;
            else                                            feedbackVal = feedbackValTmp;
            end
        else
            if abs(feedbackValTmp-feedbackVal) > maxChange, feedbackVal = feedbackVal+maxChange;
            else                                            feedbackVal = feedbackValTmp;
            end
        end
        chunkFeedback(chunkCount) = feedbackVal;
        chunkDynRange(:,chunkCount) = dynRange;
        chunkCount = chunkCount+1;
        
        if  strcmpi(runmode, 'trial')
            fprintf('Spectral power %2.3f - output %1.2f - %1.2f [%1.2f %1.2f]\n', X, feedbackVal, feedbackValTmp, dynRange(1), dynRange(2));

            % visual output through psychoToolbox
            if psychoToolbox
                colIndx = ceil((feedbackVal+0.001)*254);
                 if adrBoard
                    binval = [ '00000000' dec2bin(colIndx) ];
                    binval = binval(end-7:end);
                    fwrite(serialPort, ['SPA00000010' char(13)]); %dead
                end           
                Screen('FillPoly', window ,[0 0 colArray(colIndx)], [ xpos1 ypos1; xpos2 ypos1; xpos2 ypos2; xpos1 ypos2], 1);
                Screen('Flip', window);
                if adrBoard
                    fwrite(serialPort, ['SPA00000000' char(13)]);
                end
            end
            
            % output through TCP/IP
            if TCPIP
                outVal = feedbackVal;
                if ~isnan(TCPbinarythreshold)
                    outVal = outVal > TCPbinarythreshold;
                end
                fprintf('Feedback %s sent to client, ', num2str(outVal));
                %outToClient.println(num2str(outVal));
            end
        else
            fprintf('.');
        end
        pause(0.1);
    end
end
fprintf('\n');

if adrBoard
    fwrite(serialPort, ['SPA11111111' char(13)]);
    pause(0.05);
    fwrite(serialPort, ['SPA00000000' char(13)]);
end

chunkMarker(chunkCount:end) = [];
chunkPower(chunkCount:end) = [];
chunkFeedback(chunkCount:end) = [];
chunkDynRange(:,chunkCount:end) = [];

% select calibration data
if strcmpi(runmode, 'baseline')
    disp('Calibrating ASR...');
    dataAccu = dataAccu(:, 1:dataAccuPointer-1);
    state = asr_calibrate(dataAccu, EEG.srate);
    save('-mat', fileNameAsr, 'state', 'dynRange', 'dataAccu', 'chunkMarker', 'chunkPower', 'chunkFeedback', 'chunkDynRange', 'srate', 'freqrange' );
    fprintf('Saving file %s\n', fileNameAsr);
else 
    % close text file
    save('-mat', fileNameOut, 'stateAsr', 'dataAccu', 'chunkMarker', 'chunkPower', 'chunkFeedback', 'chunkDynRange', 'srate', 'freqrange' );
    if psychoToolbox
        Screen('Closeall');
    end
    fprintf('Saving file %s\n', fileNameOut);
end

if adrBoard
    fclose(serialPort);
end
