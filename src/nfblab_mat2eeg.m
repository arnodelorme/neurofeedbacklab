% Stand-alone function to import one of nfblab_process
% output file as an EEGLAB dataset

function EEG = nfblab_mat2eeg(fileName, field)

if nargin < 2
    field = 'dataAccuOriSave';
end

tmp = load('-mat', fileName);
EEG = eeg_emptyset;
EEG.data = tmp.(field);
EEG.nbchan = size(EEG.data ,1);
EEG.pnts = size(EEG.data ,2);
EEG.trials = 1;
EEG.srate = tmp.g.input.srate;
EEG.xmin = 0;
EEG.xmax = (EEG.pnts-1)/EEG.srate;
if isfield(tmp.g.input, 'chanlabels') && ~isempty(tmp.g.input.chanlabels)
    EEG.chanlocs = struct('labels',tmp.g.input.chanlabels);
end
EEG = eeg_checkset(EEG);
