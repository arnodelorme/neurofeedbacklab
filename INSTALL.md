# Install

1. Install LSL driver for your headset. This will depend on your hardware. Sometimes the manufacturer will provide you with a program. Sometimes you have to check out the code base and recompile from https://github.com/sccn/labstreaminglayer/tree/master/Apps. Sometimes the compiled code for these apps is available as a release on the corresponding GitHub repository. Alternatively some binaries are available for some apps from ftp://sccn.ucsd.edu/pub/software/LSL/. Then check you can connect to the stream with LabRecorder (see troubleshooting section below).

2. Clone EEGLAB with submodules from https://github.com/sccn/eeglab

3. In clean_rawdata plugins folder of EEGLAB, copy private folder content to clean_rawdata folder. Otherwise neurofeedbacklab which needs these low level functions cannot access them.

4. Clone BCILAB from https://github.com/sccn/BCILAB (devel branch which is the default one) at the same level as neurofeedbacklab. This is important because neurofeedbacklab will search the BCILAB paths and not be able to find them if it cloned at a random location. It is also possible to start BCILAB ("bcilab" command in Matlab) to add the paths or BCILAB but a large number of paths will be added which can interfere with the compilation process (if you want to compile Neurofeedbacklab instead of running it from Matlab).
 
5. Start Matlab

6. Stats EEGLAB by going to the EEGLAB folder and typing "eeglab"

7. Start nfblab_process works on your platform especially the LSL link with your EEG headset by typing nfblab_process. If everything goes well, after you select to record a baseline, the program should show you some numerical outputs. If it returns an error, it means that it could connect to your headset (see troubleshoothing below).
                           
# Make sure Matlab can connect to LSL
After running the function "nfblab_options" which will add the paths to LSL, use the following code snippet to check if you can stream data on Matlab

```Matlab
lib = lsl_loadlib();
result = nfblab_findlslstream(lib,'','EEG-name-of-your-lsl-stream')
inlet = lsl_inlet(result{1});
pause(1);
[chunk,stamps] = inlet.pull_chunk();
pause(1);
[chunk,stamps] = inlet.pull_chunk();
figure; plot(chunk');
```

# Make sure you have the right LSL stream

The default LSL stream type is set to "EEG" ("lsltype" variable in nfblab_options.m file) and the default LSL name is set to empty ("lslname" variable in nfblab_options.m file) which should work in most case to connect to a LSL EEG stream if it is available on your platsform. However, in some case, you might want to change these variables and also check that the stream is visible on your system.

To identify the name of the LSL stream for your EEG headset using the LabRecorded program (https://github.com/labstreaminglayer/App-LabRecorder/releases). This is the most stable LSL program and if this program cannot see the LSL stream, there is a problem with LSL driver you are using. Once you have the name of the stream, you can copy it to the nfblab_options.m file (and leave the "lsltype" variable as empty).

# Troubleshooting Matlab LSL interface

Note that LSL libraries Neurofeedbacklab uses are from BCILAB which are themselves compiled from the Lab Streaming Layer repository https://github.com/sccn/labstreaminglayer (and BCILAB versions might have been compiled with earlier vesions of the LSL code). If you encounter problem with connecting Matlab and LSL, you could try the following.

## Downloading and recompiling LSL itself

These libraries are common to all LSL binary program (including the driver you are using to connect to your headset). They are not specific to Matlab. Official LSL library repo is https://github.com/sccn/liblsl. Once recompiled, the easiest is to replace the binaries in BCILAB if you have already installed it (above) in the path "BCILAB/dependencies/liblsl-Matlab/bin" (using this method the Matlab interface to LSL will easily find the recompiled library).

## Recompiling the Matlab interface to LSL

When running LSL from Matlab, we use wrapper functions to the library above. These might need to be recompiled as well.

1. Checkout the the Matlab interface for the LSL library https://github.com/labstreaminglayer/liblsl-Matlab. This folder is the same as the source code used to compile the LSL binaries in BCILAB but it is more up to date.

2. Compile the mex files using the build command under Matlab. A new folder will be created for your platform.

3. Add the new path (on a brand new Matlab session without any of the previous Matlab paths added) and test the go to the section "Troubleshooting Matlab LSL interface" above to see if you can now connect to LSL streams using Matlab.

# Connecting a Muse headset (Mac, PC or Ubuntu)

1. Power on your Muse. This assumes you have a Muse 1 (not Muse 2). Use the muse-io command line interface to stream data to lsl (available at https://sites.google.com/a/interaxon.ca/muse-developer-site/download). The command is as follow (with XXXX being the name of your Muse as visible on the Bluetooth preference). For some early Muse 1 you first need to pair by hand using the Bluetooth Mac menu. For late Muse 1 headsets you do not need to. We tried this under Windows, Mac and Ubuntu.

muse-io --device Muse-XXXX --lsl-eeg EEG

2. Use LabRecorder to check that you can see the EEG stream (https://github.com/labstreaminglayer/App-LabRecorder) and stream from it. This app is very stable as mentioned earlier.

3. Start Matlab and run "nfblab_options" to add the LSL paths. Now try to connect using Matlab. Type the commands

```Matlab
lib = lsl_loadlib();
result = nfblab_findlslstream(lib,'EEG','')
inlet = lsl_inlet(result{1});
pause(1);
[chunk,stamps] = inlet.pull_chunk();
pause(1);
[chunk,stamps] = inlet.pull_chunk();
figure; plot(chunk');
```

If succesful, chunk should contain a chunk of data and it should show on the command line, otherwise it will show [] (which means empty in Matlab) or generate an error. You can also use the function lsl_resolve_byprop to find streams (lsl_resolve_byprop(lib, 'type', ‘EEG', 'name’, ‘’))
