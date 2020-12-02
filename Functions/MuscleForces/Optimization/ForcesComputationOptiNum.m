function [MuscleForcesComputationResults] = ForcesComputationOptiNum(filename, BiomechanicalModel, AnalysisParameters)
% Computation of the muscle forces estimation step by using an optimization method
%
%	Based on :
%	- Crowninshield, R. D., 1978.
%	Use of optimization techniques to predict muscle forces. Journal of Biomechanical Engineering, 100(2), 88-92.
%
%   INPUT
%   - filename: name of the file to process (character string)
%   - BiomechanicalModel: musculoskeletal model
%   - AnalysisParameters: parameters of the musculoskeletal analysis,
%   automatically generated by the graphic interface 'Analysis'
%   OUTPUT
%   - MuscleForcesComputationResults: results of the muscle forces
%   estimation step (see the Documentation for the structure)
%________________________________________________________
%
% Licence
% Toolbox distributed under GPL 3.0 Licence
%________________________________________________________
%
% Authors : Antoine Muller, Charles Pontonnier, Pierre Puchaud and
% Georges Dumont
%________________________________________________________
disp(['Forces Computation (' filename ') ...'])

%% Loading variables

load([filename '/ExperimentalData.mat']); %#ok<LOAD>
time = ExperimentalData.Time;
freq = 1/time(2);

Muscles = BiomechanicalModel.Muscles;
load([filename '/InverseKinematicsResults']) %#ok<LOAD>
load([filename '/InverseDynamicsResults']) %#ok<LOAD>



q=InverseKinematicsResults.JointCoordinates;
torques =InverseDynamicsResults.JointTorques;


Nb_q=size(q,1);
Nb_frames=4;%size(torques,2);

%existing muscles
idm = logical([Muscles.exist]);
Nb_muscles=numel(Muscles(idm));

if ~isempty(intersect({BiomechanicalModel.OsteoArticularModel.name},'root0'))
    BiomechanicalModel.OsteoArticularModel=BiomechanicalModel.OsteoArticularModel(1:end-6);
end

%% computation of muscle moment arms from joint posture
L0=ones(Nb_muscles,1);
Ls=ones(Nb_muscles,1);
for i=1:Nb_muscles
    Muscle_i = BiomechanicalModel.Muscles(i);
    if ~isempty(Muscle_i.ls) && ~isempty(Muscle_i.l0)
        L0(i) = Muscle_i.l0;
        Ls(i) = Muscle_i.ls;
    end
end
Lmt=zeros(Nb_muscles,Nb_frames);
R=zeros(Nb_q,Nb_muscles,Nb_frames);
R(:,:,1)    =   MomentArmsComputationNum(BiomechanicalModel,q(:,1),0.0001); %depend on reduced set of q (q_red)

 for i=1:Nb_frames % for each frames
     Lmt(idm,i)   =   MuscleLengthComputationNum(BiomechanicalModel,q(:,i)); %dependant of every q (q_complete)
     R(:,:,i)    =   MomentArmsComputationNum(BiomechanicalModel,q(:,i),0.0001); %depend on reduced set of q (q_red)
 end
% %load('/home/clivet/Documents/Thèse/Developpement_CusToM/thesis/Fichiers_tests/Donnees a traiter/Ana Lucia Data - Sbj 1 - Trial 1 - Forearm model/Throwing_1/MuscleForcesComputationResults.mat');
% R=   MuscleForcesComputationResults.MuscleLeverArm ;

% R=bras_levier_litt(BiomechanicalModel,R);

Lm = Lmt(idm,:)./(Ls./L0+1);
% Muscle length ratio to optimal length
Lm_norm = Lm./L0;
% Muscle velocity
Vm = gradient(Lm_norm)*freq;

[idxj,~]=find(sum(R(:,:,1),2)~=0);
% nvR=flechis_extens(2);
% [idxj,~]=find(sum(nvR,2)~=0);

%% Computation of muscle forces (optimization)
% Optimisation parameters

Amin = zeros(Nb_muscles,1);
A0  = zeros(Nb_muscles,1);
for i=1:size(idm,2)
    Muscles(i).f0 = 100*Muscles(i).f0;
end
Fmax = [Muscles(idm).f0]';
Amax = ones(Nb_muscles,1);
Fopt = zeros(Nb_muscles,Nb_frames);
Aopt = zeros(size(Fopt));
% Muscle Forces Matrices computation
[Fa,Fp]=AnalysisParameters.Muscles.MuscleModel(Lm,Vm,Fmax);
% Solver parameters
options1 = optimoptions(@fmincon,'Algorithm','sqp','Display','final','GradObj','off','GradConstr','off','TolFun',1e-4,'TolCon',1e-6,'MaxIterations',100000,'MaxFunEvals',100000);
options2 = optimoptions(@fmincon,'Algorithm','sqp','Display','final','GradObj','off','GradConstr','off','TolFun',1e-4,'TolCon',1e-6,'MaxIterations',1000,'MaxFunEvals',2000000);





h = waitbar(0,['Forces Computation (' filename ')']);

if isfield(BiomechanicalModel.OsteoArticularModel,'ClosedLoop') && ~isempty([BiomechanicalModel.OsteoArticularModel.ClosedLoop])    
    % TO BE CHANGED AFTER CALIBRATION
    k=ones(size(q,1),1);

        
    [solid_path1,solid_path2,num_solid,num_markers]=Data_ClosedLoop(BiomechanicalModel.OsteoArticularModel);

    dependancies=KinematicDependancy(BiomechanicalModel.OsteoArticularModel);
    % Closed-loop constraints
    KT(:,:,1)=ConstraintsJacobian(BiomechanicalModel,q(:,1),solid_path1,solid_path2,num_solid,num_markers,k,0.0001,dependancies)';
    [idKT,~]=find(sum(KT(:,:,1),2)~=0);
    %idq=unique(union(idKT,idxj));
    % Baleck de l'épaule
    idxj=setdiff(idxj,[8,9,10,11,12,13]);
    idq=unique(union(idKT,idxj)); 
    
    % Creation of virtual torques
  %     Z=eye(length(idq));
 
    % Adaptation of variables to closed-loop problem    
    indc=length([A0a ; randn(size(KT,2),1)]) +1;
  %  A0 = [A0a ; zeros(size(KT,2),1) ; zeros(size(Z,2),1)];
   A0 = [A0a ; randn(size(KT,2),1)];
   % Aopt = [Aopt; zeros(size(KT,2),Nb_frames); zeros(size(Z,2),Nb_frames)];
   Aopt = [Aopt; zeros(size(KT,2),Nb_frames)];
    Amin = [Amin ;-inf*ones(size(KT,2),1) ];
    Fmax = [Fmax ;inf*ones(size(KT,2),1)];
   Amax = [Amax ;inf*ones(size(KT,2),1)];
%      Amin = [Amin ;-inf*ones(size(KT,2),1);-inf*ones(size(Z,2),1)];
%      Fmax = [Fmax ;inf*ones(size(KT,2),1);inf*ones(size(Z,2),1)];
%      Amax = [Amax ;inf*ones(size(KT,2),1);inf*ones(size(Z,2),1)];
    % Moment arms and Active forces
   Aeq = [R(idq,:,1).*Fa(:,1)' KT(idq,:,1)];
  %Aeq = [R(idq,:,1).*Fa(:,1)' KT(idq,:,1) Z];
    % Joint Torques
    beq = torques(idq,1) - R(idq,:,1)*Fp(:,20);
    
   %A0 = [A0a ; zeros(size(KT,2),1) ; beq];

    
    C=zeros(length(A0)-indc+1,Nb_frames);
    % First frame optimization
    [Aopt(:,1)] = AnalysisParameters.Muscles.Costfunction(A0, Aeq, beq, Amin, Amax, options1, AnalysisParameters.Muscles.CostfunctionOptions, Fa(:,1), Fmax,time(2));
    % Muscular activiy
    A0 = Aopt(:,1);
    Fopt(:,1) = Fa(:,1).*Aopt(1:Nb_muscles,1)+Fp(:,1);
    C(:,1)=Aopt(indc:end,1);

    waitbar(1/Nb_frames)
    
    for i=2:Nb_frames % for following frames
     %   i
        % Closed-loop constraints
        KT(:,:,i)=ConstraintsJacobian(BiomechanicalModel,q(:,i),solid_path1,solid_path2,num_solid,num_markers,k,0.0001,dependancies)';
        % Moment arms and Active forces
        Aeq = [R(idq,:,i).*Fa(:,i)' KT(idq,:,i)];
%    Aeq = [R(idq,:,i).*Fa(:,i)' KT(idq,:,i) Z];
        % Joint Torques
        beq=torques(idq,i)- R(idq,:,i)*Fp(:,i);
         
        %A0 = [A0a ; zeros(size(KT,2),1) ; beq];

        % Optimization
        [Aopt(:,i)] = AnalysisParameters.Muscles.Costfunction(A0, Aeq, beq, Amin, Amax, options2, AnalysisParameters.Muscles.CostfunctionOptions, Fa(:,i), Fmax,time(2));
        % Muscular activity
         A0=Aopt(:,i);
        Fopt(:,i) = Fa(:,i).*Aopt(1:Nb_muscles,i)+Fp(:,i);
        C(:,i)=Aopt(indc:end,i);
        waitbar(i/Nb_frames)
    end
    
    % Static optimization results
    MuscleForcesComputationResults.MuscleActivations(idm,:) = Aopt(1:Nb_muscles,:);
    MuscleForcesComputationResults.MuscleForces(idm,:) = Fopt;
    MuscleForcesComputationResults.MuscleLengths= Lmt;
    MuscleForcesComputationResults.MuscleLeverArm = R;
    MuscleForcesComputationResults.Constraints = C;
    MuscleForcesComputationResults.KT = KT;
    MuscleForcesComputationResults.lambda=Aopt(Nb_muscles+1:indc-1,:);
    
else
    % Moment arms and Active forces
    Aeq=R(idxj,:,1).*Fa(:,1)';
    % Joint Torques and Passive force
    beq=torques(idxj,1) - R(idxj,:,1)*Fp(:,1);
    % First frame optimization
    [Aopt(:,1)]  = AnalysisParameters.Muscles.Costfunction(A0, Aeq, beq, Amin, Amax, options1, AnalysisParameters.Muscles.CostfunctionOptions, Fa(:,1), Fmax,time(2));
    % Muscular activity
     A0=Aopt(:,1);
    %           A0=randn(size(A0));

    Fopt(:,1) = Fa(:,1).*Aopt(:,1)+Fp(:,1);
    waitbar(1/Nb_frames)
    for i=2:Nb_frames % for folliwing frames
      %  i
        % Moment arms and Active forces
        Aeq=R(idxj,:,i).*Fa(:,i)';
        % Joint Torques and Passive force
        beq=torques(idxj,i) - R(idxj,:,i)*Fp(:,i);
        % Optimization
        [Aopt(:,i)] = AnalysisParameters.Muscles.Costfunction(A0, Aeq, beq, Amin, Amax, options2, AnalysisParameters.Muscles.CostfunctionOptions, Fa(:,i), Fmax,length(A0));        
        % Muscular activity
        
         A0=Aopt(:,i);
%          A0=randn(size(A0));
        Fopt(:,i) = Fa(:,i).*Aopt(:,i)+Fp(:,i);
        waitbar(i/Nb_frames)

    end
    
    % Static optimization results
    MuscleForcesComputationResults.MuscleActivations(idm,:) = Aopt;
    MuscleForcesComputationResults.MuscleForces(idm,:) = Fopt;
    MuscleForcesComputationResults.MuscleLengths= Lmt;
    MuscleForcesComputationResults.MuscleLeverArm = R;
    MuscleForcesComputationResults.Constraints = C;
    MuscleForcesComputationResults.K = C;
    
    
end

close(h)

disp(['... Forces Computation (' filename ') done'])


end