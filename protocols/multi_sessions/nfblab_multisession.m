disp('************************************************');
disp('This program runs is designed to run Neurofeedback on multiple sessions')
disp('To run a single session, call nfblab_process')
disp('THIS IS A LEGACY PROGRAM USE IN THIS PUBLICATION');
disp('https://www.frontiersin.org/articles/10.3389/fnhum.2020.00246/full');
disp('THIS PROGRAM MIGHT STILL BE FUNCTIONAL')
disp('BUT IT HAS NOT BEEN MAINTAINED')
disp('************************************************');

addpath(fullfile(pwd, '..','..'));
currentp = which('nfblab_process.m');
cd(fileparts(currentp));

% start BCILAB
% ------------
if ~exist('asr_process') || ~exist('eeg_emptyset')
    if ~exist('bcilab')
        error('Cannot find BCILAB. Make sure BCILAB is in your path');
    else
        bcilab;
        close;
        cd(fileparts(currentp));
    end
end

% check LSL
% ---------
if ~exist('lsl_loadlib')
    error('Cannot find Lab Streaming Layer - make sure the liblsl-Matlab folder is in your path');
else
    fprintf(2, 'Make sure your EEG device is streaming on LSL')
    fprintf(2, 'If this program cannot find it, change the options when calling nfblab_process')
end

%% Subject name
% ------------
subjectName = input('Initials of the subject:','s');
subjectName = lower(subjectName);

if exist(subjectName) ~= 7
    error([ 'This subject does not exist, first create a folder with the intial of the subject (lower case) - then start this program again' ]);
end
%hashcodefile = fullfile(subjectName, ['hashcode_' subjectName '.mat' ]);
%if ~exist(hashcodefile)
%    error([ 'This subject does not have a hashcode file' ]);
%end;

session = input('Neurofeedback session number on separate days (1 to 9):');
if session < 1 || session > 12
    error('Session must be between 1 and 9')
end

trial = input('Neurofeedback run number on the same day (0 to 9 - 0 is baseline):');
if trial < 0 || trial > 10
    error('Run must be between 0 and 9')
end

% scan all subjects in folder
% read their data
% have neurofeedback process replay their data

c = clock;
timeTag2 = [sprintf('%04.0f',c(1)) '-' sprintf('%02.0f',c(2)) '-' sprintf('%02.0f',c(3))];
timeTag = [timeTag2 '-' sprintf('%02.0f',c(4)) 'h' sprintf('%02.0f',c(5))];
asrFileName = fullfile(subjectName, ['baseline_' int2str(session) '_' timeTag2 '_ASR_state.mat' ]);
fprintf('ASR file name is: %s\n', asrFileName)
if trial == 0
    
    % ------------------------------------------------------------
    % this section of the code record one minute of baseline
    % ------------------------------------------------------------
    if exist(asrFileName)
        input([ 10 'The baseline file already exist for this session' 10 'Are you sure you want to erase it (CTRL-C to exit/Enter to continue)' ]);
    end
    fileList = dir(fullfile(subjectName, 'baseline_*'));
    fileList = { fileList.name };
    fileNum  = cellfun(@(x)str2num(x(10)), fileList);
    if ~isempty(fileNum) && max(fileNum)+1 ~= session
        input([ 10 'The previous baseline session file was ' int2str(max(fileNum)) 10 'Are you sure you want to run baseline session ' int2str(session) ' (CTRL-C to exit/Enter to continue)' ]);
    end
    s = input('Is the EEG data being saved using LSL Labrecorded - press enter when ready or if you do not want to save it (Enter/CTRL-C to exit)','s');
    
    nfblab_process('runmode', 'baseline', 'fileNameAsr', asrFileName)
    %save(asrFileName, '-mat', 'fileList');
else
    
    % ------------------------------------------------------------
    % this section of the code is the actual neurofeedback session
    % ------------------------------------------------------------
    if ~exist(asrFileName)
        error('ASR (artifact) file for this DAY does not exist - please run baseline first for this session')
    end
    fileName = fullfile(subjectName, ['session_' int2str(session) '_trial_' int2str(trial) '_' timeTag '.txt' ]);
    if exist(fileName)
        input([ 10 'This session/trial already exist' 10  'Are you sure you want to erase it (CTRL-C to exit/Enter to continue)' ]);
    end
    fileList = dir(fullfile(subjectName, [ 'session_' int2str(session) '_*' ]));
    fileList = { fileList.name };
    fileNum  = cellfun(@(x)str2num(x(17)), fileList);
    if ~isempty(fileNum) && max(fileNum)+1 ~= trial
        input([ 10 'The previous trial for this session was ' int2str(max(fileNum)) 10 'Are you sure you want to run trial ' int2str(trial) ' (CTRL-C to exit/Enter to continue)' ]);
    end
    s = input('Is the EEG data being saved using LSL Labrecorded - press enter when ready or if you do not want to save it (Enter/CTRL-C to exit)','s');
    
    nfblab_process('runmode', 'trial', 'fileNameAsr', asrFileName, 'fileNameOut', fileName)
    %save(fileName, '-mat', 'fileList');
end
