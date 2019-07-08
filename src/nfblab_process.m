function nfblab_process(runtype, fileNameAsr, fileNameOut)

nfblab_options;
global serialPort;

% make sure the function can be run again
onCleanup(@() nfblab_cleanup);

if ~strcmpi(runtype, 'trial') && ~strcmpi(runtype, 'baseline') 
    error('Wrong run type')
elseif strcmpi(runtype, 'trial')
    if nargin < 3
        error('Need at least 3 arguments in trial mode');
    end
elseif strcmpi(runtype, 'baseline')
    if nargin < 2
        error('Need at least 2 arguments in baseline mode');
    end
end
if nchans ~= 8 && nchans ~= 128 && nchans ~= 64
    error('nchans must be 8, 64 or 128')
end

dataBuffer = zeros(length(chans), (windowSize*2)/srate*srateHardware);
dataBufferPointer = 1;

dataAccu = zeros(length(chans), (sessionDuration+3)*srate); % to save the data
dataAccuPointer = 1;
feedbackVal    = 0.5;       % initial feedback value

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

% select calibration data
if strcmpi(runtype, 'trial')
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
freqRange = intersect( find(freqs >= theta(1)), find(freqs <= theta(2)) );

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
        else error('Cannot convert sampling rate');
        end
        
        % shift 1 block
        dataBuffer(:, 1:chunkSize*(winPerSec-1)) = dataBuffer(:, chunkSize+1:chunkSize*winPerSec);
        dataBufferPointer = dataBufferPointer-chunkSize;
        
        % filter data
        EEG.pnts = size(EEG.data,2);
        EEG.nchan = size(EEG.data,1);
        EEG.xmax = EEG.pnts/EEG.srate;
        %EEG = eeg_checkset(EEG);
        [EEG state] = hlp_scope({'disable_expressions',true},@flt_fir, 'signal', EEG, 'fspec', [0.5 1], 'fmode', 'highpass',  'ftype','minimum-phase', 'state', state);
        %[EEG state ] = exp_eval(flt_fir( 'signal',EEG, 'fspec', [0.9 1.1],'fmode','highpass', 'ftype','minimum-phase', 'state', state));
        
        % rereference
        %EEG.data = bsxfun(@minus, EEG.data,mean(EEG.data([24 61],:))); % P9 and P10
        EEG.data = bsxfun(@minus, EEG.data,mean(EEG.data)); % average reference

        % accumulate data if baseline mode
        if strcmpi(runtype, 'baseline')
            dataAccu(:, dataAccuPointer:dataAccuPointer+size(EEG.data,2)-1) = EEG.data;
        else
            % apply ASR and update state
            [EEG.data, stateAsr]= asr_process(EEG.data, EEG.srate, stateAsr);
            dataAccu(:, dataAccuPointer:dataAccuPointer+size(EEG.data,2)-1) = EEG.data;
        end
        dataAccuPointer = dataAccuPointer + size(EEG.data,2);
        chunkMarker(chunkCount) = dataAccuPointer;
        
        % Apply linear transformation (get channel Fz at that point)
        ICAact = mask*EEG.data;
        
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
        
        if  strcmpi(runtype, 'trial')
            fprintf('Spectral power %2.3f - output %1.2f - %1.2f [%1.2f %1.2f]\n', X, feedbackVal, feedbackValTmp, dynRange(1), dynRange(2));

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
        end
        pause(0.1);
    end
end

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
if strcmpi(runtype, 'baseline')
    disp('Calibrating ASR...');
    dataAccu = dataAccu(:, 1:dataAccuPointer-1);
    state = asr_calibrate(dataAccu, EEG.srate);
    save('-mat', fileNameAsr, 'state', 'dynRange', 'dataAccu', 'chunkMarker', 'chunkPower', 'chunkFeedback', 'chunkDynRange', 'srate', 'theta' );
else 
    % close text file
    save('-mat', fileNameOut, 'stateAsr', 'dataAccu', 'chunkMarker', 'chunkPower', 'chunkFeedback', 'chunkDynRange', 'srate', 'theta' );
    if psychoToolbox
        Screen('Closeall');
    end
end

if adrBoard
    fclose(serialPort);
end
