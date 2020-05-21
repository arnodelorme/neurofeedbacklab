nfblab_options;

% Create sockets
import java.io.*; % for TCP/IP
import java.net.*; % for TCP/IP
connectionSocket  = Socket(InetAddress.getByName("localhost"), TCPport );
fprintf('Trying to connect...\n');
outToServer = PrintWriter(connectionSocket.getOutputStream(), true);
inFromServer = BufferedReader(InputStreamReader(connectionSocket.getInputStream()));
tic;

% load sound for feedback
[V, Fs] = audioread('lowpitch.wav');

% messages
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
