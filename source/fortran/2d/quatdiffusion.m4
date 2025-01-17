c Copyright (c) 2018, Lawrence Livermore National Security, LLC.
c Produced at the Lawrence Livermore National Laboratory
c Written by M.R. Dorr, J.-L. Fattebert and M.E. Wickett
c LLNL-CODE-747500
c All rights reserved.
c This file is part of AMPE. 
c For details, see https://github.com/LLNL/AMPE
c Please also read AMPE/LICENSE.
c Redistribution and use in source and binary forms, with or without 
c modification, are permitted provided that the following conditions are met:
c - Redistributions of source code must retain the above copyright notice,
c   this list of conditions and the disclaimer below.
c - Redistributions in binary form must reproduce the above copyright notice,
c   this list of conditions and the disclaimer (as noted below) in the
c   documentation and/or other materials provided with the distribution.
c - Neither the name of the LLNS/LLNL nor the names of its contributors may be
c   used to endorse or promote products derived from this software without
c   specific prior written permission.
c
c THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
c AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
c IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
c ARE DISCLAIMED. IN NO EVENT SHALL LAWRENCE LIVERMORE NATIONAL SECURITY,
c LLC, THE U.S. DEPARTMENT OF ENERGY OR CONTRIBUTORS BE LIABLE FOR ANY
c DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
c DAMAGES  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
c OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
c HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
c STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
c IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
c POSSIBILITY OF SUCH DAMAGE.
c 
define(NDIM,2)dnl
include(SAMRAI_FORTDIR/pdat_m4arrdim2d.i)dnl
c
c Coefficient misorientation_factor*[1-p(phi)] from Pusztai et al.
c
      subroutine quatdiffusion(
     &  ifirst0,ilast0,ifirst1,ilast1,
     &  misorientation_factor,
     &  temperature, tghosts,
     &  var, ngvar,
     &  diff0, diff1, ngdiff,
     &  interp_type,
     &  avg_type )
c***********************************************************************
      implicit none
c***********************************************************************
c***********************************************************************
c input arrays:
      integer ifirst0,ilast0,ifirst1,ilast1

      double precision    misorientation_factor
      integer ngvar, ngdiff, tghosts
c
c variables in 2d cell indexed
      double precision temperature(CELL2d(ifirst,ilast,tghosts))
      double precision var(CELL2d(ifirst,ilast,ngvar))
      double precision diff0(SIDE2d0(ifirst,ilast,ngdiff))
      double precision diff1(SIDE2d1(ifirst,ilast,ngdiff))
      character*(*) interp_type
      character*(*) avg_type
c
c***********************************************************************
c***********************************************************************     
c
      integer ic0,ic1
      double precision phi, t
      double precision interp_func
      double precision average_func
c
      do ic1=ifirst1,ilast1
         do ic0=ifirst0,ilast0+1
            phi = average_func(var(ic0-1,ic1),
     &                         var(ic0  ,ic1),
     &                         avg_type)
            t = 0.5d0 * (
     &         temperature(ic0-1,ic1) + temperature(ic0,ic1) )
            
            diff0(ic0,ic1) = misorientation_factor * t *
     &         interp_func( phi, interp_type )
         end do
      end do
c
      do ic1=ifirst1,ilast1+1
         do ic0=ifirst0,ilast0
            phi = average_func(var(ic0,ic1-1),
     &                         var(ic0,ic1  ),
     &                         avg_type)
            t = 0.5d0 * (
     &         temperature(ic0,ic1-1) + temperature(ic0,ic1) )

            diff1(ic0,ic1) = misorientation_factor * t *
     &         interp_func( phi, interp_type )
         end do
      end do
c
      return
      end

      subroutine quatdiffusionderiv(
     &  ifirst0,ilast0,ifirst1,ilast1,
     &  misorientation_factor,
     &  temperature, tghosts,
     &  var, ngvar,
     &  depth,
     &  gradq0, gradq1, nggradq,
     &  diff0, diff1, ngdiff,
     &  gradient_floor, smooth_floor_type,
     &  interp_type,
     &  avg_type )
c***********************************************************************
      implicit none
c***********************************************************************
c***********************************************************************
c input arrays:
      integer ifirst0,ilast0,ifirst1,ilast1

      double precision    misorientation_factor, gradient_floor
      integer ngvar, nggradq, ngdiff, depth, tghosts
c
c variables in 2d cell indexed
      double precision var(CELL2d(ifirst,ilast,ngvar))
      double precision temperature(CELL2d(ifirst,ilast,tghosts))
      double precision gradq0(SIDE2d0(ifirst,ilast,nggradq),depth,NDIM)
      double precision gradq1(SIDE2d1(ifirst,ilast,nggradq),depth,NDIM)
      double precision diff0(SIDE2d0(ifirst,ilast,ngdiff),depth*2)
      double precision diff1(SIDE2d1(ifirst,ilast,ngdiff),depth*2)

      character*(*) smooth_floor_type
      character*(*) interp_type
      character*(*) avg_type
c
c***********************************************************************
c***********************************************************************     
c
      integer ic0,ic1,m,n
      double precision phi, dphi, jlf_threshold, d_deriv,
     &     fac, norm_gradq,
     &     floor_grad_norm2, max_grad_normi,
     &     grad_norm2, grad_normi
      parameter( jlf_threshold=1.0d-16 )
      double precision deriv_interp_func
      double precision average_func
      double precision deriv_average_func
      double precision t 

      double precision eval_grad_normi

      floor_grad_norm2 = gradient_floor**2
c
      max_grad_normi = 1.d0 / gradient_floor
c
      do ic1=ifirst1,ilast1
         do ic0=ifirst0,ilast0+1
            if (var(ic0-1,ic1) .lt. jlf_threshold .or.
     &          var(ic0  ,ic1) .lt. jlf_threshold ) then
               do m = 1, depth
                  diff0(ic0,ic1,2*m-1) = 0.d0
                  diff0(ic0,ic1,2*m  ) = 0.d0
               enddo
            else
               phi = average_func(var(ic0-1,ic1),var(ic0  ,ic1),
     &                            avg_type)
               
               t = 0.5 * (
     &            temperature(ic0-1,ic1) + temperature(ic0,ic1) )

               d_deriv = misorientation_factor * t *
     &            deriv_interp_func( phi, interp_type )

               grad_norm2 = 0.d0
               do n = 1, NDIM
                  do m = 1, depth
                     grad_norm2 = grad_norm2 + gradq0(ic0,ic1,m,n)**2
                  enddo
               enddo

               grad_normi = eval_grad_normi(grad_norm2, 
     &                                   smooth_floor_type, 
     &                                   floor_grad_norm2, 
     &                                   max_grad_normi)
               
               do m = 1, depth

                  fac = grad_normi * d_deriv

                  dphi = deriv_average_func( phi, var(ic0-1,ic1),
     &                                       avg_type)
                  diff0(ic0,ic1,2*m-1) = fac * dphi

                  dphi = deriv_average_func( phi, var(ic0  ,ic1),
     &                                       avg_type)
                  diff0(ic0,ic1,2*m  ) = fac * dphi

               end do

            endif
         end do
      end do
c
      do ic1=ifirst1,ilast1+1
         do ic0=ifirst0,ilast0
            if (var(ic0,ic1-1) .lt. jlf_threshold .or.
     &          var(ic0,ic1  ) .lt. jlf_threshold ) then
               do m = 1, depth
                  diff1(ic0,ic1,2*m-1) = 0.d0
                  diff1(ic0,ic1,2*m  ) = 0.d0
               end do
            else

               phi = average_func(var(ic0,ic1-1),var(ic0  ,ic1),
     &                            avg_type)

               t = 0.5 * (
     &            temperature(ic0,ic1-1) + temperature(ic0,ic1) )

               d_deriv = misorientation_factor * t *
     &            deriv_interp_func( phi, interp_type )

               grad_norm2 = 0.d0
               do n = 1, NDIM
                  do m = 1, depth
                     grad_norm2 = grad_norm2 + gradq1(ic0,ic1,m,n)**2
                  enddo
               enddo

               grad_normi = eval_grad_normi(grad_norm2,
     &                                   smooth_floor_type, 
     &                                   floor_grad_norm2, 
     &                                   max_grad_normi)

               do m = 1, depth

                  fac = grad_normi * d_deriv

                  dphi = deriv_average_func( phi, var(ic0,ic1-1),
     &                                       avg_type)
                  diff1(ic0,ic1,2*m-1) = fac * dphi

                  dphi = deriv_average_func( phi, var(ic0  ,ic1),
     &                                       avg_type)
                  diff1(ic0,ic1,2*m  ) = fac * dphi

               end do

            endif

         end do
      end do
c
      return
      end
