% nfblab_process() - function to perform Neurofeedback using LSL steams. 
%                    Support ICA components, spatial filtering, ERP extraction 
%                    (beta), eLoreta (beta), zscore (beta), audio and
%                    visual feeback, etc...
% Usage:
%    nfblab_process(key, val, ...)
%    nfblab_process('help', true)
%
% Type nfblab_process('help', true) for help on parameters.
%
% Parameter 'chanmask':
% This parameter determines your spacial filter with one row per channel.
% For example, if you have 3 channels Fz, Pz, and Cz, and want to compute
% Fz-Cz and Pz-Cz, the matrix would look like [1 0 -1; 0 1 -1]. The default
% parameter is identity (eye() MATLAB function) where each EEG channel is 
% transformed to itself.
%
% Parameter 'freqrange':
% This defines your frequency range of interest. Default is theta, but you
% may calculate multiple ones, for example { [3.5 6.5] [8 12] } will
% calculate theta and alpha.
%
% Parameter 'freqprocess':
% This defines how to calculate the spectral parameter to use for feedback.
% This is a function that takes as input a matrix of size 'chanmask' rows
% by 'freqrange' columns. If 'chanmask' is [1 0 -1; 0 1 -1] and 'freqrange'
% is { [3.5 6.5] } (theta), the input matrix is 2 x 1. For example the
% function param.theta = @(x)x(1) will use for feedback theta power of the first
% output of 'chanmask'. Function @(x)x(1)/x(2) will use for feedback the ratio of 
% theta power between the two output of 'chanmask'. 
% If 'freqrange' contains theta and alpha { [3.5 6.5] [8 12] }, then it is
% possible to calculate the ratio of theta over alpha of the first channel
% using param.alphabytheta = @(x)x(1,1)/x(1,2). If 'chanmask' contains spatial
% filter weights for ICA components, then it is possible to provide feedback 
% based on ICA component spectral power.
%
% Parameter 'runmode':
% One of the most important parameters is 'runmode' which can be 'trial' or 
% 'baseline'. A baseline must be run at the beginning to assess baseline 
% values and ASR rejection thresholds or ICA. 'runmode' can also be 'slave'
% if nfblab_process is controled through TCP/IP communication.
%
% Parameter 'feedbackmode':
% Another important parameter is 'feedbackmode' which can be 
% 'dynrange' dynamical range or 'threshold' mode. The threshold mode simply 
% involves activity going above or below a threshold and parameter for how this
% threshold evolves. The output is binary. In the dynamic range mode, the output 
% is continuous between 0 and 1. There are multiple parameters to control how 
% these values change through time but you must choose one mode ('dynrange' or 
% 'threshold') as the two modes are mutually exclusive.
%
% Commands:
%    About 4 times per second (depending on settings), this function
%    process commands. These commands may contain options. You should not
%    need to worry about sending commands because the sequence of commands
%    is automatically determined by your parameters. However, in specific
%    cases, such as TCP/IP communication or GUI communication, it is good
%    to know what the commands are:
%
%    'lslconnect' - connect to LSL stream (based on parameters provided as input)
%    'disconnect' - disconnect from TCP/IP and wait for new connection
%    'start'      - start streaming
%    'stop'       - stop streaming (can be resumed by starting to stream again)
%    'quit'       - quit program
%
%    When nfblab_process is controlled by TCP/IP see "tcpip_control_and_feedback_stream"
%    protocol, the commands are passed as JSON strings, which contain a
%    "command" and an "option" key. See nfblab_process('help', true) for the list 
%    of options.
% 
%    When nfblab_process is controlled by a Graphic User Interface -- see "simple_gui"
%    protocol -- the commands are passed as a variable in the global workspace
%    ('checkglobalmsg' parameter) with a "command" and an "option" field. 
%    See nfblab_process('help', true) for the list of options.

% this is the name of the stream that shows in Lab Recorder
% if empty, it will only use the type above
% USE lsl_resolve_byprop(lib, 'type', lsltype, 'name', lslname)
% to connect to the stream. If you cannot connect
% nfblab won't be able to connect either.

% NOTE:
% - remove "addfreqprocess"

function nfblab_process(varargin)

if ~exist('nfblab_setfields', 'file')
    [filePath,~] = fileparts(which('nfblab_process'));
    addpath(fullfile(filePath, 'src'));
end
if ~exist('pop_loadset', 'file')
    eeglab; % add paths
    close;
end

% get current commit (will be saved along with the data
tmpcommit = nfblab_version;
fprintf('\n**********************\n')
fprintf('**********************\n')
fprintf('** NEUROFEEDBACKLAB **\n')
fprintf('**********************\n')
fprintf('**********************\n')
fprintf('\nVersion: %s (git commit)\n\n', tmpcommit(1:8))
fprintf('Type "help nfblab_process" for basic parameter help\n');
fprintf('Type "nfblab_process(''help'', true)" for more advanced parameter help\n');
fprintf('Refer to online documentation and protocols for more information.\n\n');

g = nfblab_setfields([], varargin{:});
if isempty(g), return; end

g.commit = tmpcommit;

if isfield(g.feedback, 'diary') && ~strcmpi(g.feedback.diary, 'off')
    dateTmp = datestr(now, 30);
    if isempty(g.feedback.diary)
        diary([ 'nfblab_log_' dateTmp '.txt']);
    else
        diary(g.feedback.diary);
    end
end

% g.session.runmode = [];

import java.io.*; % for TCP/IP
import java.net.*; % for TCP/IP

if ~isempty(g.measure.loreta_file) && exist(g.measure.loreta_file)
    load('-mat', g.measure.loreta_file);
    if ~exist('loreta_Networks')
        g.measure.loreta_Networks.name = 'Network';
        g.measure.loreta_Networks.ROI_inds = 1:length(loreta_ROIS);
    end
    ROI_list = unique([loreta_Networks.ROI_inds]);
    
    % add regions used for calculating z-score
    freqloretaFields = fieldnames(g.measure.freqloreta);
    tmpMat = ones(length(loreta_ROIS),length(g.measure.freqrange));
    ROI_list_add = [];
    for iField = 1:length(freqloretaFields)
        for iROI = 1:length(loreta_ROIS)
            tmpMat2 = tmpMat;
            tmpMat2(iROI,:) = NaN;
            if any(any(isnan( feval(g.measure.freqloreta.(freqloretaFields{iField}), tmpMat2) )))
                ROI_list_add = [ROI_list_add iROI];
            end
        end
    end
    ROI_list = union(ROI_list, ROI_list_add);
    
end

% streaming file
if ~isempty(g.input.streamFile)
    [streamFileData, g.input.chanlocs] = nfblab_loadfile(g.input.streamFile);
    if streamFileData.srate ~= g.input.srate
        error('Warning: Stream file sampling rate different from streaming rate ********* ');
    end
    disp('Warning: Processing data file, overwritting session duration');
    g.session.baselineSessionDuration = ceil(size(streamFileData.data,2)/32);
    g.session.sessionDuration         = ceil(size(streamFileData.data,2)/32);
    if isempty(g.input.chans)
        g.input.chans = 1:streamFileData.nbchan;
    end
end
    
% check if one need to extract events and if the windows are large enough
% g.measure.evt does not change but evt does
[evt,nonEventChans] = nfblab_epochcheck(g.measure.evt, g.input.chans, g.input.windowSize, g.input.windowInc, g.input.srateHardware, g.input.srate);

% make sure the function can be run again
onCleanup(@() nfblab_cleanup);
chunkPerSec   = ceil(g.input.srate/g.input.windowInc);

if ~strcmpi(g.session.runmode, 'trial') && ~strcmpi(g.session.runmode, 'baseline') && ~strcmpi(g.session.runmode, 'slave')
    error('Wrong run type')
elseif strcmpi(g.session.runmode, 'baseline')
    % generate 1 command per second
    msg = [];
    if isempty(g.input.streamFile)
        msg(end+1).command = 'lslconnect';
    end
    msg(end+1).command = 'start';
    msg(end).options.runmode     = 'baseline';
    msg(end+g.session.baselineSessionDuration*chunkPerSec).command = 'stop';
    msg(end+1).command = 'quit';
    iMsg = 1;
elseif strcmpi(g.session.runmode, 'trial')
    if isequal(g.session.fileNameAsrDefault, g.session.fileNameAsr) && (g.preproc.asrFlag || g.preproc.icaFlag || g.preproc.badchanFlag)
        asrFiles = dir('*asr_filter*.mat');
        if isempty(asrFiles)
            error('No baseline file found in current folder, run baseline first');
        else
            fprintf('\nBaseline files available in current folder:\n');
            for iFile = 1:length(asrFiles)
                fprintf('%d - %s\n', iFile, asrFiles(iFile).name);
            end
            fprintf('------\n');
            iFile = input('Enter file number above to use for baseline:');
            g.session.fileNameAsr = asrFiles(iFile).name;
        end
    end
    % generate 1 command per second
    msg = [];
    if isempty(g.input.streamFile)
        msg(end+1).command = 'lslconnect';
    end
    msg(end+1).command = 'start';
    msg(end).options.runmode = 'trial';
    msg(end+g.session.sessionDuration*chunkPerSec).command = 'stop';
    msg(end+1).command = 'plotERSP';
    msg(end+1).command = 'quit';
    iMsg = 1;
end

dataBuffer     = zeros(length(g.input.chans), (g.input.windowSize*2)/g.input.srate*g.input.srateHardware);
dataBufferFilt = zeros(length(g.input.chans), (g.input.windowSize*2)/g.input.srate*g.input.srateHardware);
dataBufferPointer = 1;

dataAccuOri  = zeros(length(g.input.chans), (g.session.sessionDuration+3)*g.input.srate, 'single'); % to save the data
dataAccuFilt = zeros(length(g.input.chans), (g.session.sessionDuration+3)*g.input.srate, 'single'); % to save the data
dataAccuPointer = 1;
feedbackVal    = 0.5;       % initial feedback value

% create TCP/IP socket
oldFeedback = 0;
if g.session.TCPIP
    if ~isnan(g.session.TCPport)
        kkSocket  = ServerSocket( g.session.TCPport );
        fprintf('Trying to accept connection from client (if program get stuck here, check client)...\n');
        connectionSocket = kkSocket.accept();
        outToClient  = PrintWriter(connectionSocket.getOutputStream(), true);
        inFromClient = BufferedReader(InputStreamReader(connectionSocket.getInputStream()));
    end
end

chunkMarker   = zeros(1, g.session.sessionDuration*chunkPerSec);
chunkPower    = zeros(1, g.session.sessionDuration*chunkPerSec);
chunkFeedback = zeros(1, g.session.sessionDuration*chunkPerSec);
chunkDynRange = zeros(2, g.session.sessionDuration*chunkPerSec); % FIX THIS NOT INCREASED IN SIZE AND GENERATE CRASH WHEN SAVING BECAUSE OUT OF BOUND ARRAY
chunkThreshold = zeros(1, g.session.sessionDuration*chunkPerSec);
chunkCount    = 1;
warning('off', 'MATLAB:subscripting:noSubscriptsSpecified'); % for ASR

% initialize feedback
% -------------------
if ~isempty(g.feedback.funcinit)
    feedbackFuncStruct = feval(g.feedback.funcinit, g);
else
    feedbackFuncStruct = [];
end

currentMode = 'pause';
currentMsg  = '"Ready"';
verbose = 1;
inlet  = [];
fidRaw = [];
state  = [];
eegPointer = 1; % for offline file

% variables
threshold = g.feedback.threshold;
dynRange  = g.feedback.dynRange;

while 1
    
    % wait for first command
    if verbose > 0
        fprintf('Feedback %s sent to client (if any)\n',currentMsg);
    end
    if g.session.TCPIP
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
                    if verbose > 0
                        fprintf(2, 'Message received: %s\n', response);
                    end
                end
            end
        end
    elseif ~isempty(g.session.checkglobalmsg)
        drawnow;
        structResp = evalin('base', g.session.checkglobalmsg);
        evalin('base', [ g.session.checkglobalmsg '.command = [];' g.session.checkglobalmsg '.options = [];' ]);
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
        for iField = 1:length(fieldJson)
            % show option to use
            if ischar(structResp.options.(fieldJson{iField}))
                fprintf('Decoding option %s: %s\n', fieldJson{iField}, structResp.options.(fieldJson{iField}));
            else
                fprintf('Decoding option %s (%s)\n', fieldJson{iField}, class(structResp.options.(fieldJson{iField})));
            end
            
            g = nfblab_setfields(g, fieldJson{iField}, structResp.options.(fieldJson{iField}));
            
            % handle freqprocess parameter
            if ~isempty(g.custom) && ~isempty(findstr(fieldJson{iField}, g.custom.field))
                eval(g.custom.func);
            end
            
            % handle freqprocess parameter
            if ~isempty(findstr(fieldJson{iField}, 'freqprocess')) % freqprocess or addfreqprocess
                for iFieldProc = fieldnames(g.measure.freqprocess)'
                    if ischar(g.measure.freqprocess.(iFieldProc{1}))
                        g.measure.freqprocess.(iFieldProc{1}) = eval(g.measure.freqprocess.(iFieldProc{1}));
                    end
                end
            end
        end
        
        if strcmpi(structResp.command, 'lslconnect')
            % instantiate the LSL library
            if isempty(inlet)
                disp('Loading the library...');
                lib = lsl_loadlib();
                
                % resolve a stream...
                disp('Resolving an EEG stream...');
                result = {};
                result = nfblab_findlslstream(lib,g.input.lsltype,g.input.lslname);
                disp('Opening an inlet...');
                inlet = lsl_inlet(result{1});
                disp('Now receiving chunked data...');
            end

        elseif strcmpi(structResp.command, 'start')
            chunkCount = 1; % restart all counters
            fprintf('Starting new session...\n', g.session.fileNameAsr);
            currentMode = 'run';
            stateAsr = [];
            if strcmpi(g.session.runmode, 'trial') && ( g.preproc.asrFlag || g.preproc.icaFlag || g.preproc.badchanFlag )
                [stateAsr, dynRange, g.preproc.icaWeights, g.preproc.icaWinv, g.preproc.icaRmInd, g.preproc.badChans] = nfblab_loadasr(g.session.fileNameAsr);
            end
            
            % check if a file for saving need to be created
            if ~isempty(g.session.fileNameRaw)
                EEG = nfblab_saveset(g.session.fileNameRaw, g.input.chans, g.input.srate, g.input.chanlabels);
                fidRaw = fopen(EEG.data, 'wb');
                if fidRaw == -1, fidRaw = []; end
            end
            
        elseif strcmpi(structResp.command, 'stop')
            if strcmpi(currentMode, 'paused')
                disp('Cannot stop when in "paused" mode');
            else
                fprintf('Ending session...\n', g.session.fileNameAsr);
                % save state
                chunkMarkerSave    = chunkMarker(1:chunkCount-1);
                chunkPowerSave     = chunkPower(1:chunkCount-1);
                chunkFeedbackSave  = chunkFeedback(1:chunkCount-1);
                chunkDynRangeSave  = chunkDynRange(:,1:chunkCount-1);
                chunkThresholdSave = chunkThreshold(1:chunkCount-1);

                % select calibration data
                dataAccuOriSave  = dataAccuOri( :, 1:dataAccuPointer-1); % last second of data might be lost because still in buffer
                dataAccuFiltSave = dataAccuFilt(:, 1:dataAccuPointer-1); % last second of data might be lost because still in buffer
                
                if strcmpi(g.session.runmode, 'baseline')
                    if g.preproc.badchanFlag
                        disp('Detecting bad channels...');
                        badChans = nfblab_badchans(dataAccuFiltSave(nonEventChans,:), EEG.srate, g.input.chanlocs, g.preproc.chanCorr);
                    else
                        badChans = [];
                    end
                    if g.preproc.asrFlag
                        disp('Calibrating ASR...');
                        stateAsr = asr_calibrate(dataAccuFiltSave, g.input.srateHardware, g.preproc.asrCutoff, [], [], [], [], [], [], [], 64);
                        dataAccuFiltSave(nonEventChans,:) = asr_process(dataAccuFiltSave(nonEventChans,:), g.input.srateHardware, stateAsr, [],[],[],[],64);
                    end
                    if g.preproc.icaFlag
                        [icaWeights, icaWinv, icaRmInd] = nfblab_ica(dataAccuFiltSave(nonEventChans,:), EEG.srate, EEG.chanlocs, g.preproc.averefFlag+length(badChans));
                        icaAct = icaWeights(icaRmInd,:)*dataAccuFiltSave(nonEventChans,:);
                        dataAccuFiltSave(nonEventChans,:) = dataAccuFiltSave(nonEventChans,:)-icaWinv(:,icaRmInd)*icaAct;
                    else
                        [icaWeights, icaWinv, icaRmInd] = deal([]);
                    end
                    save('-mat', g.session.fileNameAsr, 'stateAsr', 'dynRange', 'dataAccuOriSave', 'dataAccuFiltSave', 'chunkMarkerSave', 'chunkPowerSave', 'chunkFeedbackSave', 'chunkDynRangeSave', 'chunkThresholdSave', 'icaWeights', 'icaWinv', 'icaRmInd', 'badChans', 'g');
                    fprintf('Saving Baseline file %s\n', g.session.fileNameAsr);
                else
                    % close text file
                    save('-mat', g.session.fileNameOut, 'stateAsr', 'dynRange', 'dataAccuOriSave', 'dataAccuFiltSave', 'chunkMarkerSave', 'chunkPowerSave', 'chunkFeedbackSave', 'chunkDynRangeSave', 'chunkThresholdSave', 'g');
                    fprintf('Saving file %s\n', g.session.fileNameOut);
                end

                currentMode = 'pause';
                currentMsg  = '"paused"';
                chunkCount    = 1;
                if ~isempty(fidRaw), fclose(fidRaw); fidRaw = []; end
            end
        elseif strcmpi(structResp.command, 'quit')
            fprintf('Quitting...\n');
            if g.session.TCPIP
                connectionSocket.close();
                kkSocket.close();
            end
            if ~isempty(fidRaw), fclose(fidRaw); fidRaw = []; end
            break;
        elseif strcmpi(structResp.command, 'disconnect')
            fprintf('Disconnecting...\n');
            if g.session.TCPIP
                connectionSocket.close();
            end
            currentMode = 'disconnected';
            if ~isempty(fidRaw), fclose(fidRaw); fidRaw = []; end
        elseif strcmpi(structResp.command, 'plotERSP')
            nfblab_epochersp(evt, g.input.srate);
        elseif ~isempty(structResp.command)
            fprintf('Unknown command: %s\n', structResp.command);
        end
    end
    
    % run mode
    if strcmpi(currentMode, 'run')
                
        %% create a new inlet
        tic;
        EEG = eeg_emptyset;
        EEG.nbchan = length(g.input.chans);
        EEG.srate  = g.input.srate;
        EEG.xmin   = 0;
        if isfield(g.input, 'chanlocs') && ~isempty(g.input.chanlocs)
            EEG.chanlocs = g.input.chanlocs(g.input.chans); % required for Loreta
        else
            EEG.chanlocs = [];
        end
        % tmp = load('-mat','chanlocs.mat');
        % EEG.chanlocs = tmp.chanlocs;
        prevX      = [];
        winPerSec = g.input.windowSize/g.input.windowInc;
        chunkSize = g.input.windowInc*g.input.srateHardware/g.input.srate; % at 512 so every 1/4 second is 128 samples
        tic;
        
        lastChunkTime = [];
        if isempty(g.measure.freqprocess)
            freqprocessFields = {};
        else
            freqprocessFields = fieldnames(g.measure.freqprocess);
        end
        
        % pause between each loop
        pause(g.session.pauseSecond);
        
        % get chunk from the inlet
        currentMsg = '"Streaming"';
        if isempty(g.input.streamFile) 
            if ~isempty(inlet)
                [chunk,~] = inlet.pull_chunk();
                % fprintf('Size of chuck: %d,%d\n', size(chunk,1), size(chunk,2));
            else
                chunk = [];
            end
        else
            if eegPointer+31 > size(streamFileData.data,2)
                chunk = streamFileData.data(:,eegPointer:end);
                eegPointer = size(streamFileData.data,2)+1;
                msg(iMsg).command = 'stop';
                msg(iMsg+1).command = 'quit';
                msg(iMsg+2:end) = [];
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
            chunk = chunk(g.input.chans,:);

            % write raw data
            if ~isempty(fidRaw)
                fwrite(fidRaw, chunk, 'float');
            end
            
            % filter chunk
            if g.preproc.filtFlag
                if size(chunk,2) == 1, error('Filter cannot process a single sample - increase ''pauseSecond'' parameter'); end
                chunkFilt = chunk';
                [chunkFilt(:,nonEventChans),state] = filter(g.preproc.B,g.preproc.A,chunk(nonEventChans,:)',state);
                chunkFilt = chunkFilt';
            else
                chunkFilt = chunk;
            end
            
            % interpolate channels
            if g.preproc.badchanFlag && ~strcmpi(g.session.runmode, 'baseline')
                chunkFilt(nonEventChans,:) = nfblab_interp(chunkFilt(nonEventChans,:), g.input.chanlocs, g.preproc.badChans);
            end
            
            % rereference
            %EEG.data = bsxfun(@minus, EEG.data,mean(EEG.data([24 61],:))); % P9 and P10
            if g.preproc.averefFlag || g.measure.loretaFlag
                chunkFilt(nonEventChans,:) = bsxfun(@minus, chunkFilt(nonEventChans,:), mean(chunkFilt(nonEventChans,:))); % average reference
            end
                
           % apply ASR on chunk
            if g.preproc.asrFlag && ~strcmpi(g.session.runmode, 'baseline')
                [chunkFilt(nonEventChans,:), stateAsr]= asr_process(chunkFilt(nonEventChans,:), g.input.srateHardware, stateAsr, [],[],[],[],64);
            end
            
            % apply ICA
            if g.preproc.icaFlag && ~strcmpi(g.session.runmode, 'baseline')
                icaAct = g.preproc.icaWeights(g.preproc.icaRmInd,:)*chunkFilt(nonEventChans,:);
                chunkFilt(nonEventChans,:) = chunkFilt(nonEventChans,:)-g.preproc.icaWinv(:,g.preproc.icaRmInd)*icaAct;
            end
            
            % copy data to buffers
            dataBuffer(    :,dataBufferPointer:dataBufferPointer+size(chunk,2)-1) = chunk;
            dataBufferFilt(:,dataBufferPointer:dataBufferPointer+size(chunk,2)-1) = chunkFilt;
            dataBufferPointer = dataBufferPointer+size(chunk,2);
            %fprintf('Data buffer pointer increased: %d\n', dataBufferPointer);
        end
        
        if dataBufferPointer > chunkSize
            
            % estimate sampling rate
            if ~isempty(lastChunkTime) && g.session.warnsrate
                sRateEstimated = chunkSize/(toc - lastChunkTime);
                if abs(g.input.srateHardware-sRateEstimated) > 0.1*g.input.srateHardware
                    fprintf('Warning: estimated heart rate %d Hz compared to %d Hz set in nfblab_options.m\n', round(sRateEstimated), round(g.input.srateHardware));
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
                results = [];
                
                % Decimate and create EEG structure of 1 second
                if g.input.srateHardware == g.input.srate
                    EEG.data = dataAccuFilt(:,dataAccuPointer-chunkSize*winPerSec:dataAccuPointer-1);
                elseif g.input.srateHardware == 2*g.input.srate
                    EEG.data = dataAccuFilt(:,dataAccuPointer-chunkSize*winPerSec:2:dataAccuPointer-1);
                elseif g.input.srateHardware == 4*g.input.srate
                    EEG.data = dataAccuFilt(:,dataAccuPointer-chunkSize*winPerSec:4:dataAccuPointer-1);
                elseif g.input.srateHardware == 8*g.input.srate
                    EEG.data = dataAccuFilt(:,dataAccuPointer-chunkSize*winPerSec:8:dataAccuPointer-1);
                else
                    error('Processing sampling rate not a multiple of hardware acquisition sampling rate');
                end

                % process event information if any
                [evt,epochFeedback] = nfblab_epochprocess(EEG, evt); % param 3, true or false for verbose
                if exist('results') && isfield(results, 'epochFeedback'), results = rmfield(results, 'epochFeedback'); end
                if ~isempty(epochFeedback), results.epochFeedback = epochFeedback; end
                 
                % make compliant EEGLAB dataset
                EEG.pnts = size(EEG.data,2);
                EEG.nchan = size(EEG.data,1);
                EEG.xmax = EEG.pnts/EEG.srate;
                if g.measure.loretaFlag
                    
                    opt.loreta_P = loreta_P;
                    opt.loreta_Networks = loreta_Networks;
                    opt.loreta_ROIS     =loreta_ROIS;
                    [~,results] = roi_network(EEG, 'networkfile', opt, 'nfft', g.measure.nfft, 'freqrange', g.measure.freqrange, 'freqdb', g.measure.freqdb, ...
                        'processfreq', g.measure.freqloreta, 'processconnect', g.measure.connectproces, 'roilist', ROI_list);
                end
                
                % Apply linear transformation (get channel Fz at that point)
                spatiallyFilteredData = g.input.chanmask*EEG.data;

                % Perform spectral decomposition - taper the data with hamming
                dataSpec = fft(bsxfun(@times, spatiallyFilteredData', hamming(size(spatiallyFilteredData,2))), g.measure.nfft);
                freqs  = linspace(0, EEG.srate/2, floor(g.measure.nfft/2)+1);
                
                % select frequency bands
                dataSpecSelect = zeros(size(spatiallyFilteredData,1), length(g.measure.freqrange));
                for iSpec = 1:length(g.measure.freqrange)
                    freqRangeTmp = intersect( find(freqs >= g.measure.freqrange{iSpec}(1)), find(freqs <= g.measure.freqrange{iSpec}(2)) );
                    dataSpecSelect(:,iSpec) = mean(abs(dataSpec(freqRangeTmp,:)).^2,1); % mean power in frequency range
                    if g.measure.freqdb
                        dataSpecSelect(:,iSpec) = 10*log10(dataSpecSelect(:,iSpec)); % Warning: log done after averaging power in freq range
                    end
                end
                
                % compute metric of interest
                for iProcess = 1:length(freqprocessFields)
                    results.(freqprocessFields{iProcess}) = feval(g.measure.freqprocess.(freqprocessFields{iProcess}), dataSpecSelect);
                end
                
                % normalize all fields
                if ~isempty(g.measure.normfile)
                    results = nfblab_zscore(results, g.measure.normfile, g.measure.normagerange);
                end
                
                % get feedback field
                if ~isempty(g.feedback.feedbackfield)
                    X = results.(g.feedback.feedbackfield);
                else
                    X = Inf;
                end
                if length(X) > 1
                    fprintf(2, 'Cannot process feedback field because its length is more than 1\n');
                    g.feedback.feedbackfield = [];
                    X = Inf;
                end
                
                % cap spectral change for feedback measure
                if ~isempty(prevX)
                    if X > prevX+g.feedback.capdBchange, X = prevX+g.feedback.capdBchange; end
                    if X < prevX-g.feedback.capdBchange, X = prevX-g.feedback.capdBchange; end
                end
                prevX = X;
                
                % save power and pointer position
                chunkMarker(chunkCount) = dataAccuPointer;
                chunkPower( chunkCount) = X;
                chunkFeedback( chunkCount) = 0;
                chunkDynRange(:,chunkCount) = 0;
                chunkThreshold(chunkCount) = 0;
                if chunkCount > g.session.sessionDuration*chunkPerSec
                    disp('Standard buffer size exceeded - we recommend increasing session duration');
                end
                
                if ~isinf(X)
                    if strcmpi(g.feedback.feedbackMode, 'dynrange')
                        % assess if value position within a range
                        % and return output from 0 to 1
                        totalRange = dynRange(2)-dynRange(1);
                        feedbackValTmp = (X-dynRange(1))/totalRange;
                        if feedbackValTmp > 1, dynRange(2) = dynRange(2)+g.feedback.dynRangeInc*totalRange; feedbackValTmp = 1;
                        else                   dynRange(2) = dynRange(2)-g.feedback.dynRangeDec*totalRange;
                        end
                        if feedbackValTmp < 0, dynRange(1) = dynRange(1)-g.feedback.dynRangeInc*totalRange; feedbackValTmp = 0;
                        else                   dynRange(1) = dynRange(1)+g.feedback.dynRangeDec*totalRange;
                        end
                        if feedbackValTmp<feedbackVal
                            if abs(feedbackValTmp-feedbackVal) > g.feedback.maxChange, feedbackVal = feedbackVal-g.feedback.maxChange;
                            else                                              feedbackVal = feedbackValTmp;
                            end
                        else
                            if abs(feedbackValTmp-feedbackVal) > g.feedback.maxChange, feedbackVal = feedbackVal+g.feedback.maxChange;
                            else                                              feedbackVal = feedbackValTmp;
                            end  
                        end
                        chunkDynRange(:,chunkCount) = dynRange;
                        % fprintf('Spectral power %2.3f - output %1.2f - %1.2f [%1.2f %1.2f]\n', X, feedbackVal, feedbackValTmp, dynRange(1), dynRange(2));
                    elseif strcmpi(g.feedback.feedbackMode, 'threshold')
                        % simply assess if value above threshold
                        % and return binary output
                        if strcmpi(g.feedback.thresholdMode, 'stop')
                             feedbackVal = X < threshold;
                        else feedbackVal = X > threshold;
                        end
                        
                        % recompute threshold
                        threshold = threshold*g.feedback.thresholdMem + X*(1-g.feedback.thresholdMem);
                        
                        % use percentage over a past window
                        chunkPerSecFloat = EEG.srate/g.input.windowInc;
                        if chunkCount > g.feedback.thresholdWin*chunkPerSecFloat
                            if strcmpi(g.feedback.thresholdMode, 'stop')
                                 threshold = quantile(chunkPower(chunkCount-floor(g.feedback.thresholdWin*chunkPerSecFloat):chunkCount), g.feedback.thresholdPer);
                            else threshold = quantile(chunkPower(chunkCount-floor(g.feedback.thresholdWin*chunkPerSecFloat):chunkCount), 1-g.feedback.thresholdPer);
                            end
                        else
                            if strcmpi(g.feedback.thresholdMode, 'stop')
                                 threshold = quantile(chunkPower(1:chunkCount), g.feedback.thresholdPer);
                            else threshold = quantile(chunkPower(1:chunkCount), 1-g.feedback.thresholdPer);
                            end
                        end
                        chunkThreshold(chunkCount) = threshold;
                        %results.thresholdMem = thresholdMem;
                        %results.thresholdWin = thresholdWin;
                        %results.chunkPerSecFloat = chunkPerSecFloat;
                        results.thresholdPer = g.feedback.thresholdPer;
                        %results.chunkCount = chunkCount;
                        
                        % fprintf('Spectral power %2.3f - output %1.0f - threshold %1.2f\n', X, feedbackVal, threshold);
                    end
                end
                if isempty(feedbackVal)
                    chunkFeedback(chunkCount) = NaN;
                else
                    chunkFeedback(chunkCount) = feedbackVal;
                end
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
                if strcmpi(g.session.runmode, 'trial') 
                    if ~isempty(g.feedback.funcfeedback)
                        feedbackFuncStruct = feval( g.feedback.funcfeedback, feedbackFuncStruct, feedbackVal, chunkPower, chunkCount);
                    end
                end
            end
        end
    end
end

if ~isempty(g.feedback.funcend)
    feval(g.feedback.funcend, feedbackFuncStruct);
end

function S = cpsd_welch(X,window,noverlap, nfft)

h = nfft/2+1;
n = size(X,1);
S = complex(zeros(n,n,h));
for i = 1:n
    S(i,i,:) = pwelch(X(i,:),window,noverlap,nfft);          % auto-spectra
    for j = i+1:n % so we don't compute cross-spectra twice
        S(i,j,:) = cpsd(X(i,:),X(j,:),window,noverlap,nfft); % cross-spectra
    end
end
S = S/pi; % the 'pi' is for compatibility with 'autocov_to_cpsd' routine

