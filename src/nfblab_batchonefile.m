% Read all results for a given subject
%
% res = nfblab_batchonefile('sub-000xxx')
% res = nfblab_batchonefile('sub-000xxx', 'test.json');
%
% See also optional arguments

function [subjectData,spectrum] = nfblab_batchonefile(fileNames, fileOut, varargin)

spectrum = [];
if iscell(fileNames) && length(fileNames) == 1
    fileNames = fileNames{1};
end
if ischar(fileNames)
    [filePath, fileBase] = fileparts(fileNames);
else
    filePath = '';
    fileBase = '';
end

% check path
if ~isdeployed
    if ~exist('eeg_checkset.m', 'file')
        addpath('/data/matlab/eeglab');
        eeglab; close;
    end
end

[g,otheropts] = finputcheck(varargin, { ...
    'subjectid' '' {} '';
    'agefile'   '' {} '';
    'forceread' 'string' { 'on' 'off' 'log' } 'off';
    'deletelog' 'string' { 'on' 'off' } 'on';
    'customimportfunc' 'string' {} '';
    'fileNameAsr' 'string' {} fullfile(filePath, [ fileBase '_asr.mat' ]); ...
    'fileNameRaw' 'string' {} fullfile(filePath, [ fileBase '_nfblab.mat' ]); ...
    'fileNameOut' 'string' {} fullfile(filePath, [ fileBase '_out.mat' ]) }, 'nfblab_batchonefile', 'ignore');
if ischar(g)
    error(g);
end

subjectAge = [];
if ~isempty(g.subjectid)
    ageids = loadtxt(g.agefile);
    
    posUnderscore = find(g.subjectid == '_');
    currentIDs    = lower(g.subjectid(1:posUnderscore(1)-1));
    %     if currentIDs(end) == '0', currentIDs(end) = []; end
    %     if currentIDs(end) == '0', currentIDs(end) = []; end
    ind = strmatch(currentIDs, lower(ageids(:,1)), 'exact');
    if length(ind) ~= 1
        ind = strmatch([ currentIDs '00' ], lower(ageids(:,1)), 'exact');
        if length(ind) ~= 1
            error('Cannot find age for ID %s', g.subjectid);
        end
    end
    subjectAge = ageids{ind,2}; % set age
end

% process all files
subjectData = [];

if ischar(fileNames)
    allFiles = dir(fileNames);
end
for iFile = 1:length(allFiles)
    fileName = fullfile(allFiles(iFile).folder,  allFiles(iFile).name);
    subjectDataTmp = [];
    if allFiles(iFile).name(1) ~= '.' && exist(fileName, 'dir')
        
        subjectDataTmp = nfblab_batchonefile(fileName, varargin{:}); % recursive call
        
    elseif contains(fileName, '_eeg.') || ~strcmpi(g.forceread, 'off')
        
        [~,filetmp,~] = fileparts(allFiles(iFile).name);
        underS = find( filetmp == '_' );
        if length(underS) < 3 && strcmpi(g.forceread, 'off')
            error('Badly formated file name %s\n', filetmp);
        end
        
        statFile = fullfile(allFiles(iFile).folder, [ allFiles(iFile).name(1:end-8) '_stat.mat' ]);
        
        if ~exist(statFile, 'file') || ~strcmpi(g.forceread, 'off')

            % process file
            % ------------
            [filePath,fileNameTmp,ext] = fileparts(fullfile(allFiles(iFile).folder, allFiles(iFile).name));
            fileNameLog = fullfile(filePath, [ fileNameTmp '_log.txt' ]);
            if ~exist(fileNameLog, 'file') || ~strcmpi(g.forceread, 'log')

                % import data
                if ~isempty(g.customimportfunc)
                    EEG = feval(g.customimportfunc, fileName);
                else
                    switch ext
                        case '.csv'
                            error('CSV file not supported, use custom import')
                        case { '.set', '.set ' }
                            EEG = pop_loadset(fileName);
                        case '.xdf'
                            EEG = pop_loadxdf(fileName);
                        case '.edf'
                            EEG = pop_biosig(fileName);
                        case '.mat'
                            EEG = nfblab_mat2eeg(fileName);
                        otherwise
                            error('File not supported');
                    end
                end

                if ~isempty(EEG.data)
                    % recompute file
                    options = { 'preset', 'allfreqs', ...
                        'streamFile' EEG, ...
                        'fileNameRaw', g.fileNameRaw, ...
                        'fileNameOut', g.fileNameOut, otheropts{:} };

                    % baseline for ASR
                    gtmp = struct(options{:});
                    if (isfield(gtmp, 'asrFlag') && gtmp(1).asrFlag == 1) || ...
                            (isfield(gtmp, 'icaFlag') && gtmp(1).icaFlag == 1) || ...
                            (isfield(gtmp, 'badchanFlag') && gtmp(1).badchanFlag == 1)
                        options = [ options { 'fileNameAsr' g.fileNameAsr } ];
                        tmpOptions = options;
                        for iOpt = 1:2:length(options)
                            if strcmpi(options{iOpt}, 'freqprocess') tmpOptions{iOpt+1} = []; end
                        end
                        nfblab_process('runmode', 'baseline', 'loretaFlag', false, tmpOptions{:}); % process once to get ASR and ICA weights
                    end
                    
                    % actual processings
                    if exist(fileNameLog, 'file') delete(fileNameLog); end
                    diary(fileNameLog);
                    nfblab_process('runmode', 'trial', options{:});
                    diary('off');
                else
                    fileNameLog = '';
                end
            end

            if ~isempty(fileNameLog)
                % get average
                % -----------
                fprintf('Reading log file %s ...\n', fileNameLog);
                res = nfblab_importlog(fileNameLog);  % get back JSON array
                if isfield(res, 'threshold'),   res = rmfield(res, 'threshold'); end
                if isfield(res, 'value'),       res = rmfield(res, 'value'); end
                if isfield(res, 'statechange'), res = rmfield(res, 'statechange'); end
                if isfield(res, 'feedback'),    res = rmfield(res, 'feedback'); end
                if strcmpi(g.deletelog, 'on'), delete(fileNameLog); end
                %delete(fileName); % clean up
                resFieldNames = fieldnames(res);
                subjectDataTmp = [];
                for iField = 1:length(resFieldNames)
                    if length(res(1).(resFieldNames{iField})) > 1
                        meanVal = mean(cat(3,res.(resFieldNames{iField})),3);
                        stdVal  = std( cat(3,res.(resFieldNames{iField})),[],3);
                    else
                        meanVal = mean([ res.(resFieldNames{iField}) ]);
                        stdVal  = std( [ res.(resFieldNames{iField}) ]);
                    end
                    subjectDataTmp = setfield(subjectDataTmp, 'measures', resFieldNames{iField}, 'mean', meanVal);
                    subjectDataTmp = setfield(subjectDataTmp, 'measures', resFieldNames{iField}, 'std', stdVal);
                end

                % add fields and save
                % -------------------
                subjectDataTmp.file = filetmp;
                if isempty(underS)
                    spaceS = find(filetmp == ' ');
                    if ~isempty(spaceS)
                        subjectDataTmp.participant = filetmp(1:spaceS(1)-1);
                        subjectDataTmp.task        = filetmp(spaceS(1)+1:end);
                    end
                else
                    subjectDataTmp.participant = filetmp(1:underS(1)-1);
                    if length(underS) > 1
                        subjectDataTmp.session = filetmp(underS(1)+1:underS(2)-1);
                    end
                    if length(underS) > 2
                        subjectDataTmp.task    = filetmp(underS(2)+1:underS(3)-1);
                    end
                    if length(underS) > 3
                        subjectDataTmp.run = filetmp(underS(3)+1:underS(4)-1);
                    else
                        subjectDataTmp.run = [];
                    end
                end
                save('-mat', statFile, '-struct', 'subjectDataTmp');
            end
        else
            fprintf('Reading stat file %s ...\n', statFile);
            subjectDataTmp = load('-mat', statFile);
        end
    else
        subjectDataTmp = [];
    end
    
end
if isfield(subjectDataTmp, 'run'),     subjectDataTmp = rmfield(subjectDataTmp, 'run'); end
if isfield(subjectDataTmp, 'session'), subjectDataTmp = rmfield(subjectDataTmp, 'session'); end
if ~isfield(subjectDataTmp, 'task'),   subjectDataTmp.task = ''; end
subjectData = [ subjectData subjectDataTmp ];

% this is only called at the root
if ~isempty(subjectAge)
    for iData = 1:length(subjectData)
        subjectData(iData).age = subjectAge;
    end
end

% check to output spectrum if relevant
if isfield(subjectData(1).measures, 'f1') && length(subjectData) == 1
    m = subjectData(1).measures;
    spectrum = [ m.f1.mean m.f2.mean m.f3.mean m.f4.mean m.f5.mean m.f6.mean m.f7.mean m.f8.mean m.f9.mean m.f10.mean ...
        m.f11.mean m.f12.mean m.f13.mean m.f14.mean m.f15.mean m.f16.mean m.f17.mean m.f18.mean m.f19.mean m.f20.mean ...
        m.f21.mean m.f22.mean m.f23.mean m.f24.mean m.f25.mean m.f26.mean m.f27.mean m.f28.mean m.f29.mean m.f30.mean ];
end

% write output JSON file
if nargin > 1 && ~isempty(fileOut)
    fid = fopen(fileOut, 'w');
    encodedData = jsonencode(subjectData);
    fprintf(fid, '%s', encodedData);
    fprintf('%s\n', encodedData);
    fclose(fid);
end
