
METAKR = which('planetsorbitskernels.txt');
cspice_furnsh ( METAKR );
global G;
G = 6.673e-20;
global L2frame;
L2frame = true;


% Set initial state

R0 = [-1447522.71235131;938357.823129112;22691.6506246949];
V0 = [0.00640971096544824;-0.000955550545351669;0.000543973359516699];
init_epoch = 9.824283500767865e+08;
final_epoch = 9.902741246238446e+08;


phi0 = reshape(eye(6), 36, 1);
init_state = [R0; V0; phi0];

% Initial guess
dV = [-0.001625936670348; -0.003125208256016; -0.008088501084076];


% Calculate the maneuver
deltaV = fsolve(@new_evaluate_V, dV);
disp(deltaV);
 
Init_state = init_state;
Init_state(4:6,:) = Init_state(4:6,:) + dV;%deltaV;

%global output_state;
%output_state = [];

[t, y0state, output_state, y0state_E] = ode87_test_y(@full_force_model, [init_epoch final_epoch] , Init_state);


% Graphical check of the orbit part
figure
hold on
plot3(output_state(1,:),output_state(2,:),output_state(3,:),'r','LineWidth',2)

