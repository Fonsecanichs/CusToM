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
load([filename '/ExternalForcesComputationResults.mat']); %#ok<LOAD>
if AnalysisParameters.ID.InputData == 0
    ExtForces = ExternalForcesComputationResults.NoExternalForce;
elseif AnalysisParameters.ID.InputData == 1
    ExtForces = ExternalForcesComputationResults.ExternalForcesExperiments;
elseif AnalysisParameters.ID.InputData == 2
    ExtForces = ExternalForcesComputationResults.ExternalForcesPrediction;
end



time = ExperimentalData.Time;
freq = 1/time(2);

Muscles = BiomechanicalModel.Muscles;
load([filename '/InverseKinematicsResults']) %#ok<LOAD>
load([filename '/InverseDynamicsResults']) %#ok<LOAD>



q=InverseKinematicsResults.JointCoordinates;
torques =InverseDynamicsResults.JointTorques;

Nb_q=size(q,1);

if ~isempty(intersect({BiomechanicalModel.OsteoArticularModel.name},'root0'))
    BiomechanicalModel.OsteoArticularModel=BiomechanicalModel.OsteoArticularModel(1:end-6);
end

Nb_frames=3,;%1/0.005; %size(torques,2);

%existing muscles
idm = logical([Muscles.exist]);
Nb_muscles=numel(Muscles(idm));

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
for i=1:Nb_frames % for each frames
    Lmt(idm,i)   =   MuscleLengthComputationNum(BiomechanicalModel,q(:,i)); %dependant of every q (q_complete)
    R(:,:,i)    =   MomentArmsComputationNum(BiomechanicalModel,q(:,i),0.0001); %depend on reduced set of q (q_red)
end

% R=bras_levier_litt(BiomechanicalModel,R);

Lm = Lmt(idm,:)./(Ls./L0+1);
% Muscle length ratio to optimal length
Lm_norm = Lm./L0;
% Muscle velocity
Vm = gradient(Lm_norm)*freq;

[idxj,~]=find(sum(R(:,:,1),2)~=0);
idxj=23:29;

% nvR=flechis_extens(2);
% [idxj,~]=find(sum(nvR,2)~=0);

%% Computation of muscle forces (optimization)
% Optimisation parameters

Amin = zeros(Nb_muscles,1);
A0a  = zeros(Nb_muscles,1);
for i=1:size(idm,2)
    Muscles(i).f0 = 100*Muscles(i).f0;
end
Fmax = [Muscles(idm).f0]';
Amax = ones(Nb_muscles,1);
Fopt = zeros(Nb_muscles,Nb_frames);
Aopt = zeros(size(Fopt));
% Muscle Forces Matrices computation
if isfield(AnalysisParameters.Muscles,'MuscleModel')
    [Fa,Fp]=AnalysisParameters.Muscles.MuscleModel(Lm,Vm,Fmax);
else
    [Fa,Fp]=SimpleMuscleModel(Lm,Vm,Fmax);
end
% Solver parameters
options1 = optimoptions(@fmincon,'Algorithm','sqp','Display','off','GradObj','off','GradConstr','off','TolFun',1e-4,'TolCon',1e-6,'MaxIterations',100000,'MaxFunEvals',100000);
options2 = optimoptions(@fmincon,'Algorithm','sqp','Display','off','GradObj','off','GradConstr','off','TolFun',1e-4,'TolCon',1e-6,'MaxIterations',100000,'MaxFunEvals',2000000);





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
        [Aopt(:,i)] = AnalysisParameters.Muscles.Costfunction(A0, Aeq, beq, Amin, Amax, options2, AnalysisParameters.Muscles.CostfunctionOptions, Fa(:,i), Fmax);
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
    effector = [29 2]; %Effector : hand(29) and marker end of hand (2)
    %Effectors : Solids RFOOT (22), LFOOT (28) and markers anat_position RTOE (3), LTOE (3)
    i_eff = 1;
    for solid_eff=effector(:,1)' %among the effector solids
        if solid_eff == 29 %RHand (29)
            SolidConcerned_eff = find_solid_path(BiomechanicalModel.OsteoArticularModel,solid_eff,7); %list of solids between solid_eff and Thorax (7)
%         elseif (solid_eff==22) || (solid_eff == 28) %RFoot (22) or LFoot (28)
%             SolidConcerned_eff = find_solid_path(BiomechanicalModel.OsteoArticularModel,solid_eff,1); %list of solids between solid_eff and PelvisSacrum (1)
        end
        MuscleConcerned_eff = []; %construction of MuscleConcerned
        for i=1:Nb_muscles
            if ~isempty(intersect(BiomechanicalModel.Muscles(i).num_solid(1),SolidConcerned_eff)) || ~isempty(intersect(BiomechanicalModel.Muscles(i).num_solid(end),SolidConcerned_eff)) %verifying that the first
                %and last solids connected to the muscle belong to
                %SolidConcerned_eff
                MuscleConcerned_eff = [MuscleConcerned_eff i];
            end
        end
        SolidConcerned(i_eff).list = SolidConcerned_eff;
        MuscleConcerned(i_eff).list = MuscleConcerned_eff;
        i_eff = i_eff + 1;
    end
    % Moment arms and Active forces
    Aeq=R(idxj,:,1).*Fa(:,1)';
    % Joint Torques and Passive force
    beq=torques(idxj,1) - R(idxj,:,1)*Fp(:,1);
    %Ktmax
    options = optimoptions('fmincon','Algorithm','sqp','Display','off',);
    Amin = zeros(Nb_muscles,1);
    A0 = 0.5*ones(Nb_muscles,1);
    Amax = ones(Nb_muscles,1);
    i_eff=1;
    i=1;
    Ktmax=[];
    for solid_eff=effector(:,1)'
        Fext = ExtForces(1).fext(solid_eff);
        Fext = Fext.fext(1:3,1);
        dp=0.0001;
        dRdqtemp = DerivateMomentArmsComputationNum(BiomechanicalModel,q(:,i),dp,SolidConcerned(i_eff).list);
        dRdq{i_eff}=dRdqtemp(idxj,:,idxj);
        Jtemp = diffdXdq(effector(i_eff,:), SolidConcerned(i_eff).list, BiomechanicalModel, q(:,i), dp);
        J{i_eff} = Jtemp(:,idxj);
        dJdqtemp= diff2dXdq(effector(i_eff,:), SolidConcerned(i_eff).list, BiomechanicalModel, q(:,i), dp);
        dJdq{i_eff} = dJdqtemp(idxj,:,idxj);
        [~,fval] = fmincon(@(A) funKtmax(A,BiomechanicalModel,MuscleConcerned(i_eff).list,Fext,Fa(:,i),Fp(:,i),R(idxj,:,i),dRdq{i_eff},J{i_eff},dJdq{i_eff}),A0,[],[],[],[],zeros(Nb_muscles,1),ones(Nb_muscles,1),[],options);
        Ktmax = [Ktmax -fval];
        i_eff=i_eff+1;
    end
    % Optimization
    Amin = zeros(Nb_muscles,1);
    A0 = 0.5*ones(Nb_muscles,1);
    Amax = ones(Nb_muscles,1);
    [Aopt(:,i)]=AnalysisParameters.Muscles.Costfunction(A0,Aeq,beq, Amin, Amax, options1, [],AnalysisParameters.Muscles.CostfunctionOptions,BiomechanicalModel,MuscleConcerned,Fext, Fa(:,i),Fp(:,i),R(idxj,:,i),dRdq,J,dJdq, AnalysisParameters.StiffnessPercent, Ktmax);
    % Muscular activity
    A0=Aopt(:,1);
    %           A0=randn(size(A0));
    
    Fopt(:,1) = Fa(:,1).*Aopt(:,1)+Fp(:,1);
    waitbar(1/Nb_frames)
    

    
    %initialisation
    Kt=cell(numel(effector(:,1)),Nb_frames);
    FMT = Fopt(:,i);
    i_eff = 1;
    for solid_eff=effector(:,1)'
        Fext = ExtForces(1).fext(solid_eff);
        Fext = Fext.fext(1:3,1); %external forces applied to the solid_eff at the first frame
        Kt(i_eff,i) = {TaskStiffness(BiomechanicalModel,MuscleConcerned(i_eff).list,Fext, FMT,R(idxj,:,i),dRdq{i_eff},J{i_eff},dJdq{i_eff})};
        i_eff = i_eff+1;
    end
    %     MuscleForcesComputationResults.TaskStiffness(1) = {Kt(:,1)};
    
    for i=2:Nb_frames % for following frames
        % Moment arms and Active forces
        Aeq=R(idxj,:,i).*Fa(:,i)';
        % Joint Torques and Passive force
        beq=torques(idxj,i) - R(idxj,:,i)*Fp(:,i);
        i_eff=1;
        Ktmax=[];
        for solid_eff=effector(:,1)'
            Fext = ExtForces(i).fext(solid_eff);
            Fext = Fext.fext(1:3,1);
            dp=0.0001;
            dRdqtemp = DerivateMomentArmsComputationNum(BiomechanicalModel,q(:,i),dp,SolidConcerned(i_eff).list);
            dRdq{i_eff}=dRdqtemp(idxj,:,idxj);
            Jtemp = diffdXdq(effector(i_eff,:), SolidConcerned(i_eff).list, BiomechanicalModel, q(:,i), dp);
            J{i_eff} = Jtemp(:,idxj);
            dJdqtemp= diff2dXdq(effector(i_eff,:), SolidConcerned(i_eff).list, BiomechanicalModel, q(:,i), dp);
            dJdq{i_eff} = dJdqtemp(idxj,:,idxj);
            [~,fval] = fmincon(@(A) funKtmax(A,BiomechanicalModel,MuscleConcerned(i_eff).list,Fext,Fa(:,i),Fp(:,i),R(idxj,:,i),dRdq{i_eff},J{i_eff},dJdq{i_eff}),A0,[],[],[],[],zeros(Nb_muscles,1),ones(Nb_muscles,1),[],options);
            Ktmax = [Ktmax -fval];
            i_eff=i_eff+1;
        end
        % Optimization
        Amin = zeros(Nb_muscles,1);
        A0 = 0.5*ones(Nb_muscles,1);
        Amax = ones(Nb_muscles,1);
        [Aopt(:,i)]=AnalysisParameters.Muscles.Costfunction(A0,Aeq,beq, Amin, Amax, options2, [],AnalysisParameters.Muscles.CostfunctionOptions,BiomechanicalModel,MuscleConcerned,Fext, Fa(:,i),Fp(:,i),R(idxj,:,i),dRdq,J,dJdq, AnalysisParameters.StiffnessPercent, Ktmax);
        %[Aopt(:,i)] = AnalysisParameters.Muscles.Costfunction(A0, Aeq, beq, Amin, Amax, options2, AnalysisParameters.Muscles.CostfunctionOptions, Fa(:,i), Fmax);
        % Muscular activity
        
        A0=Aopt(:,i);
        %          A0=randn(size(A0));
        Fopt(:,i) = Fa(:,i).*Aopt(:,i)+Fp(:,i);
        waitbar(i/Nb_frames)
        
        
        
        FMT = Fopt(:,i);
        i_eff = 1;
        for solid_eff=effector(:,1)'
            Fext = ExtForces(i).fext(solid_eff);
            Fext = Fext.fext(1:3,1); %external forces applied to the solid_eff at the i-frame
            Kt(i_eff,i) = {TaskStiffness(BiomechanicalModel,MuscleConcerned(i_eff).list,Fext, FMT,R(idxj,:,i),dRdq{i_eff},J{i_eff},dJdq{i_eff})};
            i_eff = i_eff+1;
        end
    end
    
    MuscleForcesComputationResults.MuscleActivations(idm,:) = Aopt;
    MuscleForcesComputationResults.MuscleForces(idm,:) = Fopt;
    MuscleForcesComputationResults.MuscleLengths= Lmt;
    MuscleForcesComputationResults.MuscleLeverArm = R;
    MuscleForcesComputationResults.TaskStiffness = Kt;    
    close(h)
    
    disp(['... Forces Computation (' filename ') done'])
end