clear;
fileName = 'eeglab_data.set';

% generate parameters
freqrange      = {};
freqprocess    = [];
for iFreq = 1:30
    freqrange{iFreq} = [iFreq-0.5 iFreq+0.49999999];
    freqprocess.(sprintf('f%d', iFreq)) = eval(sprintf('@(x)x(:,%d);', iFreq));
end

% not for ICA, decrease threshold for rejection to 70% to see any
% difference with no rejection
paramseeglab   = { 'ica' 'on' 'cleanchan'  'off'  'reref'  'off'  'cleandata' 'off' 'filter' 'off' 'recompute' 'on' 'spectrum', 'fftlog'};
paramsnfblab   = { 'icaFlag' 1 'badchanFlag' 0   'averefFlag' 0  'asrFlag'    0   'filtFlag' 0    'freqdb' 1 'forceread' 'on' 'deletelog' 'on' 'windowInc' 64 'freqrange' freqrange 'freqprocess' freqprocess };

[eegMeasure2,s2] = nfblab_batchonefile( fileName, [], 'forceread', 'log', 'deletelog', 'off',paramsnfblab{:});

[eegMeasure1,s1] = eeglab_single_file_pipeline(fileName,paramseeglab{:});
%[eegMeasure1,s2] = eeglab_single_file_pipeline(fileName,paramseeglab{:}, 'spectrum', 'welch');

figure; plot(s1(:,:), s2(:,:), '.');
[ypred, alpha, rsq, slope, intercept] = fastregress(s1(:), s2(:), 1);

title('1 color = 1 frequency')

