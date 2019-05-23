These are the different instalation steps.

# Install
- On a Windows computer
- Install Matlab. You may use a student version of Matlab.
- Install BCILAB https://github.com/sccn/BCILAB and add to Matlab path (go to the root folder and type "bcilab")
- Install the Psychophysics toolbox http://psychtoolbox.org/download/ (select download ZIP file) (go to the root folder and type "PsychDefaultSetup(2)")
- Install the Lab Streaming Layer https://github.com/sccn/labstreaminglayer binaries. **Do not clone the project or download the zip for the Github project**. Instead use the binary repository (ftp://sccn.ucsd.edu/pub/software/LSL/). Download ZIP files for the *labrecorder* (App folder), the program that can interface your EEG system (App folder - for example *Biosemix.xx.zip* if you have a BIOSEMI system) and all the LSL librairies (SDK folder *liblsl-ALL-languages-x.xx.zip*). Familiarize yourself with LSL. You need to be able to connect to your EEG hardware and use the LabRecorder to save data from your hardware, then open and inspect that data under the EEGLAB software (for example). When ready, add the path to Matlab driver to your Matlab path (*liblsl-All-Languages-x.xx/liblsl-Matlab* folder).

# Make sure Matlab can connect to LSL
After finding the name of your LSL stream using Pyrecorder, use the following code snippet to connect to your stream on Matlab

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

# To get started with Neurofeedbacklab

## Change the settings for your hardware
Edit the file nfblab_option.m to set you hardware number of channels and sampling frequency.

## Save baseline file with ASR (artifact rejection) parameters
If the code below does not work, disable to Matlab psycho toolbox in the nfblab_option.m file (set to false) 

```Matlab
nfblab_process('baseline', 'asrfile.mat', 'baseline_eeg_output.mat')
```

## Run trial session
A trial session takes as input the ASR parameter file saved above and output an EEG file with all the parameters

```Matlab
nfblab_process('trial', 'asrfile.mat', 'trial_eeg_output.mat')
```

## Run series of trial session
The program below will ask you for questions on the command line and help organize the data for your subjects (create folders etc...). 

```Matlab
nfblab_run
```

# Computer settings
- Set up your screen resolution and screen settings. This program is made to be run on 2 screens, one screen for the subject and one screen for the expertimenter. For technical reasons, it is always better to set your primary screen as the screen for the subject (otherwise the psychophysics toolbox might not work properly).
- Disable visual buffering in Matlab. Create an icon on the desktop for Matlab. Look at properties - compatibility tab. Disable "Desktop composition" and "Disable display scaling on high DPI setttings".
- Go to your graphic card properties (display settings and select your graphic card). If you do not have graphic properties, then do not worry about this step. Disable tripple buferring, double buffering and any other fancy option (3-D etc...).

# Program settings
Program settings are contained in the file nfblab_option.m, the content of which is copied below

## General parameters
- psychoToolbox (true/false), Toggle to false for testing without psych toolbox
- adrBoard      (true/false), Toggle to true if using ADR101 board to send events to the EEG amplifier

## LSL connection parameters
- lsltype (string), put to empty if you cannot connect to your system
- lslname (string), this is the name of the stream that shows in Lab Recorder f empty, it will only use the type above. USE lsl_resolve_byprop(lib, 'type', lsltype, 'name', lslname) to connect to the stream. If you cannot connect nfblab won't be able to connect either.

## sessions parameters
- baselineSessionDuration (integer), duration of baseline in second (the baseline is used to train the artifact removal ASR function)
- sessionDuration (integer), regular sessions - here 5 minutes
- ntrials (integer), number of trials per day
- ndays   (integer), number of days of training
              
## data acquisition parameters
- nchans  (integer), number of channels with data
- chans   (integer), indices of channels with data
- mask    (floating point array), patial filter for feedback (here used channel 1). May be an ICA component or complex spatial filter.

## data processing parameters
- srateHardware (integer), sampling rate of the hardware
- srate         (integer), sampling rate for processing data (must divide srateHardware)
- windowSize (integer), length of window size for FFT (if equal to srate then 1 second)
- nfft       (integer), length of FFT - allows FFT padding if necessary
- windowInc  (integer), window increment - in this case update every 1/4 second

## feedback parameters
- theta   [min max]. Frequency range of interest. This program does not allow inhibition at other frequencies although it could be modified to do so
- maxChange  (value from 0 to 1). Cap for change in feedback between processed windows every 1/4 sec. feedback is between 0 and 1 so this is 5% here
- dynRange     [min max]. Initial power range in dB
- dynRangeInc  (value from 0 to 1). Increase in dynamical range in percent if the power value is outside the range (every 1/4 sec)
- dynRangeDec  (value from 0 to 1). Decrease in dynamical range in percent if the power value is within the range (every 1/4 sec)
                            
