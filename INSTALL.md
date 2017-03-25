These are the different instalation steps.

# Installs
- On a Windows computer
- Install Matlab. You may use a student version of Matlab.
- Install BCILAB https://github.com/sccn/BCILAB and add to Matlab path (go to the root folder and type "bcilab")
- Install the Psychophysics toolbox http://psychtoolbox.org/download/ (select download ZIP file) (go to the root folder and type "PsychDefaultSetup(2)")
- Install the Lab Streaming Layer https://github.com/sccn/labstreaminglayer binaries. **Do not clone the project or download the zip for the Github project**. Instead use the binary repository (ftp://sccn.ucsd.edu/pub/software/LSL/). Download ZIP files for the *labrecorder* (App folder), the program that can interface your EEG system (App folder - for example *Biosemix.xx.zip* if you have a BIOSEMI system) and all the LSL librairies (SDK folder *liblsl-ALL-languages-x.xx.zip*). Familiarize yourself with LSL. You need to be able to connect to your EEG hardware and use the LabRecorder to save data from your hardware, then open and inspect that data under the EEGLAB software (for example). Add the path to Matlab driver to your Matlab path (liblsl-All-Languages-x.xx/liblsl-Matlab folder).

# Computer settings
- Set up your screen resolution and screen settings. This program is made to be run on 2 screens, one screen for the subject and one screen for the expertimenter. For technical reasons, it is always better to set your primary screen as the screen for the subject (otherwise the psychophysics toolbox might not work properly).
- Disable visual buffering in Matlab. Create an icon on the desktop for Matlab. Look at properties - compatibility tab. Disable "Desktop composition" and "Disable display scaling on high DPI setttings".
- Go to your graphic card properties (display settings and select your graphic card). If you do not have graphic properties, then do not worry about this step. Disable tripple buferring, double buffering and any other fancy option (3-D etc...).

# Program settings
- Coming soon
