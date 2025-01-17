/*******************************************************************
 *                                                                 *
 * File          : nvector_serial.h                                *
 * Programmers   : Scott D. Cohen, Alan C. Hindmarsh,              *
 *               : Radu Serban, and Allan G. Taylor, LLNL          *
 * Version of    : 06 June 2003                                    *
 *-----------------------------------------------------------------*
 * Copyright (c) 2002, The Regents of the University of California *
 * Produced at the Lawrence Livermore National Laboratory          *
 * All rights reserved                                             *
 * For details, see sundials/shared/LICENSE                        *
 *-----------------------------------------------------------------*
 * This is the header file for a serial implementation of the      *
 * NVECTOR package.                                                *
 *                                                                 *
 * Part I of this file contains declarations which are specific    *
 * to the particular machine environment in which this version     *
 * of the vector package is to be used. This includes the          *
 * typedef for the 'content' fields of the structures NV_Spec and  *
 * N_Vector (NV_SpecContent_Serial and N_VectorContent_Serial,     *
 * respectively).                                                  *
 *                                                                 *
 * Part II of this file defines accessor macros that allow the     *
 * user to use efficiently the type N_Vector without making        *
 * explicit references to its underlying representation.           *
 *                                                                 *
 * Part III of this file contains the prototype for the            *
 * initialization routine specific to this implementation          *
 * (NV_SpecInit_Serial) as well as prototypes for the vector       *
 * kernels which operate on the serial N_Vector. These             *
 * prototypes are unique to this particular implementation of      *
 * the vector package.                                             *
 *                                                                 *
 * NOTES:                                                          *
 *                                                                 *
 * The definitions of the generic NV_Spec and N_Vector structures  *
 * are in the header file nvector.h.                               *
 *                                                                 *
 * The definitions of the types realtype and integertype are in    *
 * the header file sundialstypes.h and these may be changed        *
 * according to the user's needs. The sundialstypes.h file also    *
 * contains the definition for the type booleantype.               *
 *                                                                 *
 * N_Vector arguments to arithmetic kernels need not be            *
 * distinct. Thus, for example, the call                           *
 *         N_VLinearSum_Serial(a,x,b,y,y);   y <- ax+by            *
 * is legal.                                                       *
 *                                                                 * 
 *******************************************************************/

#ifdef __cplusplus     /* wrapper to enable C++ usage */
extern "C" {
#endif

#ifndef included_nvector_serial_h
#define included_nvector_serial_h

#include "nvector.h"  /* Generic M_Env and N_Vector type definitions */
#include "sundialstypes.h"


/****************************************************************
 * PART I:                                                      *
 * Serial implementaion of NV_Spec and N_Vector                 *
 ****************************************************************/

/* The serial implementation of the vector specification has 
   ID tag 'serial' */
#define ID_TAG_S "serial"

/* The serial implementation of the vector specification 'content'
   structure contains the length of vectors */

struct _NV_SpecContent_Serial {
  integertype length;
};

typedef struct _NV_SpecContent_Serial *NV_SpecContent_Serial;

/* The serial implementation of the N_Vector 'content' 
   structure contains the length of the vector and a pointer 
   to an array of realtype components */

struct _N_VectorContent_Serial {
  integertype length;
  realtype   *data;
};

typedef struct _N_VectorContent_Serial *N_VectorContent_Serial;

/****************************************************************
 *                                                              *
 * PART II: Macros                                              *
 *    NV_MAKE_S, NV_DISPOSE_S, NVS_MAKE_S, NVS_DISPOSE_S        *
 *    ME_CONTENT_S, NV_CONTENT_S                                *
 *    NV_DATA_S, NV_LENGTH_S, NV_Ith_S                          *
 *--------------------------------------------------------------*
 * In the descriptions below, the following user declarations   *
 * are assumed:                                                 *
 *                                                              *
 * NV_Spec       nvSpec;                                        *
 * N_Vector      v, *vs;                                        *
 * realtype     *v_data, **vs_data, r;                          *
 * integertype   v_len, s_len, i;                               *
 *                                                              *
 * (1) NV_MAKE_S, NV_DISPOSE_S                                  *
 *                                                              *
 *     These companion routines are used to create and          *
 *     destroy an N_Vector with a component array v_data        *
 *     allocated by the user.                                   *
 *                                                              *
 *     The call NV_MAKE_S(v, v_data, nvspec) makes v an         *
 *     N_Vector with component array v_data. The length of the  *
 *     array is taken from nvspec.                              *
 *     NV_MAKE_S stores the pointer v_data so that changes      *
 *     made by the user to the elements of v_data are           *
 *     simultaneously reflected in v. There is no copying of    *
 *     elements.                                                *
 *                                                              *
 *     The call NV_DISPOSE_S(v) frees all memory associated     *
 *     with v except for its component array. This memory was   *
 *     allocated by the user and, therefore, should be          *
 *     deallocated by the user.                                 *
 *                                                              *
 * (2) NVS_MAKE_S, NVS_DISPOSE_S                                *
 *                                                              *
 *     These companion routines are used to create and destroy  *
 *     an array of N_Vectors with component vs_data allocated   *
 *     by the user.                                             *
 *                                                              *
 *     The call NVS_MAKE_S(vs, vs_data, s_len, nvspec) makes    *
 *     vs an array of s_len N_Vectors, each with component      *
 *     array vs_data[i] and array length taken from nvspec.     *
 *     NVS_MAKE_S stores the pointers vs_data[i] so that        *
 *     changes made by the user to the elements of vs_data are  *
 *     simultaneously reflected in vs. There is no copying of   *
 *     elements.                                                *
 *                                                              *
 *     The call NVS_DISPOSE_S(vs) frees all memory associated   *
 *     with vs except for its components' component array.      *
 *     This memory was allocated by the user and, therefore,    *
 *     should be deallocated by the user.                       *
 *                                                              *
 * (3) NS_CONTENT_S, NV_CONTENT_S                               *
 *                                                              *
 *     These routines give access to the contents of the serial *
 *     vector specification and N_Vector, respectively.         * 
 *                                                              *
 *     The assignment ns_cont = NS_CONTENT_S(nvspec) sets       *
 *     ns_cont to be a pointer to the serial vector             *
 *     specification content structure.                         * 
 *                                                              *
 *     The assignment v_cont = NV_CONTENT_S(v) sets             *
 *     v_cont to be a pointer to the serial N_Vector content    *
 *     structure.                                               *
 *                                                              *
 * (4) NV_DATA_S, NV_LENGTH_S                                   *
 *                                                              *
 *     These routines give individual access to the parts of    *
 *     the content of a serial N_Vector.                        *
 *                                                              *
 *     The assignment v_data=NV_DATA_S(v) sets v_data to be     *
 *     a pointer to the first component of v. The assignment    *
 *     NV_DATA_S(v)=v_data sets the component array of v to     *
 *     be v_data by storing the pointer v_data.                 *  
 *                                                              *
 *     The assignment v_len=NV_LENGTH_S(v) sets v_len to be     *
 *     the length of v. The call NV_LENGTH_S(v)=len_v sets      *
 *     the length of v to be len_v.                             *
 *                                                              *
 * (5) NV_Ith_S                                                 *
 *                                                              *
 *     In the following description, the components of an       *
 *     N_Vector are numbered 0..N-1, where N is the length of   *
 *     v.                                                       *
 *                                                              *
 *     The assignment r=NV_Ith_S(v,i) sets r to be the value of *
 *     the ith component of v. The assignment NV_Ith_S(v,i)=r   *
 *     sets the value of the ith component of v to be r.        *
 *                                                              *
 * Notes..                                                      *
 *                                                              *
 * Users who use the macros (1) and/or (2) must                 *
 * #include<stdlib.h> since these macros expand to calls to     *
 * malloc and free.                                             *
 *                                                              *
 * When looping over the components of an N_Vector v, it is     *
 * more efficient to first obtain the component array via       *
 * v_data=NV_DATA_S(v) and then access v_data[i] within the     *
 * loop than it is to use NV_Ith_S(v,i) within the loop.        *
 *                                                              *
 * NV_MAKE_S and NV_DISPOSE_S are similar to N_VNew_Serial and  *
 * N_VFree_Serial, while NVS_MAKE_S and NVS_DISPOSE_S  are      *
 * similar to  N_VNew_S_Serial and N_VFree_S_Serial. The        *
 * difference is one of responsibility for component memory     *
 * allocation and deallocation. N_VNew_Serial allocates memory  *
 * for the N_Vector components and N_VFree_Serial frees the     *
 * component memory allocated by N_VNew_Serial. For NV_MAKE_S   *
 * and NV_DISPOSE_S, the component memory is allocated and      *
 * freed by the user of this package. Similar remarks hold for  *
 * NVS_MAKE_S,  NVS_DISPOSE_S and N_VNew_S_Serial,              *
 * N_VFree_S_Serial.                                            *
 *                                                              *
 ****************************************************************/ 

#define NV_MAKE_S(v, v_data, nvspec) \
        v = (N_Vector) malloc(sizeof(*v)); \
        v->content = (N_VectorContent_Serial) malloc(sizeof(struct _N_VectorContent_Serial)); \
        v->content->data = v_data; \
        v->content->length = nvspec->content->v_len; \
        v->nvspec = nvspec

#define NV_DISPOSE_S(v) \
        free((N_VectorContent_Serial)(v->content)); \
        free(v)

#define NVS_MAKE_S(vs, vs_data, s_len, nvspec) \
        vs = (N_Vector_S) malloc(s_len*sizeof(N_Vector *)); \
        for ((int)is=0; is<s_len; is++) { \
           NV_MAKE_S(vs[is], vs_data[is], nvspec); \
        }

#define NVS_DISPOSE_S(vs, s_len) \
        for ((int)is=0; is<s_len; is++) NV_DISPOSE_S(vs[i]); \
        free(vs);

#define NS_CONTENT_S(s) ( (NV_SpecContent_Serial)(s->content) )

#define NV_CONTENT_S(v) ( (N_VectorContent_Serial)(v->content) )

#define NV_LENGTH_S(v) ( NV_CONTENT_S(v)->length )

#define NV_DATA_S(v) ( NV_CONTENT_S(v)->data )

#define NV_Ith_S(v,i) ( NV_DATA_S(v)[i] )


/****************************************************************
 * PART III:                                                    *
 * Functions exported by nvector_serial                         *
 ****************************************************************/

/*--------------------------------------------------------------*
 * Routine : NV_SpecInit_Serial                                 *
 *--------------------------------------------------------------*
 * This function sets the content field of the vector           *
 * specification for the serial implementation to a structure   *
 * of type _NV_SpecContent_Serial and attaches the vector       *
 * operations defined for this implementation.                  *
 *                                                              *
 * If successful, NV_SpecInit_Serial returns a pointer of type  *
 * NV_Spec. This pointer should in turn be passed in any user   *
 * calls to N_VNew, or uses of the macros NV_MAKE_S and         *
 * NVS_MAKE_S.                                                  *
 *                                                              *
 *--------------------------------------------------------------*
 *                                                              *
 * vec_length      is the length of the vector.                 *
 *                                                              *
 *--------------------------------------------------------------*/

NV_Spec NV_SpecInit_Serial(integertype vec_length);

/*--------------------------------------------------------------*
 * Function NV_SpecFree_Serial                                  *
 *--------------------------------------------------------------*
 * Function to free the block of vector specification           *
 * information created by NV_SpecInit_Serial.                   *
 * Its only argument is the pointer nvspec returned by          *
 * NV_SpecInit_Serial.                                          *
 *                                                              *
 *--------------------------------------------------------------*/

void NV_SpecFree_Serial(NV_Spec nvspec);

/*--------------------------------------------------------------*
 * Serial implementations of the vector operations              * 
 *                                                              *
 * For a complete description of each of the following routines *
 * see the header file nvector.h                                *
 *--------------------------------------------------------------*/

N_Vector N_VNew_Serial(NV_Spec nvspec);
void N_VSpace_Serial(NV_Spec nvspec, long int *lrw, long int *liw);
void N_VFree_Serial(N_Vector v);
N_Vector N_VMake_Serial(realtype *v_data, NV_Spec nvspec);
void N_VDispose_Serial(N_Vector v);
realtype *N_VGetData_Serial(N_Vector v);
void N_VSetData_Serial(realtype *v_data, N_Vector v);
void N_VLinearSum_Serial(realtype a, N_Vector x, realtype b, N_Vector y, N_Vector z);
void N_VConst_Serial(realtype c, N_Vector z);
void N_VProd_Serial(N_Vector x, N_Vector y, N_Vector z);
void N_VDiv_Serial(N_Vector x, N_Vector y, N_Vector z);
void N_VScale_Serial(realtype c, N_Vector x, N_Vector z);
void N_VAbs_Serial(N_Vector x, N_Vector z);
void N_VInv_Serial(N_Vector x, N_Vector z);
void N_VAddConst_Serial(N_Vector x, realtype b, N_Vector z);
realtype N_VDotProd_Serial(N_Vector x, N_Vector y);
realtype N_VMaxNorm_Serial(N_Vector x);
realtype N_VWrmsNorm_Serial(N_Vector x, N_Vector w);
realtype N_VWrmsNormMask_Serial(N_Vector x, N_Vector w, N_Vector id);
realtype N_VMin_Serial(N_Vector x);
realtype N_VWL2Norm_Serial(N_Vector x, N_Vector w);
realtype N_VL1Norm_Serial(N_Vector x);
void N_VCompare_Serial(realtype c, N_Vector x, N_Vector z);
booleantype N_VInvTest_Serial(N_Vector x, N_Vector z);
booleantype N_VConstrProdPos_Serial(N_Vector c, N_Vector x);
booleantype N_VConstrMask_Serial(N_Vector c, N_Vector x, N_Vector m);   
realtype N_VMinQuotient_Serial(N_Vector num, N_Vector denom);
void N_VPrint_Serial(N_Vector x);



#endif
#ifdef __cplusplus
}
#endif
