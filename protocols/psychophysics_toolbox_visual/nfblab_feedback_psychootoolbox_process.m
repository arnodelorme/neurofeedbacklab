% a simple function to provide visual feedback on spectral power

% tested with Psychtoolbox-3-3.0.19.0

function state = nfblab_feedback_psychootoolbox_process(state, feedbackVal, varargin)

colIndx = ceil((feedbackVal+0.001)*254);
Screen('FillPoly', state.window ,[0 0 state.colArray(colIndx)], [ state.xpos1 state.ypos1; state.xpos2 state.ypos1; state.xpos2 state.ypos2; state.xpos1 state.ypos2], 1);
Screen('Flip', state.window);
