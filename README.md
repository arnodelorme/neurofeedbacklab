# Neurofeedbacklab

Neurofeedbacklab is a neurofeedback software approach based on Matlab. It uses EEGLAB and a collection of EEGLAB plugins to provide state of the art artifact rejection and real-time source localization and connectivity analysis. Feedback is performed by the Matlab psychophysics toolbox (an example is provided). The Neurofeedbacklab real-time computing engine has been thoroughly tested against EEGLAB processing pipelines (see below).

# Dependencies

- Matlab (including student versions)
- EEGLAB from https://eeglab.org
  - clean_rawdata plugin to version 2.5 or later
  - PICARD plugin if you want to do real time Independent Component Analysis
  - ROICONNECT if you want to do real time eLoreta and connectivity analysis
- LSL install released code from https://github.com/labstreaminglayer/liblsl-Matlab/releases
- Matlab psychophysics toolbox http://psychtoolbox.org/ if you want visual feedback

See the [INSTALL.md](INSTALL.md) documentation.

# Features

- Stream real time EEG signal using LSL and process it in real time
- Compute measure of interest, provide visual feedback or stream results through TCP/IP connection to other program.
- In a typical use, the same computer runs the data acquisition and performs visual feedback
- Adaptive filtering with minimum phase distortion
- Automated artifact rejection using [Artifact Subspace Reconstruction](https://sccn.ucsd.edu/~scott/pdf/Mullen_BCI13.pdf). This methods uses PCA to find artifactual sections of data, then reconstruct a clean signal based on the statistics of the baseline. 
- Apply spatial filter (including independent component analysis)
- Spectral decomposition - tapered FFT - and selection of frequency bands of interest
- Save raw data and all transformed measures (spectral decomposition, feedback) in Matlab files for each subject
- Import the saved data in EEGLAB
- Real time eLoreta and connectivity analysis. Note that this option is beta and will require that you create a leadfield matrice for your montage and indicate which regions of interest you want to compute connectivity between (use the function eloreta_compute_file_nfblab.m to do so).

# Typical usage

In a typical session, you will call the *nfblab_process* with the *runmode* option set to *baseline* to acquire a baseline of about 1 minute. This will allow Neurofeedbacklab to find bad channels, set up the Artifact Subspace Reconstruction filer, run ICA and find bad components. After the baseline run, you run one or more trial runs (*runmode* option set to *trial*).

# Hardware

Any EEG system supported by LSL (this includes BIOSEMI, EGI, Neuroscan, Brainproducts, Emotiv, Cognionics, Enobio, Muse etc...). See the full list at https://github.com/sccn/labstreaminglayer/wiki/SupportedDevices.wiki. Allow using ADR101 board (http://www.ontrak.net/adr101.htm) if you want to be able to send events from the presentation computer to the EEG system. These boards translate serial information to parallel that can be used with EEG systems. Plan for a relatively powerfull multi-core computer to perform both data acquisition and feedback. The current program was used with a BIOSEMI 64-channel system and a 4-core Dell workstation with 8Gb of RAM.

# Feedback

Visual feedback is handled by the free Matlab Psychophysics toolbox (http://psychtoolbox.org/). Assuming that 2 screens are connected to the same PC, one screen for the experimenter and one screen for the participant. Can also be set up a single screen program that the experimenter and participant share. Default visual feedback is simple (for a session is visible see https://youtu.be/7lrMgpV1FSI) but can be tailored to any user need.

Feedback through a third party program is implemented through TCP/IP communication. An example of client is provided in simple_client.m. To use this client, start 2 sessions of Matlab. Set the nfblab_process  "runmode" parameter to "slave", then run nfblab_process which will then for a connection from a client. In the separate session run the simple_client program. The program connected through TCP/IP can change all the options for the nfblab_process program including the LSL stream name.

# Platform

Tested on Windows and Mac. Real-time code tested against offline EEGLAB processing pipelines (see function *nfblab_check_computation.m*)

# Publication

This program was used to collect data on 24 subjects in a double blinded protocol (12 neurofeedback and 12 controls). 192 sessions were recorded. An session demo is visible here https://youtu.be/7lrMgpV1FSI. Please cite

Brandmeyer T, Delorme A. Closed-Loop Frontal Midlineθ Neurofeedback: A Novel Approach for Training Focused-Attention Meditation. Front Hum Neurosci. 2020 Jun 30;14:246. doi: [10.3389/fnhum.2020.00246](https://www.frontiersin.org/articles/10.3389/fnhum.2020.00246/full
). PMID: 32714171; PMCID: PMC7344173.

# Computer settings for psychophysics toolbox display
- Set up your screen resolution and screen settings. This program is made to be run on 2 screens, one screen for the subject and one screen for the expertimenter. For technical reasons, it is always better to set your primary screen as the screen for the subject (otherwise the psychophysics toolbox might not work properly).
- Disable visual buffering in Matlab. Create an icon on the desktop for Matlab. Look at properties - compatibility tab. Disable "Desktop composition" and "Disable display scaling on high DPI setttings".
- Go to your graphic card properties (display settings and select your graphic card). If you do not have graphic properties, then do not worry about this step. Disable tripple buferring, double buffering and any other fancy option (3-D etc...).

# Compile the program (so it does not require Matlab)

See the [COMPILE.md](COMPILE.md) documentation.

