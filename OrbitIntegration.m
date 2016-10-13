clc
clear all
close all

%% Define local variables
METAKR = 'planetsorbitskernels.txt';%'satelliteorbitkernels.txt';

% Load kernel
cspice_furnsh ( METAKR );

planets_name_for_struct = {'EARTH','SUN','MOON','JUPITER','VENUS','MARS','SATURN';'EARTH','SUN','301','5','VENUS','4','6'};

observer = 'EARTH';% or 339

% global G;
% G = 6.67e-20; % km % or -17


%% Ephemeris from SPICE

% Define initial epoch for a satellite
initial_utctime = '2030 MAY 22 00:03:25.693'; 
end_utctime = '2030 DEC 28 00:03:25.693';%'2030 NOV 21 11:22:23.659';
%'2030 DEC 28 00:03:25.693'; % 7 months

initial_et = cspice_str2et ( initial_utctime );
end_et = cspice_str2et ( end_utctime );

step = 86400;

% Create et time vector
et_vector = initial_et:step:end_et;

energy = zeros(3, length(et_vector));  % 1 row Kinetic, 2 row Potential, 3 row - Total Mechanical

% Satellite initial position w.r.t the Earth center
initial_state = [-561844.307770134;-1023781.19884100;-152232.354717768;0.545714129191316;-0.288204299060291;-0.102116477725135]; 

% Create a structure for a satellite
sat = create_sat_structure(initial_state);

% Get initial states for calculating initial energy
[earth_init, sun_init, moon_init, jupiter_init, venus_init, mars_init, saturn_init] = create_structure( planets_name_for_struct, initial_et, observer);


%% ODE Integration
% Case without influence from other planets
options = odeset('RelTol',1e-12,'AbsTol',1e-12);
global influences;
influences = zeros(6,7);
pressure = 1; %0 if no solar pressure needed

tic
orbit = ode45(@(t,y) force_model(t,y,observer),et_vector,initial_state,options);    
toc

%% Mechanical Energy

% First calcilate the initial energies
b = [sat, earth_init, sun_init, moon_init, jupiter_init, venus_init, mars_init, saturn_init];
[init_total, init_kinetic, init_potential] = calculate_energy(b);
Initial_energy = init_total;
Initial_kinetic = init_kinetic;
Initial_potential = init_potential;

% Calculate for each step
for epoch = 1:length(et_vector)
    
    % Create a structure for the satellite
    sat_at_this_time = create_sat_structure(orbit.y(:,epoch));
    % Information about planets at a given epoch
    [earth, sun, moon, jupiter, venus, mars, saturn] = create_structure( planets_name_for_struct, et_vector(epoch), observer);
    bodies = [sat_at_this_time, earth, sun, moon, jupiter, venus, mars, saturn];
    [total, kinetic, potential] = calculate_energy(bodies);
    kin1 = kinetic - Initial_kinetic;
    pot1 = potential - Initial_potential;
    tot1 = total - Initial_energy;
    energy(1,epoch) = kin1;
    energy(2,epoch) = pot1;
    energy(3,epoch) = tot1;
end


% %% Define local variables
load('irassihalotime.mat', 'Date')
load('irassihalogmat.mat', 'Gmat')

%% Plotting

figure(1)
subplot(1,2,1)
view(3)
grid on
hold on
plot3(orbit.y(1,:),orbit.y(2,:),orbit.y(3,:),'r')% 
subplot(1,2,2)
view(3)
grid on
hold on
plot3(Gmat(1,:),Gmat(2,:),Gmat(3,:),'b')% 

figure(2)
view(2)
grid on
hold on
plot(et_vector(1,:), energy(1,:), 'r');
plot(et_vector(1,:), energy(2,:), 'g');
plot(et_vector(1,:), energy(3,:), 'b');

%% Plots info
figure(1)
title('Integrated ephemeris of a satellite w.r.t the Earth, 3D');
subplot(1,2,1)
legend('Integrated Orbit');
xlabel('x');
ylabel('y');
zlabel('z');
grid on
subplot(1,2,2)
legend('GMAT orbit');
xlabel('x');
ylabel('y');
zlabel('z');
grid on


figure(2)
title('Simplified energy');
%legend('Kietic', 'Potential', 'Total mechanical energy');
legend('Kinetic energy','Potential energy','Total energy');
xlabel('x');
ylabel('y');
grid on

%cspice_kclear;