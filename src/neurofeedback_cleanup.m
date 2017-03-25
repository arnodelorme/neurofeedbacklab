function neurofeedback_cleanup()

global serialPort;

try
    fclose(serialPort);
    disp('Closing serial port');
catch
end;

Screen('Closeall');