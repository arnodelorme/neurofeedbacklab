% a simple function to provide visual feedback on spectral power

function state = nfblab_feedback_psychootoolbox_init(varargin)

% check psychopyshics toolbox
% ---------------------------
if ~exist('Screen')
    error('Cannot find psychophysics toolbox - run "SetupPsychtoolbox" from the command line and try again');
end

Screen('Preference', 'SkipSyncTests', 1);
screenid = 0; % 1 = external screen
%Screen('resolution', screenid, 800, 600, 60);

%imaging = kPsychNeedFastBackingStore;
%Screen('Preference', 'VBLTimestampingMode', 1);
displaysize=Screen('Rect', screenid);
displaysize=[0 0 800 600];
state.window = Screen('OpenWindow', 0, 255, displaysize);%, [], [], [], [], imaging);
Screen('TextFont', window, 'Arial');
Screen('TextSize', window, 16);
Screen('TextStyle', window, 1);
state.xpos1 = 200;
state.ypos1 = 100;
state.xpos2 = displaysize(3)-xpos1;
state.ypos2 = displaysize(4)-ypos1;
state.colArray = [ [10:250] [250:-1:128] [128:250] ];