% To run this program, you need to create two matlab sessions and have an
% LSL stream availalble. Before trying this solution, make sure you
% can stream from LSL using other protocols.
%
% On the first MATLAB session run the program 
% - simple_server
%
% Once the server has started, on the second MATLAB session, run the program 
% - simple_client (this program)
%
% It is best to first try the solution on the same computer to avoid
% firewall issues. Once this work, you can run the server on one computer
% and the client on another one making sure they can communicate.

% Create sockets
TCPport = 9789;
sessionDuration = 60;

import java.io.*; % for TCP/IP
import java.net.*; % for TCP/IP
connectionSocket  = Socket(InetAddress.getByName("localhost"), TCPport );
fprintf('Trying to connect...\n');
outToServer = PrintWriter(connectionSocket.getOutputStream(), true);
inFromServer = BufferedReader(InputStreamReader(connectionSocket.getInputStream()));
tic;

% load sound for feedback
[V, Fs] = audioread('lowpitch.wav');

% commands to sent to server
% this section builds the list of commands
fileNameAsr = sprintf('asr_filter_client_%s.mat',  datestr(now, 'yyyy-mm-dd_HH-MM'));
msg = [];
msg(end+1).command = 'lslconnect';
msg(end).options.lslname = '';
msg(end).options.lsltype = 'EEG';

msg(end+1).command = 'start';
msg(end).options.runmode = 'baseline';

msg(end).options.fileNameAsr = fileNameAsr;
msg(end+sessionDuration).command = 'stop';

msg(end+1).command = 'start';
msg(end).options.runmode = 'trial';
msg(end+sessionDuration).command = 'stop';

msg(end+1).command = 'start';
msg(end).options.runmode = 'trial';
msg(end+sessionDuration).command = 'stop';
msg(end+1).command = 'quit';

% send the command
% this section sends the command over TCP/IP
iMsg = 1;
while iMsg <= length(msg)
    % get message and print
    modifiedSentence = inFromServer.readLine();
    disp(modifiedSentence);
    
    % play sound every 4 sample
    try
        res = jsondecode(char(modifiedSentence));
    catch
        res = [];
        disp('Error');
    end
    if isfield(res, 'feedback')
        sound(V/(2^(max(0,5-5*res.feedback))), Fs);
    end
    
    % send message and pause
    outToServer.println(jsonencode(msg(iMsg)));
    iMsg = iMsg + 1;
    pause(0.1);
end
pause(1);

connectionSocket.close()
