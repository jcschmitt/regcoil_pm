subroutine init_sensitivity()

  use global_variables
  use stel_constants
  use init_Fourier_modes_mod
  use omp_lib

  implicit none

  integer :: iomega, iflag, minSymmetry, maxSymmetry, offset, whichSymmetry, tic, toc, countrate,indexl_coil

  real(dp) :: angle, angle2, sinangle, cosangle, sum_exp_min, sum_exp_max
  real(dp) :: sinangle2, cosangle2
  real(dp) :: dxdtheta, dxdzeta, dydtheta, dydzeta, dzdtheta, dzdzeta
  real(dp), dimension(:,:,:,:), allocatable :: dist, identity
  integer :: izeta_plasma, itheta_plasma, izeta_coil, itheta_coil
  integer :: index_coil, l_coil, izetal_coil, index_plasma
  real(dp), dimension(:,:,:,:,:), allocatable :: ddistdomega
  real(dp), dimension(:,:,:), allocatable :: dsum_exp_distdomega
  real(dp) :: coil_plasma_dist_min_term, coil_plasma_dist_max_term, sum_exp_dist_term

  ! For volume calculation
  real(dp) :: major_R_squared_half_grid, dzdtheta_coil_half_grid
  integer :: index_coil_first, index_coil_last
  real(dp), dimension(:), allocatable :: dR_squared_domega_half_grid
  real(dp), dimension(:,:,:), allocatable :: dmajor_R_squareddomega

  ! Initialize Fourier arrays - need to include m = 0, n = 0 mode
  call init_Fourier_modes_sensitivity(mmax_sensitivity, nmax_sensitivity, mnmax_sensitivity, nomega_coil, &
    xm_sensitivity, xn_sensitivity, omega_coil,sensitivity_symmetry_option)

  allocate(drdomega(3,ntheta_coil*nzeta_coil,nfp,nomega_coil),stat=iflag)
  if (iflag .ne. 0) stop 'Allocation error!'
  allocate(dnorm_normaldomega(nomega_coil,ntheta_coil,nzeta_coil),stat=iflag)
  if (iflag .ne. 0) stop 'Allocation error!'
  allocate(dddomega(3, nomega_coil,ntheta_coil*nzetal_coil),stat=iflag)
  if (iflag .ne. 0) stop 'Allocation error!'
  allocate(dnormxdomega(nomega_coil,ntheta_coil*nzeta_coil,nfp),stat=iflag)
  if (iflag .ne. 0) stop 'Allocation error!'
  allocate(dnormydomega(nomega_coil,ntheta_coil*nzeta_coil,nfp),stat=iflag)
  if (iflag .ne. 0) stop 'Allocation error!'
  allocate(dnormzdomega(nomega_coil,ntheta_coil*nzeta_coil,nfp),stat=iflag)
  if (iflag .ne. 0) stop 'Allocation error!'
  allocate(domegadxdtheta(nomega_coil,ntheta_coil,nzetal_coil),stat=iflag)
  if (iflag .ne. 0) stop 'Allocation error!'
  allocate(domegadxdzeta(nomega_coil,ntheta_coil,nzetal_coil),stat=iflag)
  if (iflag .ne. 0) stop 'Allocation error!'
  allocate(domegadydtheta(nomega_coil,ntheta_coil,nzetal_coil),stat=iflag)
  if (iflag .ne. 0) stop 'Allocation error!'
  allocate(domegadydzeta(nomega_coil,ntheta_coil,nzetal_coil),stat=iflag)
  if (iflag .ne. 0) stop 'Allocation error!'
  allocate(domegadzdtheta(nomega_coil,ntheta_coil,nzetal_coil),stat=iflag)
  if (iflag .ne. 0) stop 'Allocation error!'
  allocate(domegadzdzeta(nomega_coil,ntheta_coil,nzetal_coil),stat=iflag)
  if (iflag .ne. 0) stop 'Allocation error!'

  allocate(dist(ntheta_coil,nzeta_coil,ntheta_plasma,nzeta_plasma),stat=iflag)
  if (iflag .ne. 0) stop 'Allocation error!'
  allocate(dcoil_plasma_dist_mindomega(nomega_coil),stat=iflag)
  if (iflag .ne. 0) stop 'Allocation error!'
  allocate(dcoil_plasma_dist_maxdomega(nomega_coil),stat=iflag)
  if (iflag .ne. 0) stop 'Allocation error!'
  allocate(normal_dist(ntheta_coil,nzeta_coil),stat=iflag)
  if (iflag .ne. 0) stop 'Allocation error!'
  allocate(ddistdomega(ntheta_coil,nzeta_coil,ntheta_plasma,nzeta_plasma,nomega_coil),stat=iflag)
  if (iflag .ne. 0) stop 'Allocation error!'
  allocate(dsum_exp_distdomega(ntheta_coil,nzeta_coil,nomega_coil),stat=iflag)
  if (iflag .ne. 0) stop 'Allocation error!'

  call system_clock(tic,countrate)

  do izeta_coil = 1,nzeta_coil
    do itheta_coil = 1,ntheta_coil
      index_coil = (izeta_coil-1)*ntheta_coil + itheta_coil
      do l_coil = 0, (nfp-1)
        izetal_coil = izeta_coil + l_coil*nzeta_coil

        angle2 = zetal_coil(izetal_coil)
        sinangle2 = sin(angle2)
        cosangle2 = cos(angle2)

        do iomega = 1,nomega_coil
          ! Same convention for angle as used by nescin input file
          angle = xm_sensitivity(iomega)*theta_coil(itheta_coil) + nfp*xn_sensitivity(iomega)*zetal_coil(izetal_coil)
          sinangle = sin(angle)
          cosangle = cos(angle)

          ! omega = rmnc
          if (omega_coil(iomega) == 1) then
            domegadxdtheta(iomega,itheta_coil,izetal_coil) = -xm_sensitivity(iomega)*sinangle*cosangle2
            domegadxdzeta(iomega,itheta_coil,izetal_coil) = -nfp*xn_sensitivity(iomega)*sinangle*cosangle2 - cosangle*sinangle2
            domegadydtheta(iomega,itheta_coil,izetal_coil) = -xm_sensitivity(iomega)*sinangle*sinangle2
            domegadydzeta(iomega,itheta_coil,izetal_coil) = -nfp*xn_sensitivity(iomega)*sinangle*sinangle2 + cosangle*cosangle2
            domegadzdtheta(iomega,itheta_coil,izetal_coil) = 0
            domegadzdzeta(iomega,itheta_coil,izetal_coil) = 0
            drdomega(1,index_coil,l_coil+1,iomega) = cosangle*cosangle2
            drdomega(2,index_coil,l_coil+1,iomega) = cosangle*sinangle2
            drdomega(3,index_coil,l_coil+1,iomega) = 0
          endif
          ! omega = zmns
          if (omega_coil(iomega) == 2) then
            domegadxdtheta(iomega,itheta_coil,izetal_coil) = 0
            domegadxdzeta(iomega,itheta_coil,izetal_coil) = 0
            domegadydtheta(iomega,itheta_coil,izetal_coil) = 0
            domegadydzeta(iomega,itheta_coil,izetal_coil) = 0
            domegadzdtheta(iomega,itheta_coil,izetal_coil) = xm_sensitivity(iomega)*cosangle
            domegadzdzeta(iomega,itheta_coil,izetal_coil) = nfp*xn_sensitivity(iomega)*cosangle
            drdomega(1,index_coil,l_coil+1,iomega) = 0
            drdomega(2,index_coil,l_coil+1,iomega) = 0
            drdomega(3,index_coil,l_coil+1,iomega) = sinangle
          endif
          ! omega = rmns
          if (omega_coil(iomega) == 3) then
            domegadxdtheta(iomega,itheta_coil,izetal_coil) = xm_sensitivity(iomega)*cosangle*cosangle2
            domegadxdzeta(iomega,itheta_coil,izetal_coil) = nfp*xn_sensitivity(iomega)*cosangle*cosangle2 - sinangle*sinangle2
            domegadydtheta(iomega,itheta_coil,izetal_coil) = xm_sensitivity(iomega)*cosangle*sinangle2
            domegadydzeta(iomega,itheta_coil,izetal_coil) = nfp*xn_sensitivity(iomega)*cosangle*sinangle2 + sinangle*cosangle2
            domegadzdtheta(iomega,itheta_coil,izetal_coil) = 0
            domegadzdzeta(iomega,itheta_coil,izetal_coil) = 0
            drdomega(1,index_coil,l_coil+1,iomega) = sinangle*cosangle2
            drdomega(2,index_coil,l_coil+1,iomega) = sinangle*sinangle2
            drdomega(3,index_coil,l_coil+1,iomega) = 0
          endif
          ! omega = zmnc
          if (omega_coil(iomega) == 4) then
            domegadxdtheta(iomega,itheta_coil,izetal_coil) = 0
            domegadxdzeta(iomega,itheta_coil,izetal_coil) = 0
            domegadydtheta(iomega,itheta_coil,izetal_coil) = 0
            domegadydzeta(iomega,itheta_coil,izetal_coil) = 0
            domegadzdtheta(iomega,itheta_coil,izetal_coil) = -xm_sensitivity(iomega)*sinangle
            domegadzdzeta(iomega,itheta_coil,izetal_coil) = -nfp*xn_sensitivity(iomega)*sinangle
            drdomega(1,index_coil,l_coil+1,iomega) = 0
            drdomega(2,index_coil,l_coil+1,iomega) = 0
            drdomega(3,index_coil,l_coil+1,iomega) = cosangle
          endif
          dxdtheta = drdtheta_coil(1,itheta_coil,izetal_coil)
          dydtheta = drdtheta_coil(2,itheta_coil,izetal_coil)
          dzdtheta = drdtheta_coil(3,itheta_coil,izetal_coil)
          dxdzeta = drdzeta_coil(1,itheta_coil,izetal_coil)
          dydzeta = drdzeta_coil(2,itheta_coil,izetal_coil)
          dzdzeta = drdzeta_coil(3,itheta_coil,izetal_coil)
          dnormxdomega(iomega,index_coil,l_coil+1) = &
              domegadydzeta(iomega,itheta_coil,izetal_coil)*dzdtheta &
            + domegadzdtheta(iomega,itheta_coil,izetal_coil)*dydzeta &
            - domegadydtheta(iomega,itheta_coil,izetal_coil)*dzdzeta &
            - domegadzdzeta(iomega,itheta_coil,izetal_coil)*dydtheta
          dnormydomega(iomega,index_coil,l_coil+1) = &
              domegadzdzeta(iomega,itheta_coil,izetal_coil)*dxdtheta &
            + domegadxdtheta(iomega,itheta_coil,izetal_coil)*dzdzeta &
            - domegadzdtheta(iomega,itheta_coil,izetal_coil)*dxdzeta &
            - domegadxdzeta(iomega,itheta_coil,izetal_coil)*dzdtheta
          dnormzdomega(iomega,index_coil,l_coil+1) = &
              domegadxdzeta(iomega,itheta_coil,izetal_coil)*dydtheta &
            + domegadydtheta(iomega,itheta_coil,izetal_coil)*dxdzeta &
            - domegadxdtheta(iomega,itheta_coil,izetal_coil)*dydzeta &
            - domegadydzeta(iomega,itheta_coil,izetal_coil)*dxdtheta
        enddo
      enddo
    enddo
  enddo
  call system_clock(toc)
  print *,"Loop over coil geom in init_sensitivity:",real(toc-tic)/countrate," sec."

  call system_clock(tic,countrate)

  allocate(dR_squared_domega_half_grid(nomega_coil))
  if (iflag .ne. 0) stop 'Allocation error!'
  allocate(dvolume_coildomega(nomega_coil),stat=iflag)
  if (iflag .ne. 0) stop 'Allocation error!'
  dvolume_coildomega = 0

  do itheta_coil=1,ntheta_coil-1
    do izeta_coil=1,nzeta_coil
      index_coil = (izeta_coil-1)*ntheta_coil + itheta_coil
      do l_coil = 0, (nfp-1)
        izetal_coil = izeta_coil + l_coil*nzeta_coil

        major_R_squared_half_grid = &
           (r_coil(1,itheta_coil,izetal_coil)*r_coil(1,itheta_coil,izetal_coil) &
          + r_coil(2,itheta_coil,izetal_coil)*r_coil(2,itheta_coil,izetal_coil) &
          + r_coil(1,itheta_coil+1,izetal_coil)*r_coil(1,itheta_coil+1,izetal_coil) &
          + r_coil(2,itheta_coil+1,izetal_coil)*r_coil(2,itheta_coil+1,izetal_coil)) * (0.5d+0)

        dR_squared_domega_half_grid = &
          drdomega(1,index_coil,l_coil+1,:)*r_coil(1,itheta_coil,izetal_coil) &
          + drdomega(2,index_coil,l_coil+1,:)*r_coil(2,itheta_coil,izetal_coil) &
          + drdomega(1,index_coil+1,l_coil+1,:)*r_coil(1,itheta_coil+1,izetal_coil) &
          + drdomega(2,index_coil+1,l_coil+1,:)*r_coil(2,itheta_coil+1,izetal_coil)

        dvolume_coildomega = dvolume_coildomega &
          + dR_squared_domega_half_grid &
          * (r_coil(3,itheta_coil+1,izetal_coil) - r_coil(3,itheta_coil,izetal_coil)) &
          + major_R_squared_half_grid &
          * (drdomega(3,index_coil+1,l_coil+1,:) - drdomega(3,index_coil,l_coil+1,:))
      end do
    end do
  end do
  do izeta_coil=1,nzeta_coil
    index_coil_first = (izeta_coil-1)*ntheta_coil + 1
    index_coil_last = (izeta_coil-1)*ntheta_coil + ntheta_coil
    do l_coil = 0, (nfp-1)
      izetal_coil = izeta_coil + l_coil*nzeta_coil

      major_R_squared_half_grid = &
         (r_coil(1,ntheta_coil,izetal_coil)*r_coil(1,ntheta_coil,izetal_coil) &
        + r_coil(2,ntheta_coil,izetal_coil)*r_coil(2,ntheta_coil,izetal_coil) &
        + r_coil(1,1,izetal_coil)*r_coil(1,1,izetal_coil) &
        + r_coil(2,1,izetal_coil)*r_coil(2,1,izetal_coil)) * (0.5d+0)

      dR_squared_domega_half_grid = &
        drdomega(1,index_coil_first,l_coil+1,:)*r_coil(1,1,izetal_coil) &
        + drdomega(2,index_coil_first,l_coil+1,:)*r_coil(2,1,izetal_coil) &
        + drdomega(1,index_coil_last,l_coil+1,:)*r_coil(1,ntheta_coil,izetal_coil) &
        + drdomega(2,index_coil_last,l_coil+1,:)*r_coil(2,ntheta_coil,izetal_coil)

      dvolume_coildomega = dvolume_coildomega &
        + dR_squared_domega_half_grid &
        * (r_coil(3,1,izetal_coil) - r_coil(3,ntheta_coil,izetal_coil)) &
        + major_R_squared_half_grid &
        * (drdomega(3,index_coil_first,l_coil+1,:) - drdomega(3,index_coil_last,l_coil+1,:))
    end do
  end do
  dvolume_coildomega = dvolume_coildomega*(0.5d+0)*dzeta_coil
  call system_clock(toc)
  print *,"Coil volume computation:",real(toc-tic)/countrate," sec."
  deallocate(dR_squared_domega_half_grid)

!  coil_plasma_dist_min = minval(normal_dist)
!  coil_plasma_dist_max = maxval(normal_dist)
!
!  call system_clock(toc)
!  print *,"Coil-plasma distance loop 1:",real(toc-tic)/countrate," sec."
!
!  call system_clock(tic)
!
!  ! Compute LSE normal coil-plasma distance
!  sum_exp_dist = 0
!  dsum_exp_distdomega = 0
!  coil_plasma_dist_min_lse = 0
!  coil_plasma_dist_max_lse = 0
!  !$OMP PARALLEL
!  !$OMP MASTER
!  print *,"  Number of OpenMP threads:",omp_get_num_threads()
!  !$OMP END MASTER
!  !$OMP DO PRIVATE(izeta_coil,itheta_plasma,izeta_plasma,sum_exp_dist_term)
!  do itheta_coil = 1, ntheta_coil
!    do izeta_coil = 1, nzeta_coil
!      do itheta_plasma = 1, ntheta_plasma
!        do izeta_plasma = 1, nzeta_plasma
!          sum_exp_dist_term = exp(-coil_plasma_dist_lse_p*(dist(itheta_coil,izeta_coil,itheta_plasma,izeta_plasma)-normal_dist(itheta_coil,izeta_coil)))
!
!          if ((sum_exp_dist_term /= sum_exp_dist_term) .or. (abs(sum_exp_dist_term) > huge(sum_exp_dist_term))) then
!            sum_exp_dist_term = 0
!          end if
!          sum_exp_dist(itheta_coil,izeta_coil) = sum_exp_dist(itheta_coil,izeta_coil) &
!            + sum_exp_dist_term
!          dsum_exp_distdomega(itheta_coil,izeta_coil,:) = &
!            dsum_exp_distdomega(itheta_coil,izeta_coil,:) &
!            + ddistdomega(itheta_coil,izeta_coil,itheta_plasma,izeta_plasma,:) &
!            * sum_exp_dist_term
!        end do
!      end do
!      normal_dist_lse(itheta_coil,izeta_coil) = -(1/coil_plasma_dist_lse_p)*log(sum_exp_dist(itheta_coil,izeta_coil)) + normal_dist(itheta_coil,izeta_coil)
!      dnormal_distdomega(itheta_coil,izeta_coil,:) = &
!        dsum_exp_distdomega(itheta_coil,izeta_coil,:)/sum_exp_dist(itheta_coil,izeta_coil)
!    end do
!  end do
!  !$OMP END DO
!  !$OMP END PARALLEL
!
!  call system_clock(toc)
!  print *,"Loop 2:",real(toc-tic)/countrate," sec."
!  allocate(identity(ntheta_coil,nzeta_coil,ntheta_plasma,nzeta_plasma),stat=iflag)
!  identity = 1

  call system_clock(tic,countrate)

  ! Compute coil-plasma distance using log-sum-exp norm
  !$OMP PARALLEL
  !$OMP MASTER
  print *,"  Number of OpenMP threads:",omp_get_num_threads()
  !$OMP END MASTER
  !$OMP DO PRIVATE(index_coil,izeta_coil,itheta_plasma,izeta_plasma)
  do itheta_coil = 1, ntheta_coil
    do izeta_coil = 1, nzeta_coil
      index_coil = (izeta_coil-1)*ntheta_coil + itheta_coil
      do itheta_plasma = 1, ntheta_plasma
        do izeta_plasma = 1, nzeta_plasma
          dist(itheta_coil,izeta_coil,itheta_plasma,izeta_plasma) = &
            sqrt((r_coil(1,itheta_coil,izeta_coil)-r_plasma(1,itheta_plasma,izeta_plasma))**2 &
            + (r_coil(2,itheta_coil,izeta_coil)-r_plasma(2,itheta_plasma,izeta_plasma))**2 &
            + (r_coil(3,itheta_coil,izeta_coil)-r_plasma(3,itheta_plasma,izeta_plasma))**2)
          ddistdomega(itheta_coil,izeta_coil,itheta_plasma,izeta_plasma,:) = &
            dist(itheta_coil,izeta_coil,itheta_plasma,izeta_plasma)**(-1) &
            *((r_coil(1,itheta_coil,izeta_coil)-r_plasma(1,itheta_plasma,izeta_plasma))*drdomega(1,index_coil,1,:) &
            + (r_coil(2,itheta_coil,izeta_coil)-r_plasma(2,itheta_plasma,izeta_plasma))*drdomega(2,index_coil,1,:) &
            + (r_coil(3,itheta_coil,izeta_coil)-r_plasma(3,itheta_plasma,izeta_plasma))*drdomega(3,index_coil,1,:))
        end do
      end do
      normal_dist(itheta_coil,izeta_coil) = minval(dist(itheta_coil,izeta_coil,:,:))
    end do
  end do
  !$OMP END DO
  !$OMP END PARALLEL


  print *,"mean(normal_dist): ", sum(normal_dist)/(ntheta_coil*nzeta_coil)

  coil_plasma_dist_min = minval(dist)
  coil_plasma_dist_max = maxval(dist)

  sum_exp_min = 0
  sum_exp_max = 0
  dcoil_plasma_dist_maxdomega = 0
  dcoil_plasma_dist_mindomega = 0
  do itheta_coil = 1, ntheta_coil
    do izeta_coil = 1, nzeta_coil
      do itheta_plasma = 1, ntheta_plasma
        do izeta_plasma = 1, nzeta_plasma
          sum_exp_min = sum_exp_min + exp(-coil_plasma_dist_lse_p*(dist(itheta_coil,izeta_coil,itheta_plasma,izeta_plasma)-coil_plasma_dist_min))
          sum_exp_max = sum_exp_max + exp(coil_plasma_dist_lse_p*(dist(itheta_coil,izeta_coil,itheta_plasma,izeta_plasma)-coil_plasma_dist_max))

          do iomega = 1, nomega_coil
            dcoil_plasma_dist_mindomega(iomega) = dcoil_plasma_dist_mindomega(iomega) + ddistdomega(itheta_coil,izeta_coil,itheta_plasma,izeta_plasma,iomega)*exp(-coil_plasma_dist_lse_p*(dist(itheta_coil,izeta_coil,itheta_plasma,izeta_plasma)-coil_plasma_dist_min))
            dcoil_plasma_dist_maxdomega(iomega) = dcoil_plasma_dist_maxdomega(iomega) + ddistdomega(itheta_coil,izeta_coil,itheta_plasma,izeta_plasma,iomega)*exp(coil_plasma_dist_lse_p*(dist(itheta_coil,izeta_coil,itheta_plasma,izeta_plasma)-coil_plasma_dist_max))
          end do

        end do
      end do
    end do
  end do
  dcoil_plasma_dist_mindomega = dcoil_plasma_dist_mindomega/sum_exp_min
  dcoil_plasma_dist_maxdomega = dcoil_plasma_dist_maxdomega/sum_exp_max

  coil_plasma_dist_min_lse = -(1/coil_plasma_dist_lse_p)*log(sum_exp_min) + minval(dist)

  coil_plasma_dist_max_lse =  (1/coil_plasma_dist_lse_p)*log(sum_exp_max) + maxval(dist)



  print *,"Max coil-plamsa dist: ", coil_plasma_dist_max
  print *,"Max coil-plasma dist (LSE): ", coil_plasma_dist_max_lse
  print *,"Min coil-plasma dist: ", coil_plasma_dist_min
  print *,"Min coil-plasma dist (LSE): ", coil_plasma_dist_min_lse
  call system_clock(toc)
  print *,"Coil-plasma dist computation Loop 3:",real(toc-tic)/countrate," sec."

  call system_clock(tic)

!  call system_clock(tic)
!
!  coil_plasma_dist_min_lse = 0
!  coil_plasma_dist_max_lse = 0
!  dcoil_plasma_dist_mindomega = 0
!  dcoil_plasma_dist_maxdomega = 0
!  do itheta_coil =1,ntheta_coil
!    do izeta_coil = 1,nzeta_coil
!      coil_plasma_dist_min_term = exp(-coil_plasma_dist_lse_p*(normal_dist_lse(itheta_coil,izeta_coil)-minval(normal_dist_lse)))
!      if ((coil_plasma_dist_min_term /= coil_plasma_dist_min_term) .or. abs(coil_plasma_dist_min_term) > huge(coil_plasma_dist_min_term)) then
!        coil_plasma_dist_min_term = 0
!      end if
!      coil_plasma_dist_min_lse  = coil_plasma_dist_min_lse + coil_plasma_dist_min_term
!
!      coil_plasma_dist_max_term = exp(coil_plasma_dist_lse_p*(normal_dist_lse(itheta_coil,izeta_coil)-maxval(normal_dist_lse)))
!      if ((coil_plasma_dist_max_term /= coil_plasma_dist_max_term) .or. (abs(coil_plasma_dist_max_term) > huge(coil_plasma_dist_max_term))) then
!        coil_plasma_dist_max_term = 0
!      end if
!      coil_plasma_dist_max_lse = coil_plasma_dist_max_lse + coil_plasma_dist_max_term
!
!      dcoil_plasma_dist_mindomega = dcoil_plasma_dist_mindomega &
!        + dnormal_distdomega(itheta_coil,izeta_coil,:) &
!        * coil_plasma_dist_min_term
!
!      dcoil_plasma_dist_maxdomega = dcoil_plasma_dist_maxdomega &
!        + dnormal_distdomega(itheta_coil,izeta_coil,:) &
!        * coil_plasma_dist_max_term
!    end do
!  end do
!  sum_exp_min = coil_plasma_dist_min_lse
!  sum_exp_max = coil_plasma_dist_max_lse
!
!  coil_plasma_dist_min_lse = -(1/coil_plasma_dist_lse_p) &
!    *log(coil_plasma_dist_min_lse) + minval(normal_dist_lse)
!
!  coil_plasma_dist_max_lse = &
!    (1/coil_plasma_dist_lse_p)*log(coil_plasma_dist_max_lse) + maxval(normal_dist_lse)
!
!  dcoil_plasma_dist_mindomega = dcoil_plasma_dist_mindomega/sum_exp_min
!  dcoil_plasma_dist_maxdomega = dcoil_plasma_dist_maxdomega/sum_exp_max

  do izeta_coil = 1, nzeta_coil
    do itheta_coil = 1, ntheta_coil
      index_coil = (izeta_coil-1)*ntheta_coil + itheta_coil
        do l_coil = 0, (nfp-1)
          izetal_coil = izeta_coil + l_coil*nzeta_coil
          indexl_coil = (izetal_coil-1)*ntheta_coil + itheta_coil
          dnorm_normaldomega(:,itheta_coil,izeta_coil) = &
             (normal_coil(1, itheta_coil, izeta_coil)*dnormxdomega(:,index_coil,1) &
            + normal_coil(2, itheta_coil, izeta_coil)*dnormydomega(:,index_coil,1) &
            + normal_coil(3, itheta_coil, izeta_coil)*dnormzdomega(:,index_coil,1)) &
              /norm_normal_coil(itheta_coil,izeta_coil)
          dddomega(1, :, indexl_coil) = (net_poloidal_current_Amperes*domegadxdtheta(:,itheta_coil,izetal_coil) &
            - net_toroidal_current_Amperes*domegadxdzeta(:,itheta_coil,izetal_coil))/twopi
          dddomega(2, :, indexl_coil) = (net_poloidal_current_Amperes*domegadydtheta(:,itheta_coil,izetal_coil) &
            - net_toroidal_current_Amperes*domegadydzeta(:,itheta_coil,izetal_coil))/twopi
          dddomega(3, :, indexl_coil) = (net_poloidal_current_Amperes*domegadzdtheta(:,itheta_coil,izetal_coil) &
            - net_toroidal_current_Amperes*domegadzdzeta(:,itheta_coil,izetal_coil))/twopi
      enddo
    enddo
  enddo
  call system_clock(toc)
  print *,"d sensitivity loop: ",real(toc-tic)/countrate," sec."

  print *,"Init sensitivity complete."

end subroutine init_sensitivity





