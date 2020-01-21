# This is the procedure to compile the program

1. Clone EEGLAB with submodules

2. In clean_rawdata, copy private folder content to clean_rawdata folder

3. Clone BCILAB

4. Start Matlab

5. Stats EEGLAB

6. Manually add paths (do not start BCILAB)

addpath('Z:\data\matlab\BCILAB\dependencies\liblsl-Matlab');
addpath('Z:\data\matlab\BCILAB\dependencies\liblsl-Matlab\bin');
addpath('Z:\data\matlab\BCILAB\dependencies\liblsl-Matlab\mex\build-Christian-PC');
addpath('C:\Users\labadmin\Desktop\BCILAB\dependencies\asr-matlab-2012-09-12\'); % not required if copied the files above

7. Create new compile project

8. Add nfblab_process

9. Add file BCILAB\dependencies\liblsl-Matlab\bin\liblsl64.dll

10. Package



