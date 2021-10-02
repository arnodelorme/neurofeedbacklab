function chunk = nfblab_interp(chunk, chanlocs, chanInds)

EEG = eeg_emptyset;
EEG.data = chunk;
EEG.nbchan = size(EEG.data,1);
EEG.pnts   = size(EEG.data,2);
EEG.trials = 1;
EEG.chanlocs = chanlocs(1:EEG.nbchan);

EEGOUT = eeg_interp(EEG, chanInds(:)', 'sphericalfast');
chunk = EEGOUT.data;