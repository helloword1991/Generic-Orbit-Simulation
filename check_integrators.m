clc
clear all

METAKR = 'planetsorbitskernels.txt';%'satelliteorbitkernels.txt';

%% Settings
RKV_89 = true;
RKV_89_emb = true;
ABM8 = false;
ODE113 = false;
ODE45 = false;
ODE87 = true;
COWELL = false;

global reverse_check;
reverse_check = true;

global L2frame;
L2frame = true;


global RKV_89_check;
global RKV_89_emb_check;
global ABM8_check;
global ODE113_check;
global ODE45_check;
global ODE87_check;
global COWELL_check;


% initially set to false. Changes automatically to true below in the next if statement

RKV_89_check = false;
RKV_89_emb_check = false;
ABM8_check = false;
ODE113_check = false;
ODE45_check = false;
ODE87_check = false;
COWELL_check = false;

% Force model type
   % this is changed within the force_model function
   % change it here manually for displaying on the graphs
model = 'Simplified+SRP';

%% Load kernel
cspice_furnsh ( METAKR );
planets_name_for_struct = {'EARTH','SUN','MOON','JUPITER','VENUS','MARS','SATURN';'EARTH','SUN',...
    '301','5','VENUS','4','6'};
observer = 'EARTH';

global G;
G = 6.673e-20;

%% Setting up some values and structures
% Satellite initial position w.r.t the Earth center
initial_state =  [-5.618445118318512e+005;  -1.023778587192635e+006;  -1.522315532439711e+005;...
    5.343825699573794e-001;  -2.686719669693540e-001;  -1.145921728828306e-001];

% initial_epoch = cspice_str2et ( 2030 MAY 22 00:03:25.693 ); USE IF ET EPOCH NOT KNOWN

initial_epoch = 958.910668311133e+006; % 22 May 2030
sat = create_sat_structure(initial_state);


%% Integration

% RKV89 EMBEDDED
if RKV_89_emb
    
        orbit_RKV_89_emb = [];
        totalepochs_rkv89_emb = [];
        final_point = 100.747744831378550e+08; % The integrator should not reach it.
        
        complete = false;
        init_t = initial_epoch;
        init_state = initial_state;
        
        % Maneuvers applied. Maneuvers for different integrators and models
        % are kept in the file MANEUVERS.TXT or can be calculated in
        % Calculate_Maneuvers.m script
        dV1 = [0.013256455593648; -0.016216516507728; 0.004041602572279]; % 3 months!
        dV2 = [-7.803777280688135e-04; 0.001854569833090;-0.007247538179753]; 
        dV3 = [0.002544242144491; -0.002921527856874; 0.007703415162441];
        dV4 = [-0.001625936670348; -0.003125208256016; -0.008088501084076];
        dV5 = [-0.002918536114165;-0.003384664726700;0.008333531253574];
        dV6 = [-0.002355831016669;-0.002402859984804;-0.008729136657509];
        deltaVs = {dV1;dV2;dV3;dV4;dV5;dV6};
        
        % Shows the consecutive number of the maneuver applied
        maneuver_number = 1;
        
        % Number of required integrations. One integration - approximately
        % 3 months or when y = 0. Half of the revolution
        n_integrations = 4;
        
        % Keep track on integration number. Don't change!
        n = 1;
        
        while ~complete
            
            maneuver = deltaVs{maneuver_number};
            init_state(1:6) = init_state(1:6) + [0;0;0;maneuver(1);maneuver(2);maneuver(3)];
            phi0 = reshape(eye(6), 36, 1);
            init_state = [init_state(1:6); phi0];
            
            
            [epochs, y0state, orbit_rkv89_emb, rkv89emb_y0state_E] = rkv89emb_maneuvers(@simplified_force_model_srp, init_t , init_state);

            orbit_RKV_89_emb = [orbit_RKV_89_emb, orbit_rkv89_emb];
            totalepochs_rkv89_emb = [totalepochs_rkv89_emb, epochs];
            
            
            % Change the values for the next orbit part integration
            init_t = epochs(end);
            init_state = rkv89emb_y0state_E;
            
            maneuver_number = maneuver_number + 1;
            
            n = n+1;
            if n > n_integrations 
               complete = true; 
            end
            
        end
        
end

% RKV89

if RKV_89
    
        orbit_RKV_89 = [];
        totalepochs_rkv89 = [];
        
        complete = false;
        init_t = initial_epoch;
        init_state = initial_state;
        
        % Maneuvers applied. Maneuvers for different integrators and models
        % are kept in the file MANEUVERS.TXT or can be calculated in
        % Calculate_Maneuvers.m script
        dV1 = [0.013256455593648; -0.016216516507728; 0.004041602572279]; % 3 months!
        dV2 = [-7.803777280688135e-04; 0.001854569833090;-0.007247538179753]; 
        dV3 = [0.002544242144491; -0.002921527856874; 0.007703415162441];
        dV4 = [-0.001625936670348; -0.003125208256016; -0.008088501084076];
        dV5 = [-0.002918536114165;-0.003384664726700;0.008333531253574];
        dV6 = [-0.002355831016669;-0.002402859984804;-0.008729136657509];
        deltaVs = {dV1;dV2;dV3;dV4;dV5;dV6};
        
        % Shows the consecutive number of the maneuver applied
        maneuver_number = 1;
        
        % Number of required integrations. One integration - approximately
        % 3 months or when y = 0. Half of the revolution
        n_integrations = 4;
        
        % Keep track on integration number. Don't change!
        n = 1;
        
        while ~complete
            
            maneuver = deltaVs{maneuver_number};
            init_state(1:6) = init_state(1:6) + [0;0;0;maneuver(1);maneuver(2);maneuver(3)];
            phi0 = reshape(eye(6), 36, 1);
            init_state = [init_state(1:6); phi0];
            
            
            [epochs, y0state, orbit_rkv89, rkv89_y0state_E] = RKV89(@simplified_force_model_srp, init_t, init_state);

            orbit_RKV_89 = [orbit_RKV_89, orbit_rkv89];
            totalepochs_rkv89 = [totalepochs_rkv89, epochs];
            
            
            % Change the values for the next orbit part integration
            init_t = epochs(end);
            init_state = rkv89_y0state_E;
            
            maneuver_number = maneuver_number + 1;
            
            n = n+1;
            if n > n_integrations 
               complete = true; 
            end
            
        end
        
end

if ABM8
    
        orbit_ABM8 = [];
        totalepochs_abm8 = [];
        final_point = 100.747744831378550e+08; % The integrator should not reach it.
        
        complete = false;
        init_t = initial_epoch;
        init_state = initial_state;
        
        % Maneuvers applied. Maneuvers for different integrators and models
        % are kept in the file MANEUVERS.TXT or can be calculated in
        % Calculate_Maneuvers.m script
        dV1 = [0.013256455593648; -0.016216516507728; 0.004041602572279]; % 3 months!
        dV2 = [-7.803777280688135e-04; 0.001854569833090;-0.007247538179753]; 
        dV3 = [0.002544242144491; -0.002921527856874; 0.007703415162441];
        dV4 = [-0.001625936670348; -0.003125208256016; -0.008088501084076];
        dV5 = [];
        dV6 = [];
        deltaVs = {dV1;dV2;dV3;dV4;dV5;dV6};
        
        % Shows the consecutive number of the maneuver applied
        maneuver_number = 1;
        
        % Number of required integrations. One integration - approximately
        % 3 months or when y = 0. Half of the revolution
        n_integrations = 4;
        
        % Keep track on integration number. Don't change!
        n = 1;
        
        while ~complete
            
            maneuver = deltaVs{maneuver_number};
            init_state(1:6) = init_state(1:6) + [0;0;0;maneuver(1);maneuver(2);maneuver(3)];
            phi0 = reshape(eye(6), 36, 1);
            init_state = [init_state(1:6); phi0];
            
            
            [epochs, y0state, orbit_abm8, y0state_E] = ABM8(@simplified_force_model_srp, init_t , init_state);

            orbit_ABM8 = [orbit_ABM8, orbit_abm8];
            totalepochs_abm8 = [totalepochs_abm8, epochs];
            
            
            % Change the values for the next orbit part integration
            init_t = epochs(end);
            init_state = y0state_E;
            
            maneuver_number = maneuver_number + 1;
            
            n = n+1;
            if n > n_integrations 
               complete = true; 
            end
            
        end
        
end

if ODE113
    
        orbit_ODE113 = [];
        totalepochs_ode113 = [];
        final_point = 100.747744831378550e+08; % The integrator should not reach it.
        
        complete = false;
        init_t = initial_epoch;
        init_state = initial_state;
        
        % Maneuvers applied. Maneuvers for different integrators and models
        % are kept in the file MANEUVERS.TXT or can be calculated in
        % Calculate_Maneuvers.m script
        dV1 = [0.013256455593648; -0.016216516507728; 0.004041602572279]; % 3 months!
        dV2 = [-7.803777280688135e-04; 0.001854569833090;-0.007247538179753]; 
        dV3 = [0.002544242144491; -0.002921527856874; 0.007703415162441];
        dV4 = [-0.001625936670348; -0.003125208256016; -0.008088501084076];
        dV5 = [];
        dV6 = [];
        deltaVs = {dV1;dV2;dV3;dV4;dV5;dV6};
        
        % Shows the consecutive number of the maneuver applied
        maneuver_number = 1;
        
        % Number of required integrations. One integration - approximately
        % 3 months or when y = 0. Half of the revolution
        n_integrations = 4;
        
        % Keep track on integration number. Don't change!
        n = 1;
        
        while ~complete
            
            maneuver = deltaVs{maneuver_number};
            init_state(1:6) = init_state(1:6) + [0;0;0;maneuver(1);maneuver(2);maneuver(3)];
            phi0 = reshape(eye(6), 36, 1);
            init_state = [init_state(1:6); phi0];
            
            
            options = odeset('Events',@event_handler, 'MaxStep', 2700, 'InitialStep', 60);
            solution = ode113(@simplified_force_model_srp,[init_t final_point],init_state,options);
            epochs = solution.x;
            orbit_ode113 = solution.y;
            ode113_y0state_E = orbit_ode113(:,end); %solution.ye;
            % Event handler does inner transformation to check y=0
            % Now I need to transform the result to L2 frame
            orbit_ode113 = EcenToL2frame( orbit_ode113, epochs );

            orbit_ODE113 = [orbit_ODE113, orbit_ode113];
            totalepochs_ode113 = [totalepochs_ode113, epochs];
            
            
            % Change the values for the next orbit part integration
            init_t = epochs(end);
            init_state = y0state_E;
            
            maneuver_number = maneuver_number + 1;
            
            n = n+1;
            if n > n_integrations 
               complete = true; 
            end
            
        end
        
end

if ODE45
    
        orbit_ODE45 = [];
        totalepochs_ode45 = [];
        final_point = 100.747744831378550e+08; % The integrator should not reach it.
        
        complete = false;
        init_t = initial_epoch;
        init_state = initial_state;
        
        % Maneuvers applied. Maneuvers for different integrators and models
        % are kept in the file MANEUVERS.TXT or can be calculated in
        % Calculate_Maneuvers.m script
        dV1 = [0.013256455593648; -0.016216516507728; 0.004041602572279]; % 3 months!
        dV2 = [-7.803777280688135e-04; 0.001854569833090;-0.007247538179753]; 
        dV3 = [0.002544242144491; -0.002921527856874; 0.007703415162441];
        dV4 = [-0.001625936670348; -0.003125208256016; -0.008088501084076];
        dV5 = [];
        dV6 = [];
        deltaVs = {dV1;dV2;dV3;dV4;dV5;dV6};
        
        % Shows the consecutive number of the maneuver applied
        maneuver_number = 1;
        
        % Number of required integrations. One integration - approximately
        % 3 months or when y = 0. Half of the revolution
        n_integrations = 4;
        
        % Keep track on integration number. Don't change!
        n = 1;
        
        while ~complete
            
            maneuver = deltaVs{maneuver_number};
            init_state(1:6) = init_state(1:6) + [0;0;0;maneuver(1);maneuver(2);maneuver(3)];
            phi0 = reshape(eye(6), 36, 1);
            init_state = [init_state(1:6); phi0];
            
            
             
            options = odeset('Events',@event_handler, 'MaxStep', 2700, 'InitialStep', 60);
            solution = ode45(@simplified_force_model_srp,[init_t final_point],init_state,options);
            epochs = solution.x;
            orbit_ode45 = solution.y;
            ode45_y0state_E = orbit_ode45(:,end); %solution.ye;
            % Event handler does inner transformation to check y=0
            % Now I need to transform the result to L2 frame
            orbit_ode45 = EcenToL2frame( orbit_ode45, epochs );

            orbit_ODE45 = [orbit_ODE45, orbit_ode45];
            totalepochs_ode45 = [totalepochs_ode45, epochs];
            
            
            % Change the values for the next orbit part integration
            init_t = epochs(end);
            init_state = ode45_y0state_E;
            
            maneuver_number = maneuver_number + 1;
            
            n = n+1;
            if n > n_integrations 
               complete = true; 
            end
            
        end
        
end

if ODE87
    
        orbit_ODE87 = [];
        totalepochs_ode87 = [];
        final_point = 100.747744831378550e+08; % The integrator should not reach it.
        
        complete = false;
        init_t = initial_epoch;
        init_state = initial_state;
        
        % Maneuvers applied. Maneuvers for different integrators and models
        % are kept in the file MANEUVERS.TXT or can be calculated in
        % Calculate_Maneuvers.m script
        dV1 = [0.013256455593648; -0.016216516507728; 0.004041602572279]; % 3 months!
        dV2 = [-7.803777280688135e-04; 0.001854569833090;-0.007247538179753]; 
        dV3 = [0.002544242144491; -0.002921527856874; 0.007703415162441];
        dV4 = [-0.001625936670348; -0.003125208256016; -0.008088501084076];
        dV5 = [];
        dV6 = [];
        deltaVs = {dV1;dV2;dV3;dV4;dV5;dV6};
        
        % Shows the consecutive number of the maneuver applied
        maneuver_number = 1;
        
        % Number of required integrations. One integration - approximately
        % 3 months or when y = 0. Half of the revolution
        n_integrations = 4;
        
        % Keep track on integration number. Don't change!
        n = 1;
        
        while ~complete
            
            maneuver = deltaVs{maneuver_number};
            init_state(1:6) = init_state(1:6) + [0;0;0;maneuver(1);maneuver(2);maneuver(3)];
            phi0 = reshape(eye(6), 36, 1);
            init_state = [init_state(1:6); phi0];
            
            
            [epochs, y0state, orbit_ode87, ode87_y0state_E] = ode87(@simplified_force_model_srp, [init_t final_point] , init_state);

            orbit_ODE87 = [orbit_ODE87, orbit_ode87];
            totalepochs_ode87 = [totalepochs_ode87, epochs];
            
            
            % Change the values for the next orbit part integration
            init_t = epochs(end);
            init_state = ode87_y0state_E;
            
            maneuver_number = maneuver_number + 1;
            
            n = n+1;
            if n > n_integrations 
               complete = true; 
            end
            
        end
        
end

if COWELL
    
        orbit_COWELL = [];
        totalepochs_cowell = [];
        final_point = 100.747744831378550e+08; % The integrator should not reach it.
        
        complete = false;
        init_t = initial_epoch;
        init_state = initial_state;
        
        % Maneuvers applied. Maneuvers for different integrators and models
        % are kept in the file MANEUVERS.TXT or can be calculated in
        % Calculate_Maneuvers.m script
        dV1 = [0.013256455593648; -0.016216516507728; 0.004041602572279]; % 3 months!
        dV2 = [-7.803777280688135e-04; 0.001854569833090;-0.007247538179753]; 
        dV3 = [0.002544242144491; -0.002921527856874; 0.007703415162441];
        dV4 = [-0.001625936670348; -0.003125208256016; -0.008088501084076];
        dV5 = [];
        dV6 = [];
        deltaVs = {dV1;dV2;dV3;dV4;dV5;dV6};
        
        % Shows the consecutive number of the maneuver applied
        maneuver_number = 1;
        
        % Number of required integrations. One integration - approximately
        % 3 months or when y = 0. Half of the revolution
        n_integrations = 4;
        
        % Keep track on integration number. Don't change!
        n = 1;
        
        while ~complete
            
            maneuver = deltaVs{maneuver_number};
            init_state(1:6) = init_state(1:6) + [0;0;0;maneuver(1);maneuver(2);maneuver(3)];
            phi0 = reshape(eye(6), 36, 1);
            init_state = [init_state(1:6); phi0];
            
            
            [epochs, y0state, orbit_cowell, y0state_E] = cowell(@simplified_force_model_srp, init_t , init_state);

            orbit_COWELL = [orbit_COWELL, orbit_cowell];
            totalepochs_cowell = [totalepochs_cowell, epochs];
            
            
            % Change the values for the next orbit part integration
            init_t = epochs(end);
            init_state = y0state_E;
            
            maneuver_number = maneuver_number + 1;
            
            n = n+1;
            if n > n_integrations 
               complete = true; 
            end
            
        end
        
end


%% Checking accuracy of the integrators

if reverse_check == true
    %Reverse method
    if RKV_89_emb == true

        RKV_89_emb_check = true;
            
        reverse_orbit_RKV_89_emb = [];
        reverse_totalepochs_rkv89_emb = [];
        final_point = 938.910668311133e+006; % The integrator should not reach it.
        
        complete = false;
        init_t = totalepochs_rkv89_emb(end);
        init_state = rkv89emb_y0state_E;%orbit_RKV_89(1:6,end);
        % rkv89_y0state is the last point of the orbit but in EME!
        
        dV1 = [0.013256455593648; -0.016216516507728; 0.004041602572279]; % 3 months!
        dV2 = [-7.803777280688135e-04; 0.001854569833090;-0.007247538179753]; 
        dV3 = [0.002544242144491; -0.002921527856874; 0.007703415162441];
        dV4 = [-0.001625936670348; -0.003125208256016; -0.008088501084076];
        dV5 = [-0.002918536114165;-0.003384664726700;0.008333531253574];
        dV6 = [-0.002355831016669;-0.002402859984804;-0.008729136657509];
        
        
        % Shows the consecutive number of the maneuver applied
        maneuver_number = 1;

        n_integrations = 2;
        % 3 integrations means that one should start from maneuver 3
        deltaVs = {dV4;dV3;dV2;dV1};
        
        % Keep track on integration number. Don't change!
        n = 1;
        
        while ~complete

            phi0 = reshape(eye(6), 36, 1);
            init_state = [init_state(1:6); phi0];
             
            [epochs, y0state, orbit_rkv89_emb, rev_rkv89emb_y0state_E] = rkv89emb_maneuvers(@simplified_force_model_srp, init_t , init_state);

            maneuver = deltaVs{maneuver_number};
            rev_rkv89emb_y0state_E(1:6) = rev_rkv89emb_y0state_E(1:6) - [0;0;0;maneuver(1);maneuver(2);maneuver(3)];
           
            reverse_orbit_RKV_89_emb = [reverse_orbit_RKV_89_emb, orbit_rkv89_emb];
            reverse_totalepochs_rkv89_emb = [reverse_totalepochs_rkv89_emb, epochs];
            
            
            % Change the values for the next orbit part integration
            init_t = epochs(end);
            init_state = rev_rkv89emb_y0state_E;      
            
            maneuver_number = maneuver_number + 1;
            
            n = n+1;
            if n > n_integrations 
                
                % Before this run a small piece from last y = 0 till state at t = t_initial
               start_time = 958.910668311133e+006;
               global rkv89emb_lastpiece;
               rkv89emb_lastpiece = true;
               [epochs, y0state, rev_orbit_rkv89emb, rev_rkv89emb_y0state_E] = rkv89emb_maneuvers(@simplified_force_model_srp, [init_t start_time], init_state);
                
                reverse_orbit_RKV_89_emb = [reverse_orbit_RKV_89_emb, rev_orbit_rkv89];
                reverse_totalepochs_rkv89_emb = [reverse_totalepochs_rkv89_emb, epochs];
                
               complete = true; 
            end
            
        end
        rkv89emb_lastpiece = false; % set back to false

            %rkv89emb_conditions_difference = abs(fliplr(reverse_orbit_RKV_89_emb) - orbit_RKV_89_emb);
            rkv89emb_flp = fliplr(reverse_orbit_RKV_89_emb);
            rkv89emb_initial_value_difference = abs(rkv89emb_flp(:,1) - orbit_RKV_89_emb(:,1));
            disp('difference RKV_89_emb');
            disp(rkv89emb_initial_value_difference);

    end

     if RKV_89 == true

        RKV_89_check = true;
            
        reverse_orbit_RKV_89 = [];
        reverse_totalepochs_rkv89 = [];
        final_point = 938.910668311133e+006; % The integrator should not reach it.
        
        complete = false;
        % Init have to be in EME!
        init_t = totalepochs_rkv89(end);
        init_state = rkv89_y0state_E;%orbit_RKV_89(1:6,end);
        % rkv89_y0state is the last point of the orbit but in EME!
        
        dV1 = [0.013256455593648; -0.016216516507728; 0.004041602572279]; % 3 months!
        dV2 = [-7.803777280688135e-04; 0.001854569833090;-0.007247538179753]; 
        dV3 = [0.002544242144491; -0.002921527856874; 0.007703415162441];
        dV4 = [-0.001625936670348; -0.003125208256016; -0.008088501084076];
        dV5 = [-0.002918536114165;-0.003384664726700;0.008333531253574];
        dV6 = [-0.002355831016669;-0.002402859984804;-0.008729136657509];
        
        
        % Shows the consecutive number of the maneuver applied
        maneuver_number = 1;
        
        n_integrations = 2;
        % Adjust maneuvers manually
        % 3 integrations means that one should start from maneuver 3
        deltaVs = {dV4;dV3;dV2;dV1};
        
        % Keep track on integration number. Don't change!
        n = 1;
        
        while ~complete
            
            phi0 = reshape(eye(6), 36, 1);
            init_state = [init_state(1:6); phi0];
            
            [epochs, y0state, rev_orbit_rkv89, rev_rkv89_y0state_E] = RKV89(@simplified_force_model_srp, init_t , init_state);

            % Now subtract the maneuver
            
            maneuver = deltaVs{maneuver_number};
            rev_rkv89_y0state_E(1:6) = rev_rkv89_y0state_E(1:6) - [0;0;0;maneuver(1);maneuver(2);maneuver(3)];
            
            reverse_orbit_RKV_89 = [reverse_orbit_RKV_89, rev_orbit_rkv89];
            reverse_totalepochs_rkv89 = [reverse_totalepochs_rkv89, epochs];
            

            % Change the values for the next orbit part integration
            init_t = epochs(end);
            init_state = rev_rkv89_y0state_E;     
            
            maneuver_number = maneuver_number + 1;
            
            n = n+1;
            if n > n_integrations 
                
               % Before this run a small piece from last y = 0 till state at t = t_initial
               start_time = 958.910668311133e+006;
               global rkv89_lastpiece;
               rkv89_lastpiece = true;
               [epochs, y0state, rev_orbit_rkv89, rev_rkv89_y0state_E] = RKV89(@simplified_force_model_srp, [init_t start_time], init_state);
                
                reverse_orbit_RKV_89 = [reverse_orbit_RKV_89, rev_orbit_rkv89];
                reverse_totalepochs_rkv89 = [reverse_totalepochs_rkv89, epochs];
                
               complete = true; 
            end
            
        end
            rkv89_lastpiece = false; % set back to false
            %rkv89_conditions_difference = abs(fliplr(reverse_orbit_RKV_89) - orbit_RKV_89);
            rkv89_flp = fliplr(reverse_orbit_RKV_89);
            rkv89_initial_value_difference = abs(rkv89_flp(1:6,1) - orbit_RKV_89(1:6,1));
            disp('difference RKV_89');
            disp(rkv89_initial_value_difference);

     end

    
     if ODE87 == true
         
        ODE87_check = true;
            
        reverse_orbit_ODE87 = [];
        reverse_totalepochs_ode87 = [];
        final_point = 938.910668311133e+006; % The integrator should not reach it.
        
        complete = false;
        % Init have to be in EME!
        init_t = totalepochs_ode87(end);
        init_state = ode87_y0state_E;%orbit_RKV_89(1:6,end);
        % rkv89_y0state is the last point of the orbit but in EME!
        
        dV1 = [0.013256455593648; -0.016216516507728; 0.004041602572279]; % 3 months!
        dV2 = [-7.803777280688135e-04; 0.001854569833090;-0.007247538179753]; 
        dV3 = [0.002544242144491; -0.002921527856874; 0.007703415162441];
        dV4 = [-0.001625936670348; -0.003125208256016; -0.008088501084076];
        dV5 = [-0.002918536114165;-0.003384664726700;0.008333531253574];
        dV6 = [-0.002355831016669;-0.002402859984804;-0.008729136657509];
        
        
        % Shows the consecutive number of the maneuver applied
        maneuver_number = 1;
        
        n_integrations = 4;
        % Adjust maneuvers manually
        % 3 integrations means that one should start from maneuver 3
        deltaVs = {dV4;dV3;dV2;dV1};
        
        % Keep track on integration number. Don't change!
        n = 1;
        
        while ~complete
            
            phi0 = reshape(eye(6), 36, 1);
            init_state = [init_state(1:6); phi0];
            
            [epochs, y0state, rev_orbit_ode87, rev_ode87_y0state_E] = ode87(@simplified_force_model_srp, [init_t final_point], init_state);

            % Now subtract the maneuver
            
            maneuver = deltaVs{maneuver_number};
            rev_ode87_y0state_E(1:6) = rev_ode87_y0state_E(1:6) - [0;0;0;maneuver(1);maneuver(2);maneuver(3)];
            
            reverse_orbit_ODE87 = [reverse_orbit_ODE87, rev_orbit_ode87];
            reverse_totalepochs_ode87 = [reverse_totalepochs_ode87, epochs];
            

            % Change the values for the next orbit part integration
            init_t = epochs(end);
            init_state = rev_ode87_y0state_E;     
            
            maneuver_number = maneuver_number + 1;
            
            n = n+1;
            if n > n_integrations 
                
                 % Before this run a small piece from last y = 0 till state at t = t_initial
               start_time = 958.910668311133e+006;

               [epochs, y0state, rev_orbit_ode87, rev_ode87_y0state_E] = rkv89emb_maneuvers(@simplified_force_model_srp, [init_t start_time], init_state);
                
                reverse_orbit_ODE87  = [reverse_orbit_ODE87, rev_orbit_ode87];
                reverse_totalepochs_ode87 = [reverse_totalepochs_ode87, epochs];
                
               complete = true; 
            end
            
        end

            %rkv89_conditions_difference = abs(fliplr(reverse_orbit_RKV_89) - orbit_RKV_89);
           	ode87_flp = fliplr(reverse_orbit_ODE87);
            ode87_initial_value_difference = abs(ode87_flp(1:6,1) - orbit_ODE87(1:6,1));
            disp('difference ODE87');
            disp(ode87_initial_value_difference);

         
     end
     
      if ODE45 == true
         
        ODE45_check = true;
            
        reverse_orbit_ODE45 = [];
        reverse_totalepochs_ode45 = [];
        final_point = 938.910668311133e+006; % The integrator should not reach it.
        
        complete = false;
        % Init have to be in EME!
        init_t = totalepochs_ode45(end);
        init_state = ode45_y0state_E;%orbit_RKV_89(1:6,end);
        % rkv89_y0state is the last point of the orbit but in EME!
        
        dV1 = [0.013256455593648; -0.016216516507728; 0.004041602572279]; % 3 months!
        dV2 = [-7.803777280688135e-04; 0.001854569833090;-0.007247538179753]; 
        dV3 = [0.002544242144491; -0.002921527856874; 0.007703415162441];
        dV4 = [-0.001625936670348; -0.003125208256016; -0.008088501084076];
        dV5 = [-0.002918536114165;-0.003384664726700;0.008333531253574];
        dV6 = [-0.002355831016669;-0.002402859984804;-0.008729136657509];
        
        
        % Shows the consecutive number of the maneuver applied
        maneuver_number = 1;
        
        n_integrations = 4;
        % Adjust maneuvers manually
        % 3 integrations means that one should start from maneuver 3
        deltaVs = {dV4;dV3;dV2;dV1};
        
        % Keep track on integration number. Don't change!
        n = 1;
        
        while ~complete
            
            phi0 = reshape(eye(6), 36, 1);
            init_state = [init_state(1:6); phi0];
            
            options = odeset('Events',@event_handler, 'MaxStep', -2700, 'InitialStep', -60);
            solution = ode45(@simplified_force_model_srp,[init_t final_point],init_state,options);
            epochs = solution.x;
            rev_orbit_ode45 = solution.y;
            rev_ode45_y0state_E = orbit_ode45(:,end); %solution.ye;
            % Event handler does inner transformation to check y=0
            % Now I need to transform the result to L2 frame
            rev_orbit_ode45 = EcenToL2frame( orbit_ode45, epochs );
            % Now subtract the maneuver
            
            maneuver = deltaVs{maneuver_number};
            rev_ode45_y0state_E(1:6) = rev_ode45_y0state_E(1:6) - [0;0;0;maneuver(1);maneuver(2);maneuver(3)];
            
            reverse_orbit_ODE45 = [reverse_orbit_ODE45, rev_orbit_ode45];
            reverse_totalepochs_ode45 = [reverse_totalepochs_ode45, epochs];
            

            % Change the values for the next orbit part integration
            init_t = epochs(end);
            init_state = rev_ode45_y0state_E;     
            
            maneuver_number = maneuver_number + 1;
            
            n = n+1;
            if n > n_integrations 
                
                 % Before this run a small piece from last y = 0 till state at t = t_initial
               start_time = 958.910668311133e+006;

            options = odeset('MaxStep', -2700, 'InitialStep', -60);
            solution = ode45(@simplified_force_model_srp,[init_t start_time],init_state,options);
            epochs = solution.x;
            rev_orbit_ode45 = solution.y;
            rev_ode45_y0state_E = orbit_ode45(:,end);
            rev_orbit_ode45 = EcenToL2frame( orbit_ode45, epochs );
              
                reverse_orbit_ODE45  = [reverse_orbit_ODE45, rev_orbit_ode45];
                reverse_totalepochs_ode45 = [reverse_totalepochs_ode45, epochs];
                
               complete = true; 
            end
            
        end

            %rkv89_conditions_difference = abs(fliplr(reverse_orbit_RKV_89) - orbit_RKV_89);
           	ode45_flp = fliplr(reverse_orbit_ODE45);
            ode45_initial_value_difference = abs(ode45_flp(1:6,1) - orbit_ODE45(1:6,1));
            disp('difference ODE45');
            disp(ode45_initial_value_difference);

         
      end
     
      if ODE113 == true
         
        ODE113_check = true;
            
        reverse_orbit_ODE113 = [];
        reverse_totalepochs_ode113 = [];
        final_point = 938.910668311133e+006; % The integrator should not reach it.
        
        complete = false;
        % Init have to be in EME!
        init_t = totalepochs_ode113(end);
        init_state = ode113_y0state_E;%orbit_RKV_89(1:6,end);
        % rkv89_y0state is the last point of the orbit but in EME!
        
        dV1 = [0.013256455593648; -0.016216516507728; 0.004041602572279]; % 3 months!
        dV2 = [-7.803777280688135e-04; 0.001854569833090;-0.007247538179753]; 
        dV3 = [0.002544242144491; -0.002921527856874; 0.007703415162441];
        dV4 = [-0.001625936670348; -0.003125208256016; -0.008088501084076];
        dV5 = [-0.002918536114165;-0.003384664726700;0.008333531253574];
        dV6 = [-0.002355831016669;-0.002402859984804;-0.008729136657509];
        
        
        % Shows the consecutive number of the maneuver applied
        maneuver_number = 1;
        
        n_integrations = 4;
        % Adjust maneuvers manually
        % 3 integrations means that one should start from maneuver 3
        deltaVs = {dV4;dV3;dV2;dV1};
        
        % Keep track on integration number. Don't change!
        n = 1;
        
        while ~complete
            
            phi0 = reshape(eye(6), 36, 1);
            init_state = [init_state(1:6); phi0];
            
            options = odeset('Events',@event_handler, 'MaxStep', -2700, 'InitialStep', -60);
            solution = ode113(@simplified_force_model_srp,[init_t final_point],init_state,options);
            epochs = solution.x;
            rev_orbit_ode113 = solution.y;
            rev_ode113_y0state_E = orbit_ode113(:,end); %solution.ye;
            % Event handler does inner transformation to check y=0
            % Now I need to transform the result to L2 frame
            rev_orbit_ode113 = EcenToL2frame( orbit_ode113, epochs );
            % Now subtract the maneuver
            
            maneuver = deltaVs{maneuver_number};
            rev_ode113_y0state_E(1:6) = rev_ode45_y0state_E(1:6) - [0;0;0;maneuver(1);maneuver(2);maneuver(3)];
            
            reverse_orbit_ODE113 = [reverse_orbit_ODE113, rev_orbit_ode113];
            reverse_totalepochs_ode113 = [reverse_totalepochs_ode113, epochs];
            

            % Change the values for the next orbit part integration
            init_t = epochs(end);
            init_state = rev_ode113_y0state_E;     
            
            maneuver_number = maneuver_number + 1;
            
            n = n+1;
            if n > n_integrations 
                
                 % Before this run a small piece from last y = 0 till state at t = t_initial
               start_time = 958.910668311133e+006;

            options = odeset('MaxStep', -2700, 'InitialStep', -60);
            solution = ode113(@simplified_force_model_srp,[init_t start_time],init_state,options);
            epochs = solution.x;
            rev_orbit_ode113 = solution.y;
            rev_ode113_y0state_E = orbit_ode113(:,end);
            rev_orbit_ode113 = EcenToL2frame( orbit_ode113, epochs );
              
                reverse_orbit_ODE113  = [reverse_orbit_ODE113, rev_orbit_ode113];
                reverse_totalepochs_ode113 = [reverse_totalepochs_ode45, epochs];
                
               complete = true; 
            end
            
        end

            %rkv89_conditions_difference = abs(fliplr(reverse_orbit_RKV_89) - orbit_RKV_89);
           	ode113_flp = fliplr(reverse_orbit_ODE113);
            ode113_initial_value_difference = abs(ode113_flp(1:6,1) - orbit_ODE113(1:6,1));
            disp('difference ODE113');
            disp(ode113_initial_value_difference);

         
     end
     
     
    %% Create a table with results

%     Integrators = {'RKV89';'ABM';'RK45';'PD78';'RKV89_embedded'};
%     
%     if RKV_89 && ~simpleRKV89
%         rkv89_initial_value_difference = zeros(6,1);
%         if ~embedded_estimation
%             rkv89emb_initial_value_difference = zeros(6,1);
%        end
%     end
%     if ~RKV_89 
%         rkv89_initial_value_difference = zeros(6,1);
%         rkv89emb_initial_value_difference = zeros(6,1);
% %         if ~embedded_estimation == true
% %            rkv89emb_initial_value_difference = zeros(6,1);
% %         end
%     end
%     if ~ABM
%         abm_initial_value_difference = zeros(6,1);
%     end
%     if ~RK45 
%         rk_initial_value_difference = zeros(6,1);
%     end
%     if ~PD78 
%         pd78_initial_value_difference = zeros(6,1);
%     end
%     Init_diffs = [rkv89_initial_value_difference;abm_initial_value_difference;rk_initial_value_difference;pd78_initial_value_difference;rkv89_initial_value_difference];
%     %x_diffs = [rkv89_initial_value_difference;abm_initial_value_difference;rk_initial_value_difference;pd78_initial_value_difference ];
%     dX = [rkv89_initial_value_difference(1);abm_initial_value_difference(1);rk_initial_value_difference(1);pd78_initial_value_difference(1);rkv89emb_initial_value_difference(1)];
%     dY = [rkv89_initial_value_difference(2);abm_initial_value_difference(2);rk_initial_value_difference(2);pd78_initial_value_difference(2);rkv89emb_initial_value_difference(2)];
%     dZ = [rkv89_initial_value_difference(3);abm_initial_value_difference(3);rk_initial_value_difference(3);pd78_initial_value_difference(3);rkv89emb_initial_value_difference(3)];
%     dVX = [rkv89_initial_value_difference(4);abm_initial_value_difference(4);rk_initial_value_difference(4);pd78_initial_value_difference(4);rkv89emb_initial_value_difference(4)];
%     dVY = [rkv89_initial_value_difference(5);abm_initial_value_difference(5);rk_initial_value_difference(5);pd78_initial_value_difference(5);rkv89emb_initial_value_difference(5)];
%     dVZ = [rkv89_initial_value_difference(6);abm_initial_value_difference(6);rk_initial_value_difference(6);pd78_initial_value_difference(6);rkv89emb_initial_value_difference(6)];
%     dX_scalar = [sqrt(dX(1)^2+dY(1)^2+dZ(1)^2);sqrt(dX(2)^2+dY(2)^2+dZ(2)^2);sqrt(dX(3)^2+dY(3)^2+dZ(3)^2);sqrt(dX(4)^2+dY(4)^2+dZ(4)^2);sqrt(dX(5)^2+dY(5)^2+dZ(5)^2)];
%     dVX_scalar = [sqrt(dVX(1)^2+dVY(1)^2+dVZ(1)^2);sqrt(dVX(2)^2+dVY(2)^2+dVZ(2)^2);sqrt(dVX(3)^2+dVY(3)^2+dVZ(3)^2);sqrt(dVX(4)^2+dVY(4)^2+dVZ(4)^2);sqrt(dVX(5)^2+dVY(5)^2+dVZ(5)^2)];
%     Table = table(dX,dY,dZ,dVX,dVY,dVZ,dX_scalar,dVX_scalar,'RowNames',Integrators);
end

%% Plotting

% figure(2)
% plot3(reverse_orbit_RKV_89_emb(1,:),reverse_orbit_RKV_89_emb(2,:),reverse_orbit_RKV_89_emb(3,:),'g'); % orbit


figure(1)
view(3)
grid on
hold on
plot3(0,0,0,'*r'); % nominal L2 point
if RKV_89
   plot3(orbit_RKV_89(1,:),orbit_RKV_89(2,:),orbit_RKV_89(3,:),'b'); % orbit
   plot3(reverse_orbit_RKV_89(1,:),reverse_orbit_RKV_89(2,:),reverse_orbit_RKV_89(3,:),'r'); % orbit
end


figure(2)
view(3)
grid on
hold on
plot3(0,0,0,'*r'); % nominal L2 point
if RKV_89_emb
    plot3(orbit_RKV_89_emb(1,:),orbit_RKV_89_emb(2,:),orbit_RKV_89_emb(3,:),'b'); % orbit
    plot3(reverse_orbit_RKV_89_emb(1,:),reverse_orbit_RKV_89_emb(2,:),reverse_orbit_RKV_89_emb(3,:),'g'); % orbit

end

figure(3)
view(3)
grid on
hold on
plot3(0,0,0,'*r'); % nominal L2 point
if ODE87 
    plot3(orbit_ODE87(1,:),orbit_ODE87(2,:),orbit_ODE87(3,:),'m');
    plot3(reverse_orbit_ODE87(1,:),reverse_orbit_ODE87(2,:),reverse_orbit_ODE87(3,:),'b'); % orbit

end

figure(4)
view(3)
grid on
hold on
plot3(0,0,0,'*r'); % nominal L2 point
if ODE87 
    plot3(orbit_ODE45(1,:),orbit_ODE45(2,:),orbit_ODE45(3,:),'m');
    plot3(reverse_orbit_ODE45(1,:),reverse_orbit_ODE45(2,:),reverse_orbit_ODE45(3,:),'b'); % orbit

end
%% Plots info
figure(1)
title(['HALO orbit around L2 SEM. ', model]);
legend('Nominal L2 point','HALO orbit');
xlabel('x');
ylabel('y');
zlabel('z');
grid on

