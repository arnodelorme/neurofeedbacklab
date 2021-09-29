function [streamFileData, chanlocs] = nfblab_loadfile(streamFile)
    
    if ~isstruct(streamFile)
        [~,~,ext] = fileparts(streamFile);
        if strcmpi(ext, '.set')
            streamFileData = load('-mat', streamFile);
            streamFileData = streamFileData.EEG;
            if ischar(streamFileData.data)
                streamFileData.data = floatread(streamFileData.data, [streamFileData.nbchan Inf]);
            end
        elseif strcmpi(ext, '.edf')
            streamFileData = pop_biosig(streamFile);
        elseif strcmpi(ext, '.xdf')
            streamFileData = pop_loadxdf(streamFile , 'streamtype', 'EEG', 'exclude_markerstreams', {});
        end
    else
        streamFileData = streamFile;
    end
    streamFileData = eeg_checkset(streamFileData);
    
    if ~isempty(streamFileData.chanlocs)
        for iChan = 1:length(streamFileData.chanlocs)
            posSpace = find(streamFileData.chanlocs(iChan).labels == ' ');
            posDash  = find(streamFileData.chanlocs(iChan).labels == '-');
            if ~isempty(posSpace) && ~isempty(posDash)
                streamFileData.chanlocs(iChan).labels = streamFileData.chanlocs(iChan).labels(posSpace+1:posDash-1);
            end
        end
        if isempty(streamFileData.chanlocs(1).X)
            streamFileData = pop_chanedit(streamFileData, 'lookup','standard-10-5-cap385.elp');
        end
    end
    
    %chans = [1:streamFileData.nbchan];
    try
        disp('Warning: Overwriting channel labels with those contained in the data file');
        chanlocs = streamFileData.chanlocs; 
    catch, end
