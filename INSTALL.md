# Install

1. Clone this repository (or download the zip code)

1. Install LSL driver for your headset. This will depend on your hardware. Sometimes the manufacturer will provide you with a program. Sometimes you have to check out the code base and recompile from https://github.com/sccn/labstreaminglayer/tree/master/Apps. Then check if you can connect to the stream with LabRecorder (see the troubleshooting section below). 

2. Then install the LSL Matlab interface library using the released code from https://github.com/labstreaminglayer/liblsl-Matlab/releases (install the zip release, which contains binary for your Platform). Unzip the file in the **src** folder of the current repository. Make sure the folder is named **liblsl-Matlab** or Neurofeedbacklab will not be able to find it (the path is defined at the end of the nfblab_setfields.m function).

2. Clone EEGLAB with submodules from https://github.com/sccn/eeglab or install the released version

3. Make sure you have the latest version (2.5 or later) of the *clean_rawdata* plugin (use the EEGLAB plugin manager -- menu item *File > Manage extensions*)

4. Install the *Picard* plugin using the EEGLAB plugin manager if you want to perform real-time independent component rejections

5. Install the *ROIconnect* plugin (beta) from https://github.com/arnodelorme/roiconnect if you want to do real-time eLoreta and connectivity analysis.

5. Start Matlab

6. Stats EEGLAB by going to the EEGLAB folder and typing "eeglab"

7. Use *nfblab_check_computation.m* to check Neurofeedbacklab real-time computation against a standard EEGLAB pipeline.

8. Adapt *nfblab_muse.m* for your headset

9. Type *nfblab_process('help', true)* to see Neurofeedbacklab parameters.

The default LSL stream type is set to "EEG" ("lsltype" variable in nfblab_options.m file), and the default LSL name is set to empty ("lslname" variable in nfblab_options.m file), which should work in most case to connect to a LSL EEG stream if it is available on your platform. However, in some cases, you might want to change these variables and also check that the stream is visible on your system.

To identify the name of the LSL stream for your EEG headset using the LabRecorded program (https://github.com/labstreaminglayer/App-LabRecorder/releases). This is the most stable LSL program, and if this program cannot see the LSL stream, there is a problem with the LSL driver you are using. Once you have the stream's name, you can copy it to the nfblab_options.m file (and leave the "lsltype" variable empty).

# Troubleshooting Matlab LSL interface

Note that LSL libraries Neurofeedbacklab uses are from BCILAB, which are themselves compiled from the Lab Streaming Layer repository https://github.com/sccn/labstreaminglayer (and BCILAB versions might have been compiled with earlier versions of the LSL code). If you encounter a problem with connecting Matlab and LSL, you could try the following.

# Connecting to a headset (Mac, PC, or Ubuntu)

1. This example uses the Muse headset, but the process is similar for other headsets. Power on your Muse. This assumes you have a Muse 1 headset (not Muse 2). Use the muse-io command line interface to stream data to lsl (available at https://sites.google.com/a/interaxon.ca/muse-developer-site/download). The command is as follows (with XXXX being the name of your Muse as visible on the Bluetooth preference). For some early Muse 1 you first need to pair by hand using the Bluetooth Mac menu. For late Muse 1 headsets, you do not need to. We tried this under Windows, Mac, and Ubuntu.

muse-io --device Muse-XXXX --lsl-eeg EEG

2. Use LabRecorder to check that you can see the EEG stream (https://github.com/labstreaminglayer/App-LabRecorder) and stream from it. This app is very stable, as mentioned earlier. This will allow you to make sure the LSL steam is visible and functional.

3. Start Matlab and run *nfblab_process('help', true)* to add the LSL paths. Now try to connect using Matlab. Note that the code below will work for any headset and is not limited to the Muse. Type the commands

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

If successful, the variable <i>chunk</i> should contain a chunk of data, and it should show on the command line. Otherwise, it will show [] (which means empty in Matlab) or generate an error. You can also use the function lsl_resolve_byprop to find streams (lsl_resolve_byprop(lib, 'type', ‘EEG', 'name’, ‘’)).

# Getting started with running Neurofeedback experiments

Run and modify the file [nfblab_run_template.m](https://github.com/arnodelorme/neurofeedbacklab/blob/master/src/nfblab_run_template.m) to get started. Change the number of channels and sampling rate to match your system. Neurofeedbacklab should be able to pick up the LSL stream of type EEG. If it does not, troubleshoot LSL as explained in the previous sections.
