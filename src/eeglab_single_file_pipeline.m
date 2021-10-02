function [eegMeasure, spectrum] = eeglab_single_file_pipeline( fileName, varargin )

fileNameOut = [ fileName(1:end-3) '_processed.set'];
fileNameSpec = [ fileName(1:end-3) '_spec.mat'];

g = finputcheck( varargin, ...
    { 'reref'   'string' { 'on' 'off' }  'on';
    'filter'    'string' { 'on' 'off' }  'off';
    'cleanchan' 'string' { 'on' 'off' }  'on';
    'cleandata' 'string' { 'on' 'off' }  'on';
    'recompute' 'string' { 'on' 'off' }  'off';
    'spectrum'  'string' { 'spectopo' 'fft' 'fftlog' 'welch' }  'spectopo';
    'ica'       'string' { 'on' 'off' }  'on' });
if isstr(g)
    error(g);
end

if ~exist(fileNameSpec, 'file') || strcmpi(g.recompute, 'on')
    if ~exist(fileNameOut, 'file') || strcmpi(g.recompute, 'on')
        [~,~,ext] = fileparts(fileName);
        if strcmpi(ext, '.set')
            EEG = pop_loadset(fileName);
        else
            EEG = pop_biosig( fileName );
        end
        for iChan = 1:length(EEG.chanlocs)
            pos = find(EEG.chanlocs(iChan).labels == '-');
            if ~isempty(pos)
                EEG.chanlocs(iChan).labels = EEG.chanlocs(iChan).labels(5:pos(1)-1);
            end
        end
        EEG = pop_chanedit(EEG, 'lookup','standard-10-5-cap385.elp');
        %EEG = pop_chanedit(EEG, 'lookup','standard_1005.elc');
        if EEG.nbchan == 20
            EEG = pop_select( EEG, 'nochannel', 20);
        end
        chanlocs = EEG.chanlocs;
        
        %% Preprocessing
        % remove channels with no coordinates
        EEG = pop_select( EEG,'nochannel', find(cellfun(@isempty, { EEG(1).chanlocs.X })) );
        
        % do not reference before bad channel rejection
        
        % filter data
        if strcmpi(g.filter, 'on')
            nyq      = EEG.srate/2; % Nyquist frequency
            hicutoff = 1;      % low cutoff
            trans_bw = 0.5;    % transition bandwidth
            rp=0.05;           % Ripple in the passband 0.0025
            rs=20;             % Ripple in the stopband 40
            ws=(hicutoff-trans_bw)/nyq;
            wp=(hicutoff)/nyq;
            [N,wn] = ellipord(wp,ws,rp,rs);
            fprintf('HPF has cutoff of %1.1f Hz, transition bandwidth of %1.1f Hz and its order is %1.1f\n',hicutoff, trans_bw,N);
            [g.preproc.B,g.preproc.A]=ellip(N,rp,rs,wn, 'high');
            tmpData = EEG.data';
           	tmpData = filter(g.preproc.B,g.preproc.A,tmpData);
            EEG.data = tmpData';
        end        
        
        % Remove bad channels
        if strcmpi(g.cleanchan, 'on')
            
            EEG = clean_artifacts(EEG, 'FlatlineCriterion', 5,'Highpass','off',...
                'ChannelCriterion', 0.65,'LineNoiseCriterion', 4,...
                'BurstCriterion', 'off','WindowCriterion', 'off');

            % Interp channels
            nInterp = length(chanlocs)-length(EEG.chanlocs);
            EEG = pop_interp(EEG, chanlocs);
            %EEG = eeg_interp(EEG, chanlocs, 'sphericalfast');
        else
            nInterp = 0;
        end
        
        % Rereference using average reference
        if strcmpi(g.reref, 'on')
            EEG = pop_reref( EEG,[]);
            nInterp = nInterp + 1;
        end
                
        if strcmpi(g.cleandata, 'on')
        
            EEG = pop_clean_rawdata( EEG,'FlatlineCriterion','off','ChannelCriterion','off',...
                'LineNoiseCriterion','off','Highpass','off',...
                'BurstCriterion',20,'WindowCriterion',0.25,'BurstRejection','off',...
                'Distance','Euclidian','WindowCriterionTolerances',[-Inf 7]); % turn WindowCriterion to on for final cleaning pass
        
        end
        
        % Run ICA and flag artifactual components using IClabel
        if strcmpi(g.ica, 'on')
            EEG = pop_runica(EEG, 'icatype','picard','concatcond','on', 'pca', -nInterp, 'maxiter', 500);
            EEG = pop_iclabel(EEG,'default');
            EEG = pop_icflag(EEG,[NaN NaN;0.9 1;0.9 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]);
            EEG = pop_subcomp(EEG, [], 0); % remove pre-flagged bad components
        end
        
        EEG    = pop_saveset(EEG, fileNameOut);
    else
        EEG = pop_loadset( fileNameOut );
    end
    
    if strcmpi(g.spectrum, 'spectopo')
        [spectrum,freqs] = pop_spectopo(EEG, 1, [], 'EEG', 'freqrange',[1 30],'electrodes','off', 'plot', 'off');
    elseif strcmpi(g.spectrum, 'welch')
        [spectrum,freqs] = pwelch(EEG.data',EEG.srate,EEG.srate/2,EEG.srate,EEG.srate); % Window, overlap, nfft, srate
        spectrum = 10*log10(spectrum');
    elseif strcmpi(g.spectrum(1:3), 'fft')
        nfft = EEG.srate;
        EEG = eeg_regepochs(EEG, 'limits', [0 1], 'recurrence', 0.5);
        data = permute(EEG.data, [2 1 3]);
        % data = data - repmat(mean(data,1), [size(data,1) 1 1]); % baseline removal
        dataSpec = fft(bsxfun(@times, data, hamming(size(data,1))), nfft);
        freqs  = linspace(0, EEG.srate/2, floor(nfft/2)+1);
        if strcmpi(g.spectrum, 'fftlog')
            spectrum = mean(10*log10(abs(dataSpec).^2),3)';
        else
            % standard pwelch
            dataSpec = mean(abs(dataSpec).^2,3);
            spectrum = 10*log10(abs(dataSpec))';
        end
    else
        error('Wrong spectrum');
    end
    
    [~,minf] = min(abs(freqs-1));
    [~,maxf] = min(abs(freqs-30));
    spectrum = spectrum(:,minf:maxf);
    save('-mat', fileNameSpec, 'spectrum')
else
    spectrum = load('-mat', fileNameSpec);
    spectrum = spectrum.spectrum;
end

for iFreq = 1:30
    eegMeasure.measures.(['f' int2str(iFreq)]).mean = spectrum(:,iFreq);
end

