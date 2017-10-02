module global_variables

  use stel_kinds

  implicit none

  integer :: general_option=1

  integer :: ntheta_plasma=64, nzeta_plasma=64, nzetal_plasma
  integer :: ntheta_coil=64, nzeta_coil=64, nzetal_coil

  integer :: geometry_option_plasma = 0
  integer :: geometry_option_coil = 0

  real(dp) :: R0_plasma = 10.0, R0_coil = 10.0
  real(dp) :: a_plasma = 0.5, a_coil = 1.0
  real(dp) :: separation=0.2

  character(len=200) :: wout_filename=""
  character(len=200) :: shape_filename_plasma=""
  character(len=200) :: nescin_filename=""
  character(len=200) :: nescout_filename=""
  character(len=200) :: efit_filename=""
  character(len=200) :: outputFilename

  real(dp), dimension(:), allocatable :: theta_plasma, zeta_plasma, zetal_plasma
  real(dp), dimension(:,:,:), allocatable :: r_plasma, drdtheta_plasma, drdzeta_plasma, normal_plasma

  real(dp), dimension(:,:), allocatable :: g, f_x, f_y, f_z
  real(dp), dimension(:), allocatable :: h, d_x, d_y, d_z

  real(dp), dimension(:,:), allocatable :: Bnormal_from_plasma_current
  real(dp), dimension(:,:), allocatable :: Bnormal_from_net_coil_currents
  real(dp), dimension(:,:), allocatable :: matrix_B, matrix_K, inductance
  real(dp), dimension(:,:), allocatable :: single_valued_current_potential_mn
  real(dp), dimension(:,:,:), allocatable :: single_valued_current_potential_thetazeta
  real(dp), dimension(:,:,:), allocatable :: current_potential
  real(dp), dimension(:), allocatable :: RHS_B, RHS_K
  real(dp), dimension(:,:,:), allocatable :: Bnormal_total
  real(dp), dimension(:,:,:), allocatable :: K2
  real(dp), dimension(:), allocatable :: chi2_B, chi2_K, max_Bnormal, max_K

  real(dp), dimension(:), allocatable :: theta_coil, zeta_coil, zetal_coil
  real(dp), dimension(:,:,:), allocatable :: r_coil, drdtheta_coil, drdzeta_coil, normal_coil

  real(dp), dimension(:,:), allocatable :: norm_normal_plasma, norm_normal_coil
  real(dp), dimension(:,:), allocatable :: basis_functions

  real(dp) :: dtheta_plasma, dzeta_plasma, dtheta_coil, dzeta_coil

  integer :: mpol_coil=12
  integer :: ntor_coil=12
  integer :: mnmax_coil
  integer :: num_basis_functions
  integer, dimension(:), allocatable :: xm_coil, xn_coil

  real(dp), dimension(:), allocatable :: rmns, zmnc, rmnc, zmns
  integer :: mnmax, nfp
  integer, dimension(:), allocatable :: xm, xn
  logical :: lasym

  integer :: save_level = 3
  integer :: nfp_imposed = 1

  integer :: symmetry_option = 1
  real(dp) :: totalTime

  integer :: efit_num_modes = 10
  real(dp) :: efit_psiN = 0.98

  real(dp) :: mpol_transform_refinement=5, ntor_transform_refinement=1
  real(dp) :: area_plasma, area_coil, volume_plasma, volume_coil

  real(dp) :: net_poloidal_current_Amperes = 1
  real(dp) :: net_toroidal_current_Amperes = 0
  logical :: load_bnorm = .false.
  character(len=200) :: bnorm_filename=""
  real(dp) :: curpol = 1  ! number which multiplies data in bnorm file.

  integer :: nlambda = 4
  real(dp) :: lambda_min = 1.0d-19, lambda_max = 1.0d-13
  real(dp), dimension(:), allocatable :: lambda

  integer :: target_option = 1
  real(dp) :: target_option_p = 4.0
  real(dp) :: current_density_target = 8.0d+6
  real(dp) :: lambda_search_tolerance = 1.0d-5
  integer :: exit_code = 0
  real(dp) :: chi2_B_target = 0

  ! Items related to L_p norm
  integer :: L_p_diagnostic_option = 1
  real(dp) :: L_p_diagnostic_min = 4.0
  real(dp) :: L_p_diagnostic_max = 16.0
  real(dp) :: L_p_diagnostic_dp
  integer :: L_p_diagnostic_np = 4
  real(dp), dimension(:,:), allocatable :: L_p_diagnostic, L_p_diagnostic_with_area, L_p_diagnostic_3
  real(dp), dimension(:,:), allocatable :: L_p_diagnostic_4, L_p_diagnostic_5, L_p_diagnostic_6
  real(dp), dimension(:), allocatable :: L_p_norm, L_p_norm_with_area, L_p_norm_option_3, L_p_norm_option_4
  real(dp), dimension(:), allocatable :: LSE_current_density, LSE_current_density_with_area
  integer, dimension(:), allocatable :: ps
  real(dp), dimension(:,:), allocatable :: dLSE_current_density_with_areadOmega, dLSE_current_density_with_areadPhi
  real(dp), dimension(:), allocatable :: rms_K
  integer :: fixed_norm_sensitivity_option = 1
  real(dp), dimension(:,:), allocatable :: dRMSKdomega
  real(dp), dimension(:), allocatable :: darea_coildomega
  real(dp), dimension(:,:), allocatable :: q_tilde, dlambdadomega

  ! Needed for sensitivity calculation
  integer :: normal_displacement_option = 0
  integer :: sensitivity_option = 1
  integer :: sensitivity_symmetry_option = 1
  integer :: nmax_sensitivity = 0
  integer :: mmax_sensitivity = 0
  integer :: mnmax_sensitivity
  integer :: nomega_coil
  real(dp) :: coil_plasma_dist_lse_p = 1.0d3
  real(dp), dimension(:,:), allocatable :: dchi2Kdphi, dchi2Bdphi
  integer, dimension(:), allocatable :: omega_coil
  integer, dimension(:), allocatable :: xm_sensitivity, xn_sensitivity
  real(dp), dimension(:,:,:), allocatable :: dddomega, dfxdomega, dfydomega, dfzdomega
  real(dp), dimension(:,:,:), allocatable :: dnorm_normaldomega, dgdomega, dinductancedomega
  real(dp), dimension(:,:,:), allocatable :: dnormxdomega, dnormydomega, dnormzdomega
  real(dp), dimension(:,:), allocatable :: dchi2domega, dchi2Kdomega, dchi2Bdomega, dchi2Kdomega_withoutadjoint
  real(dp), dimension(:,:,:,:), allocatable :: drdomega
  real(dp), dimension(:,:,:), allocatable :: domegadxdtheta, domegadxdzeta, domegadydtheta, domegadydzeta
  real(dp), dimension(:,:,:), allocatable :: domegadzdtheta, domegadzdzeta
  real(dp), dimension(:,:), allocatable :: dhdomega, dchi2dr_normal
  real(dp), dimension(:,:), allocatable :: domegadx, domegady, domegadz
  real(dp), dimension(:,:), allocatable :: q_K, q_B, dFdomega
  real(dp), dimension(:,:,:), allocatable :: dmatrix_Kdomega, dmatrix_Bdomega, dmatrixdomega
  real(dp), dimension(:,:), allocatable :: dRHS_Bdomega, dRHS_Kdomega, dRHSdomega
  integer :: save_nescin_option = 0
  integer :: save_nescin_mpol = 12, save_nescin_ntor = 12
  integer :: minLambda, maxLambda
  real(dp), dimension(:), allocatable :: dvolume_coildomega
  real(dp), dimension(:), allocatable :: dcoil_plasma_dist_mindomega, dcoil_plasma_dist_maxdomega
  real(dp) :: coil_plasma_dist_min, coil_plasma_dist_max
  real(dp) :: coil_plasma_dist_min_lse, coil_plasma_dist_max_lse

  ! Curvature-related things
  integer :: compute_curvature = 0
  real(dp), dimension(:,:,:), allocatable :: d2r_coildtheta2, d2r_coildthetadzeta, d2r_coildzeta2
  real(dp), dimension(:,:), allocatable :: principle_curvature_1, principle_curvature_2
  real(dp) :: max_curvature_1, max_curvature_2
  real(dp), dimension(:,:), allocatable :: mean_curvature, gaussian_curvature

end module global_variables

