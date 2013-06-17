function OscillatingBField

addpath('C:\QotoolboxV015')

% Laser Parameters

Omega1 = 0.01;
Delta1 = -1;
pol1 = 'x';
phi = 0;    % rotation angle around B-field
theta = pi/4; % angle perpendicular to B-field

Omega3 = 10;
Delta3 = 10;
pol3 = 'y';
phiIR = 0;    % rotation angle around B-field
thetaIR = 0;

%x = trap axis        (shuttle direction)
% y = cavity axis     (output to input mirror)
% z = vertical axis   B-field

Bx = 0;
By = 0;
Bz = 0.05;
DeltaB = 0.01; % Oscillation amplitude

NF = 5; % Number of different osc. frequency values

omega_list = logspace(-4,0,NF); % Frequencies 
tMax = 3*pi./omega_list; %Array of times for each freq.: 1.5 cycles

for i = 1:NF
    if tMax(i) < 20000;
        tMax(i) = 20000;
    end
end
t_step = 1;

GammaPump1 = 0;
GammaPump3 = 0;

N_max = length(0:t_step:tMax(1));
Fluorescence = zeros(NF,N_max);
FluorTrunc = zeros(NF, 1000);
%tTrunc = zeros(NF, 1000);
Frequencies = {};

for i=1:NF
    omega = omega_list(i);
    t_list = 0:t_step:tMax(i);
    tTrunc = t_list((end-999):end);
    N_t = length(t_list);
    [~, occupation_E2, ~] =  TimeDepCalcium( phi, theta, phiIR, thetaIR, Bx, By, Bz, DeltaB, Omega1, Omega3, Delta1, Delta3, ... 
                                                      pol1, pol3, GammaPump1, GammaPump3, omega, t_list);
     Fluorescence(i,1:N_t) = occupation_E2(1,:)+occupation_E2(2,:);
     FluorTrunc(i,:) = Fluorescence(i,(N_t-999):N_t);
     Frequencies = [Frequencies, num2str(omega_list(i))];
end,  

figure(2)
plot(0:t_step:tMax(1), Fluorescence)
legend(Frequencies)

figure(1)
plot(tTrunc, FluorTrunc)
legend(Frequencies)
%dlmwrite('Fluorescence.dat',Fluorescence, ';');