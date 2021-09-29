#include "lsl_common.h"

/* function lsl_set_processing(LibHandle,inlet, processing_flags) */

void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray *prhs[] ) 
{
    /* handle of the desired field */
    mxArray *field;
    /* temp pointer */
    uintptr_t *pTmp;
    /* function handle */
    lsl_set_postprocessing_t func;
    /* input/output variables */
    uintptr_t in;
    processing_options_t proc_flag;
    
    if (nrhs != 3)
        mexErrMsgTxt("3 input argument(s) required."); 
    if (nlhs != 0)
        mexErrMsgTxt("0 output argument(s) required."); 
    
    /* get function handle */
    field = mxGetField(prhs[0],0,"lsl_set_postprocessing");
    if (!field)
        mexErrMsgTxt("The field does not seem to exist.");
    pTmp = (uintptr_t*)mxGetData(field);
    if (!pTmp)
        mexErrMsgTxt("The field seems to be empty.");
    func = (lsl_set_postprocessing_t*)*pTmp;
    
    /* get additional inputs */
    in = *(uintptr_t*)mxGetData(prhs[1]);
    if (mxGetClassID(prhs[2]) != mxDOUBLE_CLASS)
        mexErrMsgTxt("The processing flag must be passed as a double.");
    proc_flag = (int)*(double*)mxGetData(prhs[2]);
    /* invoke & return */
    func(in, proc_flag);
}