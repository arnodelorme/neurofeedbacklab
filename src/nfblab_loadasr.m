function [stateAsr, dynRange, icaWeights, icaWinv, icaRmInd] = nfblab_loadasr(fileNameAsr) % modify options ASR and ICA

fprintf('Loading baseline ASR file %s...\n', fileNameAsr);
stateFile = load('-mat', fileNameAsr);
dynRange = stateFile.dynRange;
stateAsr = stateFile.stateAsr;
icaWeights = stateFile.icaWeights;
icaWinv    = stateFile.icaWinv;
icaRmInd   = stateFile.icaRmInd;
