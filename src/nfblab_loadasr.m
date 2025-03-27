% nfblab_process support function to load ASR files
% stored during the baseline period

function [stateAsr, dynRange, icaWeights, icaWinv, icaRmInd, badChans, zmean, zmean2] = nfblab_loadasr(fileNameAsr) % modify options ASR and ICA

fprintf('Loading baseline ASR file %s...\n', fileNameAsr);
stateFile = load('-mat', fileNameAsr);
dynRange = stateFile.dynRange;
stateAsr = stateFile.stateAsr;
icaWeights = stateFile.icaWeights;
icaWinv    = stateFile.icaWinv;
icaRmInd   = stateFile.icaRmInd;
if isfield(stateFile, 'badChans')
    badChans = stateFile.badChans;
else
    badChans = [];
end

if isfield(stateFile, 'zmean')
    zmean  = stateFile.zmean;
    zmean2 = stateFile.zmean2;
else
    zmean  = 0;
    zmean2 = 0;
end