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
try
%    nfblab_options_additional; % additional options that overwritte the options above
catch
end
import java.io.*; % for TCP/IP
import java.net.*; % for TCP/IP

% decode input parameters and overwrite defaults
for iArg = 1:2:length(varargin)
    if isstr(varargin{iArg+1})
        eval( [ varargin{iArg} ' = ''' varargin{iArg+1} ''';'] );
    else
        eval( [ varargin{iArg} ' = ' num2str(varargin{iArg+1}) ';' ] );
    end
end
if asrFlag == false
    runmode = 'trial';
    disp('ASR disabled so skipping baseline');
else
    if filtFlag
        error('ASR does its own filtering, disable ''filtFlag'' flag');
    end
    disp('Note: default ASR instroduces a delay - in our experience 1/4 second)');
end
if ~exist('runmode')
    s = input('Do you want to run a baseline now (y/n)?', 's');
    if strcmpi(s, 'y'), runmode = 'baseline';
    elseif strcmpi(s, 'n'), runmode = 'trial';
    else error('Unknown option');
    end
end

% make sure the function can be run again
onCleanup(@() nfblab_cleanup);

if ~strcmpi(runmode, 'trial') && ~strcmpi(runmode, 'baseline') && ~strcmpi(runmode, 'slave')
    error('Wrong run type')
elseif strcmpi(runmode, 'baseline')
    % generate 1 command per second
    msg = [];
    if isempty(streamFile)
        msg(end+1).command = 'lslconnect';
    end
    msg(end+1).command = 'start';
    msg(end).options.runmode     = 'baseline';
    msg(end+baselineSessionDuration).command = 'stop';
    msg(end+1).command = 'quit';
    iMsg = 1;
elseif strcmpi(runmode, 'trial')
    if isequal(defaultNameAsr, fileNameAsr) && asrFlag == true
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
    % generate 1 command per second
    msg = [];
    if isempty(streamFile)
        msg(end+1).command = 'lslconnect';
    end
    msg(end+1).command = 'start';
    msg(end).options.runmode = 'trial';
    msg(end+sessionDuration).command = 'stop';
    msg(end+1).command = 'quit';
    iMsg = 1;
end

dataBuffer     = zeros(length(chans), (windowSize*2)/srate*srateHardware);
dataBufferFilt = zeros(length(chans), (windowSize*2)/srate*srateHardware);
dataBufferPointer = 1;

dataAccuOri  = zeros(length(chans), (sessionDuration+3)*srate); % to save the data
dataAccuFilt = zeros(length(chans), (sessionDuration+3)*srate); % to save the data
dataAccuPointer = 1;
feedbackVal    = 0.5;       % initial feedback value

% create TCP/IP socket
oldFeedback = 0;
if TCPIP
    if ~isnan(TCPport)
        kkSocket  = ServerSocket( TCPport );
        fprintf('Trying to accept connection from client (if program get stuck here, check client)...\n');
        connectionSocket = kkSocket.accept();
        outToClient  = PrintWriter(connectionSocket.getOutputStream(), true);
        inFromClient = BufferedReader(InputStreamReader(connectionSocket.getInputStream()));
    end
end

chunkMarker   = zeros(1, sessionDuration*10);
chunkPower    = zeros(1, sessionDuration*10);
chunkFeedback = zeros(1, sessionDuration*10);
chunkDynRange = zeros(2, sessionDuration*10); % FIX THIS NOT INCREASED IN SIZE FOR CURTIS AND GENERATE CRASH WHEN SAVING BECAUSE OUT OF BOUND ARRAY
chunkThreshold = zeros(1, sessionDuration*10);
chunkCount    = 1;
warning('off', 'MATLAB:subscripting:noSubscriptsSpecified'); % for ASR

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

if ~isempty(streamFile)
    streamFileData = load('-mat', streamFile);
    streamFileData = streamFileData.EEG;
    eegPointer     = 1;
end

currentMode = 'pause';
currentMsg  = '"Ready"';
inlet = [];
while 1
    
    % wait for first command
    fprintf('Feedback %s sent to client\n',currentMsg);
    if TCPIP
        structResp = '';
        while isempty(structResp)
            outToClient.println(currentMsg)
            try
                response = inFromClient.readLine();
            catch
                response = '';
                disp('Java socket exception');
            end

            if isempty(response)
                currentMode = 'disconnected';
                break;
            end
            
            % try decoding message from server
            try
                structResp = jsondecode(char(response));
            catch
                fprintf('Error when deconding json message %s from server', response);
                disp(lasterror)
                structResp = '';
            end
            if ~isfield(structResp, 'command')
                structResp = '';
            end
            if ~isempty(structResp) 
                if (isfield(structResp, 'command') && ~isempty(structResp.command)) ...
                || (isfield(structResp, 'options') && ~isempty(structResp.options))
                    fprintf(2, 'Message received: %s\n', response);
                end
            end
        end
    else
        structResp = msg(iMsg);
        iMsg = iMsg + 1;
    end
        
    % Execute commands and change mode
    if strcmpi(currentMode, 'disconnected')
        connectionSocket.close();
        pause(0.1);
        fprintf('Trying to accept connection from client (if program get stuck here, check client)...\n');
        connectionSocket = kkSocket.accept();
        outToClient  = PrintWriter(connectionSocket.getOutputStream(), true);
        inFromClient = BufferedReader(InputStreamReader(connectionSocket.getInputStream()));
        currentMode = 'pause';
    else
        % Decode message
        fieldJson = {};
        if ~isempty(structResp.options)
            fieldJson = fieldnames(structResp.options);
        end
        allowedFields = { 'runmode' 'fileNameAsr' 'fileNameOut' 'threshold' 'thresholdMem' ...
            'thresholdMode' 'maxChange' 'dynRange' 'dynRangeDec' 'dynRangeInc' 'filtFlag' ...
            'asrFlag' 'freqrange' 'freqdb' 'freqprocess' 'addfreqprocess' 'ntlfreqprocess' 'capdBchange' 'feedbackMode' ...
            'chans' 'averefflag' 'chanmask' 'eLoretaFlag' 'lsltype' 'lslname' };
        for iField = 1:length(fieldJson)
            if ~ismember(fieldJson{iField}, allowedFields)
                fprintf('Unknown option "%s"\n', fieldJson{iField});
            else
                % show option to use
                if ischar(structResp.options.(fieldJson{iField}))
                    fprintf('Decoding option %s: %s\n', fieldJson{iField}, structResp.options.(fieldJson{iField}));
                else
                    fprintf('Decoding option %s (%s)\n', fieldJson{iField}, class(structResp.options.(fieldJson{iField})));
                end
                
                eval( [ fieldJson{iField} ' = structResp.options.(fieldJson{iField});' ] );

                % handle addfreqprocess parameter
                if isequal(fieldJson{iField}, 'addfreqprocess')
                    for iFieldProc = fieldnames(addfreqprocess)'
                        freqprocess.(iFieldProc{1}) = addfreqprocess.(iFieldProc{1});
                    end
                end
                
                % handle freqprocess parameter
                if ~isempty(findstr(fieldJson{iField}, 'ntlfreqprocess'))
                    nfblab_jsonntl; % process NTL command 
                end
                
                % handle freqprocess parameter
                if ~isempty(findstr(fieldJson{iField}, 'freqprocess')) % freqprocess or addfreqprocess
                    for iFieldProc = fieldnames(freqprocess)'
                        if ischar(freqprocess.(iFieldProc{1}))
                            freqprocess.(iFieldProc{1}) = eval(freqprocess.(iFieldProc{1}));
                        end
                    end
                end
            end
        end
        
        if strcmpi(structResp.command, 'lslconnect')
            % instantiate the LSL library
            disp('Loading the library...');
            lib = lsl_loadlib();

            % resolve a stream...
            disp('Resolving an EEG stream...');
            result = {};
            result = nfblab_findlslstream(lib,lsltype,lslname);
            disp('Opening an inlet...');
            inlet = lsl_inlet(result{1});
            disp('Now receiving chunked data...');
        elseif strcmpi(structResp.command, 'start')
            chunkCount = 1; % restart all counters
            fprintf('Starting new session...\n', fileNameAsr);
            currentMode = 'run';
            stateAsr = [];
            if strcmpi(runmode, 'trial') && asrFlag
                fprintf('Loading baseline ASR file %s...\n', fileNameAsr);
                stateFile = load('-mat', fileNameAsr);
                dynRange = stateFile.dynRange;
                if isfield(stateAsr, 'state')
                    stateAsr = stateFile.state; % legacy
                else
                    stateAsr = stateFile.stateAsr;
                end
            end
        elseif strcmpi(structResp.command, 'stop')
            if strcmpi(currentMode, 'paused')
                disp('Cannot stop when in "paused" mode');
            else
                fprintf('Ending session...\n', fileNameAsr);
                % save state
                chunkMarkerSave    = chunkMarker(1:chunkCount-1);
                chunkPowerSave     = chunkPower(1:chunkCount-1);
                chunkFeedbackSave  = chunkFeedback(1:chunkCount-1);
                chunkDynRangeSave  = chunkDynRange(:,1:chunkCount-1);
                chunkThresholdSave = chunkThreshold(1:chunkCount-1);

                % select calibration data
                dataAccuOriSave  = dataAccuOri( :, 1:dataAccuPointer-1); % last second of data might be lost because still in buffer
                dataAccuFiltSave = dataAccuFilt(:, 1:dataAccuPointer-1); % last second of data might be lost because still in buffer
                if strcmpi(runmode, 'baseline')
                    disp('Calibrating ASR...');
                    stateAsr = asr_calibrate(dataAccuFiltSave, srateHardware);
                    save('-mat', fileNameAsr, 'stateAsr', 'dynRange', 'dataAccuOriSave', 'dataAccuFiltSave', 'chunkMarkerSave', 'chunkPowerSave', 'chunkFeedbackSave', 'chunkDynRangeSave', 'chunkThresholdSave', 'srate', 'freqrange' );
                    fprintf('Saving Baseline file %s\n', fileNameAsr);
                else
                    % close text file
                    save('-mat', fileNameOut, 'stateAsr', 'dynRange', 'dataAccuOriSave', 'dataAccuFiltSave', 'chunkMarkerSave', 'chunkPowerSave', 'chunkFeedbackSave', 'chunkDynRangeSave', 'chunkThresholdSave', 'srate', 'freqrange' );
                    fprintf('Saving file %s\n', fileNameOut);
                end

                currentMode = 'pause';
                currentMsg  = '"paused"';
                chunkCount    = 1;
            end
        elseif strcmpi(structResp.command, 'quit')
            fprintf('Quitting...\n');
            if TCPIP
                connectionSocket.close();
                kkSocket.close();
            end
            break;
        elseif strcmpi(structResp.command, 'disconnect')
            fprintf('Disconnecting...\n');
            if TCPIP
                connectionSocket.close();
            end
            currentMode = 'disconnected';
        elseif ~isempty(structResp.command)
            fprintf('Unknown command: %s\n', structResp.command);
        end
    end
    
    % run mode
    if strcmpi(currentMode, 'run')
        
        % frequencies for spectral decomposition
        freqs  = linspace(0, srate/2, floor(nfft/2));
        freqs     = freqs(2:end); % remove DC (match the output of PSD)
        
        %% create a new inlet
        tic;
        state = [];
        EEG = eeg_emptyset;
        EEG.nbchan = length(chans);
        EEG.srate  = srate;
        EEG.xmin   = 0;
        prevX      = [];
        % tmp = load('-mat','chanlocs.mat');
        % EEG.chanlocs = tmp.chanlocs;
        winPerSec = windowSize/windowInc;
        chunkSize = windowInc*srateHardware/srate; % at 512 so every 1/4 second is 128 samples
        tic;
        
        lastChunkTime = [];
        freqprocessFields = fieldnames(freqprocess);
        
        % pause between each loop
        pause(pauseSecond);
        
        % get chunk from the inlet
        currentMsg = '"Streaming"';
        if isempty(streamFile) 
            if ~isempty(inlet)
                [chunk,~] = inlet.pull_chunk();
                %fprintf('Size of chuck: %d,%d\n', size(chunk,1), size(chunk,2));
            else
                chunk = [];
            end
        else
            if eegPointer+31 > size(streamFileData.data,2)
                break;
            else
                chunk = streamFileData.data(:,eegPointer:eegPointer+31);
                eegPointer = eegPointer+32;
            end
        end
        
        % fill buffer
        if ~isempty(chunk) && size(chunk,2) > 1
            % fprintf('%d samples (%1.10f)\n', size(chunk,2), sum(chunk(:,1)));
            
            % truncate chunk if too long
            if dataBufferPointer+size(chunk,2) > size(dataBuffer,2)
                disp('Buffer overrun');
                % truncate beginning of chunk
                chunk(:,1:end-(size(dataBuffer,2)-dataBufferPointer)) = [];
                lastChunkTime = [];
            end
            
            % subset of channels
            chunk = chunk(chans,:);
            
            % filter chunk
            if filtFlag
                if size(chunk,2) == 1, error('Filter cannot process a single sample - increase ''pauseSecond'' parameter'); end
                [chunkFilt,state] = filter(B,A,chunk',state);
                chunkFilt = chunkFilt';
            else
                chunkFilt = chunk;
            end
            
            % apply ASR on chunk
            if asrFlag && ~strcmpi(runmode, 'baseline')
                [chunkFilt, stateAsr]= asr_process(chunkFilt, srateHardware, stateAsr);
            end
            
            % copy data to buffers
            dataBuffer(    :,dataBufferPointer:dataBufferPointer+size(chunk,2)-1) = chunk;
            dataBufferFilt(:,dataBufferPointer:dataBufferPointer+size(chunk,2)-1) = chunkFilt;
            dataBufferPointer = dataBufferPointer+size(chunk,2);
            %fprintf('Data buffer pointer increased: %d\n', dataBufferPointer);
        end
        
        if dataBufferPointer > chunkSize
            
            % estimate sampling rate
            if ~isempty(lastChunkTime) && warnsrate
                sRateEstimated = chunkSize/(toc - lastChunkTime);
                if abs(srateHardware-sRateEstimated) > 0.1*srateHardware
                    fprintf('Warning: estimated heart rate %d Hz compared to %d Hz set in nfblab_options.m\n', round(sRateEstimated), round(srateHardware));
                end
            end
            lastChunkTime = toc;
            
            % copy first chunk of raw data array
            dataAccuOri( :, dataAccuPointer:dataAccuPointer+chunkSize-1) = dataBuffer(:, 1:chunkSize);
            dataAccuFilt(:, dataAccuPointer:dataAccuPointer+chunkSize-1) = dataBufferFilt(:, 1:chunkSize);
            dataAccuPointer   = dataAccuPointer+chunkSize;
            
            % shift one chunk
            dataBuffer(    :, 1:end-chunkSize) = dataBuffer(    :, chunkSize+1:end);
            dataBufferFilt(:, 1:end-chunkSize) = dataBufferFilt(:, chunkSize+1:end);
            dataBuffer(    :, end-chunkSize+1:end) = 0; % not necessary but good for debugging
            dataBufferFilt(:, end-chunkSize+1:end) = 0; % not necessary but good for debugging
            dataBufferPointer = dataBufferPointer-chunkSize;
            %fprintf('Data buffer pointer decreased: %d\n', dataBufferPointer);
            
            if dataAccuPointer > chunkSize*winPerSec
                
                % Decimate and create EEG structure of 1 second
                if srateHardware == srate
                    EEG.data = dataAccuFilt(:,dataAccuPointer-chunkSize*winPerSec:dataAccuPointer-1);
                elseif srateHardware == 2*srate
                    EEG.data = dataAccuFilt(:,dataAccuPointer-chunkSize*winPerSec:2:dataAccuPointer-1);
                elseif srateHardware == 4*srate
                    EEG.data = dataAccuFilt(:,dataAccuPointer-chunkSize*winPerSec:4:dataAccuPointer-1);
                elseif srateHardware == 8*srate
                    EEG.data = dataAccuFilt(:,dataAccuPointer-chunkSize*winPerSec:8:dataAccuPointer-1);
                else
                    error('Processing sampling rate not a multiple of hardware acquisition sampling rate');
                end
                
                % rereference
                %EEG.data = bsxfun(@minus, EEG.data,mean(EEG.data([24 61],:))); % P9 and P10
                if averefflag
                    EEG.data = bsxfun(@minus, EEG.data, mean(EEG.data)); % average reference
                end
                
                % make compliant EEGLAB dataset
                EEG.pnts = size(EEG.data,2);
                EEG.nchan = size(EEG.data,1);
                EEG.xmax = EEG.pnts/EEG.srate;
                
                if eLoretaFlag
                    % project to source space
                    source_voxel_data = reshape(EEG.data(:, :)'*P_eloreta(:, :), EEG.pnts*EEG.trials, nvox, 3);
                    
                    % select voxels of interest and average
                    source_roi_data = mean(abs(source_voxel_data(:,ind_roi,:),3),2)';
                else
                    % Apply linear transformation (get channel Fz at that point)
                    spatiallyFilteredData = chanmask*EEG.data;
                end
                
                % step to get ROI activity
                % - compute leadfield
                % - compute Loreta solution
                % - extract voxels of interest
                % - average
                
                % Perform spectral decomposition
                % taper the data with hamming
                dataSpec = fft(bsxfun(@times, spatiallyFilteredData', hamming(size(spatiallyFilteredData,2))), nfft);
                
                % select frequency bands
                dataSpecSelect = zeros(size(spatiallyFilteredData,1), length(freqrange));
                for iSpec = 1:length(freqrange)
                    freqRangeTmp = intersect( find(freqs >= freqrange{iSpec}(1)), find(freqs <= freqrange{iSpec}(2)) );
                    dataSpecSelect(:,iSpec) = mean(abs(dataSpec(freqRangeTmp,:)).^2,1); % mean power in frequency range
                    if freqdb
                        dataSpecSelect(:,iSpec) = 10*log10(abs(dataSpecSelect(:,iSpec)).^2);
                    end
                end
                
                % compute metric of interest
                for iProcess = 1:length(freqprocessFields)
                    results.(freqprocessFields{iProcess}) = feval(freqprocess.(freqprocessFields{iProcess}), dataSpecSelect);
                end
                X = results.(freqprocessFields{end}); % last item on the list
                
                % cap spectral change for feedback measure
                if ~isempty(prevX)
                    if X > prevX+capdBchange, X = prevX+capdBchange; end
                    if X < prevX-capdBchange, X = prevX-capdBchange; end
                end
                prevX = X;
                
                % save power and pointer position
                chunkMarker(chunkCount) = dataAccuPointer;
                chunkPower( chunkCount) = X;
                chunkFeedback( chunkCount) = 0;
                chunkDynRange(:,chunkCount) = 0;
                chunkThreshold(chunkCount) = 0;
                if chunkCount > sessionDuration*10
                    disp('Standard buffer size exceedeed - we recommend increasing sessionDuration');
                end
                
                if ~isinf(X)
                    if strcmpi(feedbackMode, 'dynrange')
                        % assess if value position within a range
                        % and return output from 0 to 1
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
                        chunkDynRange(:,chunkCount) = dynRange;
                        % fprintf('Spectral power %2.3f - output %1.2f - %1.2f [%1.2f %1.2f]\n', X, feedbackVal, feedbackValTmp, dynRange(1), dynRange(2));
                    elseif strcmpi(feedbackMode, 'threshold')
                        % simply assess if value above threshold
                        % and return binary output
                        feedbackVal = X > threshold;
                        if strcmpi(thresholdMode, 'stop')
                            feedbackVal = ~feedbackVal;
                        end
                        threshold = threshold*thresholdMem + X*(1-thresholdMem);
                        chunkThreshold(chunkCount) = threshold;
                        % fprintf('Spectral power %2.3f - output %1.0f - threshold %1.2f\n', X, feedbackVal, threshold);
                    end
                end
                chunkFeedback(chunkCount) = feedbackVal;
                chunkCount = chunkCount+1;
                
                % output message through TCP/IP
                tcpipmsg             = results;
                tcpipmsg.threshold   = threshold;
                tcpipmsg.value       = X;
                tcpipmsg.statechange = feedbackVal == oldFeedback;
                tcpipmsg.feedback    = feedbackVal;
		currentMsg = jsonencode(tcpipmsg);
                oldFeedback = feedbackVal;
                
                % visual output through psychoToolbox
                if strcmpi(runmode, 'trial')&& psychoToolbox
                    colIndx = ceil((feedbackVal+0.001)*254);
                    Screen('FillPoly', window ,[0 0 colArray(colIndx)], [ xpos1 ypos1; xpos2 ypos1; xpos2 ypos2; xpos1 ypos2], 1);
                    Screen('Flip', window);
                end
            end
        end
    end
    
end

if psychoToolbox
    Screen('Closeall');
end
