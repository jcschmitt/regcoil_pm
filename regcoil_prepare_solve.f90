subroutine regcoil_prepare_solve()

  use regcoil_variables

  implicit none

  integer :: iflag

  if (allocated(matrix)) deallocate(matrix)
  allocate(matrix(system_size, system_size), stat=iflag)
  if (iflag .ne. 0) stop 'regcoil_prepare_solve Allocation error 1!'

  if (allocated(RHS)) deallocate(RHS)
  allocate(RHS(system_size), stat=iflag)
  if (iflag .ne. 0) stop 'regcoil_prepare_solve Allocation error 2!'

  if (allocated(solution)) deallocate(solution)
  allocate(solution(system_size), stat=iflag)
  if (iflag .ne. 0) stop 'regcoil_prepare_solve Allocation error 3!'

  if (allocated(LAPACK_WORK)) deallocate(LAPACK_WORK)
  allocate(LAPACK_WORK(1), stat=iflag)
  if (iflag .ne. 0) stop 'regcoil_prepare_solve Allocation error 4!'

  if (allocated(LAPACK_IPIV)) deallocate(LAPACK_IPIV)
  allocate(LAPACK_IPIV(num_basis_functions), stat=iflag)
  if (iflag .ne. 0) stop 'regcoil_prepare_solve Allocation error 5!'

  if (allocated(chi2_B)) deallocate(chi2_B)
  allocate(chi2_B(nlambda), stat=iflag)
  if (iflag .ne. 0) stop 'regcoil_prepare_solve Allocation error 6!'

  if (allocated(chi2_M)) deallocate(chi2_M)
  allocate(chi2_M(nlambda), stat=iflag)
  if (iflag .ne. 0) stop 'regcoil_prepare_solve Allocation error 7!'

  if (allocated(max_Bnormal)) deallocate(max_Bnormal)
  allocate(max_Bnormal(nlambda), stat=iflag)
  if (iflag .ne. 0) stop 'regcoil_prepare_solve Allocation error 8!'

  if (allocated(max_M)) deallocate(max_M)
  allocate(max_M(nlambda), stat=iflag)
  if (iflag .ne. 0) stop 'regcoil_prepare_solve Allocation error 9!'

  if (allocated(min_M)) deallocate(min_M)
  allocate(min_M(nlambda), stat=iflag)
  if (iflag .ne. 0) stop 'regcoil_prepare_solve Allocation error 9!'

  if (allocated(Bnormal_total)) deallocate(Bnormal_total)
  allocate(Bnormal_total(ntheta_plasma,nzeta_plasma,nlambda), stat=iflag)
  if (iflag .ne. 0) stop 'regcoil_prepare_solve Allocation error 14!'

  allocate(M_R_mn(   num_basis_functions,ns_magnetization,nlambda))
  allocate(M_zeta_mn(num_basis_functions,ns_magnetization,nlambda))
  allocate(M_Z_mn(   num_basis_functions,ns_magnetization,nlambda))

  allocate(M_R(   ntheta_coil, nzeta_coil, ns_magnetization, nlambda))
  allocate(M_zeta(ntheta_coil, nzeta_coil, ns_magnetization, nlambda))
  allocate(M_Z(   ntheta_coil, nzeta_coil, ns_magnetization, nlambda))
  allocate(abs_M( ntheta_coil, nzeta_coil, ns_magnetization, nlambda))

  ! Call LAPACK's DSYSV in query mode to determine the optimal size of the work array
  call DSYSV('U',system_size, 1, matrix, system_size, LAPACK_IPIV, RHS, system_size, LAPACK_WORK, -1, LAPACK_INFO)
  LAPACK_LWORK = int(LAPACK_WORK(1))
  if (verbose) print *,"Optimal LWORK:",LAPACK_LWORK
  deallocate(LAPACK_WORK)
  allocate(LAPACK_WORK(LAPACK_LWORK), stat=iflag)
  if (iflag .ne. 0) stop 'regcoil_prepare_solve LAPACK error!'

end subroutine regcoil_prepare_solve

    ! Here is the LAPACK documentation for solving a symmetric linear system:

!!$
!!$
!!$*> \brief <b> DSYSV computes the solution to system of linear equations A * X = B for SY matrices</b>
!!$*
!!$*  =========== DOCUMENTATION ===========
!!$*
!!$* Online html documentation available at 
!!$*            http://www.netlib.org/lapack/explore-html/ 
!!$*
!!$*> \htmlonly
!!$*> Download DSYSV + dependencies 
!!$*> <a href="http://www.netlib.org/cgi-bin/netlibfiles.tgz?format=tgz&filename=/lapack/lapack_routine/dsysv.f"> 
!!$*> [TGZ]</a> 
!!$*> <a href="http://www.netlib.org/cgi-bin/netlibfiles.zip?format=zip&filename=/lapack/lapack_routine/dsysv.f"> 
!!$*> [ZIP]</a> 
!!$*> <a href="http://www.netlib.org/cgi-bin/netlibfiles.txt?format=txt&filename=/lapack/lapack_routine/dsysv.f"> 
!!$*> [TXT]</a>
!!$*> \endhtmlonly 
!!$*
!!$*  Definition:
!!$*  ===========
!!$*
!!$*       SUBROUTINE DSYSV( UPLO, N, NRHS, A, LDA, IPIV, B, LDB, WORK,
!!$*                         LWORK, INFO )
!!$* 
!!$*       .. Scalar Arguments ..
!!$*       CHARACTER          UPLO
!!$*       INTEGER            INFO, LDA, LDB, LWORK, N, NRHS
!!$*       ..
!!$*       .. Array Arguments ..
!!$*       INTEGER            IPIV( * )
!!$*       DOUBLE PRECISION   A( LDA, * ), B( LDB, * ), WORK( * )
!!$*       ..
!!$*  
!!$*
!!$*> \par Purpose:
!!$*  =============
!!$*>
!!$*> \verbatim
!!$*>
!!$*> DSYSV computes the solution to a real system of linear equations
!!$*>    A * X = B,
!!$*> where A is an N-by-N symmetric matrix and X and B are N-by-NRHS
!!$*> matrices.
!!$*>
!!$*> The diagonal pivoting method is used to factor A as
!!$*>    A = U * D * U**T,  if UPLO = 'U', or
!!$*>    A = L * D * L**T,  if UPLO = 'L',
!!$*> where U (or L) is a product of permutation and unit upper (lower)
!!$*> triangular matrices, and D is symmetric and block diagonal with
!!$*> 1-by-1 and 2-by-2 diagonal blocks.  The factored form of A is then
!!$*> used to solve the system of equations A * X = B.
!!$*> \endverbatim
!!$*
!!$*  Arguments:
!!$*  ==========
!!$*
!!$*> \param[in] UPLO
!!$*> \verbatim
!!$*>          UPLO is CHARACTER*1
!!$*>          = 'U':  Upper triangle of A is stored;
!!$*>          = 'L':  Lower triangle of A is stored.
!!$*> \endverbatim
!!$*>
!!$*> \param[in] N
!!$*> \verbatim
!!$*>          N is INTEGER
!!$*>          The number of linear equations, i.e., the order of the
!!$*>          matrix A.  N >= 0.
!!$*> \endverbatim
!!$*>
!!$*> \param[in] NRHS
!!$*> \verbatim
!!$*>          NRHS is INTEGER
!!$*>          The number of right hand sides, i.e., the number of columns
!!$*>          of the matrix B.  NRHS >= 0.
!!$*> \endverbatim
!!$*>
!!$*> \param[in,out] A
!!$*> \verbatim
!!$*>          A is DOUBLE PRECISION array, dimension (LDA,N)
!!$*>          On entry, the symmetric matrix A.  If UPLO = 'U', the leading
!!$*>          N-by-N upper triangular part of A contains the upper
!!$*>          triangular part of the matrix A, and the strictly lower
!!$*>          triangular part of A is not referenced.  If UPLO = 'L', the
!!$*>          leading N-by-N lower triangular part of A contains the lower
!!$*>          triangular part of the matrix A, and the strictly upper
!!$*>          triangular part of A is not referenced.
!!$*>
!!$*>          On exit, if INFO = 0, the block diagonal matrix D and the
!!$*>          multipliers used to obtain the factor U or L from the
!!$*>          factorization A = U*D*U**T or A = L*D*L**T as computed by
!!$*>          DSYTRF.
!!$*> \endverbatim
!!$*>
!!$*> \param[in] LDA
!!$*> \verbatim
!!$*>          LDA is INTEGER
!!$*>          The leading dimension of the array A.  LDA >= max(1,N).
!!$*> \endverbatim
!!$*>
!!$*> \param[out] IPIV
!!$*> \verbatim
!!$*>          IPIV is INTEGER array, dimension (N)
!!$*>          Details of the interchanges and the block structure of D, as
!!$*>          determined by DSYTRF.  If IPIV(k) > 0, then rows and columns
!!$*>          k and IPIV(k) were interchanged, and D(k,k) is a 1-by-1
!!$*>          diagonal block.  If UPLO = 'U' and IPIV(k) = IPIV(k-1) < 0,
!!$*>          then rows and columns k-1 and -IPIV(k) were interchanged and
!!$*>          D(k-1:k,k-1:k) is a 2-by-2 diagonal block.  If UPLO = 'L' and
!!$*>          IPIV(k) = IPIV(k+1) < 0, then rows and columns k+1 and
!!$*>          -IPIV(k) were interchanged and D(k:k+1,k:k+1) is a 2-by-2
!!$*>          diagonal block.
!!$*> \endverbatim
!!$*>
!!$*> \param[in,out] B
!!$*> \verbatim
!!$*>          B is DOUBLE PRECISION array, dimension (LDB,NRHS)
!!$*>          On entry, the N-by-NRHS right hand side matrix B.
!!$*>          On exit, if INFO = 0, the N-by-NRHS solution matrix X.
!!$*> \endverbatim
!!$*>
!!$*> \param[in] LDB
!!$*> \verbatim
!!$*>          LDB is INTEGER
!!$*>          The leading dimension of the array B.  LDB >= max(1,N).
!!$*> \endverbatim
!!$*>
!!$*> \param[out] WORK
!!$*> \verbatim
!!$*>          WORK is DOUBLE PRECISION array, dimension (MAX(1,LWORK))
!!$*>          On exit, if INFO = 0, WORK(1) returns the optimal LWORK.
!!$*> \endverbatim
!!$*>
!!$*> \param[in] LWORK
!!$*> \verbatim
!!$*>          LWORK is INTEGER
!!$*>          The length of WORK.  LWORK >= 1, and for best performance
!!$*>          LWORK >= max(1,N*NB), where NB is the optimal blocksize for
!!$*>          DSYTRF.
!!$*>          for LWORK < N, TRS will be done with Level BLAS 2
!!$*>          for LWORK >= N, TRS will be done with Level BLAS 3
!!$*>
!!$*>          If LWORK = -1, then a workspace query is assumed; the routine
!!$*>          only calculates the optimal size of the WORK array, returns
!!$*>          this value as the first entry of the WORK array, and no error
!!$*>          message related to LWORK is issued by XERBLA.
!!$*> \endverbatim
!!$*>
!!$*> \param[out] INFO
!!$*> \verbatim
!!$*>          INFO is INTEGER
!!$*>          = 0: successful exit
!!$*>          < 0: if INFO = -i, the i-th argument had an illegal value
!!$*>          > 0: if INFO = i, D(i,i) is exactly zero.  The factorization
!!$*>               has been completed, but the block diagonal matrix D is
!!$*>               exactly singular, so the solution could not be computed.
!!$*> \endverbatim
