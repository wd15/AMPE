#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "sundialstypes.h"
#include "levmar.h"
#include "lmspgmr.h"
#include "nvector_serial.h"
#include "sundialsmath.h"


static realtype cf_fun(N_Vector p, void *f_data);
static void gr_fun(N_Vector p, N_Vector g, void *f_data);
static int hv_fun(N_Vector v, N_Vector Hv, N_Vector pp, booleantype *new_pp, 
                  void *H_data);

/***************************** Main Program ******************************/

int main()
{
  N_Vector p, s;
  int flag, maxl, nni;
  void *mem;
  realtype *pdata, cfval, grd_inf;

  /* Create serial vectors of length  */
  p = N_VNew_Serial(2);
  s = N_VNew_Serial(2);

  pdata = NV_DATA_S(p);
  pdata[0] = 3.0;
  pdata[1] = 1.0;
  
  N_VConst(1.0, s);

  mem = LMCreate();
  LMSetEps1(mem, 1.0e-6);
  LMSetEps2(mem, 1.0e-15);
  LMSetMaxIters(mem, 50);
  flag = LMMalloc(mem, cf_fun, gr_fun, p);
  printf("flag LMMalloc = %d\n",flag);

  maxl = 2;
  flag = LMSpgmr(mem, maxl);
  printf("flag LMSpgmr = %d\n",flag);
  LMSpgmrSetHesTimesVecFn(mem, hv_fun);

  flag = LMSolve(mem, p, s, s);
  printf("flag LMSolve = %d\n",flag);

  LMGetNumNonlinSolvIters(mem, &nni);
  LMGetCost(mem, &cfval);
  LMGetGradNorm(mem, &grd_inf);

  printf("p =  %e  %e\n",pdata[0],pdata[1]);
  printf("nni = %d   cf = %e  ||grd|| = %e\n",nni,cfval,grd_inf);

  N_VDestroy(p);
  N_VDestroy(s);
  LMFree(mem);

  return(0);

}

static realtype cf_fun(N_Vector p, void *f_data)
{
  realtype *pdata;
  realtype p1, p2;
  realtype f1, f2, f3;
  realtype cf;

  pdata = NV_DATA_S(p);
  p1 = pdata[0];
  p2 = pdata[1];

  f1 = p1*p1 + p2*p2 + p1*p2;
  f2 = sin(p1);
  f3 = cos(p2);

  cf = 0.5*(f1*f1+f2*f2+f3*f3);

  //  printf("p:  %e  %e\n",pdata[0],pdata[1]);
  //  printf("cf: %e  %e  %e   %e\n",f1,f2,f3,cf);

  return(cf);

}
static void gr_fun(N_Vector p, N_Vector g, void *f_data)
{
  realtype *pdata, *gdata;
  realtype cp, sp;
  realtype p1, p2;
  realtype f1, f2, f3;

  pdata = NV_DATA_S(p);
  p1 = pdata[0];
  p2 = pdata[1];

  cp = cos(p1);
  sp = sin(p2);

  f1 = p1*p1 + p2*p2 + p1*p2;
  f2 = sp;
  f3 = cp;

  gdata = NV_DATA_S(g);
  gdata[0] = (2*p1+p2)*f1 + cp*f2;
  gdata[1] = (2*p2+p1)*f1 - sp*f3;

  //  printf("g: %e  %e\n",gdata[0],gdata[1]);

}

static int hv_fun(N_Vector v, N_Vector Hv, N_Vector p, booleantype *new_p, 
                  void *H_data)
{
  realtype *pdata, *Hvdata, *vdata;
  realtype cp, sp;
  realtype p1, p2;
  realtype v1, v2;

  pdata = NV_DATA_S(p);
  p1 = pdata[0];
  p2 = pdata[1];

  vdata = NV_DATA_S(v);
  v1 = vdata[0];
  v2 = vdata[1];

  cp = cos(p1);
  sp = sin(p2);

  Hvdata = NV_DATA_S(Hv);

  Hvdata[0] = ((2*p1+p2)*(2*p1+p2)+cp*cp)*v1 + (2*p1+p2)*(2*p2+p1)*v2;
  Hvdata[1] = (2*p1+p2)*(2*p2+p1)*v1 + ((2*p2+p1)*(2*p2+p1)+sp*sp)*v2;

  return(0);
}
