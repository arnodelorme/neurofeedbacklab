This is the MATLAB interface for liblsl.

* You need to add this directory to your MATLAB path recursively
    * Using the MATLAB GUI, use File/Set Path...
    * Alternatively, in a script, use `addpath(genpath('path/to/liblsl-Matlab'));`
* The `bin/` directory needs to contain an up-to-date build of the library file for your MATLAB version.
    * see [here](https://github.com/sccn/labstreaminglayer/blob/master/doc/BUILD.md#note-about-architectures--binaries) for more information which library you need
    * download precompiled libraries from the [liblsl release page](https://github.com/sccn/liblsl/releases)
    * e.g. `liblsl64.dll` for 64-bit MATLAB on Windows.
    * e.g. `liblsl64.dylib` and `liblsl64.1.4.0.dylib` for 64-bit MATLAB on MacOS.
    * e.g. `liblsl64.so` and `liblsl64.so.1.4.0` for 64-bit MATLAB in Linux
* Once this taken care of, see the example files in the examples/ directory for how to use this interface in a MATLAB program.

### Troubleshooting

If you get an error similar to `lsl_loadlib_ undefined`, then you may need to run the `build_mex.m` script from within the liblsl-Matlab directory.
(From the command line: `matlab -nodesktop -nosplash -r 'build_mex'`)

On MacOS, you may still get an error similar to `Invalid MEX-file [...] lsl_loadlib_.mexmaci64; Reason: image not found.`. To fix this run the following command in a Terminal window from within the liblsl-Matlab directory: `install_name_tool -add_rpath "@loader_path/" bin/lsl_loadlib_.mexmaci64`
