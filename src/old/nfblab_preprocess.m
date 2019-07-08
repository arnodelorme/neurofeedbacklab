
% stationary data (continuous)
%[EEG state ] = exp_eval(flt_fir('Signal', EEG, 'Frequencies', [0.9 1.1],'Mode', 'highpass', ))
[EEG state ] = exp_eval(flt_fir( EEG, [0.9 1.1],'highpass', 'zero-phase', -20, -20))

% first call (or stationary data)
[EEG state ] = exp_eval(flt_fir('Signal', EEG, 'Frequencies', [0.9 1.1],'Mode', 'highpass', 'type', 'minimum-phase'))

% subsequent calls 
[EEG state ] = exp_eval(flt_fir('Signal', EEG, 'Frequencies', [0.9 1.1],'Mode', 'highpass', 'State', state, 'type', 'minimum-phase'))

state = asr_calibrate(EEG.data(1:end, 55000:65000), EEG.srate);

tic; [tmp state]= asr_process(EEG.data(:, 4500:4600),EEG.srate, state); toc