function [ desired_t_for_maneuver, state_at_desired_t , state_Earth] = srp_find_T_foryzero( initials, init_state, ytol )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
global RKV_89_emb_check;
global RKV_89_check;
global ODE87_check;
% Check the interpolation code
        % using binary search tree
        found = false;
        int_step = 0.1;
        if RKV_89_emb_check 
           int_step = -0.1; 
        end
        if RKV_89_check 
           int_step = -0.1; 
        end
        if ODE87_check
            int_step = -0.1;
        end
        initials = initials(1):int_step:initials(length(initials));%epochs(5872):int_step:epochs(5873);
        %init_state = orbit_rkv89_emb(:,5872);
        %ytol = 0.000001;
        desired_t_for_maneuver = 0;
        state_at_desired_t = zeros(42,1);
        yvalue = 0; % Desired value of y-component of the sat in L2centered frame
        
        
        while ~found
            %options = odeset('RelTol',1e-8,'AbsTol',1e-10,'MaxStep', 0.1,'InitialStep',0.001);
            %options = odeset('MaxStep', 1,'InitialStep',0.1);
            [ti, oiE] = ode45(@simplified_force_model_srp, initials, init_state);  
            ti = ti';
            oiE = oiE';
            oiE = [oiE;ti];
            % now in this oi array I have to check second row to find the
            % closest to 0 +- tolerance
            oi = zeros(43,length(ti)); % 7 without monodromy matrix, 43 with
            L2_points = cspice_spkezr('392', ti, 'J2000', 'NONE', '399');
            
            oiEminusL2 = oiE;
            oiEminusL2(1:6,:) = oiE(1:6,:) - L2_points;
            
            % Convert to L2centered
            xform = cspice_sxform('J2000','L2CENTERED', ti);
            for g = 1:length(ti) % oeE
                phi = reshape(oiEminusL2(7:42,g), 6, 6);
                phi = xform(:,:,g)*phi*xform(:,:,g)^(-1);
                phi = reshape(phi, 36,1);
                oi(1:6,g) = xform(:,:,g)*oiEminusL2(1:6,g);
                oi(7:42,g) = phi;
                oi(43,g) = ti(g);
            end
           
            % Check from which side we approach zero. Check the first value
            syms negative_positive;
            if oi(2,1) < 0
               negative_positive = true;
            else 
               negative_positive = false;
            end
            
            center_epoch = floor(length(ti)/2); % integer epoch
           % disp(center_epoch);
            center_state = oi(1:42,center_epoch);
            % need init state in Earth frame for future load into
            % integrator
            center_stateE = oiE(1:42,center_epoch);
            %disp(center_stateE);
            ycenter = oi(2,center_epoch);
            center_t = oi(43,center_epoch);
           % disp(ycenter);
           % disp(center_t);
            
            % Second part of the orbit, y goes from + thorugh 0 towards -
            % Have to check for that and switch conditions
            
            if negative_positive == true
                % Goes from negative to positive
                if ycenter >= yvalue 
                    initials = [initials(1) center_t]; 
                  %  disp('bigger');
                end

                if ycenter < yvalue 
                    initials = [center_t initials(length(initials))]; 
                    init_state = center_stateE;
                   % disp('smaller');
                end
                
            else
                % Goes from positive to negative
                if ycenter >= yvalue 
                    initials = [center_t initials(length(initials))]; 
                    init_state = center_stateE; 
                  %  disp('bigger');
                end

                if ycenter < yvalue 
                    initials = [initials(1) center_t]; 
                   % disp('smaller');
                end
            
            end
             left_border = yvalue - ytol;
             right_border = yvalue + ytol;
             
             if ycenter <= right_border && ycenter >= left_border
                 %index = find(abs(oi(2,:))<ytol); 
                 [closest_value, N] = min((abs(oi(2,:))));
                 desired_t_for_maneuver = oi(43,N);
                 %state_at_desired_t = oi(1:6,N); % If I wanted L2frame
                 state_at_desired_t = oi(1:42,N);
                 state_Earth = oiE(1:42,N);
                 disp(closest_value);
                 found = true;       
             end
            
        end
end


