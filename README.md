# Neurofeedback:

A Neurofeedback software approach based on Matlab. There is no visual programming languager, so it is only sutable for those who do not fear source code and the command line. Programming experience is needed to fine tune the protocol parameters but not for running experiments.

# Dependencies:

- Matlab (including student versions)
- Matlab psychophyics toolbox
- BCILAB
- LSL (lab streaming layer)

# Features:

- Run n sessions over m days. The first session of each day is always a baseline used for ASR below.
- Manage subjects, automatically creates new folders for new subjects and track subject progress. Track human errors by checking that a new sessions is preceeded by an existing previous session.
- Allow blinded protocol where a session from one subject is replayed to another subject (the data from the sham subject is recorded as if he was doing the task but the feedback from another subject is shownn).
- Adaptive filtering with minimum phase distortion
- Automated artifact rejection using Artifact Subspace Reconstruction. This methods uses PCA to find artifactual sections of data, then reconstruct a clean signal based on the statistics of the basline. https://sccn.ucsd.edu/~scott/pdf/Mullen_BCI13.pdf
- Possible spacial filter (independent component analysis) although these have to be entered manually in the script for each subject
- Spectral decomposition - tapered FFT - and selection of frequency bands of interest
- Save raw data and all transformed measures (spectral decomposition, feedback) in Matlab files for each subject
- Import the data in EEGLAB (scripts available upon request but not included in this project)

# Hardware:

Any hardware supported by LSL. ADR100 board if you want to be able to send events from the presentation computer to the EEG system.

# Platform

Tested on Mac but should run on other platforms
