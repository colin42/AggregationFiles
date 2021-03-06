%% General Conditions %%
T = 300;                % Temperature (K)
Vn = 512.0;             % Atom size (Angstroms Cubed/Atom)
N = 27;                 % Number of Atoms
Vol = N * Vn;           % Total Volume (Angstroms^3)
side = Vol^(1.0/3.0);   % Length of Side of Simulation Volume (Angstrom)
dt = 1;                 % Time Step (fs)
MW = 16.0;              % Molecular Weight (Grams/mole)
halfSide = 0.5 * side;  % Half of the Side (Angstrom)
density = 1 / Vn;       % Molar Density (Atom/Angstrom)
Na = 6.022e+23;         % Avogadro's Number (Atoms)
eps = 136;              % Depth of the Potential Well (eV)              ***
sigma = 3.884;          % Collision Diameter (Angstroms)                
rCut = 15;              % Cut-off Distance (Angstroms)
Q = 0;                  % Charge of Atom (Coulomb)                      ***
e0 = 8.854187;          % Vacuum Permittivity (Farads/metre)            ***
kb = 1.38066e-5;        % Boltzmann's Constant (aJ/molecule/K)          ***
maxStep = 2000;         % Upper bound for iterations
U = 0;                  % Potential Energy (J)                          ***
sampleIntval = 1;       % Sampling Interval
nbrIntval = 10;         % Neighbor's List Update Interval
writeIntval = 100;      % Writing Interval
nProp = 4;              % Number of Properties

%% Property Initialization %%
% Here we have matrices of N atoms/particles containing their mechanical
% propeties.

particles = Particle([]); 

%% Initial Computations and Correction Balancing Variables %%
mass = (MW / (Na / 1000)) * 1.0e+28;        % (1e-28 * kg / molecule)
Tcorr = (3.0 * N * kb * T) / mass;          % Temperature Correction Factor (Angstrom/fs)^2
dtva = [dt (dt * dt) (dt * dt * dt) (dt * dt * dt * dt) (dt * dt * dt * dt * dt)];      % Gear Correction Factor
fv = [1 2 6 24 120];                        % Vector of Factorials
dtv = dtva./fv;                             % Gear Correction Factor
rNbr = rCut + 3.0;                          % Radius Defining if Particle is a Neighbours (Angstrom)
rCut2 = rCut * rCut;
rNbr2 = rNbr * rNbr;
rCut3 = rCut^3;
rCut9 = rCut^9;

% Corrector Coefficients for Gear Using Dimensioned Variables
% "Where is the equation/formula for all these? %
gear = [(3.0 / 2.0) (251.0 / 360.0) (1.0) (11.0 / 18.0) (1.0 / 6.0) (1.0 / 60.0)];
dtv6 = [1 dt (dt * dt) (dt * dt * dt) (dt * dt * dt * dt) (dt * dt * dt * dt * dt)];
fv6 = [1 1 2 6 24 120];
alpha(1:6) = gear(1:6)./(dtv6(1:6).*fv6);
alpha = (alpha * dt^2) / 2;

%% Initialize Positions %%
particles = PositionInitialization(N, side, particles);   % Get initial position for particles
pos = zeros(N, 3);                                        % Pre-allocation of memory
for i = 1:3
   pos(:,i) = GetVectorProps(particles, N, i);            % Position vector for particles                
end

% Generate plot for initial position
plot3(pos(:,1), pos(:,2), pos(:,3), 'o', 'MarkerFaceColor', 'k');
xlabel('x'), ylabel('y'), zlabel('z'), title('Coordinates of Particles');
zlim([0 ceil(side)]), ylim([0 ceil(side)]), zlim([0 ceil(side)]);
grid on

%% Initialize System Potential %%

ULJ = LennardJones(eps, sigma, rCut);       % Lennard-Jones Potential (eV)
UCoulomb = Q^2 / (4 * pi * e0 * rCut);      % Coulomb Potential (eV)
UTot = ULJ + UCoulomb;                      % Meaure of bonding potential and total system energy

%% Initial Velocity %%
% Initialize the velocity of particles with zerno net momentum in the
% system.

particles = VelocityInitialize(particles, N, Tcorr);

%% Neighbour List %%
% Compute distance between all pairs of particles

particles = ComputeDistance(particles, N, rNbr2);


%% Subroutines %%
% The following methods will compute thew new position of particles,
% evaluate the forces in the system, correct position computations based on
% repulsiong/attractive forces and gear corrector, apply the periodic
% boundary conditions, scale velocity, update neighbours list and print the
% results for each time step up until the max time.

for t = 1:maxStep
   particles = PositionPredictor(particles, N, dtv); 
end