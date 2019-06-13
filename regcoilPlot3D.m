%regcoil_out_filename = 'examples/compareToMatlab1/regcoil_out.compareToMatlab1.nc';
%regcoil_out_filename = 'examples/NCSX_vv_randomResolution1_iterate_d/regcoil_out.NCSX_vv_randomResolution1_iterate_d.nc';
%regcoil_out_filename = '/Users/mattland/Box Sync/work19/regcoil_out.20190531-15_mgrid_lambda_1e-14.nc'; % Original figure I circulated
%regcoil_out_filename = '/Users/mattland/Box Sync/work19/regcoil_out.20190607-01-043-mgrid_lambda_1e-15.nc'; % Updated figure after implementing stellarator symmetry
%regcoil_out_filename = '/Users/mattland/Box Sync/work19/20190526-01-testing_regcoil_pm/20190526-01-044-vv_thetaZeta64_mpolNtor12_sMagnetization2_sIntegration2_d0.15/regcoil_out.NCSX.nc';
%regcoil_out_filename = '/Users/mattland/Box Sync/work19/20190709-01-regcoilPM_analytic_benchmark/20190709-01-024-coilAspect30_aOverB0.33_n3_ntheta96_nzeta4_nfp128_mpol24_sym/regcoil_out.benchmark.nc';
%regcoil_out_filename = '/Users/mattland/Box Sync/work19/regcoil_out.20190611-01-025_c09r00_withPorts_lambda1e-15_Picard_thetaZeta128_mpolNtor32_ns2_mgrid.nc';
%regcoil_out_filename = '/Users/mattland/Box Sync/work19/regcoil_out.20190611-01-027_c09r00_withPorts_lambda1e-15_Picard_thetaZeta128_mpolNtor32_ns2_mgrid_1T.nc';
regcoil_out_filename = '/Users/mattland/Box Sync/work19/regcoil_out.20190611-01-028_c09r00_noPorts_lambda1e-15_Picard_thetaZeta128_mpolNtor32_ns2_1T.nc';

ilambda = 8;

decimate = 2;

quantity_for_colormap = 'd';
%quantity_for_colormap = 'M';

nfp = ncread(regcoil_out_filename,'nfp');
sign_normal = double(ncread(regcoil_out_filename,'sign_normal'));
norm_normal_coil = ncread(regcoil_out_filename,'norm_normal_coil');
abs_M = ncread(regcoil_out_filename,'abs_M');
magnetization_vector = ncread(regcoil_out_filename,'magnetization_vector');
zetal_coil = ncread(regcoil_out_filename,'zetal_coil');
ns_magnetization = ncread(regcoil_out_filename,'ns_magnetization');
s_magnetization = ncread(regcoil_out_filename,'s_magnetization');
try
    normal_coil = ncread(regcoil_out_filename,'normal_coil');
catch
    error('Unable to read normal_coil from the output file. Probably save_level was set >1.')
end
r_plasma = ncread(regcoil_out_filename,'r_plasma');
r_coil = ncread(regcoil_out_filename,'r_coil');
nzetal_coil = ncread(regcoil_out_filename,'nzetal_coil');
ntheta_coil = ncread(regcoil_out_filename,'ntheta_coil');
d = ncread(regcoil_out_filename,'d');

norm_normal_coil = repmat(norm_normal_coil,[1,nfp]);
unit_normal_coil = normal_coil;
for j=1:3
    unit_normal_coil(j,:,:) = squeeze(unit_normal_coil(j,:,:)) ./ norm_normal_coil;
end
size(d)

r_coil_outer = r_coil;
for j = 1:3
    r_coil_outer(j,:,:) = squeeze(r_coil_outer(j,:,:)) + sign_normal * repmat(d(:,:,ilambda),[1,nfp]) .* squeeze(unit_normal_coil(j,:,:));
end

size(abs_M)

abs_M_inner = repmat(abs_M(:,:,  1,ilambda),[1,nfp]);
abs_M_outer = repmat(abs_M(:,:,end,ilambda),[1,nfp]);

figure(10)
clf

% Close plasma surface in theta and zeta:
r_plasma(:,end+1,:) = r_plasma(:,1,:);
r_plasma(:,:,end+1) = r_plasma(:,:,1);

surf(squeeze(r_plasma(1,:,:)), squeeze(r_plasma(2,:,:)), squeeze(r_plasma(3,:,:)),'facecolor','r','edgecolor','none')
hold on
light
daspect([1,1,1])
axis vis3d off
set(gca,'clipping','off')
rotate3d on
zoom(1.4)

big_d = repmat(d(:,:,ilambda),[1,nfp]);

%{
% Shift in theta to hide the seam
shift_amount = round(ntheta_coil * 0.25);
r_coil = circshift(r_coil,[0,shift_amount,0]);
r_coil_outer = circshift(r_coil_outer,[0,shift_amount,0]);
abs_M_inner = circshift(abs_M_inner,[shift_amount,0]);
abs_M_outer = circshift(abs_M_outer,[shift_amount,0]);
big_d = circshift(big_d,[shift_amount,0]);
% Need to shift M vector too!
%}

% Close surface in theta:
r_coil(:,end+1,:) = r_coil(:,1,:);
r_coil_outer(:,end+1,:) = r_coil_outer(:,1,:);
abs_M_inner(end+1,:) = abs_M_inner(1,:);
abs_M_outer(end+1,:) = abs_M_outer(1,:);

% Only show a sector of the magnetization region:
max_zeta_index = round(nzetal_coil/2);
r_coil = r_coil(:,:,1:max_zeta_index);
r_coil_outer = r_coil_outer(:,:,1:max_zeta_index);
unit_normal_coil = unit_normal_coil(:,:,1:max_zeta_index);
abs_M_inner = abs_M_inner(:,1:max_zeta_index);
abs_M_outer = abs_M_outer(:,1:max_zeta_index);
big_d = big_d(:,1:max_zeta_index);
bigger_d = [big_d; big_d(1,:)];

switch quantity_for_colormap
    case 'd'
        data = bigger_d;
    case 'M'
        data = abs_M_inner;
    otherwise
        error('Invalid quantity_for_colormap')
end
surf(squeeze(r_coil(1,:,:)), squeeze(r_coil(2,:,:)), squeeze(r_coil(3,:,:)),data,'edgecolor','none','facecolor','interp','facealpha',1)
switch quantity_for_colormap
    case 'd'
        data = bigger_d;
    case 'M'
        data = abs_M_outer;
    otherwise
        error('Invalid quantity_for_colormap')
end
surf(squeeze(r_coil_outer(1,:,:)), squeeze(r_coil_outer(2,:,:)), squeeze(r_coil_outer(3,:,:)),data,'edgecolor','none','facecolor','interp','facealpha',0.7)
lw=2;
plot3(squeeze(r_coil(1,:,1)), squeeze(r_coil(2,:,1)), squeeze(r_coil(3,:,1)),'g','linewidth',lw)
plot3(squeeze(r_coil(1,:,end)), squeeze(r_coil(2,:,end)), squeeze(r_coil(3,:,end)),'g','linewidth',lw)
plot3(squeeze(r_coil_outer(1,:,1)), squeeze(r_coil_outer(2,:,1)), squeeze(r_coil_outer(3,:,1)),'y','linewidth',lw)
plot3(squeeze(r_coil_outer(1,:,end)), squeeze(r_coil_outer(2,:,end)), squeeze(r_coil_outer(3,:,end)),'y','linewidth',lw)
colorbar
lighting gouraud

switch quantity_for_colormap
    case 'd'
        title_string = 'Color = thickness of magnetization layer [meters]. Black arrows show direction of magnetization.';
        set(gca,'clim',[0,max(max(big_d))])
    case 'M'
        title_string = 'Color = |M| [Amperes / meter]. Black arrows show direction of magnetization.';
    otherwise
        error('Invalid quantity_for_colormap')
end
annotation(gcf,'textbox',...
    [0.00703968938740293 0.954476479514416 0.989509059534081 0.0394537177541729],...
    'String',title_string,'linestyle','none','horizontalalignment','center','fontsize',16,...
    'FitBoxToText','off');
magnetization_vector = repmat(magnetization_vector(:,:,:,:,ilambda),[1,nfp,1,1]);
magnetization_vector = magnetization_vector(:,1:max_zeta_index,:,:);
MZ = magnetization_vector(:,:,:,3);
MX = MZ*0;
MY = MZ*0;
for izeta = 1:max_zeta_index
    coszeta = cos(zetal_coil(izeta));
    sinzeta = sin(zetal_coil(izeta));
    MX(:,izeta,:) = magnetization_vector(:,izeta,:,1) * coszeta + magnetization_vector(:,izeta,:,2) * (-sinzeta);
    MY(:,izeta,:) = magnetization_vector(:,izeta,:,1) * sinzeta + magnetization_vector(:,izeta,:,2) * coszeta;
end

X = MX * 0;
Y = MX * 0;
Z = MX * 0;
for js = 1:ns_magnetization
    X(:,:,js) = squeeze(r_coil(1,1:end-1,:)) + sign_normal * s_magnetization(js) * big_d .* squeeze(unit_normal_coil(1,:,:));
    Y(:,:,js) = squeeze(r_coil(2,1:end-1,:)) + sign_normal * s_magnetization(js) * big_d .* squeeze(unit_normal_coil(2,:,:));
    Z(:,:,js) = squeeze(r_coil(3,1:end-1,:)) + sign_normal * s_magnetization(js) * big_d .* squeeze(unit_normal_coil(3,:,:));
end
scale = 2;
quiver3(X(1:decimate:end,1:decimate:end,:),Y(1:decimate:end,1:decimate:end,:),Z(1:decimate:end,1:decimate:end,:), ...
    MX(1:decimate:end,1:decimate:end,:),MY(1:decimate:end,1:decimate:end,:),MZ(1:decimate:end,1:decimate:end,:),scale,'k')
