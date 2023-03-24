% a simple function to provide visual feedback on spectral power
% need to be executed as a script

%function  feedbackFuncStruct = nfblab_feedback_psychootoolbox_init(varargin)

% tested with Psychtoolbox-3-3.0.19.0

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
feedbackFuncStruct.window = Screen('OpenWindow', 0, 255, displaysize);%, [], [], [], [], imaging);
feedbackFuncStruct.window
Screen('TextFont',  feedbackFuncStruct.window, 'Arial');
Screen('TextSize',  feedbackFuncStruct.window, 16);
Screen('TextStyle',  feedbackFuncStruct.window, 1);
feedbackFuncStruct.xpos1 = 200;
feedbackFuncStruct.ypos1 = 100;
feedbackFuncStruct.xpos2 = displaysize(3)- feedbackFuncStruct.xpos1;
feedbackFuncStruct.ypos2 = displaysize(4)- feedbackFuncStruct.ypos1;
feedbackFuncStruct.colArray = [ [10:250] [250:-1:128] [128:250] ];
