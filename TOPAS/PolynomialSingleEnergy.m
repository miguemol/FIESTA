% Script for importing data from the following text file:
%
%    filename: /Users/dani/Google Drive/Trabajo/UCM/01-Proyectos/20-FLASH/Sims_TOPAS/puntual/1MeV/Fluence.csv
%
% Auto-generated by MATLAB on 12-Dec-2019 12:55:22

% # Results for scorer Fluence
% # R in 100 bins of 0.01 cm
% # Phi in 1 bin  of 360 deg
% # Z in 2000 bins of 0.02 cm
% # Fluence ( /mm2 ) : Sum   

%% Setup the Import Options
opts = delimitedTextImportOptions("NumVariables", 4);

% Specify range and delimiter
opts.DataLines = [9, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["A", "B", "C", "D"];
opts.VariableTypes = ["double", "double", "double", "double"];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% CHOOSE DESIRED ENERGY
tblFlu = readtable(fullfile('3MeV','Fluence.csv'), opts);
tblEdep = readtable(fullfile('3MeV', 'EnergyDep.csv'), opts);

close all

flu=tblFlu.D;
Edep=tblEdep.D;
NR = 100;
NZ=2000;
dR = 0.01;
dZ = 0.02;


flu = reshape(flu, [NZ NR]);
Edep = reshape(Edep, [NZ NR]);

%Dose calculation
rho=1;
A=pi*([0.005:0.01:0.995].^2-[0,0.005:0.01:0.985].^2);
Atot=sum(A);
Dose=Edep.*(rho*dZ*A).^(-1);
DoseZ=sum(Dose.*A,2)/Atot; %Total Dose per plane

clear rho A Atot

%Fitting Bin Range
NZfluMin=35;
NZEdepMin=35;
NZfluMax=90;
NZEdepMax=70;

% Calculate Range
sumflu=sum(flu,2);
sumEdep=sum(Edep,2);
NZflu=Range(sumflu)-NZfluMax;
NZEdep=Range(sumEdep)-NZEdepMax;
flu=flu(1:NZflu,:);
Edep=Edep(1:NZEdep,:);
Dose=Dose(1:NZ,:);

Rvalues = dR*(1:NR) - dR/2;
Zvaluesflu = dZ*(1:NZflu) - dZ/2;
ZvaluesEdep = dZ*(1:NZEdep) - dZ/2;

%% Sigma for the Fluence
Sflu = nan(1, NZflu);
maxFitIgnored = 0;
for i=1:NZflu
    try
        F1 = fit(Rvalues', flu(i,:)', 'gauss1');
        Sflu(i) = F1.c1 / sqrt(2);        
    catch
        maxFitIgnored = i;
    end
end
maxFitIgnored = maxFitIgnored +NZfluMin;
Sflu(1:maxFitIgnored) = dR;
fprintf('Polynomial Fluence: Fittingin the range %4.2f <= Z < %4.2f\n', Zvaluesflu(maxFitIgnored), Zvaluesflu(length(Zvaluesflu)));

% pflu=polyfit(Zvalues,Sflu,2); %% polyfit no permite restringir valores
F = fit(Zvaluesflu(maxFitIgnored+1:length(Zvaluesflu))', Sflu(maxFitIgnored+1:length(Sflu))', 'poly2', 'Lower', [0 0 0]);
pflu = coeffvalues(F);

%% Sigma for the Edep
SEdep = nan(1, NZEdep);
maxFitIgnored = 0;
for i=1:NZEdep
    try
        F1 = fit(Rvalues', Edep(i,:)', 'gauss1');
        SEdep(i) = F1.c1 / sqrt(2);        
    catch
        maxFitIgnored = i;
    end
end
maxFitIgnored = maxFitIgnored + NZEdepMin;
SEdep(1:maxFitIgnored) = dR;
fprintf('Polynomial Edep: Fitting in the range %4.2f <= Z < %4.2f\n', ZvaluesEdep(maxFitIgnored), ZvaluesEdep(length(ZvaluesEdep)));

F=fit(ZvaluesEdep(maxFitIgnored+1:length(ZvaluesEdep))',SEdep(maxFitIgnored+1:length(SEdep))','poly2', 'Lower', [0 0 0]);
pEdep = coeffvalues(F);

clear F F1 NR NZ dR dZ

%Figures
SfluInterp=polyval(pflu,Zvaluesflu);
figure
plot(Zvaluesflu, Sflu, 'r.')
hold on
plot(Zvaluesflu,SfluInterp, 'b-')

ylabel('Sigma (cm)')
xlabel('Z (cm)')
title('Fluence')

SEdepInterp=polyval(pEdep,ZvaluesEdep);
figure
plot(ZvaluesEdep,SEdepInterp)
hold on
plot(ZvaluesEdep, SEdep, 'r.')
ylabel('Sigma (cm)')
xlabel('Z (cm)')
title('Energy deposition')

pflu
pEdep

P=[pflu;pEdep];

