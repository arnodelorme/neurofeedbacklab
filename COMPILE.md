# This is the procedure to compile the program
  
This program has been compiled successfully under PC, Mac and Linux Ubuntu,
including the necessary binary LSL libraries. Note that based on your
version of MAC or Linux it might be necessary to recompile the LSL libraries.

The first steps are common with a standard Matlab neurofeedbacklab installation.

1. See [INSTALL.md](INSTALL.md) documentation.

2. Check that nfblab_process works on your platform especially the LSL
   link with your EEG headset by typing nfblab_process

3. Create new compile project using the Matlab graphical interface
   (Select Apps then Application Compiler). If the application compiler
   does not show, it means you need to purchase this additional Matlab
   toolbox.

4. Add nfblab_process.m ("+" button of the application compiler)

5. Add all the binary LSL files in BCILAB/dependencies/liblsl-Matlab/bin
   to your project (+ button under the File Required for your application
   to run - you only need to add the file corresponding to your platform but
   it will not hurt to add them all)

6. Press the package button

7. From a command prompt (Dos for Windows or terminal for OSx and Linux)
    go to the folder "for_testing" created by the compiler.

        - On Windows, run the exe file nfblab_process.exe by typing its
          name on the command line. It should behave the same as when the
          function of the same name is used from the command line. You
          will need to wait for about 1 minute for the program to uncompress
          itself the first time you start it.

        - On Mac, go to subfolder nfblab_process.app/Contents/MacOS/ and
          start the applauncher program "./applauncher"

        - On Linux, run the "run_nfblab_process.sh" passing as argument
          the location of the deployed Matlab runtime engine folder
          (install the version corresponding to Matlab version you used
          from compiling from https://www.mathworks.com/products/compiler/matlab-runtime.html
          For example ./run_nfblab_process.sh /usr/local/MATLAB/MATLAB_Runtime/v98/
          If you are running command line Ubuntu (no graphical interface),
          you might have to install the Ubuntu package "Sudo ap install libxmu6"
