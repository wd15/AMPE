/*
 * -----------------------------------------------------------------
 * $Revision: 1.3 $
 * $Date: 2007/04/30 19:29:01 $
 * ----------------------------------------------------------------- 
 * Programmer: Radu Serban @ LLNL
 * -----------------------------------------------------------------
 * Copyright (c) 2006, The Regents of the University of California.
 * Produced at the Lawrence Livermore National Laboratory.
 * All rights reserved.
 * For details, see the LICENSE file.
 * -----------------------------------------------------------------
 * This is the implementation file for the KINDIRECT linear solvers
 * -----------------------------------------------------------------
 */

/* 
 * =================================================================
 * IMPORTED HEADER FILES
 * =================================================================
 */

#include <stdio.h>
#include <stdlib.h>

#include "kinsol_impl.h"
#include "kinsol_direct_impl.h"
#include <sundials/sundials_math.h>

/* 
 * =================================================================
 * FUNCTION SPECIFIC CONSTANTS
 * =================================================================
 */

/* Constant for DQ Jacobian approximation */
#define MIN_INC_MULT RCONST(1000.0)

#define ZERO         RCONST(0.0)
#define ONE          RCONST(1.0)
#define TWO          RCONST(2.0)

/*
 * =================================================================
 * READIBILITY REPLACEMENTS
 * =================================================================
 */

#define lrw1           (kin_mem->kin_lrw1)
#define liw1           (kin_mem->kin_liw1)
#define uround         (kin_mem->kin_uround)
#define func           (kin_mem->kin_func)
#define user_data      (kin_mem->kin_user_data)
#define printfl        (kin_mem->kin_printfl)
#define linit          (kin_mem->kin_linit)
#define lsetup         (kin_mem->kin_lsetup)
#define lsolve         (kin_mem->kin_lsolve)
#define lfree          (kin_mem->kin_lfree)
#define lmem           (kin_mem->kin_lmem)
#define inexact_ls     (kin_mem->kin_inexact_ls)
#define uu             (kin_mem->kin_uu)
#define fval           (kin_mem->kin_fval)
#define uscale         (kin_mem->kin_uscale)
#define fscale         (kin_mem->kin_fscale)
#define sqrt_relfunc   (kin_mem->kin_sqrt_relfunc)
#define sJpnorm        (kin_mem->kin_sJpnorm)
#define sfdotJp        (kin_mem->kin_sfdotJp)
#define errfp          (kin_mem->kin_errfp)
#define infofp         (kin_mem->kin_infofp)
#define setupNonNull   (kin_mem->kin_setupNonNull)
#define vtemp1         (kin_mem->kin_vtemp1)
#define vec_tmpl       (kin_mem->kin_vtemp1)
#define vtemp2         (kin_mem->kin_vtemp2)

#define mtype          (kindls_mem->d_type)
#define n              (kindls_mem->d_n)
#define ml             (kindls_mem->d_ml)
#define mu             (kindls_mem->d_mu)
#define smu            (kindls_mem->d_smu)
#define jacDQ          (kindls_mem->d_jacDQ)
#define djac           (kindls_mem->d_djac)
#define bjac           (kindls_mem->d_bjac)
#define J              (kindls_mem->d_J)
#define pivots         (kindls_mem->d_pivots)
#define nje            (kindls_mem->d_nje)
#define nfeDQ          (kindls_mem->d_nfeDQ)
#define J_data         (kindls_mem->d_J_data)
#define last_flag      (kindls_mem->d_last_flag)

/* 
 * =================================================================
 * EXPORTED FUNCTIONS
 * =================================================================
 */
              
/*
 * -----------------------------------------------------------------
 * KINDlsSetJacFn
 * -----------------------------------------------------------------
 */

int KINDlsSetDenseJacFn(void *kinmem, KINDlsDenseJacFn jac)
{
  KINMem kin_mem;
  KINDlsMem kindls_mem;

  /* Return immediately if kinmem is NULL */
  if (kinmem == NULL) {
    KINProcessError(NULL, KINDIRECT_MEM_NULL, "KINDIRECT", "KINDlsSetDenseJacFn", MSGD_KINMEM_NULL);
    return(KINDIRECT_MEM_NULL);
  }
  kin_mem = (KINMem) kinmem;

  if (lmem == NULL) {
    KINProcessError(kin_mem, KINDIRECT_LMEM_NULL, "KINDIRECT", "KINDlsSetDenseJacFn", MSGD_LMEM_NULL);
    return(KINDIRECT_LMEM_NULL);
  }
  kindls_mem = (KINDlsMem) lmem;

  if (jac != NULL) {
    jacDQ = FALSE;
    djac = jac;
  } else {
    jacDQ = TRUE;
  }

  return(KINDIRECT_SUCCESS);
}

int KINDlsSetBandJacFn(void *kinmem, KINDlsBandJacFn jac)
{
  KINMem kin_mem;
  KINDlsMem kindls_mem;

  /* Return immediately if kinmem is NULL */
  if (kinmem == NULL) {
    KINProcessError(NULL, KINDIRECT_MEM_NULL, "KINDIRECT", "KINDlsSetBandJacFn", MSGD_KINMEM_NULL);
    return(KINDIRECT_MEM_NULL);
  }
  kin_mem = (KINMem) kinmem;

  if (lmem == NULL) {
    KINProcessError(kin_mem, KINDIRECT_LMEM_NULL, "KINDIRECT", "KINDlsSetBandJacFn", MSGD_LMEM_NULL);
    return(KINDIRECT_LMEM_NULL);
  }
  kindls_mem = (KINDlsMem) lmem;

  if (jac != NULL) {
    jacDQ = FALSE;
    bjac = jac;
  } else {
    jacDQ = TRUE;
  }

  return(KINDIRECT_SUCCESS);
}

/*
 * -----------------------------------------------------------------
 * KINDlsGetWorkSpace
 * -----------------------------------------------------------------
 */

int KINDlsGetWorkSpace(void *kinmem, long int *lenrwLS, long int *leniwLS)
{
  KINMem kin_mem;
  KINDlsMem kindls_mem;

  /* Return immediately if kinmem is NULL */
  if (kinmem == NULL) {
    KINProcessError(NULL, KINDIRECT_MEM_NULL, "KINDIRECT", "KINBandGetWorkSpace", MSGD_KINMEM_NULL);
    return(KINDIRECT_MEM_NULL);
  }
  kin_mem = (KINMem) kinmem;

  if (lmem == NULL) {
    KINProcessError(kin_mem, KINDIRECT_LMEM_NULL, "KINDIRECT", "KINBandGetWorkSpace", MSGD_LMEM_NULL);
    return(KINDIRECT_LMEM_NULL);
  }
  kindls_mem = (KINDlsMem) lmem;

  if (mtype == SUNDIALS_DENSE) {
    *lenrwLS = n*n;
    *leniwLS = n;
  } else if (mtype == SUNDIALS_BAND) {
    *lenrwLS = n*(smu + mu + 2*ml + 2);
    *leniwLS = n;
  }

  return(KINDIRECT_SUCCESS);
}

/*
 * -----------------------------------------------------------------
 * KINDlsGetNumJacEvals
 * -----------------------------------------------------------------
 */

int KINDlsGetNumJacEvals(void *kinmem, long int *njevals)
{
  KINMem kin_mem;
  KINDlsMem kindls_mem;

  /* Return immediately if kinmem is NULL */
  if (kinmem == NULL) {
    KINProcessError(NULL, KINDIRECT_MEM_NULL, "KINDIRECT", "KINDlsGetNumJacEvals", MSGD_KINMEM_NULL);
    return(KINDIRECT_MEM_NULL);
  }
  kin_mem = (KINMem) kinmem;

  if (lmem == NULL) {
    KINProcessError(kin_mem, KINDIRECT_LMEM_NULL, "KINDIRECT", "KINDlsGetNumJacEvals", MSGD_LMEM_NULL);
    return(KINDIRECT_LMEM_NULL);
  }
  kindls_mem = (KINDlsMem) lmem;

  *njevals = nje;

  return(KINDIRECT_SUCCESS);
}

/*
 * -----------------------------------------------------------------
 * KINDlsGetNumFuncEvals
 * -----------------------------------------------------------------
 */

int KINDlsGetNumFuncEvals(void *kinmem, long int *nfevalsLS)
{
  KINMem kin_mem;
  KINDlsMem kindls_mem;

  /* Return immediately if kinmem is NULL */
  if (kinmem == NULL) {
    KINProcessError(NULL, KINDIRECT_MEM_NULL, "KINDIRECT", "KINDlsGetNumFuncEvals", MSGD_KINMEM_NULL);
    return(KINDIRECT_MEM_NULL);
  }
  kin_mem = (KINMem) kinmem;

  if (lmem == NULL) {
    KINProcessError(kin_mem, KINDIRECT_LMEM_NULL, "KINDIRECT", "KINDlsGetNumGuncEvals", MSGD_LMEM_NULL);
    return(KINDIRECT_LMEM_NULL);
  }
  kindls_mem = (KINDlsMem) lmem;

  *nfevalsLS = nfeDQ;

  return(KINDIRECT_SUCCESS);
}

/*
 * -----------------------------------------------------------------
 * KINDlsGetLastFlag
 * -----------------------------------------------------------------
 */

int KINDlsGetLastFlag(void *kinmem, int *flag)
{
  KINMem kin_mem;
  KINDlsMem kindls_mem;

  /* Return immediately if kinmem is NULL */
  if (kinmem == NULL) {
    KINProcessError(NULL, KINDIRECT_MEM_NULL, "KINDIRECT", "KINDlsGetLastFlag", MSGD_KINMEM_NULL);
    return(KINDIRECT_MEM_NULL);
  }
  kin_mem = (KINMem) kinmem;

  if (lmem == NULL) {
    KINProcessError(kin_mem, KINDIRECT_LMEM_NULL, "KINDIRECT", "KINDlsGetLastFlag", MSGD_LMEM_NULL);
    return(KINDIRECT_LMEM_NULL);
  }
  kindls_mem = (KINDlsMem) lmem;

  *flag = last_flag;

  return(KINDIRECT_SUCCESS);
}

/*
 * -----------------------------------------------------------------
 * KINDlsGetReturnFlagName
 * -----------------------------------------------------------------
 */

char *KINDlsGetReturnFlagName(int flag)
{
  char *name;

  name = (char *)malloc(30*sizeof(char));

  switch(flag) {
  case KINDIRECT_SUCCESS:
    sprintf(name, "KINDIRECT_SUCCESS");
    break;
  case KINDIRECT_MEM_NULL:
    sprintf(name, "KINDIRECT_MEM_NULL");
    break;
  case KINDIRECT_LMEM_NULL:
    sprintf(name, "KINDIRECT_LMEM_NULL");
    break;
  case KINDIRECT_ILL_INPUT:
    sprintf(name, "KINDIRECT_ILL_INPUT");
    break;
  case KINDIRECT_MEM_FAIL:
    sprintf(name, "KINDIRECT_MEM_FAIL");
    break;
  default:
    sprintf(name, "NONE");
  }

  return(name);
}

/* 
 * =================================================================
 * DQ JACOBIAN APPROXIMATIONS
 * =================================================================
 */



/*
 * -----------------------------------------------------------------
 * kinDlsDenseDQJac 
 * -----------------------------------------------------------------
 * This routine generates a dense difference quotient approximation to
 * the Jacobian of F(u). It assumes that a dense matrix of type
 * DlsMat is stored column-wise, and that elements within each column
 * are contiguous. The address of the jth column of J is obtained via
 * the macro DENSE_COL and this pointer is associated with an N_Vector
 * using the N_VGetArrayPointer/N_VSetArrayPointer functions. 
 * Finally, the actual computation of the jth column of the Jacobian is 
 * done with a call to N_VLinearSum.
 *
 * The increment used in the finite-difference approximation
 *   J_ij = ( F_i(u+sigma_j * e_j) - F_i(u)  ) / sigma_j
 * is
 *  sigma_j = max{|u_j|, |1/uscale_j|} * sqrt(uround)
 *
 * Note: uscale_j = 1/typ(u_j)
 *
 * NOTE: Any type of failure of the system function her leads to an
 *       unrecoverable failure of the Jacobian function and thus
 *       of the linear solver setup function, stopping KINSOL.
 * -----------------------------------------------------------------
 */

int kinDlsDenseDQJac(int N,
                     N_Vector u, N_Vector fu,
                     DlsMat Jac, void *data,
                     N_Vector tmp1, N_Vector tmp2)
{
  realtype inc, inc_inv, ujsaved, ujscale, sign;
  realtype *tmp2_data, *u_data, *uscale_data;
  N_Vector ftemp, jthCol;
  long int j;
  int retval;

  KINMem kin_mem;
  KINDlsMem  kindls_mem;

  /* data points to kin_mem */
  kin_mem = (KINMem) data;
  kindls_mem = (KINDlsMem) lmem;

  /* Save pointer to the array in tmp2 */
  tmp2_data = N_VGetArrayPointer(tmp2);

  /* Rename work vectors for readibility */
  ftemp = tmp1; 
  jthCol = tmp2;

  /* Obtain pointers to the data for u and uscale */
  u_data   = N_VGetArrayPointer(u);
  uscale_data = N_VGetArrayPointer(uscale);

  /* This is the only for loop for 0..N-1 in KINSOL */

  for (j = 0; j < N; j++) {

    /* Generate the jth col of Jac(u) */

    N_VSetArrayPointer(DENSE_COL(Jac,j), jthCol);

    ujsaved = u_data[j];
    ujscale = ONE/uscale_data[j];
    sign = (ujsaved >= ZERO) ? ONE : -ONE;
    inc = sqrt_relfunc*MAX(ABS(ujsaved), ujscale)*sign;
    u_data[j] += inc;

    retval = func(u, ftemp, user_data);
    if (retval != 0) return(-1); 

    u_data[j] = ujsaved;

    inc_inv = ONE/inc;
    N_VLinearSum(inc_inv, ftemp, -inc_inv, fu, jthCol);

  }

  /* Restore original array pointer in tmp2 */
  N_VSetArrayPointer(tmp2_data, tmp2);

  /* Increment counter nfeDQ */
  nfeDQ += N;

  return(0);
}

/*
 * -----------------------------------------------------------------
 * kinDlsBandDQJac
 * -----------------------------------------------------------------
 * This routine generates a banded difference quotient approximation to
 * the Jacobian of F(u).  It assumes that a band matrix of type
 * BandMat is stored column-wise, and that elements within each column
 * are contiguous. This makes it possible to get the address of a column
 * of J via the macro BAND_COL and to write a simple for loop to set
 * each of the elements of a column in succession.
 *
 * NOTE: Any type of failure of the system function her leads to an
 *       unrecoverable failure of the Jacobian function and thus
 *       of the linear solver setup function, stopping KINSOL.
 * -----------------------------------------------------------------
 */

int kinDlsBandDQJac(int N, int mupper, int mlower,
                    N_Vector u, N_Vector fu,
                    DlsMat Jac, void *data,
                    N_Vector tmp1, N_Vector tmp2)
{
  realtype inc, inc_inv;
  N_Vector futemp, utemp;
  long int group, i, j, width, ngroups, i1, i2;
  realtype *col_j, *fu_data, *futemp_data, *u_data, *utemp_data, *uscale_data;
  int retval;

  KINMem kin_mem;
  KINDlsMem kindls_mem;

  /* data points to kinmem */
  kin_mem = (KINMem) data;
  kindls_mem = (KINDlsMem) lmem;

  /* Rename work vectors for use as temporary values of u and fu */
  futemp = tmp1;
  utemp = tmp2;

  /* Obtain pointers to the data for ewt, fy, futemp, y, ytemp */
  fu_data    = N_VGetArrayPointer(fu);
  futemp_data = N_VGetArrayPointer(futemp);
  u_data     = N_VGetArrayPointer(u);
  uscale_data = N_VGetArrayPointer(uscale);
  utemp_data = N_VGetArrayPointer(utemp);

  /* Load utemp with u */
  N_VScale(ONE, u, utemp);

  /* Set bandwidth and number of column groups for band differencing */
  width = mlower + mupper + 1;
  ngroups = MIN(width, N);
  
  for (group=1; group <= ngroups; group++) {
    
    /* Increment all utemp components in group */
    for(j=group-1; j < N; j+=width) {
      inc = sqrt_relfunc*MAX(ABS(u_data[j]), ABS(uscale_data[j]));
      utemp_data[j] += inc;
    }

    /* Evaluate f with incremented u */
    retval = func(utemp, futemp, user_data);
    if (retval != 0) return(-1); 

    /* Restore utemp components, then form and load difference quotients */
    for (j=group-1; j < N; j+=width) {
      utemp_data[j] = u_data[j];
      col_j = BAND_COL(Jac,j);
      inc = sqrt_relfunc*MAX(ABS(u_data[j]), ABS(uscale_data[j]));
      inc_inv = ONE/inc;
      i1 = MAX(0, j-mupper);
      i2 = MIN(j+mlower, N-1);
      for (i=i1; i <= i2; i++)
        BAND_COL_ELEM(col_j,i,j) = inc_inv * (futemp_data[i] - fu_data[i]);
    }
  }
  
  /* Increment counter nfeDQ */
  nfeDQ += ngroups;

  return(0);
}
