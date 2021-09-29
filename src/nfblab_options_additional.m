% ***************************
%
% ADDITIONAL SETTINGS
%
% ***************************

% ***************************
% PREDEFINED MONTAGE CHANGING
% DEFAULT SETTIGNS ABOVE
% ***************************

%custom_config = 'none';
custom_config = 'muse';
%custom_config = 'offline-simple';
%custom_config = 'offline-epoch';

%custom_config = 'offline-loreta24';
%custom_config = 'offline-loreta32';
%custom_config = 'offline-loreta-braindx';
depthCall = dbstack;
if length(depthCall) > 2
    custom_config = 'batch_mode';
    disp('***************************');
    disp('*** BATCH CALL DETECTED ***');
    disp('***************************');
end

% ****************************************
% default paramters for all configurations
% ****************************************
g.session.TCPIP        = false;
g.session.runmode      = 'slave';
g.session.warnsrate    = true;

g.input.fileNameRaw = 'test.set';
g.input.lsltype       = '';

% these frequency parameters are common to all montages
g.measure.freqrange      = { [4 8] [8 12] [8 10] [10 12] [18 22] [4 10] [12 15] [20 30] };
g.measure.freqprocess = [];
g.measure.freqprocess.theta = @(x)sum(x([2 4 5 3],1)); % Average theta power
g.measure.freqloreta.loretaztheta = @(x)x(77,1); % area 77 theta
%g.freqloreta.loretaztheta = @(x)x(:,:); % all areas; all frequencies
g.measure.evt = [];

% field to use for feedback
g.feedback.feedbackfield = fieldnames(g.measure.freqprocess);
g.feedback.feedbackfield = g.feedback.feedbackfield{end};
g.feedback.feedbackMode = 'threshold';
g.feedback.simplePlot   = false;

switch custom_config
    case 'none'
    case 'muse'
        g.input.chans    = [1 2 3 4]; % indices of data channels
        g.input.chanmask = zeros(10,4); 
        g.input.chanmask(1,1)  =  1;
        g.input.chanmask(2,2)  =  1;
        g.input.chanmask(3,3)  =  1;
        g.input.chanmask(4,4)  =  1;
        g.input.chanmask(5,1)  =  1;
        g.input.chanmask(6,2)  =  1;
        g.input.chanmask(7,3)  =  1;
        g.input.chanmask(8,4)  =  1;
        g.input.chanmask(9,1)  =  1;
        g.input.chanmask(10,2) =  1;
        g.input.srate    = 250;
        g.input.srateHardware = 250;
        g.input.windowSize    = 250; % length of window size for FFT (if equal to srate then 1 second)
        g.input.nfft          = 250; % length of FFT - allows FFT padding if necessary
        g.input.windowInc     = 75;  % window increment - in this case update every 1/4 second
        
        % configuration local
        g.session.runmode = [];
        g.session.TCPIP = false;
        
        g.input.lslname  = '';
        g.input.lsltype  = 'EEG';
        g.session.pauseSecond    = 0.2;
        disp('CAREFUL: using alternate configuration in nfblab_option');
        g.input.streamFile = '';
        
    case 'offline-simple'
        p = fileparts(which('nfblab_options.m'));
        streamFile = fullfile(p, 'eeglab_data.set'); % if not empty stream a file instead of using LSL
        chans    = [1:32]; % indices of data channels
        % chanlabels = { 'FPz' 'EOG1' 'F3' 'Fz' 'F4' 'EOG2' 'FC5' 'FC1' 'FC2' 'FC6' 'T7' 'C3' 'C4' 'Cz' 'T8' 'CP5' 'CP1' 'CP2' 'CP6' 'P7' 'P3' 'Pz' 'P4' 'P8' 'PO7' 'PO3' 'POz' 'PO4' 'PO8' 'O1' 'Oz' 'O2' };
                        %   1      2    3    4    5      6     7     8     9    10   11   12   13   14   15    16    17    18    19   20   21   22   23   24  
        chanmask = zeros(10,32);
        chanmask(1,4)  =  1; % this virtual channel is Fz
        chanmask(2,14) =  1; % this virtual channel is Cz
        chanmask(3,22) =  1; % this virtual channel is Pz
        chanmask(4,21) =  1; % this virtual channel is P3
        chanmask(5,23) =  1; % this virtual channel is P4
        chanmask(6,3)  =  1; % this virtual channel is F3
        chanmask(7,5)  =  1; % this virtual channel is F4
        chanmask(8,12) =  1; % this virtual channel is C3
        chanmask(9,13) =  1; % this virtual channel is C4
        chanmask(10,13)=  1; chanmask(10,22) = -1; % this virtual channel is C4-Pz
        %chanmask = eye(32);
        srate    = 128;
        srateHardware = 128;
        windowSize    = 128; % length of window size for FFT (if equal to srate then 1 second)
        nfft          = 128; % length of FFT - allows FFT padding if necessary
        windowInc     = 32;  % window increment - in this case update every 1/4 second
        pauseSecond   = 0;

        %TCPIP         = true;
        %TCPport       = 9789;
        %pauseSecond   = 0.24;
        %TCPformat = 'json';
        disp('CAREFUL: using alternate configuration in nfblab_option');
        
    case 'offline-epoch'
        p = fileparts(which('nfblab_options.m'));
        streamFile = fullfile(p, 'xxx.xdf'); % if not empty stream a file instead of using LSL
        chans    = [1:13]; % indices of data channels
        chanmask = zeros(10,13);
        chanmask(1,1)  =  1; % this virtual channel is Fz
        chanmask(2,2)  =  1; % this virtual channel is Cz
        chanmask(3,3)  =  1; % this virtual channel is Pz
        chanmask(4,4)  =  1; % this virtual channel is P3
        chanmask(5,5)  =  1; % this virtual channel is P4
        chanmask(6,6)  =  1; % this virtual channel is F3
        chanmask(7,7)  =  1; % this virtual channel is F4
        chanmask(8,8)  =  0; % this virtual channel is C3 (not present in this montage)
        chanmask(9,8)  =  1; % this virtual channel is C4
        chanmask(10,8) =  1; chanmask(10,3) = -1; % this virtual channel is C4-Pz
        
        %chanmask = eye(32);
        srate    = 128;
        srateHardware = 128;
        windowSize    = 128; % length of window size for FFT (if equal to srate then 1 second)
        nfft          = 128; % length of FFT - allows FFT padding if necessary
        windowInc     = 32;  % window increment - in this case update every 1/4 second
        pauseSecond   = 0;
        disp('CAREFUL: using alternate configuration in nfblab_option');
    
        % FOR EVENT EXTRACTION, YOU MUST CONSIDER FILTER AND ASR DELAYS
        % AND CORRECT/OFFSET LATENCIES ACCORDINGLY. FOR EXAMPLE, IF YOUR
        % FILTER INTRODUCE A 100 ms DELAY, ADD 100 ms to epochRange
        evt.eventChan        = 11; % extract epoch on non-0
        evt.respChan         = 13; % WARNING: 12 for real-time file
        evt.eventVals        = [0.005];
        evt.respVals         = [-1 1];
        evt.epochLimits      = [-100 600]; % in milliseconds
        evt.epochBaseline    = [-100 0]; % otherwise indicate range
        evt.epochMemory      = [0.95 0.95];
        evt.epochRange       = [200 400];
        evt.epochFormula     = [1 -1];
        evt.epochMask        = zeros(1,13);
        evt.epochMask(1)     = 1;
        evt.epochMinN        = 2; % minimum number of epoch for feedback

        asrFlag          = true;
        sessionDuration  = 240;
        
    case 'offline-loreta32'
        clear runmode;
        loretaFlag = true;
        averefFlag = true;
        
        srate         = 128;
        srateHardware = 128;
        windowSize    = 128; % length of window size for FFT (if equal to srate then 1 second)
        nfft          = 128; % length of FFT - allows FFT padding if necessary
        windowInc     = 32;  % window increment - in this case update every 1/4 second
        
        p = fileparts(which('nfblab_options.m'));
        streamFile = fullfile(p, 'eeglab_data.set'); % if not empty stream a file instead of using LSL
        loreta_file = 'loreta_06172020_32.mat';
        chans = [1:32];
        chanmask = eye(32);
        
    case 'batch_mode'
        disp('CAREFUL: using alternate configuration in nfblab_option');
        g.session.pauseSecond   = 0;
        g.session.TCPIP = false;
        g.session.pauseSecond = 0;
                                        
        g.input.streamFile    = '';
        g.input.chans         = [1:19]; % indices of data channels
        g.input.chanmask      = eye(19);
        g.input.srate         = 250;
        g.input.srateHardware = 250;
        g.input.windowSize    = 250; % length of window size for FFT (if equal to srate then 1 second)
        g.input.windowInc     = 75;  % window increment - in this case update every 1/4 second
        
        g.preproc.averefFlag = true;
        g.preproc.asrFlag    = true;
        g.preproc.icaFlag    = true;
        
        g.measure.nfft           = 250; % length of FFT - allows FFT padding if necessary
        g.measure.freqrange      = {};
        g.measure.freqprocess    = [];
        g.measure.connectprocess = [];
        for iFreq = 1:30
            g.measure.freqrange{iFreq} = [iFreq-0.5 iFreq+0.49999999]; 
            g.measure.freqprocess.(sprintf('f%d', iFreq)) = eval(sprintf('@(x)x(:,%d);', iFreq));
        end
        g.measure.freqrange{31} = [12 15];
        g.measure.freqrange{32} = [4  10];
        g.measure.freqrange{33} = [20 30];
        g.measure.connectprocess.(sprintf('f1')) = eval(sprintf('@(x)squeeze(mean(mean(x(:,:,31),1),2));', iFreq));
        g.measure.connectprocess.(sprintf('f2')) = eval(sprintf('@(x)squeeze(mean(mean(x(:,:,32),1),2));', iFreq));
        g.measure.connectprocess.(sprintf('f3')) = eval(sprintf('@(x)squeeze(mean(mean(x(:,:,33),1),2));', iFreq));
        
        g.measure.loretaFlag     = false;
        %g.measure.loreta_file = 'loreta_hubs_04212021_19.mat';
                
        g.feedback.feedbackfield = [];
        
    otherwise 
        error('Unknown configuration');
end

% runmode = 'slave';
% msg = [];
% msg(end+1).command = 'start';
% msg(end).options.runmode = 'baseline';
% msg(end).options.fileNameAsr = 'test_test';
% msg(end+sessionDuration).command = 'stop';
% 
% msg(end+1).command = 'start';
% msg(end).options.runmode = 'trial';
% msg(end+sessionDuration).command = 'stop';
% 
% msg(end+1).command = 'start';
% msg(end).options.runmode = 'trial';
% msg(end+sessionDuration).command = 'stop';
% msg(end+1).command = 'quit';
% iMsg = 1;
% TCPIP = true;

