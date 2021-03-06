function yp = force_model( t,y0 )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

%G=6.673e-20; %always e-20
global G;
global L2frame;

observer = '399';%'EARTH';
full = 0; % 1 full, 0 Sun Earth Moon        NB! Show to Meltem with full = 1; Full Model + SRP gives interesting result
SRP_ON = 1; % 1 on 0 off 

%Use this for all bodies in solar system
planets = {'EARTH','SUN','MOON','JUPITER','VENUS','MARS','SATURN';'EARTH','SUN','301','5','VENUS','4','6'};

% Use this for Earth, Sun and Moon
%planets_simplified = {'EARTH', 'SUN', 'MOON';'EARTH', 'SUN', '301'};
% 
% if L2frame == true
%     xform = cspice_sxform('J2000','L2CENTERED', t);
%     y0 = xform*y0;
% end

 % bodies - vector of structures
 % Create a structure for the satellite
sat = create_sat_structure(y0);

% Use this for all bodies in solar system
[earth, sun, moon, jupiter, venus, mars, saturn] = create_structure( planets, t, observer);

% Use this for Earth, Sun and Moon
%[earth, sun, moon] = simplified_create_structure( planets_simplified, t, observer);
 
%% Accelerations due to:

% GRAVITY

% y0 - satellite, rows: x y z vx vy vz
% Radiuses between the body and the satellite
R_earth = sqrt((sat.x - earth.x)^2 + (sat.y - earth.y)^2 +  (sat.z - earth.z)^2);
R_sun = sqrt((sun.x - sat.x)^2 + (sun.y - sat.y)^2 +  (sun.z - sat.z)^2);
R_moon = sqrt((moon.x - sat.x)^2 + (moon.y - sat.y)^2 +  (moon.z - sat.z)^2);
R_jupiter = sqrt((jupiter.x - sat.x)^2 + (jupiter.y - sat.y)^2 +  (jupiter.z - sat.z)^2);
R_venus = sqrt((venus.x - venus.x)^2 + (venus.y - sat.y)^2 +  (venus.z - sat.z)^2);
R_mars = sqrt((mars.x - sat.x)^2 + (mars.y - sat.y)^2 +  (mars.z - sat.z)^2);
R_saturn = sqrt((saturn.x - sat.x)^2 + (saturn.y - sat.y)^2 +  (saturn.z - sat.z)^2);

% Radiuses between celestial bodies
R_earth_sun = sqrt((sun.x - earth.x)^2 + (sun.y - earth.y)^2 +  (sun.z - earth.z)^2);
R_earth_moon = sqrt((moon.x - earth.x)^2 + (moon.y - earth.y)^2 +  (moon.z - earth.z)^2);
R_earth_jupiter = sqrt((jupiter.x - earth.x)^2 + (jupiter.y - earth.y)^2 +  (jupiter.z - earth.z)^2);
R_earth_venus = sqrt((venus.x - earth.x)^2 + (venus.y - earth.y)^2 +  (venus.z - earth.z)^2);
R_earth_mars = sqrt((mars.x - earth.x)^2 + (mars.y - earth.y)^2 +  (mars.z - earth.z)^2);
R_earth_saturn = sqrt((saturn.x - earth.x)^2 + (saturn.y - earth.y)^2 +  (saturn.z - earth.z)^2);

% Earth is a primary body here

% 20/11 changed some stuff. For backup see commits before 20/11

%earth_influence = -((G*(earth.mass + sat.mass))*(sat.coords - earth.coords))/((R_earth)^3);
earth_influence = -(earth.GM*(sat.coords - earth.coords))/((R_earth)^3);
sun_influence = (sun.GM*(((sun.coords - sat.coords)/R_sun^3) -  ((sun.coords - earth.coords)/R_earth_sun^3)));
moon_influence = (moon.GM*(((moon.coords - sat.coords)/R_moon^3) -  ((moon.coords - earth.coords)/R_earth_moon^3)));
jupiter_influence = (jupiter.GM*(((jupiter.coords - sat.coords)/R_jupiter^3) -  ((jupiter.coords - earth.coords)/R_earth_jupiter^3)));
venus_influence = (venus.GM*(((venus.coords - sat.coords)/R_venus^3) -  ((venus.coords - earth.coords)/R_earth_venus^3)));
mars_influence = (mars.GM*(((mars.coords - sat.coords)/R_mars^3) -  ((mars.coords - earth.coords)/R_earth_mars^3)));
saturn_influence = (saturn.GM*(((saturn.coords - sat.coords)/R_saturn^3) -  ((saturn.coords - earth.coords)/R_earth_saturn^3)));

if full == 1 
a_earth_sat =  earth_influence + sun_influence + moon_influence + jupiter_influence + venus_influence + mars_influence + saturn_influence;
else 
a_earth_sat =  earth_influence + sun_influence + moon_influence;
end

global influence;

influence(:,1) = a_earth_sat;


%% Solar Pressure
if SRP_ON == 1
solar_a = srp(2, earth, sun, sat); % 0 stands for type of formula, can be 1 as well;
solar_a = solar_a';
else
solar_a = zeros(3,1);
end

influence(:,2) = solar_a;

%% Maneuvers
% global t_at_etvector;
% if t == t_at_etvector
% maneuver = [-0.02263165253058913;0.02267983525317713;-0.001364259283054504]; 
% else
% maneuver = [0;0;0]; 
% end

%% Total Acceleration for a given planet
yp=zeros(6,1);


yp(1)=y0(4);
yp(2)=y0(5);
yp(3)=y0(6);

yp(4)= a_earth_sat(1) + solar_a(1);% + maneuver(1);
yp(5)= a_earth_sat(2) + solar_a(2);% + maneuver(2);
yp(6)= a_earth_sat(3) + solar_a(3);% + maneuver(3);


%disp(solar_a);
end
