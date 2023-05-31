% This function is called on the baseline file
% to detect bad channels. Bad channels are stored
% and then ignored in other sessions
% Requires the badchanFlag to be set to true

function badChans = nfblab_badchans(dataAccuFiltSave, srate, chanlocs, chancorr)

EEG = eeg_emptyset;
EEG.data = dataAccuFiltSave;
EEG.srate = srate;
EEG.nbchan = size(EEG.data,1);
EEG.pnts   = size(EEG.data,2);
EEG.trials = 1;
EEG.chanlocs = chanlocs(1:EEG.nbchan);

EEG = eeg_checkset(EEG);

EEGrmchans = clean_artifacts(EEG, 'FlatlineCriterion', 5,'Highpass','off',...
    'ChannelCriterion', chancorr,'LineNoiseCriterion', 4,...
    'BurstCriterion', 'off','WindowCriterion', 'off');
oriChans = { EEG.chanlocs.labels };
newChans = { EEGrmchans.chanlocs.labels };
[~,badChans] = setdiff( oriChans, newChans);
