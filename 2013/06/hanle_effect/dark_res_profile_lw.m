% Function for single-ion dark resonance spectroscopy (with added laser
% linewidth contribution)
% N.Seymour-Smith 17/1/13                      
        
% full Zeeman level structure with arbitrary magnetic field included
% Polarization of incoming beams converted to frame of reference with
% z-axis in direction of B
% Omega1, Omega2, Delta1, GammaPump1 are in units of Gamma
% Omega1 and Omega2 are the Rabi frequencies of the two ions
% taulist is a list of delay times in units of 1/Gamma
% d_ions is the ion distance in �m
% alpha, beta are the angles of the laser with the trap axis and out of the horizontal plane
% theta_out is the angle of the laser beam and the direction of observation 
% with the trap axis 

% wfl 05-04-2003   

epsilon_0 = 8.85e-12;
c = 3E8;
hbar = 1.05457e-34;

% B-field (gauss)
Bx=0;
By=0;
Bz=1;

% laser direction
deg = pi/180;
alpha = 0*deg;   % angle with trap axis in horizontal plane
beta  = 0*deg;    % angle out of horizontal plane

% laser polarization  (x,y,sigma+ or sigma-) for coherent and incoherent pump
pol1 = 'x';
pol3 = 'y';

%P-state decay rate (MHz)
Gamma = 2*pi*22*1E6;

% laser linewidths (in units of Gamma)
gamma_1 = 1E6*2*pi/Gamma; %linewidth of cooling laser (ground to p state)
gamma_3 = 1E6*2*pi/Gamma; %linewidth of repumping laser (excited to p state)
gamma_rel = gamma_1 + gamma_3; %combined linewidth (gnd to exc)

% cooling laser power and spot size (SI)
P_1 = 1E-5;
waist_1 = 200E-6;

% cooling laser rabi frequency (units of Gamma)
lambda_1 = 397E-9;
w_1 = 2*pi*c/lambda_1;
I_1 = 2*P_1/(pi*waist_1^2);
Ef_1 = sqrt(2*I_1/(c*epsilon_0));
Omega1 = sqrt(3*pi*epsilon_0*hbar*c^3*Gamma/(w_1^3))*(Ef_1/hbar)/Gamma;
s_1 = 2*Omega1^2;

% repumper power and spot size (SI)
P_3 = 1E-5;
waist_3 = 200E-6;

% repumper rabi frequency (units of Gamma)
lambda_3 = 866E-9;
w_3 = 2*pi*c/lambda_3;
I_3 = 2*P_3/(pi*waist_3^2);
Ef_3 = sqrt(2*I_3/(c*epsilon_0));
Omega3 = sqrt(3*pi*epsilon_0*hbar*c^3*Gamma*(1/12)/(w_3^3))*(Ef_3/hbar)/Gamma;
s_3 = 144*2*Omega3^2;

% saturation parameters
% s_1 = 10;
% s_3 = 144;
% Omega1 = sqrt(s_1/2);
% Omega3 = sqrt(s_3/2)*(1/12);

% Omega1 = 1;
% Omega3 = 1;
%Delta1 = -1;
Delta3 = 0;


% incoherent pumping 
GammaPump1 = 0;
GammaPump3 = 0;

% Frequency spectrum
df = 0.01;        % Resolution
f = -2:df:2;   % Spectrum
N_loop = length(f); 
count = zeros(1,N_loop); %Fluorescence on cooling transition
pop_1 = zeros(1,N_loop); %Population of ground states S_1/2
pop_2 = zeros(1,N_loop); %Population of excited states P_1/2
pop_3 = zeros(1,N_loop); %Population of metastable state D_3/2

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Definitions of constants and operators (don't change)     % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
addpath('/home/nic/q_opt_toolbox')

name = 'PulsedPump';

%lambda = 0.397;     % wavelength in �m

% Calcium system:
Gamma1  = 1;
Gamma3  = 0.076;

J1 = 1/2;    %  ground state      S 1/2    1
N1 = 2*J1+1; %  number of zeeman sub-levels   
J2 = 1/2;    %  excited state     P 1/2    2
N2 = 2*J2+1;    
J3 = 3/2;    %  metastable state  D 3/2    3
N3 = 2*J3+1;    

M1 = -J1:J1; %  array of sub-levels
M2 = -J2:J2;
M3 = -J3:J3;

E1 =            (1:N1); %  numbered energy levels, split into arrays for 
E2 = N1       + (1:N2); %  each manifold
E3 = N1+N2    + (1:N3);

Nat = N1+N2+N3; % total energy levels
idat = identity(Nat); % Identity matrix, N = Nat dimensions

% Zeeman splittings for the three levels per Gauss
% function w = zeemanFS(J,S,L,B,Gamma_phys)

w1 = zeemanFS(1/2,1/2,0,1E-4,Gamma); 
w2 = zeemanFS(1/2,1/2,1,1E-4,Gamma); 
w3 = zeemanFS(3/2,1/2,2,1E-4,Gamma); 

% transition ( |1>  |2>)
A1m = sparse(Nat,Nat); % sigma-minus transition operator (not initialised)
A10 = sparse(Nat,Nat); % pi transition operator
A1p = sparse(Nat,Nat); % sigma-plus transition operator
[am,a0,ap] = murelj(J1,J2); % submatrices of Clebsch-Gordan coefficients
                            % for sigma-minus, pi and sigma-plus
A1m(E1,E2)=am; % Full lowering transition operators
A10(E1,E2)=a0;
A1p(E1,E2)=ap;

A1m = qo(A1m); % Convert to quantum optics toolbox `quantum object'
A10 = qo(A10);
A1p = qo(A1p);

% transition ( |3>  |2>)
A3m = sparse(Nat,Nat); 
A30 = sparse(Nat,Nat); 
A3p = sparse(Nat,Nat); 
[am,a0,ap] = murelj(J3,J2);
A3m(E3,E2)=am;
A30(E3,E2)=a0;
A3p(E3,E2)=ap;

A3m = qo(A3m);
A30 = qo(A30);
A3p = qo(A3p);

% single atom projection operators
% basis(n,index) gives the mth ket vector in n-dim space, with m = index
% E1, E2, E3 are vectors, representing the number of the levels in each
% manifold. Therefore "basis(Nat,E1)" returns a vector of the kets
% associated with those numbers/energy levels.

PE1 = basis(Nat,E1);
PE2 = basis(Nat,E2);
PE3 = basis(Nat,E3);

ProjE1=PE1*PE1'; % This gives us a vector of operators, each element
ProjE2=PE2*PE2'; % associated with a different sublevel
ProjE3=PE3*PE3';

% Zeeman splitting (per Gauss):
% "diag([ w1*M1 w2*M2 w3*M3 ])" is a diagonal matrix of the Zeeman
% splittings with respect to their associated energy levels
HB = qo(diag([ w1*M1 w2*M2 w3*M3 ]));

% Convert above to superoperator (for easier computation)
LB  = -1i*(spre(HB)  - spost(HB));

% New assignement of angles   
kx =  cos(alpha) * cos(beta);           % x = trap axis       (endcap-endcap)
ky = -sin(alpha) * cos(beta);           % y = cavity axis     (horizontal and perp. to above)
kz =               sin(beta);           % z = vertical axis   (up direction)

ke = [ kx ; ky ; kz ];
B  = [ Bx ; By ; Bz ];

if norm(B)==0, 
    B = [0.00001 0 0]'; 
end
    
% Calculate polarization in frame of reference with z-axis in B-direction
[A1Bp,A1B0,A1Bm] = RotAtomPol([A1p,A10,A1m],B,ke);
[A3Bp,A3B0,A3Bm] = RotAtomPol([A3p,A30,A3m],B,ke);

% Polarization in frame of laser (can be sigma+, sigma- or linear combination)

if pol1=='y',
    % y-polarization
    H1 = -1i*(A1Bp-A1Bm)/sqrt(2) ;  
    % incoherent pump in B-frame
    Pu1  = -1i * [  A1Bp, 0 * A1B0,  -A1Bm ] / sqrt(2);
elseif pol1=='x',
    % x-polarization
    H1 = (A1Bp+A1Bm)/sqrt(2) ;  
    Pu1  = [  A1Bp, 0 * A1B0,  -A1Bm ] / sqrt(2);
elseif pol1=='sigma+',
    % sigma+ polarization
    H1 = A1Bp;  
    Pu1  = [  A1Bp, 0 * A1B0,  0 * A1Bm ] ;
elseif pol1=='sigma-',
    % sigma- polarization
    H1 = A1Bm;  
    Pu1  = [  0 * A1Bp, 0 * A1B0,  A1Bm ] ;
else
    warndlg([pol1 ' is invalid polarization for laser 1'],'Solver warning'); 
    return
end


%disp('input polarization in atomic frame');
a1p = -H1(1,4)*sqrt(3/2);      %  A1p contribution
a1m = H1(2,3)*sqrt(3/2);      %  A1m contribution
a10 = -H1(1,3)*sqrt(3);       %  A10 contribution
if ~(a10==H1(2,4)*sqrt(3)), disp('error in polarization analysis'); end;       %  A10 contribution

if pol3=='y',
    % y-polarization
    H3 = -1i*(A3Bp-A3Bm)/sqrt(2) ;  
    % incoherent pump in B-frame
    Pu3  = -1i * [  A3Bp, 0 * A3B0,  -A3Bm ] / sqrt(2);
elseif pol3=='x',
    % x-polarization
    H3 = (A3Bp+A3Bm)/sqrt(2) ;  
    Pu3  = [  A3Bp, 0 * A3B0,  A3Bm ] / sqrt(2);
elseif pol3=='sigma+',
    % sigma+ polarization 
    H3 = A3Bp;  
    Pu3  = [   A3Bp, 0 * A3B0,  0 * A3Bm ];
elseif pol3=='sigma-',
    % sigma- polarization
    H3 = A3Bm;  
    Pu3  = [ 0* A3Bp, 0 * A3B0,  A3Bm];
else
    warndlg([pol3 ' is invalid polarization for laser 3'],'Solver warning'); 
    return;
end


H1d = H1';  H3d = H3';

L1  = -1i*(spre(H1)  - spost(H1));
L1d = -1i*(spre(H1d) - spost(H1d));
L3  = -1i*(spre(H3)  - spost(H3));
L3d = -1i*(spre(H3d) - spost(H3d));

% Loss terms (normal spontaneous decay)

C1   = [A1m,A10,A1p];   
C3   = [A3m,A30,A3p]; 

C1dC1 = C1'*C1;
C3dC3 = C3'*C3;

LC1 = spre(C1)*spost(C1')-0.5*spre(C1dC1)-0.5*spost(C1dC1);
LC3 = spre(C3)*spost(C3')-0.5*spre(C3dC3)-0.5*spost(C3dC3);

% incoherent Pump terms (in B-frame)

Pu3Pu3d = Pu3*Pu3';
LPu3 = spre(Pu3')*spost(Pu3)-0.5*spre(Pu3Pu3d)-0.5*spost(Pu3Pu3d);

Pu1Pu1d = Pu1*Pu1';
LPu1 = spre(Pu1')*spost(Pu1)-0.5*spre(Pu1Pu1d)-0.5*spost(Pu1Pu1d);

% Laser decoherence terms c.f. Pritchard thesis p43
% List of dephasing terms for transitions to one of the ground states:
Dgg = [0 0];
Dgp = -gamma_1*[1 1];
Dge = -gamma_rel*[1 1 1 1];

% Dephasing for transitions to one of the p states
Dpg = -gamma_1*[1 1];
Dpp = [0 0];
Dpe = -gamma_3*[1 1 1 1];

% Dephasing for transitions to one of the excited states (d1/2)
Deg = -gamma_rel*[1 1];
Dep = -gamma_3*[1 1];
Dee = [0 0 0 0];

% Array of dephasing terms for transitions to all ground states
DG_ = cat(2, Dgg, Dgp, Dge);
DG = cat(2, DG_, DG_);

% Dephasing terms for transition to all p states
DP_ = cat(2, Dpg, Dpp, Dpe);
DP = cat(2, DP_, DP_);

% Dephasing terms for transitions to all d states
DE_ = cat(2, Deg, Dep, Dee);
DE = cat(2, DE_, DE_, DE_, DE_);

% Specify the dimensions of the pre/post-multiplication operator ({8 8} is
% the dimension of the Hilbert space)
C = {{8 8} {8 8}};

% Create a matrix with the dephasing terms in the format used by the
% toolbox (see the manual), and convert to quantum object of the dimensions
% of a pre/post-multiplication superoperator
LD = qo(diag(cat(2, DG, DP, DE)'), C); 

% initial condition for densiy matrix
rho_atom=sparse(Nat,Nat);
rho_atom(1,1)=0.5; 
rho_atom(2,2)=0.5; %Equally populated S_1 states
rho_atom=qo(rho_atom);
rho0     = rho_atom; 

% % Atomic detuning terms 
% 
% H0 = Delta1 * sum(ProjE1) +  Delta3 * sum(ProjE3);
% L0  = -1i*(spre(H0)  - spost(H0));

% Build function series for Liouville operator
% (Deleted a term with E*L4 because neither were defined)
L =  norm(B) * LB + ...
     Omega1 * L1 + Omega1' * L1d + ...
     Omega3 * L3 + Omega3' * L3d + ...
     Gamma1  * sum(LC1)  + ...
     Gamma3  * sum(LC3)  + ...
     GammaPump3 * sum(LPu3) + ...
     GammaPump1 * sum(LPu1) + ...
     LD;
 
save 'liouville' L

for k = 1:N_loop
    Delta1 = f(k);
    H0 = Delta1 * sum(ProjE1) + Delta3 * sum(ProjE3);
    L0 = -1i*(spre(H0) - spost(H0));
    L_s = L + L0;
    % Solve the differential equation
    rhos=steady(qo(L_s));
    count(k) = Gamma*real(sum(expect(C1dC1, rhos)));
    pop_1(k) = real(sum(expect(ProjE1, rhos)));
    pop_2(k) = real(sum(expect(ProjE2, rhos)));
    pop_3(k) = real(sum(expect(ProjE3, rhos)));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Construct parameter string for plots
s1 = ['[B_x, B_y, B_z] = [', num2str(Bx),', ', num2str(By), ...
    ', ', num2str(Bz),'] gauss, '];

s2 = ['pol1 = ', pol1, ', pol3 = ', pol3',', '];

s3 = ['P_1 = ', num2str(P_1*1E6), ' uW, ',...
    '(\Omega_1 = ', num2str(Omega1,2), ' \Gamma, ',...
    's_1 = ', num2str(s_1,2), '), '...
    'P_3 = ', num2str(P_3*1E6), ' uW, ',...
    '(\Omega_3 = ', num2str(Omega3,2), ' \Gamma, '...
    's_3 = ', num2str(s_3,2),'), '];

s4 = ['\Delta_1 = (', num2str(f(1),2),'...', num2str(f(end),2), ...
    ') \Gamma, \Delta_3 = ',...
    num2str(Delta3), '\Gamma, \deltaFreq = ', num2str(df*Gamma*1E-6/(2*pi)), ...
    ' MHz, '];

s8 = ['Laser linewidths: \gamma_{1} = ', ...
    num2str(gamma_1*Gamma*1E-6/(2*pi), 2), ' MHz, \gamma_{3} = ', ...
    num2str(gamma_3*Gamma*1E-6/(2*pi), 2), ' MHz, \gamma_{rel} = ', ...
    num2str(gamma_rel*Gamma*1E-6/(2*pi), 2), ' MHz'];

figure
plot(f, count);
title({'Fluorescence spectrum: ', [s1,s2], s3, s4, s8,''});
xlabel('\Delta_1 /\Gamma')
ylabel('\gamma /Hz')
figure
plot(f, pop_1, f, pop_2, f, pop_3);
title({'Population of atomic states: ', [s1, s2], s3, s4, s8,''});
legend('S_{1/2}', 'P_{1/2}', 'D_{3/2}');
xlabel('\Delta_1 /\Gamma')
ylabel('\rho_{nn}')



  

    
    
 
     
    
    

