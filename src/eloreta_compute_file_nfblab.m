% compute loreta file for neurofeedbacklab
clear
chans = 32;

p = fileparts(which('eeglab.m'));
loretaAtlasFile = fullfile(p, 'plugins','dipfit','LORETA-Talairach-BAs.mat');
EEG = pop_loadset(fullfile(p, 'sample_data', 'eeglab_data_epochs_ica.set'));
EEG = pop_dipfit_settings( EEG, 'hdmfile', fullfile(p, 'plugins','dipfit','standard_BEM','standard_vol.mat'),'coordformat','MNI', ...
    'mrifile',fullfile(p, 'plugins','dipfit','standard_BEM','standard_mri.mat'),'chanfile',fullfile(p, 'plugins','dipfit','standard_BEM','elec','standard_1005.elc'), ...
    'coord_transform',[0.83215 -15.6287 2.4114 0.081214 0.00093739 -1.5732 1.1742 1.0601 1.1485] ,'chansel',[1:32] );
% options = { ...
%     'headmodel' '/data/matlab/eeglab/plugins/dipfit/standard_BEM/standard_vol.mat' ...
%     'elec2mni'  EEG.dipfit.coord_transform ...
%     'leadfield' struct([]) ...
%     'sourcemodel' '/data/matlab/eeglab/functions/supportfiles/head_modelColin27_5003_Standard-10-5-Cap339.mat' ...
%     'sourcemodel2mni' [0.000000000 -24.000000000 -45.000000000 0.000000000 0.000000000 -1.570796300 1000.000000000 1000.000000000 1000.000000000] ...
%     'sourcemodelatlas' 'Desikan-Kiliany' ...
%     'downsample' 1 ...
%     'sourceanalysis' 'roiconnect' ... 
%     };
optionsLeadfield = { ...
    'sourcemodel' loretaAtlasFile ...
    'sourcemodel2mni' [] ...
    'downsample' 1 };    
EEG = pop_leadfield(EEG, optionsLeadfield{:});

optionROI = { ...
    'atlas' 'LORETA-Talairach-BAs' ...
    'model' 'eLoreta' ... 
    'leadfield' EEG.dipfit.sourcemodel ...
    };
EEG = pop_roi_activity(EEG, optionROI{:});
%EEG = roi_connect(EEG, options{:});

loreta_P = EEG.roi.P_eloreta;
loreta_ROIS = EEG.roi.atlas.Scouts(1:7);
% save('-mat', 'loreta_05282020.mat', 'loreta_P', 'loreta_ROIS');

%% Add areas to Loreta file
atlas = load('-mat', loretaAtlasFile);
atlas.Atlas.Scouts = atlas.Atlas.Scouts(1:90);
allAreas = loadtxt('NGNetworkROIsArno_area_definition.txt', 'delim', 9);

% new code to create labels with vertices and add them to the list of brain areas
allLabels = { atlas.Atlas.Scouts.Label };
for iNetwork = 1:size(allAreas,2)
    atlas.Atlas.Scouts(end+1).Label = allAreas{1, iNetwork};
    ROI_inds = [];
    for iRow = 2:size(allAreas,1)
        areaName = allAreas{iRow, iNetwork };
        if ~isempty(areaName)
            if ~isnan(str2double(areaName(1)))
                areaName = [ 'Brodmann area ' areaName ];
            end
            posArea = strmatch(areaName, allLabels, 'exact');
            if isempty(posArea)
                error('Area not found');
            end
            ROI_inds = [ ROI_inds posArea ];
        end
    end
    atlas.Atlas.Scouts(end).Vertices = vertcat(atlas.Atlas.Scouts(ROI_inds).Vertices);
end    
save('-mat', loretaAtlasFile, '-struct', 'atlas');
EEG.roi.atlas = atlas.Atlas;

%% Network selection
% ------------------
allNeworks = loadtxt('NGNetworkROIsFULL.txt', 'delim', 9);
selectedNetworks = { 'WorkingMemory' 'Anxiety' };
allNeworks = loadtxt('NGNetworkROIsArno_v3.txt', 'delim', 9);
selectedNetworks = { 'DNM' 'Salience_network' 'Executive_network' 'Working_memory_network' 'Cingulo_opercular_network' 'Dorsal_attention_network' };

allAreaInds = [];
clear loreta_Networks;
allLabels = { EEG.roi.atlas.Scouts.Label };
for iSelect = 1:length(selectedNetworks)
    loreta_Networks(iSelect).name = selectedNetworks{iSelect};
    loreta_Networks(iSelect).ROI_inds = [];
    networkName = strmatch(selectedNetworks{iSelect}, allNeworks(1,:), 'exact');
    if isempty(networkName)
        error('Could not find network');
    end
    for iRow = 2:size(allNeworks,1)
        areaName = allNeworks{iRow, networkName };
        if ~isempty(areaName)
            if ~isnan(str2double(areaName(1)))
                areaName = [ 'Brodmann area ' areaName ];
            end
            posArea = strmatch(areaName, allLabels, 'exact');
            if isempty(posArea)
                error('Area not found');
            end
            loreta_Networks(iSelect).ROI_inds = [ loreta_Networks(iSelect).ROI_inds posArea ];
        end
    end
end
loreta_ROIS = EEG.roi.atlas.Scouts(:);
chanlocs    = EEG.chanlocs;
save('-mat', sprintf('loreta_hubs_%s_%d.mat', datestr(now, 'mmddYYYY'), chans), 'loreta_P', 'loreta_ROIS', 'loreta_Networks', 'chanlocs');

%loreta_rois = EEG.roiconnect.roi_vertex_indices;
    
