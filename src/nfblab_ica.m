% nfblab_process support function to compute
%  ICA and find artifactual components

function [icaWeights, icaWinv, icaRmInd] = nfblab_ica(data, srate, chanlocs)

EEG = eeg_emptyset;
EEG.data = data;
EEG.nbchan = size(data,1);
EEG.srate  = srate;
EEG = eeg_checkset(EEG);
EEG.chanlocs = chanlocs;

%[EEG.icaweights,EEG.icasphere] = beamica( EEG.data );
EEG.icasphere = eye(EEG.nbchan);
[~, EEG.icaweights] = picard( EEG.data );
EEG = eeg_checkset(EEG);

EEG = iclabel(EEG);
thresholds = [0 0;0.9 1; 0.9 1; 0 0; 0 0; 0 0; 0 0];
EEG = pop_icflag(EEG, thresholds);

icaWeights = EEG.icaweights;
icaWinv    = EEG.icawinv;
icaRmInd   = find(EEG.reject.gcompreject);