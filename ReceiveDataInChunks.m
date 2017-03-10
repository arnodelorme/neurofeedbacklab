function neurofeedback_process(runtype, setupFileName)

global serialPort;

% make sure the function can be run again
c = onCleanup(cleanup_neurofeedback);

if ~strmpi(runtype, 'trial') && ~strmpi(runtype, 'baseline') 
    error('Wrong run type')
end;

% data acquisition parameters
srate        = 256;
srateBiosemi = 2048;
nfft       = 256;
windowSize = 256; % 1 second
windowInc  = 128; % update every 1/4 second
chans      = 34:41;
theta      = [3.5 6.5];
dataBuffer = zeros(length(chans), (windowSize*2)/srate*srateBiosemi);
if strmpi(runtype, 'trial')
    sessionDuration = 60*5; % 5 minutes
    maxChange      = 0.05;
    psychoToolbox  = true;    
else
    % 1 minute of data for baseline
    sessionDuration = 60; % 1 minute
    dataAccu = zeros(length(chans), (sessionDuration+3)*srate);    
    dataAccuPointer = 1;    
    maxChange      = 0.15;
    psychoToolbox  = false;
end;
dataBufferPointer = 1;

% feedback parameters
dynRange       = [16 29];
feedbackVal    = 0.5;

adrBoard       = true;

% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

% resolve a stream...
disp('Resolving an EEG stream...');
disp('Opening an inlet...');
disp('Now receiving chunked data...');
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib,'type','EEG');
end
inlet = lsl_inlet(result{1});

% ADR board
if adrBoard
    port = 'COM4';
    
    serialPort = serial(port, 'baudrate', 9600);
    set(serialPort, 'terminator', 13);
    fopen(serialPort);
    
    fwrite(serialPort, ['CPA00000000' char(13)]);
    fwrite(serialPort, ['SPA00000000' char(13)]);
end;

% select calibration data
if strmpi(runtype, 'trial')
    stateAsr = load('-mat', fullfile(pathnameCal, filenameCal));
    stateAsr = stateAsr.state;
    dynRange = stateAsr.theta_range;
end;

%EEG.icaact = [];
%disp('Training ASR, please wait...');
%stateAsr = asr_calibrate(EEG.data(:, 1:EEG.srate*60), EEG.srate);

% frequencies for spectral decomposition
freqs  = linspace(0, srate/2, floor(nfft/2));
freqs     = freqs(2:end); % remove DC (match the output of PSD)
freqRange = intersect( find(freqs >= theta(1)), find(freqs <= theta(2)) );

% create screen psycho toolbox
% ----------------------------
if psychoToolbox
    %Screen('Preference', 'SkipSyncTests', 1);
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
end;

%% create a new inlet
tic;
totSamples = 0;
state = [];
EEG = eeg_emptyset;
EEG.nbchan = length(chans);
EEG.srate  = srate;
EEG.xmin   = 0;
tmp = load('-mat','chanlocs.mat');
EEG.chanlocs = tmp.chanlocs;
winPerSec = windowSize/windowInc;
chunkSize = windowInc*srateBiosemi/srate; % at 512 so every 1/4 second is 128 samples
tic;

if adrBoard
    fwrite(serialPort, ['SPA11111111' char(13)]);
    pause(0.05);
    fwrite(serialPort, ['SPA00000000' char(13)]);
end;

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
        end;
    end;
    
    if dataBufferPointer > chunkSize*winPerSec
        
        % empty buffer
        if srateBiosemi == srate
            EEG.data = dataBuffer(:,1:chunkSize*winPerSec);            
        elseif srateBiosemi == 2*srate
            EEG.data = dataBuffer(:,1:2:chunkSize*winPerSec);
        elseif srateBiosemi == 4*srate
            EEG.data = dataBuffer(:,1:4:chunkSize*winPerSec);
        elseif srateBiosemi == 8*srate
            EEG.data = dataBuffer(:,1:8:chunkSize*winPerSec);
        else error('Cannot convert sampling rate');
        end;
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
        if strmpi(runtype, 'baseline') && toc > 1
            dataAccu(:, dataAccuPointer:dataAccuPointer+size(EEG.data)-1) = EEG.data;
            dataAccuPointer = dataAccuPointer + size(EEG.data);
        else
            % apply ASR and update state
            [EEG.data stateAsr]= asr_process(EEG.data, EEG.srate, stateAsr);
        end;
        
        % Apply linear transformation (get channel Fz at that point)
        compVals = zeros(size(EEG.data,1),1);
        compVals(1) = 1; % FPz
        ICAact = compVals'*EEG.data;
        
        % Perform spectral decomposition
        dataSpec = fft(ICAact, nfft);
        dataSpec = dataSpec(freqRange);
        X        = mean(10*log10(abs(dataSpec).^2));
        
        % compute feedback value between 0 and 1
        totalRange = dynRange(2)-dynRange(1);
        feedbackValTmp = (X-dynRange(1))/totalRange;
        if feedbackValTmp > 1, dynRange(2) = dynRange(2)+totalRange/30; feedbackValTmp = 1;
        else                   dynRange(2) = dynRange(2)-totalRange/100;
        end;
        if feedbackValTmp < 0, dynRange(1) = dynRange(1)-totalRange/30; feedbackValTmp = 0;
        else                   dynRange(1) = dynRange(1)+totalRange/100;
        end;
        if feedbackValTmp<feedbackVal
            if abs(feedbackValTmp-feedbackVal) > maxChange, feedbackVal = feedbackVal-maxChange;
            else                                            feedbackVal = feedbackValTmp;
            end;
        else
            if abs(feedbackValTmp-feedbackVal) > maxChange, feedbackVal = feedbackVal+maxChange;
            else                                            feedbackVal = feedbackValTmp;
            end;
        end;            
        fprintf('Spectral power %2.3f - output %1.2f - %1.2f [%1.2f %1.2f]\n', X, feedbackVal, feedbackValTmp, dynRange(1), dynRange(2));

        if psychoToolbox
            colIndx = ceil((feedbackVal+0.001)*254);
             if adrBoard
                binval = [ '00000000' dec2bin(colIndx) ];
                binval = binval(end-7:end);
                fwrite(serialPort, ['SPA00000010' char(13)]); %dead
            end;           
            Screen('FillPoly', window ,[0 0 colArray(colIndx)], [ xpos1 ypos1; xpos2 ypos1; xpos2 ypos2; xpos1 ypos2], 1);
            Screen('Flip', window);
            if adrBoard
                fwrite(serialPort, ['SPA00000000' char(13)]);
            end;
        end;
        pause(0.1);
    end;
end

if adrBoard
    fwrite(serialPort, ['SPA11111111' char(13)]);
    pause(0.05);
    fwrite(serialPort, ['SPA00000000' char(13)]);
end;

if psychoToolbox
    Screen('Closeall');
end;
if adrBoard
    fclose(serialPort);
end;