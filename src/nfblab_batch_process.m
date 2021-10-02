% ---------------------------------------------------
% This file must be run every time new z-score are calculated
% Use Brain-DX to process multiple files
% set custom config to 'offline-loreta-braindx'
% make sure to use the same settings as for realtime
%
% copy the file saved at the end to the ntl_web_services folder
% copy its name in the settings
% ---------------------------------------------------

clear
files = dir(fullfile( '/Users/arno/GoogleDrive/NTL-EEGLAB/braindx_150files/sets', '*EEG.csv') );
addpath('/Users/arno/GoogleDrive/NTL-EEGLAB/ntl_web_services/');
braindxfolder = '/Users/arno/GoogleDrive/NTL-EEGLAB/braindx_150files';
ageids = loadtxt(fullfile(braindxfolder,'age_ids.txt'));

% find corresponding age for each file
for iFile = 1:size(ageids)
    posUnderscore = find(files(iFile).name == '_');
    currentIDs    = lower(files(iFile).name(1:posUnderscore(1)-1));
%     if currentIDs(end) == '0', currentIDs(end) = []; end
%     if currentIDs(end) == '0', currentIDs(end) = []; end
    ind = strmatch(currentIDs, lower(ageids(:,1)), 'exact');
    if length(ind) ~= 1
        ind = strmatch([ currentIDs '00' ], lower(ageids(:,1)), 'exact');
        if length(ind) ~= 1
            error('Order issue')
        end
    end
    allInds(iFile) = ind; % age match for file
end
for iFile = 1:length(allInds)
    allSubjectData(iFile).age = ageids{allInds(iFile),2}; % set age
end

% process all files
options = { 'runmode', 'baseline' };
allSubjectData = [];
for iFile = 1:length(files)
    EEG = ntl_importbraindx(fullfile(files(iFile).folder, files(iFile).name));

    newOptions = options;
    newOptions = { newOptions{:} 'streamFile' EEG };

    % in nfblab_options_additional, select "offline-loreta24"
    [~,fileName,ext] = fileparts(fullfile(files(iFile).folder, files(iFile).name));

    % process file
    fileName = [ fileName '_log.txt' ];
    if exist(fileName, 'file'), delete(fileName); end
    diary(fileName);
    nfblab_process(newOptions{:}); % will use batch_mode
    diary('off');
    return
    
    % get back JSON array
    res = nfblab_importlog(fileName);
    
    % get average
    resFieldNames = fieldnames(res);
    for iField = 1:length(resFieldNames)
        if length(res(1).(resFieldNames{iField})) > 1
            tmpVal= mean(cat(3,res.loretaztheta),3);
        else
            tmpVal = mean([ res.(resFieldNames{iField}) ]);
        end
        allSubjectData = setfield(allSubjectData, { iFile }, resFieldNames{iField}, tmpVal);
    end    
    
    % simple plots
    if 0
        %%
        fields = { 'TEI' 'AI' 'IPI' 'TI' 'TLI' 'FTItheta' 'FTIalpha' 'loretaztheta' 'WorkingMemory_mean' 'Anxiety_mean' 'feedback' };
        figure;
        for iField = 1:length(fields)
            subplot(length(fields),1,iField);
            plot([res.(fields{iField})]);
            title(fields{iField}, 'interpreter', 'none');
        end
    end
end

save('-mat', 'newnormfile.mat', 'allSubjectData');