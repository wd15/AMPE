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
define(NDIM,3)dnl
include(SAMRAI_FORTDIR/pdat_m4arrdim3d.i)dnl

      subroutine compute_face_coef3d(
     &     lo0, hi0, lo1, hi1, lo2, hi2,
     &     depth,
     &     eps_q,
     &     dx, dxlo0, dxhi0, dxlo1, dxhi1, dxlo2, dxhi2,
     &     dy, dylo0, dyhi0, dylo1, dyhi1, dylo2, dyhi2,
     &     dz, dzlo0, dzhi0, dzlo1, dzhi1, dzlo2, dzhi2,
     &     gqx, gqxlo0, gqxhi0, gqxlo1, gqxhi1, gqxlo2, gqxhi2,
     &     gqy, gqylo0, gqyhi0, gqylo1, gqyhi1, gqylo2, gqyhi2,
     &     gqz, gqzlo0, gqzhi0, gqzlo1, gqzhi1, gqzlo2, gqzhi2,
     &     fcx, fcxlo0, fcxhi0, fcxlo1, fcxhi1, fcxlo2, fcxhi2,
     &     fcy, fcylo0, fcyhi0, fcylo1, fcyhi1, fcylo2, fcyhi2,
     &     fcz, fczlo0, fczhi0, fczlo1, fczhi1, fczlo2, fczhi2,
     &     gradient_floor, floor_type
     &     )
c
      implicit none
      integer lo0, hi0, lo1, hi1, lo2, hi2,
     &        depth,
     &        gqxlo0, gqxhi0, gqxlo1, gqxhi1, gqxlo2, gqxhi2,
     &        gqylo0, gqyhi0, gqylo1, gqyhi1, gqylo2, gqyhi2,
     &        gqzlo0, gqzhi0, gqzlo1, gqzhi1, gqzlo2, gqzhi2,
     &        dxlo0, dxhi0, dxlo1, dxhi1, dxlo2, dxhi2,
     &        dylo0, dyhi0, dylo1, dyhi1, dylo2, dyhi2,
     &        dzlo0, dzhi0, dzlo1, dzhi1, dzlo2, dzhi2,
     &        fcxlo0, fcxhi0, fcxlo1, fcxhi1, fcxlo2, fcxhi2,
     &        fcylo0, fcyhi0, fcylo1, fcyhi1, fcylo2, fcyhi2,
     &        fczlo0, fczhi0, fczlo1, fczhi1, fczlo2, fczhi2
      character*(*)        floor_type
      double precision
     &           gqx(gqxlo0:gqxhi0,gqxlo1:gqxhi1,gqxlo2:gqxhi2,depth,NDIM),
     &           gqy(gqylo0:gqyhi0,gqylo1:gqyhi1,gqylo2:gqyhi2,depth,NDIM),
     &           gqz(gqzlo0:gqzhi0,gqzlo1:gqzhi1,gqzlo2:gqzhi2,depth,NDIM),
     &           dx(dxlo0:dxhi0,dxlo1:dxhi1,dxlo2:dxhi2),
     &           dy(dylo0:dyhi0,dylo1:dyhi1,dylo2:dyhi2),
     &           dz(dzlo0:dzhi0,dzlo1:dzhi1,dzlo2:dzhi2),
     &           fcx(fcxlo0:fcxhi0,fcxlo1:fcxhi1,fcxlo2:fcxhi2,depth),
     &           fcy(fcylo0:fcyhi0,fcylo1:fcyhi1,fcylo2:fcyhi2,depth),
     &           fcz(fczlo0:fczhi0,fczlo1:fczhi1,fczlo2:fczhi2,depth),
     &           gradient_floor, eps_q

      double precision eval_grad_normi

c     local variables:
      integer i, j, k, m, n
      double precision grad_norm2, grad_normi,
     &     floor_grad_norm2,
     &     max_grad_normi, eps2, grad_norm

      floor_grad_norm2 = gradient_floor**2
      eps2 = eps_q*eps_q
      
      max_grad_normi = 1.d0 / gradient_floor

c     x faces

      do k = lo2, hi2
         do j = lo1, hi1
            do i = lo0, hi0+1

c              compute reciprocal of gradient L2 norm on this face
               grad_norm2 = 0.d0
               do n = 1, NDIM
                  do m = 1, depth
                     grad_norm2 = grad_norm2 + gqx(i,j,k,m,n)**2
                  enddo
               enddo
               grad_normi = eval_grad_normi(grad_norm2, floor_type, 
     &                                      floor_grad_norm2, 
     &                                      max_grad_normi)
               do m = 1, depth
                  fcx(i,j,k,m) = - grad_normi * dx(i,j,k) - eps2
c                  fcx(i,j,k,m) = - dx(i,j,k) * ( grad_normi + eps2 )
               enddo

            enddo
         enddo
      enddo

c     y faces

      do k = lo2, hi2
         do j = lo1, hi1+1
            do i = lo0, hi0

c              compute reciprocal of gradient L2 norm on this face
               grad_norm2 = 0.d0
               do n = 1, NDIM
                  do m = 1, depth
                     grad_norm2 = grad_norm2 + gqy(i,j,k,m,n)**2
                  enddo
               enddo
               grad_normi = eval_grad_normi(grad_norm2, floor_type, 
     &                                      floor_grad_norm2, 
     &                                      max_grad_normi)
               do m = 1, depth
                  fcy(i,j,k,m) = - grad_normi * dy(i,j,k) - eps2
c                  fcy(i,j,k,m) = - dy(i,j,k) * ( grad_normi + eps2 )
               enddo

            enddo
         enddo
      enddo

c     z faces

      do k = lo2, hi2+1
         do j = lo1, hi1
            do i = lo0, hi0

c              compute reciprocal of gradient L2 norm on this face
               grad_norm2 = 0.d0
               do n = 1, NDIM
                  do m = 1, depth
                     grad_norm2 = grad_norm2 + gqz(i,j,k,m,n)**2
                  enddo
               enddo
               grad_normi = eval_grad_normi(grad_norm2, floor_type, 
     &                                      floor_grad_norm2, 
     &                                      max_grad_normi)
               do m = 1, depth
                  fcz(i,j,k,m) = - grad_normi * dz(i,j,k) - eps2
c                  fcz(i,j,k,m) = - dz(i,j,k) * ( grad_normi + eps2 )
               enddo

            enddo
         enddo
      enddo

      return
      end

      subroutine compute_dquatdphi_face_coef3d(
     &     lo0, hi0, lo1, hi1, lo2, hi2,
     &     depth,
     &     dprimex, dpxlo0, dpxhi0, dpxlo1, dpxhi1, dpxlo2, dpxhi2,
     &     dprimey, dpylo0, dpyhi0, dpylo1, dpyhi1, dpylo2, dpyhi2,
     &     dprimez, dpzlo0, dpzhi0, dpzlo1, dpzhi1, dpzlo2, dpzhi2,
     &     phi, plo0, phi0, plo1, phi1, plo2, phi2,
     &     fcx, fcxlo0, fcxhi0, fcxlo1, fcxhi1, fcxlo2, fcxhi2,
     &     fcy, fcylo0, fcyhi0, fcylo1, fcyhi1, fcylo2, fcyhi2,
     &     fcz, fczlo0, fczhi0, fczlo1, fczhi1, fczlo2, fczhi2
     &     )
c
      implicit none
      integer lo0, hi0, lo1, hi1, lo2, hi2,
     &        depth,
     &        dpxlo0, dpxhi0, dpxlo1, dpxhi1, dpxlo2, dpxhi2,
     &        dpylo0, dpyhi0, dpylo1, dpyhi1, dpylo2, dpyhi2,
     &        dpzlo0, dpzhi0, dpzlo1, dpzhi1, dpzlo2, dpzhi2,
     &        plo0, phi0, plo1, phi1, plo2, phi2,
     &        fcxlo0, fcxhi0, fcxlo1, fcxhi1, fcxlo2, fcxhi2,
     &        fcylo0, fcyhi0, fcylo1, fcyhi1, fcylo2, fcyhi2,
     &        fczlo0, fczhi0, fczlo1, fczhi1, fczlo2, fczhi2
      double precision
     &     dprimex(dpxlo0:dpxhi0,dpxlo1:dpxhi1,dpxlo2:dpxhi2,depth*2),
     &     dprimey(dpylo0:dpyhi0,dpylo1:dpyhi1,dpylo2:dpyhi2,depth*2),
     &     dprimez(dpzlo0:dpzhi0,dpzlo1:dpzhi1,dpzlo2:dpzhi2,depth*2),
     &     phi(plo0:phi0,plo1:phi1,plo2:phi2),
     &     fcx(fcxlo0:fcxhi0,fcxlo1:fcxhi1,fcxlo2:fcxhi2,depth),
     &     fcy(fcylo0:fcyhi0,fcylo1:fcyhi1,fcylo2:fcyhi2,depth),
     &     fcz(fczlo0:fczhi0,fczlo1:fczhi1,fczlo2:fczhi2,depth)

c     local variables:
      integer i, j, k, m

c     x faces

      do m = 1, depth
         do k = lo2, hi2
            do j = lo1, hi1
               do i = lo0, hi0+1
                  fcx(i,j,k,m) = - dprimex(i,j,k,2*m-1) * phi(i-1,j,k)
     &                           - dprimex(i,j,k,2*m  ) * phi(i  ,j,k)
               enddo
            enddo
         enddo
      enddo

c     y faces

      do m = 1, depth
         do k = lo2, hi2
            do j = lo1, hi1+1
               do i = lo0, hi0
                  fcy(i,j,k,m) = - dprimey(i,j,k,2*m-1) * phi(i,j-1,k)
     &                           - dprimey(i,j,k,2*m  ) * phi(i,j  ,k)
               enddo
            enddo
         enddo
      enddo

c     z faces

      do m = 1, depth
         do k = lo2, hi2+1
            do j = lo1, hi1
               do i = lo0, hi0
                  fcz(i,j,k,m) = - dprimez(i,j,k,2*m-1) * phi(i,j,k-1)
     &                           - dprimez(i,j,k,2*m  ) * phi(i,j,k  )
               enddo
            enddo
         enddo
      enddo

      return
      end

      subroutine compute_flux3d(
     &     lo0, hi0, lo1, hi1, lo2, hi2,
     &     depth,
     &     fcx, fcxlo0, fcxhi0, fcxlo1, fcxhi1, fcxlo2, fcxhi2,
     &     fcy, fcylo0, fcyhi0, fcylo1, fcyhi1, fcylo2, fcyhi2,
     &     fcz, fczlo0, fczhi0, fczlo1, fczhi1, fczlo2, fczhi2,
     &     q, qlo0, qhi0, qlo1, qhi1, qlo2, qhi2,
     &     h,
     &     fx, fxlo0, fxhi0, fxlo1, fxhi1, fxlo2, fxhi2,
     &     fy, fylo0, fyhi0, fylo1, fyhi1, fylo2, fyhi2,
     &     fz, fzlo0, fzhi0, fzlo1, fzhi1, fzlo2, fzhi2
     &     )
c
      implicit none
      integer lo0, hi0, lo1, hi1, lo2, hi2,
     &        depth,
     &        fcxlo0, fcxhi0, fcxlo1, fcxhi1, fcxlo2, fcxhi2,
     &        fcylo0, fcyhi0, fcylo1, fcyhi1, fcylo2, fcyhi2,
     &        fczlo0, fczhi0, fczlo1, fczhi1, fczlo2, fczhi2,
     &        qlo0, qhi0, qlo1, qhi1, qlo2, qhi2,
     &        fxlo0, fxhi0, fxlo1, fxhi1, fxlo2, fxhi2,
     &        fylo0, fyhi0, fylo1, fyhi1, fylo2, fyhi2,
     &        fzlo0, fzhi0, fzlo1, fzhi1, fzlo2, fzhi2
      double precision 
     &     fcx(fcxlo0:fcxhi0,fcxlo1:fcxhi1,fcxlo2:fcxhi2,depth),
     &     fcy(fcylo0:fcyhi0,fcylo1:fcyhi1,fcylo2:fcyhi2,depth),
     &     fcz(fczlo0:fczhi0,fczlo1:fczhi1,fczlo2:fczhi2,depth),
     &     q(qlo0:qhi0,qlo1:qhi1,qlo2:qhi2,depth),
     &     h(NDIM),
     &     fx(fxlo0:fxhi0,fxlo1:fxhi1,fxlo2:fxhi2,depth),
     &     fy(fylo0:fyhi0,fylo1:fyhi1,fylo2:fyhi2,depth),
     &     fz(fzlo0:fzhi0,fzlo1:fzhi1,fzlo2:fzhi2,depth)

c     local variables:
      integer i, j, k, m
      double precision hinv

c     x faces

      hinv = 1.d0 / h(1)

      do m = 1, depth
         do k = lo2, hi2
            do j = lo1, hi1
               do i = lo0, hi0+1
                  fx(i,j,k,m) = fcx(i,j,k,m) * hinv
     &                 * (q(i,j,k,m) - q(i-1,j,k,m))
               enddo
            enddo
         enddo
      enddo

c     y faces

      hinv = 1.d0 / h(2)

      do m = 1, depth
         do k = lo2, hi2
            do j = lo1, hi1+1
               do i = lo0, hi0
                  fy(i,j,k,m) = fcy(i,j,k,m) * hinv
     &                 * (q(i,j,k,m) - q(i,j-1,k,m))
               enddo

            enddo
         enddo
      enddo

c     z faces

      hinv = 1.d0 / h(3)

      do m = 1, depth
         do k = lo2, hi2+1
            do j = lo1, hi1
               do i = lo0, hi0
                  fz(i,j,k,m) = fcz(i,j,k,m) * hinv
     &                 * (q(i,j,k,m) - q(i,j,k-1,m))
               enddo
            enddo
         enddo
      enddo
      
      return
      end

      subroutine compute_flux3d_from_gradq(
     &     lo0, hi0, lo1, hi1, lo2, hi2,
     &     depth,
     &     fcx, fcxlo0, fcxhi0, fcxlo1, fcxhi1, fcxlo2, fcxhi2,
     &     fcy, fcylo0, fcyhi0, fcylo1, fcyhi1, fcylo2, fcyhi2,
     &     fcz, fczlo0, fczhi0, fczlo1, fczhi1, fczlo2, fczhi2,
     &     grad_x_xside,
     &     grad_y_yside,
     &     grad_z_zside,
     &     fx, fxlo0, fxhi0, fxlo1, fxhi1, fxlo2, fxhi2,
     &     fy, fylo0, fyhi0, fylo1, fyhi1, fylo2, fyhi2,
     &     fz, fzlo0, fzhi0, fzlo1, fzhi1, fzlo2, fzhi2
     &     )
c
      implicit none
      integer lo0, hi0, lo1, hi1, lo2, hi2,
     &        depth,
     &        fcxlo0, fcxhi0, fcxlo1, fcxhi1, fcxlo2, fcxhi2,
     &        fcylo0, fcyhi0, fcylo1, fcyhi1, fcylo2, fcyhi2,
     &        fczlo0, fczhi0, fczlo1, fczhi1, fczlo2, fczhi2,
     &        qlo0, qhi0, qlo1, qhi1, qlo2, qhi2,
     &        fxlo0, fxhi0, fxlo1, fxhi1, fxlo2, fxhi2,
     &        fylo0, fyhi0, fylo1, fyhi1, fylo2, fyhi2,
     &        fzlo0, fzhi0, fzlo1, fzhi1, fzlo2, fzhi2
      double precision 
     &     fcx(fcxlo0:fcxhi0,fcxlo1:fcxhi1,fcxlo2:fcxhi2,depth),
     &     fcy(fcylo0:fcyhi0,fcylo1:fcyhi1,fcylo2:fcyhi2,depth),
     &     fcz(fczlo0:fczhi0,fczlo1:fczhi1,fczlo2:fczhi2,depth),
     &     fx(fxlo0:fxhi0,fxlo1:fxhi1,fxlo2:fxhi2,depth),
     &     fy(fylo0:fyhi0,fylo1:fyhi1,fylo2:fyhi2,depth),
     &     fz(fzlo0:fzhi0,fzlo1:fzhi1,fzlo2:fzhi2,depth)

      double precision grad_x_xside(SIDE3d0(lo,hi,0),depth)
      double precision grad_y_yside(SIDE3d1(lo,hi,0),depth)
      double precision grad_z_zside(SIDE3d1(lo,hi,0),depth)

c     local variables:
      integer i, j, k, m

c     x faces

      do m = 1, depth
         do k = lo2, hi2
            do j = lo1, hi1
               do i = lo0, hi0+1
                  fx(i,j,k,m) = fcx(i,j,k,m) * grad_x_xside(i,j,k,m)
               enddo
            enddo
         enddo
      enddo

c     y faces

      do m = 1, depth
         do k = lo2, hi2
            do j = lo1, hi1+1
               do i = lo0, hi0
                  fy(i,j,k,m) = fcy(i,j,k,m) * grad_y_yside(i,j,k,m)
               enddo

            enddo
         enddo
      enddo

c     z faces

      do m = 1, depth
         do k = lo2, hi2+1
            do j = lo1, hi1
               do i = lo0, hi0
                  fz(i,j,k,m) = fcz(i,j,k,m) * grad_z_zside(i,j,k,m)
               enddo
            enddo
         enddo
      enddo
      
      return
      end

      subroutine compute_sym_flux3d(
     &     lo0, hi0, lo1, hi1, lo2, hi2,
     &     depth,
     &     fcx, fcxlo0, fcxhi0, fcxlo1, fcxhi1, fcxlo2, fcxhi2,
     &     fcy, fcylo0, fcyhi0, fcylo1, fcyhi1, fcylo2, fcyhi2,
     &     fcz, fczlo0, fczhi0, fczlo1, fczhi1, fczlo2, fczhi2,
     &     sqrt_m, mlo0, mhi0, mlo1, mhi1, mlo2, mhi2,
     &     q, qlo0, qhi0, qlo1, qhi1, qlo2, qhi2,
     &     h,
     &     fx, fxlo0, fxhi0, fxlo1, fxhi1, fxlo2, fxhi2,
     &     fy, fylo0, fyhi0, fylo1, fyhi1, fylo2, fyhi2,
     &     fz, fzlo0, fzhi0, fzlo1, fzhi1, fzlo2, fzhi2
     &     )
c
      implicit none
      integer lo0, hi0, lo1, hi1, lo2, hi2,
     &        depth,
     &        fcxlo0, fcxhi0, fcxlo1, fcxhi1, fcxlo2, fcxhi2,
     &        fcylo0, fcyhi0, fcylo1, fcyhi1, fcylo2, fcyhi2,
     &        fczlo0, fczhi0, fczlo1, fczhi1, fczlo2, fczhi2,
     &        mlo0, mhi0, mlo1, mhi1, mlo2, mhi2,
     &        qlo0, qhi0, qlo1, qhi1, qlo2, qhi2,
     &        fxlo0, fxhi0, fxlo1, fxhi1, fxlo2, fxhi2,
     &        fylo0, fyhi0, fylo1, fyhi1, fylo2, fyhi2,
     &        fzlo0, fzhi0, fzlo1, fzhi1, fzlo2, fzhi2
      double precision 
     &     fcx(fcxlo0:fcxhi0,fcxlo1:fcxhi1,fcxlo2:fcxhi2,depth),
     &     fcy(fcylo0:fcyhi0,fcylo1:fcyhi1,fcylo2:fcyhi2,depth),
     &     fcz(fczlo0:fczhi0,fczlo1:fczhi1,fczlo2:fczhi2,depth),
     &     sqrt_m(mlo0:mhi0,mlo1:mhi1,mlo2:mhi2),
     &     q(qlo0:qhi0,qlo1:qhi1,qlo2:qhi2,depth),
     &     h(NDIM),
     &     fx(fxlo0:fxhi0,fxlo1:fxhi1,fxlo2:fxhi2,depth),
     &     fy(fylo0:fyhi0,fylo1:fyhi1,fylo2:fyhi2,depth),
     &     fz(fzlo0:fzhi0,fzlo1:fzhi1,fzlo2:fzhi2,depth)

c     local variables:
      integer i, j, k, m
      double precision hinv

c     x faces

      hinv = 1.d0 / h(1)

      do m = 1, depth
         do k = lo2, hi2
            do j = lo1, hi1
               do i = lo0, hi0+1
                  fx(i,j,k,m) = fcx(i,j,k,m) * hinv
     &                 * (sqrt_m(i  ,j,k)*q(i  ,j,k,m) 
     &                  - sqrt_m(i-1,j,k)*q(i-1,j,k,m))
               enddo
            enddo
         enddo
      enddo

c     y faces

      hinv = 1.d0 / h(2)

      do m = 1, depth
         do k = lo2, hi2
            do j = lo1, hi1+1
               do i = lo0, hi0
                  fy(i,j,k,m) = fcy(i,j,k,m) * hinv
     &                 * (sqrt_m(i,j  ,k)*q(i,j  ,k,m)
     &                  - sqrt_m(i,j-1,k)*q(i,j-1,k,m))
               enddo
            enddo
         enddo
      enddo

c     z faces

      hinv = 1.d0 / h(3)

      do m = 1, depth
         do k = lo2, hi2+1
            do j = lo1, hi1
               do i = lo0, hi0
                  fz(i,j,k,m) = fcz(i,j,k,m) * hinv
     &                 * (sqrt_m(i,j,k  )*q(i,j,k  ,m)
     &                  - sqrt_m(i,j,k-1)*q(i,j,k-1,m))
               enddo
            enddo
         enddo
      enddo
      
      return
      end

      subroutine compute_q_residual3d(
     &     lo0, hi0, lo1, hi1, lo2, hi2,
     &     depth,
     &     sqrt_m, mlo0, mhi0, mlo1, mhi1, mlo2, mhi2,
     &     fx, fxlo0, fxhi0, fxlo1, fxhi1, fxlo2, fxhi2,
     &     fy, fylo0, fyhi0, fylo1, fyhi1, fylo2, fyhi2,
     &     fz, fzlo0, fzhi0, fzlo1, fzhi1, fzlo2, fzhi2,
     &     q, qlo0, qhi0, qlo1, qhi1, qlo2, qhi2,
     &     h, gamma,
     &     rhs, rhlo0, rhhi0, rhlo1, rhhi1, rhlo2, rhhi2,
     &     residual, rlo0, rhi0, rlo1, rhi1, rlo2, rhi2
     &     )
c
      implicit none
      integer lo0, hi0, lo1, hi1, lo2, hi2,
     &        depth,
     &        mlo0, mhi0, mlo1, mhi1, mlo2, mhi2,
     &        fxlo0, fxhi0, fxlo1, fxhi1, fxlo2, fxhi2,
     &        fylo0, fyhi0, fylo1, fyhi1, fylo2, fyhi2,
     &        fzlo0, fzhi0, fzlo1, fzhi1, fzlo2, fzhi2,
     &        qlo0, qhi0, qlo1, qhi1, qlo2, qhi2,
     &        rhlo0, rhhi0, rhlo1, rhhi1, rhlo2, rhhi2,
     &        rlo0, rhi0, rlo1, rhi1, rlo2, rhi2
      double precision 
     &        sqrt_m(mlo0:mhi0,mlo1:mhi1,mlo2:mhi2),
     &        fx(fxlo0:fxhi0,fxlo1:fxhi1,fxlo2:fxhi2,depth),
     &        fy(fylo0:fyhi0,fylo1:fyhi1,fylo2:fyhi2,depth),
     &        fz(fzlo0:fzhi0,fzlo1:fzhi1,fzlo2:fzhi2,depth),
     &        q(qlo0:qhi0,qlo1:qhi1,qlo2:qhi2,depth),
     &        h(NDIM), gamma,
     &        rhs(rhlo0:rhhi0,rhlo1:rhhi1,rhlo2:rhhi2,depth),
     &        residual(rlo0:rhi0,rlo1:rhi1,rlo2:rhi2,depth)

c     local variables:
      integer i, j, k, m
      double precision dxinv, dyinv, dzinv,
     &                 right, left, up, down, back, front,
     &                 divergence

      dxinv = 1.d0 / h(1)
      dyinv = 1.d0 / h(2)
      dzinv = 1.d0 / h(3)

      do m = 1, depth
         do k = lo2, hi2
            do j = lo1, hi1
               do i = lo0, hi0

                  right = fx(i+1,j  ,k  ,m)
                  left  = fx(i  ,j  ,k  ,m)
                  up    = fy(i  ,j+1,k  ,m)
                  down  = fy(i  ,j  ,k  ,m)
                  back  = fz(i  ,j  ,k+1,m)
                  front = fz(i  ,j  ,k  ,m)

                  divergence = (right - left ) * dxinv
     &                       + (up    - down ) * dyinv 
     &                       + (back  - front) * dzinv

                  residual(i,j,k,m) = rhs(i,j,k,m) - q(i,j,k,m)
     &                 - gamma * sqrt_m(i,j,k) * divergence

               enddo
            enddo
         enddo
      enddo

      return
      end

      subroutine compute_q_residual3d_symm(
     &     lo0, hi0, lo1, hi1, lo2, hi2,
     &     depth,
     &     sqrt_m, mlo0, mhi0, mlo1, mhi1, mlo2, mhi2,
     &     fx, fxlo0, fxhi0, fxlo1, fxhi1, fxlo2, fxhi2,
     &     fy, fylo0, fyhi0, fylo1, fyhi1, fylo2, fyhi2,
     &     fz, fzlo0, fzhi0, fzlo1, fzhi1, fzlo2, fzhi2,
     &     q, qlo0, qhi0, qlo1, qhi1, qlo2, qhi2,
     &     h, gamma,
     &     rhs, rhlo0, rhhi0, rhlo1, rhhi1, rhlo2, rhhi2,
     &     residual, rlo0, rhi0, rlo1, rhi1, rlo2, rhi2,
     &     iqrot_x, iqrot_y, iqrot_z, ngiq
     &     )
c
      implicit none
      integer lo0, hi0, lo1, hi1, lo2, hi2,
     &        depth, ngiq,
     &        mlo0, mhi0, mlo1, mhi1, mlo2, mhi2,
     &        fxlo0, fxhi0, fxlo1, fxhi1, fxlo2, fxhi2,
     &        fylo0, fyhi0, fylo1, fyhi1, fylo2, fyhi2,
     &        fzlo0, fzhi0, fzlo1, fzhi1, fzlo2, fzhi2,
     &        qlo0, qhi0, qlo1, qhi1, qlo2, qhi2,
     &        rhlo0, rhhi0, rhlo1, rhhi1, rhlo2, rhhi2,
     &        rlo0, rhi0, rlo1, rhi1, rlo2, rhi2
      double precision 
     &        sqrt_m(mlo0:mhi0,mlo1:mhi1,mlo2:mhi2),
     &        fx(fxlo0:fxhi0,fxlo1:fxhi1,fxlo2:fxhi2,depth),
     &        fy(fylo0:fyhi0,fylo1:fyhi1,fylo2:fyhi2,depth),
     &        fz(fzlo0:fzhi0,fzlo1:fzhi1,fzlo2:fzhi2,depth),
     &        q(qlo0:qhi0,qlo1:qhi1,qlo2:qhi2,depth),
     &        h(NDIM), gamma,
     &        rhs(rhlo0:rhhi0,rhlo1:rhhi1,rhlo2:rhhi2,depth),
     &        residual(rlo0:rhi0,rlo1:rhi1,rlo2:rhi2,depth)
      integer iqrot_x(SIDE3d0(lo,hi,ngiq))
      integer iqrot_y(SIDE3d1(lo,hi,ngiq))
      integer iqrot_z(SIDE3d2(lo,hi,ngiq))

      print*,'compute_q_residual3d_symm not implemented'
      stop
      
      return
      end

      subroutine add_quat_op3d(
     &     lo0, hi0, lo1, hi1, lo2, hi2,
     &     depth,
     &     mobility, mlo0, mhi0, mlo1, mhi1, mlo2, mhi2,
     &     fx, fxlo0, fxhi0, fxlo1, fxhi1, fxlo2, fxhi2,
     &     fy, fylo0, fyhi0, fylo1, fyhi1, fylo2, fyhi2,
     &     fz, fzlo0, fzhi0, fzlo1, fzhi1, fzlo2, fzhi2,
     &     h,
     &     rhs, rhlo0, rhhi0, rhlo1, rhhi1, rhlo2, rhhi2
     &     )
c
      implicit none
      integer lo0, hi0, lo1, hi1, lo2, hi2,
     &        depth,
     &        mlo0, mhi0, mlo1, mhi1, mlo2, mhi2,
     &        fxlo0, fxhi0, fxlo1, fxhi1, fxlo2, fxhi2,
     &        fylo0, fyhi0, fylo1, fyhi1, fylo2, fyhi2,
     &        fzlo0, fzhi0, fzlo1, fzhi1, fzlo2, fzhi2,
     &        rhlo0, rhhi0, rhlo1, rhhi1, rhlo2, rhhi2
      double precision 
     &        mobility(mlo0:mhi0,mlo1:mhi1,mlo2:mhi2),
     &        fx(fxlo0:fxhi0,fxlo1:fxhi1,fxlo2:fxhi2,depth),
     &        fy(fylo0:fyhi0,fylo1:fyhi1,fylo2:fyhi2,depth),
     &        fz(fzlo0:fzhi0,fzlo1:fzhi1,fzlo2:fzhi2,depth),
     &        h(NDIM),
     &        rhs(rhlo0:rhhi0,rhlo1:rhhi1,rhlo2:rhhi2,depth)

c     local variables:
      integer i, j, k, m
      double precision dxinv, dyinv, dzinv,
     &                 right, left, up, down, back, front,
     &                 divergence

      dxinv = 1.d0 / h(1)
      dyinv = 1.d0 / h(2)
      dzinv = 1.d0 / h(3)

      do m = 1, depth
         do k = lo2, hi2
            do j = lo1, hi1
               do i = lo0, hi0

                  right = fx(i+1,j  ,k  ,m)
                  left  = fx(i  ,j  ,k  ,m)
                  up    = fy(i  ,j+1,k  ,m)
                  down  = fy(i  ,j  ,k  ,m)
                  back  = fz(i  ,j  ,k+1,m)
                  front = fz(i  ,j  ,k  ,m)

                  divergence = (right - left ) * dxinv
     &                       + (up    - down ) * dyinv 
     &                       + (back  - front) * dzinv

                  rhs(i,j,k,m) = rhs(i,j,k,m)
     &                 - mobility(i,j,k) * divergence
               enddo
            enddo
         enddo
      enddo

      return
      end

      subroutine add_quat_proj_op3d(
     &     lo0, hi0, lo1, hi1, lo2, hi2,
     &     depth,
     &     mobility, mlo0, mhi0, mlo1, mhi1, mlo2, mhi2,
     &     fx, fxlo0, fxhi0, fxlo1, fxhi1, fxlo2, fxhi2,
     &     fy, fylo0, fyhi0, fylo1, fyhi1, fylo2, fyhi2,
     &     fz, fzlo0, fzhi0, fzlo1, fzhi1, fzlo2, fzhi2,
     &     q, qlo0, qhi0, qlo1, qhi1, qlo2, qhi2,
     &     lambda, llo0, lhi0, llo1, lhi1, llo2, lhi2,
     &     h,
     &     rhs, rhlo0, rhhi0, rhlo1, rhhi1, rhlo2, rhhi2
     &     )
c
      implicit none
      integer lo0, hi0, lo1, hi1, lo2, hi2,
     &        depth,
     &        mlo0, mhi0, mlo1, mhi1, mlo2, mhi2,
     &        fxlo0, fxhi0, fxlo1, fxhi1, fxlo2, fxhi2,
     &        fylo0, fyhi0, fylo1, fyhi1, fylo2, fyhi2,
     &        fzlo0, fzhi0, fzlo1, fzhi1, fzlo2, fzhi2,
     &        qlo0, qhi0, qlo1, qhi1, qlo2, qhi2,
     &        llo0, lhi0, llo1, lhi1, llo2, lhi2,
     &        rhlo0, rhhi0, rhlo1, rhhi1, rhlo2, rhhi2
      double precision 
     &        mobility(mlo0:mhi0,mlo1:mhi1,mlo2:mhi2),
     &        fx(fxlo0:fxhi0,fxlo1:fxhi1,fxlo2:fxhi2,depth),
     &        fy(fylo0:fyhi0,fylo1:fyhi1,fylo2:fyhi2,depth),
     &        fz(fzlo0:fzhi0,fzlo1:fzhi1,fzlo2:fzhi2,depth),
     &        q(qlo0:qhi0,qlo1:qhi1,qlo2:qhi2,depth),
     &        lambda(llo0:lhi0,llo1:lhi1,llo2:lhi2),
     &        h(NDIM),
     &        rhs(rhlo0:rhhi0,rhlo1:rhhi1,rhlo2:rhhi2,depth)

c     local variables:
      integer i, j, k, m
      double precision dxinv, dyinv, dzinv,
     &                 right, left, up, down, back, front,
     &                 divergence

      dxinv = 1.d0 / h(1)
      dyinv = 1.d0 / h(2)
      dzinv = 1.d0 / h(3)

      do m = 1, depth
         do k = lo2, hi2
            do j = lo1, hi1
               do i = lo0, hi0

                  right = fx(i+1,j  ,k  ,m)
                  left  = fx(i  ,j  ,k  ,m)
                  up    = fy(i  ,j+1,k  ,m)
                  down  = fy(i  ,j  ,k  ,m)
                  back  = fz(i  ,j  ,k+1,m)
                  front = fz(i  ,j  ,k  ,m)

                  divergence = (right - left ) * dxinv
     &                       + (up    - down ) * dyinv 
     &                       + (back  - front) * dzinv

                  rhs(i,j,k,m) = rhs(i,j,k,m)
     &                 - mobility(i,j,k) * (divergence
     &                 + 2.d0 * q(i,j,k,m) * lambda(i,j,k))
               enddo
            enddo
         enddo
      enddo

      return
      end

      subroutine compute_lambda_flux3d(
     &     lo0, hi0, lo1, hi1, lo2, hi2,
     &     depth,
     &     fx, fxlo0, fxhi0, fxlo1, fxhi1, fxlo2, fxhi2,
     &     fy, fylo0, fyhi0, fylo1, fyhi1, fylo2, fyhi2,
     &     fz, fzlo0, fzhi0, fzlo1, fzhi1, fzlo2, fzhi2,
     &     q, qlo0, qhi0, qlo1, qhi1, qlo2, qhi2,
     &     h,
     &     lambda, llo0, lhi0, llo1, lhi1, llo2, lhi2
     &     )
c
      implicit none
      integer lo0, hi0, lo1, hi1, lo2, hi2,
     &        depth,
     &        fxlo0, fxhi0, fxlo1, fxhi1, fxlo2, fxhi2,
     &        fylo0, fyhi0, fylo1, fyhi1, fylo2, fyhi2,
     &        fzlo0, fzhi0, fzlo1, fzhi1, fzlo2, fzhi2,
     &        qlo0, qhi0, qlo1, qhi1, qlo2, qhi2,
     &        llo0, lhi0, llo1, lhi1, llo2, lhi2
      double precision 
     &     fx(fxlo0:fxhi0,fxlo1:fxhi1,fxlo2:fxhi2,depth),
     &     fy(fylo0:fyhi0,fylo1:fyhi1,fylo2:fyhi2,depth),
     &     fz(fzlo0:fzhi0,fzlo1:fzhi1,fzlo2:fzhi2,depth),
     &     q(qlo0:qhi0,qlo1:qhi1,qlo2:qhi2,depth),
     &     h(3),
     &     lambda(llo0:lhi0,llo1:lhi1,llo2:lhi2)

c     local variables:
      integer i, j, k, m
      double precision xfac, yfac, zfac, left, right, down, up,
     &       front, back, sumq2

      xfac = 0.5d0 / h(1)
      yfac = 0.5d0 / h(2)
      zfac = 0.5d0 / h(3)

      do k = lo2, hi2
         do j = lo1, hi1
            do i = lo0, hi0

               lambda(i,j,k) = 0.d0
               sumq2 = 0.d0
               do m = 1, depth

                  left   = fx(i,j,k,m)   
                  right  = fx(i+1,j,k,m)
                  down   = fy(i,j,k,m)
                  up     = fy(i,j+1,k,m)
                  front  = fz(i,j,k,m)
                  back   = fz(i,j,k+1,m)

                  lambda(i,j,k) = lambda(i,j,k) - q(i,j,k,m) *
     &                 ((right - left) * xfac + (up - down) * yfac
     &                + (back - front) * zfac)
                  sumq2 = sumq2 + q(i,j,k,m)**2
               enddo
               lambda(i,j,k) = lambda(i,j,k) / sumq2
            enddo
         enddo
      enddo

      return
      end

      subroutine fixflux3d(
     &     xflux, yflux, zflux, fluxgi, fluxgj, fluxgk, fluxnc,
     &     xdc, ydc, zdc, dcgi, dcgj, dcgk, dcnc,
     &     soln, solngi, solngj, solngk, solnnc,
     &     ifirst, ilast, jfirst, jlast, kfirst, klast, nc,
     &     location_index,
     &     ratio_to_coarser,
     &     blower, bupper,
     &     dx
     &     )
c
      implicit none
      integer
     &     ifirst, ilast, jfirst, jlast, kfirst, klast, nc,
     &     dcgi, dcgj, dcgk, dcnc, fluxgi, fluxgj, fluxgk, fluxnc,
     &     solngi, solngj, solngk, solnnc
      double precision
     &     xflux(ifirst-fluxgi:ilast+1+fluxgi,
     &     jfirst-fluxgj:jlast+fluxgj,
     &     kfirst-fluxgk:klast+fluxgk,fluxnc),
     &     yflux(ifirst-fluxgi:ilast+fluxgi,
     &     jfirst-fluxgj:jlast+1+fluxgj,
     &     kfirst-fluxgk:klast+fluxgk,fluxnc),
     &     zflux(ifirst-fluxgi:ilast+fluxgi,
     &     jfirst-fluxgj:jlast+fluxgj,
     &     kfirst-fluxgk:klast+1+fluxgk,fluxnc),
     &     xdc(ifirst-dcgi:ilast+1+dcgi,
     &     jfirst-dcgj:jlast+dcgj,
     &     kfirst-dcgk:klast+dcgk,dcnc),
     &     ydc(ifirst-dcgi:ilast+dcgi,
     &     jfirst-dcgj:jlast+1+dcgj,
     &     kfirst-dcgk:klast+dcgk,dcnc),
     &     zdc(ifirst-dcgi:ilast+dcgi,
     &     jfirst-dcgj:jlast+dcgj,
     &     kfirst-dcgk:klast+1+dcgk,dcnc),
     &     soln(ifirst-solngi:ilast+solngi,
     &     jfirst-solngj:jlast+solngj,
     &     kfirst-solngk:klast+solngk,solnnc),
     &     dx(0:2)
      integer location_index, ratio_to_coarser(0:2)
c     Lower and upper corners of boundary box
      integer blower(0:2), bupper(0:2)

c     local variables
      double precision h
      integer i, ibeg, iend, ibnd, igho,
     &        j, jbeg, jend, jbnd, jgho,
     &        k, kbeg, kend, kbnd, kgho, comp
c     Fine grid indices inside one coarse grid.
      integer ip, jp, kp
c     Fine grid indices for point diametrically opposite from (ip,jp).
      integer iq, jq, kq
c     Weights associated with longtitudinal and transverse
c     (with respect to boundary normal) gradients.
      double precision tranwt, longwt

      if ( location_index .eq. 0 ) then
c        min i face
         tranwt = 1.0/(1+ratio_to_coarser(0))
         longwt = 2*tranwt
         h = dx(0)
         i = bupper(0)+1
         ibnd = bupper(0)+1
         jbeg = max(blower(1),jfirst)
         jend = min(bupper(1),jlast)
         kbeg = max(blower(2),kfirst)
         kend = min(bupper(2),klast)
         do comp = 1, nc
            do k=kbeg,kend,ratio_to_coarser(2)
               do j=jbeg,jend,ratio_to_coarser(1)
                  do kp=0,ratio_to_coarser(2)-1
                     kq = ratio_to_coarser(2) - kp - 1
                     do jp=0,ratio_to_coarser(1)-1
                        jq = ratio_to_coarser(1) - jp - 1
                        xflux(ibnd,j+jp,k+kp,comp)
     &                       = longwt*xflux(ibnd,j+jp,k+kp,comp)
     &                       + tranwt*xdc(ibnd,j+jp,k+kp,comp)*( 
     &                       soln(i,j+jq,k+kq,comp) 
     &                     - soln(i,j+jp,k+kp,comp) )/h
                     enddo
                  enddo
               enddo
            enddo
         enddo
      elseif ( location_index .eq. 1 ) then
c        max i face
         tranwt = 1.0/(1+ratio_to_coarser(0))
         longwt = 2*tranwt
         h = dx(0)
         i = blower(0)-1
         ibnd = blower(0)
         jbeg = max(blower(1),jfirst)
         jend = min(bupper(1),jlast)
         kbeg = max(blower(2),kfirst)
         kend = min(bupper(2),klast)
         do comp = 1, nc
            do k=kbeg,kend,ratio_to_coarser(2)
               do j=jbeg,jend,ratio_to_coarser(1)
                  do kp=0,ratio_to_coarser(2)-1
                     kq = ratio_to_coarser(2) - kp - 1
                     do jp=0,ratio_to_coarser(1)-1
                        jq = ratio_to_coarser(1) - jp - 1
                        xflux(ibnd,j+jp,k+kp,comp)
     &                       = longwt*xflux(ibnd,j+jp,k+kp,comp)
     &                       - tranwt*xdc(ibnd,j+jp,k+kp,comp)*( 
     &                       soln(i,j+jq,k+kq,comp)
     &                     - soln(i,j+jp,k+kp,comp) )/h
                     enddo
                  enddo
               enddo
            enddo
         enddo
      elseif ( location_index .eq. 2 ) then
c        min j face
         tranwt = 1.0/(1+ratio_to_coarser(1))
         longwt = 2*tranwt
         h = dx(1)
         j = bupper(1)+1
         jbnd = bupper(1)+1
         ibeg = max(blower(0),ifirst)
         iend = min(bupper(0),ilast)
         kbeg = max(blower(2),kfirst)
         kend = min(bupper(2),klast)
         do comp = 1, nc
            do i=ibeg,iend,ratio_to_coarser(0)
               do k=kbeg,kend,ratio_to_coarser(2)
                  do ip=0,ratio_to_coarser(0)-1
                     iq = ratio_to_coarser(0) - ip - 1
                     do kp=0,ratio_to_coarser(2)-1
                        kq = ratio_to_coarser(2) - kp - 1
                        yflux(i+ip,jbnd,k+kp,comp)
     &                       = longwt*yflux(i+ip,jbnd,k+kp,comp)
     &                       + tranwt*ydc(i+ip,jbnd,k+kp,comp)*( 
     &                       soln(i+iq,j,k+kq,comp)
     &                     - soln(i+ip,j,k+kp,comp) )/h
                     enddo
                  enddo
               enddo
            enddo
         enddo
      elseif ( location_index .eq. 3 ) then
c        max j face
         tranwt = 1.0/(1+ratio_to_coarser(1))
         longwt = 2*tranwt
         h = dx(1)
         j = blower(1)-1
         jbnd = blower(1)
         ibeg = max(blower(0),ifirst)
         iend = min(bupper(0),ilast)
         kbeg = max(blower(2),kfirst)
         kend = min(bupper(2),klast)
         do comp = 1, nc
            do i=ibeg,iend,ratio_to_coarser(0)
               do k=kbeg,kend,ratio_to_coarser(2)
                  do ip=0,ratio_to_coarser(0)-1
                     iq = ratio_to_coarser(0) - ip - 1
                     do kp=0,ratio_to_coarser(2)-1
                        kq = ratio_to_coarser(2) - kp - 1
                        yflux(i+ip,jbnd,k+kp,comp)
     &                       = longwt*yflux(i+ip,jbnd,k+kp,comp)
     &                       - tranwt*ydc(i+ip,jbnd,k+kp,comp)*( 
     &                       soln(i+iq,j,k+kq,comp)
     &                     - soln(i+ip,j,k+kp,comp) )/h
                     enddo
                  enddo
               enddo
            enddo
         enddo
      elseif ( location_index .eq. 4 ) then
c        min k face
         tranwt = 1.0/(1+ratio_to_coarser(2))
         longwt = 2*tranwt
         h = dx(2)
         k = bupper(2)+1
         kbnd = bupper(2)+1
         ibeg = max(blower(0),ifirst)
         iend = min(bupper(0),ilast)
         jbeg = max(blower(1),jfirst)
         jend = min(bupper(1),jlast)
         do comp = 1, nc
            do i=ibeg,iend,ratio_to_coarser(0)
               do j=jbeg,jend,ratio_to_coarser(1)
                  do ip=0,ratio_to_coarser(0)-1
                     iq = ratio_to_coarser(0) - ip - 1
                     do jp=0,ratio_to_coarser(1)-1
                        jq = ratio_to_coarser(1) - jp - 1
                        zflux(i+ip,j+jp,kbnd,comp)
     &                       = longwt*zflux(i+ip,j+jp,kbnd,comp)
     &                       + tranwt*zdc(i+ip,j+jp,kbnd,comp)*( 
     &                       soln(i+iq,j+jq,k,comp)
     &                     - soln(i+ip,j+jp,k,comp) )/h
                     enddo
                  enddo
               enddo
            enddo
         enddo
      elseif ( location_index .eq. 5 ) then
c        max k face
         tranwt = 1.0/(1+ratio_to_coarser(2))
         longwt = 2*tranwt
         h = dx(2)
         k = blower(2)-1
         kbnd = blower(2)
         ibeg = max(blower(0),ifirst)
         iend = min(bupper(0),ilast)
         jbeg = max(blower(1),jfirst)
         jend = min(bupper(1),jlast)
         do comp = 1, nc
            do i=ibeg,iend,ratio_to_coarser(0)
               do j=jbeg,jend,ratio_to_coarser(1)
                  do ip=0,ratio_to_coarser(0)-1
                     iq = ratio_to_coarser(0) - ip - 1
                     do jp=0,ratio_to_coarser(1)-1
                        jq = ratio_to_coarser(1) - jp - 1
                        zflux(i+ip,j+jp,kbnd,comp)
     &                       = longwt*zflux(i+ip,j+jp,kbnd,comp)
     &                       - tranwt*zdc(i+ip,j+jp,kbnd,comp)*( 
     &                       soln(i+iq,j+jq,k,comp)
     &                     - soln(i+ip,j+jp,k,comp) )/h
                     enddo
                  enddo
               enddo
            enddo
         enddo
      endif

      return
      end

      subroutine project3d(
     &     lo0, hi0, lo1, hi1, lo2, hi2,
     &     depth,
     &     q, qlo0, qhi0, qlo1, qhi1, qlo2, qhi2,
     &     corr, clo0, chi0, clo1, chi1, clo2, chi2,
     &     err, elo0, ehi0, elo1, ehi1, elo2, ehi2
     &     )
c
      implicit none
      integer lo0, hi0, lo1, hi1, lo2, hi2,
     &        depth,
     &        qlo0, qhi0, qlo1, qhi1, qlo2, qhi2,
     &        clo0, chi0, clo1, chi1, clo2, chi2,
     &        elo0, ehi0, elo1, ehi1, elo2, ehi2
      double precision 
     &        q(qlo0:qhi0,qlo1:qhi1,qlo2:qhi2,depth),
     &        corr(clo0:chi0,clo1:chi1,clo2:chi2,depth),
     &        err(elo0:ehi0,elo1:ehi1,elo2:ehi2,depth)

c     local variables:
      double precision fac
      integer i, j, k, m

      do k = lo2, hi2
         do j = lo1, hi1
            do i = lo0, hi0

               fac = 0.d0
               do m = 1, depth
                  fac = fac + q(i,j,k,m)**2
               enddo
               fac = 1.d0 / dsqrt(fac)

c              Store the q projection in the correction array for now
               do m = 1, depth
                  corr(i,j,k,m) = q(i,j,k,m) * fac
               enddo

c              Compute the dot product of the error with the projected q
               fac = 0.d0
               do m = 1, depth
                  fac = fac + corr(i,j,k,m) * err(i,j,k,m)
               enddo

c              Subtract the error component in the q direction
               do m = 1, depth
                  err(i,j,k,m) = err(i,j,k,m) - corr(i,j,k,m) * fac
               enddo

c              Finalize the correction: q + corr is on the constraint
               do m = 1, depth
                  corr(i,j,k,m) = corr(i,j,k,m) - q(i,j,k,m)
               enddo

            enddo
         enddo
      enddo

      return
      end

      subroutine take_square_root3d(
     &     lo0, hi0, lo1, hi1, lo2, hi2,
     &     var, vlo0, vhi0, vlo1, vhi1, vlo2, vhi2
     &     )
c
      implicit none
      integer lo0, hi0, lo1, hi1, lo2, hi2,
     &        vlo0, vhi0, vlo1, vhi1, vlo2, vhi2
      double precision 
     &        var(vlo0:vhi0,vlo1:vhi1,vlo2:vhi2)

c     local variables:
      integer i, j, k

      do k = lo2, hi2
         do j = lo1, hi1
            do i = lo0, hi0
               var(i,j,k) = dsqrt(var(i,j,k))
            enddo
         enddo
      enddo

      return
      end

      subroutine multicomponent_multiply3d(
     &     lo0, hi0, lo1, hi1, lo2, hi2,
     &     factor, flo0, fhi0, flo1, fhi1, flo2, fhi2,
     &     var, vlo0, vhi0, vlo1, vhi1, vlo2, vhi2, vnc
     &     )
c
      implicit none
      integer
     &     lo0, hi0, lo1, hi1, lo2, hi2,
     &     flo0, fhi0, flo1, fhi1, flo2, fhi2,
     &     vlo0, vhi0, vlo1, vhi1, vlo2, vhi2, vnc
      double precision 
     &     factor(flo0:fhi0,flo1:fhi1,flo2:fhi2),
     &     var(vlo0:vhi0,vlo1:vhi1,vlo2:vhi2,vnc)

c     local variables:
      integer i, j, k, n

      do n = 1, vnc
         do k = lo2, hi2
            do j = lo1, hi1
               do i = lo0, hi0
                  var(i,j,k,n) = var(i,j,k,n) * factor(i,j,k)
               enddo
            enddo
         enddo
      enddo

      return
      end

      subroutine multicomponent_divide3d(
     &     lo0, hi0, lo1, hi1, lo2, hi2,
     &     factor, flo0, fhi0, flo1, fhi1, flo2, fhi2,
     &     var, vlo0, vhi0, vlo1, vhi1, vlo2, vhi2, vnc
     &     )
c
      implicit none
      integer
     &     lo0, hi0, lo1, hi1, lo2, hi2,
     &     flo0, fhi0, flo1, fhi1, flo2, fhi2,
     &     vlo0, vhi0, vlo1, vhi1, vlo2, vhi2, vnc
      double precision 
     &     factor(flo0:fhi0,flo1:fhi1,flo2:fhi2),
     &     var(vlo0:vhi0,vlo1:vhi1,vlo2:vhi2,vnc)

c     local variables:
      integer i, j, k, n

      do n = 1, vnc
         do k = lo2, hi2
            do j = lo1, hi1
               do i = lo0, hi0
                  var(i,j,k,n) = var(i,j,k,n) / factor(i,j,k)
               enddo
            enddo
         enddo
      enddo

      return
      end
