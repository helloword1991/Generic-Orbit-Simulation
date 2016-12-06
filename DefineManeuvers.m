
METAKR = 'planetsorbitskernels.txt';

cspice_furnsh ( METAKR );
planets_name_for_struct = {'EARTH','SUN','MOON','JUPITER','VENUS','MARS','SATURN';'EARTH','SUN','301','5','VENUS','4','6'};
observer = 'EARTH';% or 339

global G;
G = 6.673e-20;
global L2frame;
L2frame = true;

initial_state = [5.795985038263178e+05; 7.776779586882917e+05;...
6.171179196351578e+05; -0.538364883921726; 0.286800406339146;0.125771126285189];
initial_et = 9.747626128418571e+08;

sat = create_sat_structure(initial_state);
% Get initial states for calculating initial energy
[earth_init, sun_init, moon_init, jupiter_init, venus_init, mars_init, saturn_init] = create_structure( planets_name_for_struct, initial_et, observer);

% Pos + velocites
%X0 = [5.795985038263178e+05; 7.776779586882917e+05;6.171179196351578e+05; -0.538364883921726; 0.286800406339146;0.125771126285189];

% Only velocities
 %V0 = [-0.58364883921726; 0.286800406339146;0.125771126285189];
 %V0 = [-5.399272545222726e-001;   2.861191946127703e-001;   1.254733378780861e-001];
% MY NEW VALUES
V0 = [-0.538669578263083; 0.286257511925448; 0.125184841442128];
% Initial values before maneuver
 %V0 = [5.343825699573794e-001;  -2.686719669693540e-001;  -1.145921728828306e-001];

 
 % my values [-0.58364883921726; 0.286800406339146;0.125771126285189];
% luisa [-5.399272545222726e-001;   2.861191946127703e-001;   1.254733378780861e-001];
% Add STM
%phi0 = [1;0;0;0;0;0;0;1;0;0;0;0;0;0;1;0;0;0;0;0;0;1;0;0;0;0;0;0;1;0;0;0;0;0;0;1];
%phi0 = eye(6);
%phi0 = reshape(phi, 36,1);
%X0 = [X0; phi0];

% Trying the orbit form the beginning
%V0 = [5.343825699573794e-001;  -2.686719669693540e-001;  -1.145921728828306e-001];


%V0 = [0;0;0];
    
%options=optimoptions(@fsolve, 'Display', 'iter-detailed', 'Jacobian', 'on', 'TolFun', 1e-9);

options=optimoptions(@fsolve, 'Algorithm', 'Levenberg-Marquardt','Display', 'iter-detailed', 'TolFun', 1e-3,'Jacobian', 'on','TolX', 1e-3);
%options=optimoptions(@fsolve, 'Algorithm', 'Levenberg-Marquardt','Display', 'iter-detailed', 'TolFun', 1e-9,'Jacobian', 'off','TolX', 1e-9);

V = fsolve(@evaluate_V, V0, options);

deltaV = V - V0;





