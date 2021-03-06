%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GIANMARCO PINTON
% WRITTEN: NOV 13, 2013
% LAST MODIFIED: MAR 2, 2017
% Launch Fullwave code, easy matlab wrapper
%%% Basic variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
c0 = 1540;         % speed of sound (m/s)
omega0 = 2*pi*1e6; % center radian frequency of transmitted wave
wY = 2e-2;         % width of simulation field (m)
wZ = 3e-2;         % depth of simulation field (m)
duration = 40e-6;  % duration of simulation (s)
p0 = 1e5; % pressure in Pa
%%% Advanced variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ppw = 15;          % number of points per spatial wavelength
cfl = 0.4;         % Courant-Friedrichs-Levi condition
phi_s = 10;        % Steering angle (degree)
%%% Grid size calculations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lambda = c0/omega0*2*pi;
nY = round(wY/lambda*ppw);  % number of lateral elements
nZ = round(wZ/lambda*ppw);  % number of depth elements
nT = round(duration*c0/lambda*ppw/cfl);
dY = c0/omega0*2*pi/ppw;
dZ = c0/omega0*2*pi/ppw;
dT = dY/c0*cfl;
%%% Generate field maps %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cmap = ones(nY,nZ)*1540;   % speed of sound map (m/s)
rhomap = ones(nY,nZ)*1000; % density map (kg/m^3)
Amap = ones(nY,nZ)*0.0;    % attenuation map (dB/MHz/cm)
boveramap = -2*ones(nY,nZ);    % nonlinearity map
cmap(round(nY/2)-1:round(nY/2)+1,round(nZ/1.3)-1:round(nZ/1.3)+1)=0.5*c0; % scatterer
% cmap(round(0.8e-2/dY)-1:round(0.8e-2/dY)+1,round(1.9e-2/dZ)-1:round(1.9e-2/dZ)+1)=0.5*c0; % scatterer @ (0.8, 1.9) cm
% cmap(:,round(nZ/1.3):end)=0.6*c0; % surface
imagesc(cmap'), axis equal, axis tight
%%% Generate input coordinates %%%%%%%%%%%%%%%%%%%%%%%%%%%
inmap = zeros(nY,nZ);
inmap(:,1) = ones(nY,1); inmap(:,2) = ones(nY,1); 
inmap(:,3) = ones(nY,1);
imagesc(inmap'), axis equal, axis tight
incoords = mapToCoords(inmap); % note zero indexing for compiled code
plot(incoords(:,1),incoords(:,2),'.')
%%% Generate initial conditions based on input coordinates %%%%%%
ncycles = 2; % number of cycles in pulse
dur = 2; % exponential drop-off of envelope
fcen=[round(nY/2) round(nZ/1.3)]; % center of focus
t = (0:nT-1)/nT*duration-ncycles/omega0*2*pi;
% icvec = exp(-(1.05*t*omega0/(ncycles*pi)).^(2*dur)).*sin(t*omega0)*p0;
% icmat=repmat(icvec,size(incoords,1)/3,1);
% icvec = exp(-(1.05*t*omega0/(ncycles*pi)).^(2*dur)).*sin((t-dY/c0)*omega0)*p0; % retarded time
% icmat=[icmat; repmat(icvec,size(incoords,1)/3,1)];
% icvec = exp(-(1.05*t*omega0/(ncycles*pi)).^(2*dur)).*sin((t-2*dY/c0)*omega0)*p0; % retarded time
% icmat=[icmat; repmat(icvec,size(incoords,1)/3,1)];

% steering
% steering_dly = (0:nY-1)*dY*sind(phi_s)/c0;
% steering_dly = repmat(steering_dly',1,nT);
% tmat = repmat(t,size(incoords,1)/3,1);
% tmatsteering = tmat + steering_dly;
% icmat = exp(-(1.05*tmat*omega0/(ncycles*pi)).^(2*dur)).*sin(tmatsteering*omega0)*p0;
% icmat=[icmat; exp(-(1.05*tmat*omega0/(ncycles*pi)).^(2*dur)).*sin((tmatsteering-dY/c0)*omega0)*p0];
% icmat=[icmat; exp(-(1.05*tmat*omega0/(ncycles*pi)).^(2*dur)).*sin((tmatsteering-2*dY/c0)*omega0)*p0];

% steering
steering_dly = (0:nY-1)*dY*sind(phi_s)/c0;
steering_dly = repmat(steering_dly',1,nT);
tmat = repmat(t,size(incoords,1)/3,1);
tmatsteering = tmat + steering_dly;
icmat = exp(-(1.05*tmatsteering*omega0/(ncycles*pi)).^(2*dur)).*sin(tmatsteering*omega0)*p0;
icmat=[icmat; exp(-(1.05*tmatsteering*omega0/(ncycles*pi)).^(2*dur)).*sin((tmatsteering-dY/c0)*omega0)*p0];
icmat=[icmat; exp(-(1.05*tmatsteering*omega0/(ncycles*pi)).^(2*dur)).*sin((tmatsteering-2*dY/c0)*omega0)*p0];

% steering and focusing
% icvec = exp(-(1.05*t*omega0/(ncycles*pi)).^(2*dur)).*sin(t*omega0)*p0;
% idy = round(0.005/dY);
% idz = round(0.0231/dZ);
% [icmat] = focusCoords (idy,idz,incoords,icvec,cfl);

% load time reversal
% load('icmat2.mat');
% icmat = icmat'; icmat = icmat(:,end:-1:1);
% icmat = icmat/max(icmat(:))*p0;
imagesc(icmat)
%%% Generate output coordinates %%%%%%%%%%%%%%%%%%%%%%%%%%
outmap = zeros(nY,nZ);
[modidy, modidz] = meshgrid(1:2:nY,1:2:nZ);
outmap(modidy,modidz) = 1;
imagesc(outmap'), axis equal, axis tight
outcoords = mapToCoords(outmap);
% outcoords = incoords(size(incoords,1)/3*2+1:end,:);
% outcoords = incoords; % for time reversal
%%% Launch %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
launchTotalFullWave2(c0,omega0,wY,wZ,duration,p0,ppw,cfl,cmap',rhomap',Amap',boveramap',incoords,outcoords,icmat);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
!./try6_nomex
toc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ncoordsout=size(outcoords,1)
% nRun=sizeOfFile('genout.dat')/4/ncoordsout
% genout = readGenoutSlice(['genout.dat'],0:nRun-1,size(outcoords,1));
% p = reshape(genout,size(genout,1),size(modidy,2),size(modidy,1));
% imagesc(squeeze(p(end,:,:))), colorbar
% 
% for i=1:2:size(p,1)
%   imagesc(squeeze(p(i,:,:))', [-1 1]*p0), title(num2str(i)), drawnow
% end
