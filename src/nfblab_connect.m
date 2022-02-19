function results = nfblab_connect(EEG, varargin)

opt = struct(varargin{:});

if ~isfield(opt, 'nfblabloreta')
    error('No field nfblabloreta given as input');
else
    if ischar(opt.nfblabloreta)
        opt.nfblabloreta = load('-mat', opt.nfblabloreta);
    end
end
loreta_P        = opt.nfblabloreta.loreta_P;
loreta_Networks = opt.nfblabloreta.loreta_Networks;
loreta_ROIS     = opt.nfblabloreta.loreta_ROIS;

% other paratemers
if isfield(opt, 'roilist')
    ROI_list = opt.roilist;
else
    ROI_list = unique([loreta_Networks.ROI_inds]); % list of ROI necessary to compute connectivity
end

if ~isfield(opt, 'nfft')
    opt.nfft = EEG.srate*2;
end
if ~isfield(opt, 'freqrange')
    opt.freqrange = { [4 6] [ 8 12] [18 22] }; % alpha range
end
if ~isfield(opt, 'processfreq')
    opt.processfreq.theta = @(x)x(:,1);
    opt.processfreq.alpha = @(x)x(:,2);
    opt.processfreq.beta  = @(x)x(:,3);
end
if~isfield(opt, 'processconnect')
    opt.processconnect.theta = @(x)sum(sum(x(:,:,1)))/((size(x,1).^2)-size(x,1)); % the diverder is the number of non zero values    
    opt.processconnect.alpha = @(x)sum(sum(x(:,:,2)))/((size(x,1).^2)-size(x,1)); % the diverder is the number of non zero values    
    opt.processconnect.beta  = @(x)sum(sum(x(:,:,3)))/((size(x,1).^2)-size(x,1)); % the diverder is the number of non zero values    
end
if~isfield(opt, 'freqdb')
    opt.freqdb = 1;    
end

% project to source space
source_voxel_data = reshape(EEG.data(:, :)'*loreta_P(:, :), size(EEG.data,2), size(loreta_P,2), 3);

% Computing spectrum
sz = size(source_voxel_data);
tmpdata = reshape(source_voxel_data, sz(1), sz(2)*sz(3));
source_voxel_spec = pwelch(tmpdata, EEG.srate, EEG.srate/2, EEG.srate); % assuming 1 second of data
source_voxel_spec = reshape(source_voxel_spec, size(source_voxel_spec,1), sz(2), sz(3));
source_voxel_spec = mean(source_voxel_spec(2:size(source_voxel_spec,1),:,:),3); % frequency selection 2 to 31 (1Hz to 30Hz)
freqs  = linspace(0, EEG.srate/2, floor(opt.nfft/2)+1);
freqs  = freqs(2:end); % remove DC (match the output of PSD)

% Compute ROI activity
for ind_roi = ROI_list
    % data used for connectivity analysis
    spatiallyFilteredDataTmp = roi_getact( source_voxel_data, loreta_ROIS(ind_roi).Vertices, 1, 0); % Warning no zscore here; also PCA=1 is too low
    spatiallyFilteredSpecTmp = roi_getact( source_voxel_spec, loreta_ROIS(ind_roi).Vertices, 1, 0);
    if ind_roi == 1
        spatiallyFilteredData = zeros(max(ROI_list), length(spatiallyFilteredDataTmp));
        spatiallyFilteredSpec = zeros(max(ROI_list), length(spatiallyFilteredSpecTmp));
    end
    spatiallyFilteredData(ind_roi,:) = spatiallyFilteredDataTmp;
    spatiallyFilteredSpec(ind_roi,:) = spatiallyFilteredSpecTmp;
end
loretaSpec = spatiallyFilteredSpec';

% select frequency bands
for iSpec = 1:length(opt.freqrange)
    freqRangeTmp = intersect( find(freqs >= opt.freqrange{iSpec}(1)), find(freqs <= opt.freqrange{iSpec}(2)) );
    loretaSpecSelect(:,iSpec) = mean(abs(loretaSpec(freqRangeTmp,:)).^2,1); % mean power in frequency range
    if opt.freqdb
        loretaSpecSelect(:,iSpec) = 10*log10(abs(loretaSpecSelect(:,iSpec)).^2);
    end
end

% compute metric of interest
processfreqFields = fieldnames(opt.processfreq);
for iProcess = 1:length(processfreqFields)
    results.(processfreqFields{iProcess}) = feval(opt.processfreq.(processfreqFields{iProcess}), loretaSpecSelect);
end

% compute cross-spectral density for each network
% -----------------------------------------------
if ~isempty(opt.processconnect)
    for iNet = 1:length(loreta_Networks)
        if 1
            restmp = roi_network( spatiallyFilteredData, loreta_Networks(iNet).ROI_inds, 'nfft', opt.nfft, 'postprocess', opt.processconnect, 'freqranges', opt.freqrange);
            % copy results
            fields = fieldnames(restmp);
            for iField = 1:length(fields)
                results.([ loreta_Networks(iNet).name '_' fields{iField} ]) = restmp.(fields{iField});
            end
        else
            networkData = spatiallyFilteredData(loreta_Networks(iNet).ROI_inds,:);
            S = cpsd_welch(networkData,size(networkData,2),0,g.measure.nfft);
            [nchan, nchan, nfreq] = size(S);
            
            % imaginary part of cross-spectral density
            % ----------------------------------------
            absiCOH = S;
            for ifreq = 1:nfreq
                absiCOH(:, :, ifreq) = squeeze(S(:, :, ifreq)) ./ sqrt(diag(squeeze(S(:, :, ifreq)))*diag(squeeze(S(:, :, ifreq)))');
            end
            absiCOH = abs(imag(absiCOH));
            
            % frequency selection
            % -------------------
            connectSpecSelect = zeros(size(absiCOH,1), size(absiCOH,2), length(opt.freqrange));
            for iSpec = 1:length(g.measure.freqrange)
                freqRangeTmp = intersect( find(freqs >= opt.freqrange{iSpec}(1)), find(freqs <= opt.freqrange{iSpec}(2)) );
                connectSpecSelect(:,:,iSpec) = mean(absiCOH(:,:,freqRangeTmp),3); % mean power in frequency range
            end
            
            connectprocessFields = fieldnames(opt.processconnect);
            for iProcess = 1:length(connectprocessFields)
                results.([ loreta_Networks(iNet).name '_' connectprocessFields{iProcess} ]) = feval(opt.processconnect.(connectprocessFields{iProcess}), connectSpecSelect);
            end
        end
    end
end
