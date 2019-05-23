# Neurofeedbacklab:

A Neurofeedback software approach based on Matlab. There is no visual programming languager, so it is only sutable for those who do not fear source code and the command line. Programming experience is needed to fine tune the protocol parameters but not for running experiments.

# Dependencies:

- Matlab (including student versions)
- Matlab psychophyics toolbox http://psychtoolbox.org/
- BCILAB https://sccn.ucsd.edu/wiki/BCILAB
- LSL (lab streaming layer) https://github.com/sccn/labstreaminglayer

# Features:

- Manage subjects and track subjects' progress. Track human errors by checking that new sessions are preceeded by existing previous sessions. Made as much human proof as possible.
- One computer runs data acquisition and performs the feedback. Assumes that 2 screens are connected to the same PC, one screen for the experimenter and one screen for the participant. Can also be set up a single screen program that the experimenter and participant share.
- Allow blinded protocol where a session from one subject is replayed to another subject (the data from the sham subject is recorded as if he was doing the task but the feedback from another subject is shownn).
- Run n sessions over m days. The first session of each day is always a baseline used for artifact rejection below.
- Adaptive filtering with minimum phase distortion
- Automated artifact rejection using Artifact Subspace Reconstruction. This methods uses PCA to find artifactual sections of data, then reconstruct a clean signal based on the statistics of the basline. https://sccn.ucsd.edu/~scott/pdf/Mullen_BCI13.pdf
- Possible spacial filter (independent component analysis) although these have to be entered manually in the script for each subject
- Spectral decomposition - tapered FFT - and selection of frequency bands of interest
- Save raw data and all transformed measures (spectral decomposition, feedback) in Matlab files for each subject
- Import the data in EEGLAB (scripts available upon request but not included in this project)

# Hardware:

Any EEG system supported by LSL (this includes BIOSEMI, EGI, Neuroscan, Brainproducts, Emotiv, Cognionics, Enobio, Muse etc...). See the full list at https://github.com/sccn/labstreaminglayer/wiki/SupportedDevices.wiki. Allow using ADR101 board (http://www.ontrak.net/adr101.htm) if you want to be able to send events from the presentation computer to the EEG system. These boards translate serial information to parallel that can be used with EEG systems. Plan for a relatively powerfull multi-core computer to perform both data acquisition and feedback. The current program was used with a BIOSEMI 64-channel system and a 4-core Dell workstation with 8Gb of RAM.

# Platform

Tested on Windows. It should run on Mac if you can find the LSL drivers for your EEG system.

# Publication

This program was used to collect data on 24 subjects in a double blinded protocol (12 neurofeedback and 12 controls). 192 sessions were recorded. The publication is pending. An example of a session is visible here https://youtu.be/7lrMgpV1FSI.

# Install and getting started

See the [Install.md] documentation.
