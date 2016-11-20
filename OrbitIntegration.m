
clc
clear all
close all

%% Define local variables
METAKR = 'planetsorbitskernels.txt';%'satelliteorbitkernels.txt';

%% Settings
full_mission = false; % full mission or just a test part before the first maneuver
one_revolution = true; % only one maneuver applied % if false then all mission till the end
starting_from_earth = false; % mission with leop phase. Leave it false always!
RKV_89 = true;
ABM = false;
RK45 = false;
PD78 = false;
apply_maneuvers = false;

if not(full_mission)
    load('irassihalotime.mat', 'Date');
    load('irassihalogmat.mat', 'Gmat');
       
else
    load('IRASSIFullMissionDate.mat', 'Date');
    load('IRASSIFullMission.mat', 'Gmat');
end

%% Load kernel
cspice_furnsh ( METAKR );
planets_name_for_struct = {'EARTH','SUN','MOON','JUPITER','VENUS','MARS','SATURN';'EARTH','SUN','301','5','VENUS','4','6'};
observer = 'EARTH';% or 339

% global G;
% G = 6.67e-20; % km % or -17


%% Ephemeris from SPICE
% Define initial epoch for a satellite
initial_utctime = '2030 MAY 22 00:03:25.693'; 
end_utctime = '2030 NOV 21 11:22:23.659';% NOV! %'2030 DEC 28 00:03:25.693'; %'2030 DEC 28 00:03:25.693';%'2030 NOV 21 11:22:23.659';
%'2030 DEC 28 00:03:25.693'; % 7 months
initial_et = cspice_str2et ( initial_utctime );
end_et = cspice_str2et ( end_utctime );
%step = 86400/10; %86400; %86400 3600 - every hour

if not(full_mission)
   et_vector = zeros(1,length(Date));
   for d=1:length(Date)
        utcdate = datestr((datetime(Date(d,:),'InputFormat','yyyy-MM-dd''T''HH:mm:ss.SSS', 'TimeZone', 'UTC')), 'yyyy mmm dd HH:MM:SS.FFF');
        et_vector(d) = cspice_str2et (utcdate);
   end
else
    if one_revolution == true
        et_vector = zeros(1,11621);
        for d=3245:1:14866-1
        utcdate = datestr((datetime(Date(d,:),'InputFormat','yyyy-MM-dd''T''HH:mm:ss.SSS', 'TimeZone', 'UTC')), 'yyyy mmm dd HH:MM:SS.FFF');
        et_vector(d-3244) = cspice_str2et (utcdate);
        end
    else
        if ~starting_from_earth
            et_vector = zeros(1,length(Date));
            for d=3245:length(Date)
            utcdate = datestr((datetime(Date(d,:),'InputFormat','yyyy-MM-dd''T''HH:mm:ss.SSS', 'TimeZone', 'UTC')), 'yyyy mmm dd HH:MM:SS.FFF');
            et_vector(d-3244) = cspice_str2et (utcdate);
            end
        else
            et_vector = zeros(1,length(Date));
            for d=1:length(Date)
            utcdate = datestr((datetime(Date(d,:),'InputFormat','yyyy-MM-dd''T''HH:mm:ss.SSS', 'TimeZone', 'UTC')), 'yyyy mmm dd HH:MM:SS.FFF');
            et_vector(d) = cspice_str2et (utcdate);
            end
        end
    end
end

disp(length(et_vector));


%% Setting up some values and structures
% Satellite initial position w.r.t the Earth center
initial_state = [-561844.307770134;-1023781.19884100;-152232.354717768;0.545714129191316;-0.288204299060291;-0.102116477725135]; 
% Create a structure for a satellite
sat = create_sat_structure(initial_state);
% Get initial states for calculating initial energy
[earth_init, sun_init, moon_init, jupiter_init, venus_init, mars_init, saturn_init] = create_structure( planets_name_for_struct, initial_et, observer);



%% Check influences
global influence;
influence = zeros(3,2);

%% Maneuvers Insertion
% In HALO orbit phase
%              [ 21 Nov 2030 09:06:53.955 ; 19 May 2031 17:30:30.286; 19
%              Nov 2031 07:20:00.739; 16 May 2032 09:02:25.529; 
%              15 Nov 2032 20:12:11.617; 13 May 2033 12:06:40.408;
%              12 Nov 2033 20:30:57.484;10 May 2034 11:17:41.967
global epochs_numbers;
global maneuvers;

if starting_from_earth == true
    epochs_numbers = [9120; 14866; 20741; 26472; 32344; 38067; 43935; 49652]; % 8 maneuvers
else
    epochs_numbers = [9120; 14866; 20741; 26472; 32344; 38067; 43935; 49652];
    dif = 3244; % difference in epochs numbers. Halo phase starts at 3245. Which is 1 in my case
    for h = 1:length(epochs_numbers)
        epochs_numbers(h) = epochs_numbers(h) - dif;
    end
end   
if apply_maneuvers == true
    maneuver1 = [0.003696355989169846;-0.004709746685339394;0.01461216953990576]; 
    % my maneuver with corrections
    %maneuver1 = [0.003696355989169846-0.0016;-0.004709746685339394-0.0013;0.01461216953990576-0.0011];
    maneuver2 = [-0.004873280356119337;-0.007500302117829953;0.01748835216221812];          
    maneuver3 = [0.004395508963826083;-0.006574683170090312;0.01163890236306115];          
    maneuver4 = [-0.003729004790675886;-0.002912961186885862;0.01277290066887374];        
    maneuver5 = [0.003390651811125526;-0.005644399141577779;0.01143305771064858];           
    maneuver6 = [-0.003048218009434191;-0.003950944322589558;0.01099888048023886];        
    maneuver7 = [0.001693792364818979;-0.002281349967081013;0.008762453816533339];        
    maneuver8 = [-0.002822612198624273;-0.005352768508478975;0.01193703854590986];
    
    maneuvers = {maneuver1,maneuver2,maneuver3,maneuver4,maneuver5,maneuver6,maneuver7,maneuver8};
else
    zeromaneuvers = zeros(3,1);
    
    maneuvers = {zeromaneuvers,zeromaneuvers,zeromaneuvers,zeromaneuvers,zeromaneuvers,zeromaneuvers,zeromaneuvers,zeromaneuvers};
end




%% INTEGRATION PART
options = odeset('RelTol',1e-12,'AbsTol',1e-12);

% ODE45
if RK45 == true
tic
orbit = ode45(@(t,y) force_model(t,y),et_vector,initial_state,options);    
toc
end

% Adams-Bashforth-Moulton Predictor-Corrector
if ABM == true
tic 
[orbit_ab8, tour] = adambashforth8(@force_model,et_vector,initial_state, length(et_vector));
toc
end

% Runge-Kutta-Verner 8(9)
simpleRKV89 = true;
embedded_estimation = false;
tic
if RKV_89 == true
    
    if simpleRKV89 == true
       %[orbit_rkv89, tourrkv] = RKV89(@force_model,et_vector,initial_state, length(et_vector));
       [orbit_rkv89, tourrkv] = RKV89_2(@force_model,et_vector,initial_state, length(et_vector));
    end
    if embedded_estimation == true
    
        orbit_rkv89_emb(:,1) = initial_state;
        next_step = 60; % initial value for next_step.
        final = false;
        n = 1;
        epochs(1) = et_vector(1);
        while not(final)
                [state, newstep, last] = rkv(@force_model,epochs(n),orbit_rkv89_emb(:,n), next_step, et_vector(length(et_vector)));
                next_step = newstep;
                final = last;

        n=n+1;
        orbit_rkv89_emb(:,n) = state;
        
        % Add maneuver if this is required epoch
        for k = 1:length(epochs_numbers)
            if n == epochs_numbers(k)
                % If this epoch is one of the epoch presented in maneuvers
                % array - add dV to its components
                applied_maneuver = maneuvers{k};
                orbit_rkv89_emb(4,n) = orbit_rkv89_emb(4,n) + applied_maneuver(1);
                orbit_rkv89_emb(5,n) = orbit_rkv89_emb(5,n) + applied_maneuver(2);
                orbit_rkv89_emb(6,n) = orbit_rkv89_emb(6,n) + applied_maneuver(3);
                
                next_step = 60; % Change next_step to 60 as if I started the integration from the beginning
                
            end
        end
        
        
        epochs(n) = epochs(n-1) + next_step;
        
        
            if n == 2 || n == 3
                disp(next_step);
            end
        end
        
    end
end
toc
% Prince Dormand 7(8)
if PD78 == true
options87 = odeset('RelTol',1e-13,'AbsTol',1e-13, 'MaxStep',2700,'InitialStep',60);
[tour1, orbit_ode87] = ode45(@(t,y) force_model(t,y),et_vector,initial_state, options87);
orbit_ode87 = orbit_ode87';
end
toc


%% The differences
%difference_rkv89emb = abs(Gmat(:,1:5859) - orbit_rkv89_emb(:,1:5859));
%difference_ab8 = abs(Gmat - orbit_ab8);
%difference_rkv89 = abs(Gmat - orbit_rkv89);


%% Total Energy checks

% energy = zeros(3, length(et_vector));  % 1 row Kinetic, 2 row Potential, 3 row - Total Mechanical
% 
% energy_ab4 = zeros(3, length(et_vector));
% First calculate the initial energies
% b = [sat, earth_init, sun_init, moon_init, jupiter_init, venus_init, mars_init, saturn_init];
% [init_total, init_kinetic, init_potential] = calculate_energy(b);
% Initial_energy = init_total;
% Initial_kinetic = init_kinetic;
% Initial_potential = init_potential;

%% Plotting

figure(1)
view(3)
grid on
hold on
%plot3(Gmat(1,:),Gmat(2,:),Gmat(3,:),'b');% Reference
plot3(Gmat(1,1:15000),Gmat(2,1:15000),Gmat(3,1:15000),'b');
if RK45 == true
plot3(orbit.y(1,:),orbit.y(2,:),orbit.y(3,:),'r');% RK45
end
if ABM == true
plot3(orbit_ab8(1,:),orbit_ab8(2,:),orbit_ab8(3,:),'g'); % ABM8
end
if RKV_89 == true
    if simpleRKV89 == true
    plot3(orbit_rkv89(1,:),orbit_rkv89(2,:),orbit_rkv89(3,:),'c'); % RKV89
    difference_rkv89 = abs(Gmat(:,1:length(orbit_rkv89)) - orbit_rkv89);
    end
    if embedded_estimation == true
    plot3(orbit_rkv89_emb(1,:),orbit_rkv89_emb(2,:),orbit_rkv89_emb(3,:),'m'); % RKV89 with real error estimate
    end
    %plot3(orbit_rkv89(1,:),orbit_rkv89(2,:),orbit_rkv89(3,:),'c');
end
if PD78 == true
plot3(orbit_ode87(1,:),orbit_ode87(2,:),orbit_ode87(3,:),'y'); % RK87
end

% figure(2)
% grid on
% hold on
% plot(et_vector(1,1:5859),difference_rkv89emb(1,1:5859),et_vector(1,1:5859),difference_rkv89emb(2,1:5859),et_vector(1,1:5859),difference_rkv89emb(3,1:5859) );% Reference

figure(3)
grid on
hold on
plot(et_vector,difference_rkv89,et_vector,difference_rkv89,et_vector,difference_rkv89);% Reference

%% Plots info
figure(3)
title('Reference vs Integration');
legend('Reference','RK45','ABM8', 'RKV89', 'RKV89 embedded');
xlabel('x');
ylabel('y');
grid on


%cspice_kclear;