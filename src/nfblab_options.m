
ntrials = 8; % number of trials per day
ndays   = 8; % number of days of training

lsltype = 'EEG'; % put to empty if you cannot connect to your system
lslname = ''; % this is the name of the stream that shows in Lab Recorder
              % if empty, it will only use the type above
              % USE lsl_resolve_byprop(lib, 'type', lsltype, 'name',
              % lslname) to connect to the stream. If you cannot connect
              % nfblab won't be able to connect either.
