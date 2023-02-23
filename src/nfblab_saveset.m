% support file for nfblab_process to save the raw data

function EEG = nfblab_saveset( fileNameRaw, chans, srate, chanlabels)

EEG = eeg_emptyset;
EEG.nbchan = length(chans);
EEG.srate  = srate;
EEG.xmin   = 0;
EEG.trials = 1;
EEG.data   = [ fileNameRaw(1:end-4) '.fdt' ];
try
    EEG = eeg_checkset(EEG);
catch, end
if ~isempty(chanlabels)
    if length(chanlabels) > chans
        EEG.chanlocs = struct('labels', chanlabels(chans));
    else EEG.chanlocs = struct('labels', chanlabels);
    end
end
save('-mat', fileNameRaw, 'EEG');

