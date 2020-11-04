function [Colors]=ColorsAnimation(filename,Muscles,AnimateParameters,Human_model,ModelParameters,AnalysisParameters,options,Markers_set)
% Preparing the colors for animation
%
%   INPUT
%   - filename : nameof the used file
%   - Muscles: muscles set (see the Documentation for the structure);
%   - AnimateParameters : parameters of the animation, automatically
%   generated by the graphic interface 'GenerateAnimate'
%   - Human_model : osteo-articular model (see the Documentation for the structure)
%   - ModelParameters: parameters of the musculoskeletal model,
%   - AnalysisParameters : parameters of the analysis
%   - options : structure of options ticked in the interface
%   - Markers_set : markers set (see the Documentation for the structure);

%
%   OUTPUT
%   - Colors : structure of useful colors
%________________________________________________________
%
% Licence
% Toolbox distributed under GPL 3.0 Licence
%________________________________________________________
%
% Authors : Antoine Muller, Charles Pontonnier, Pierre Puchaud and
% Georges Dumont
%________________________________________________________










Colors.fmk=[];
Colors.C_mk=[];
Colors.C_ms=[];
Colors.C_pt_p=[];
Colors.color0=[];
Colors.color1=[];
Colors.Prediction=[];
Colors.Aopt=[];
Colors.external_forces=[];
Colors.color_vect_force=[];
Colors.external_forces_pred=[];
Colors.color_vect_force_p=[];
Colors.lmax_vector_visual=[];
Colors.coef_f_visual=[];
Colors.ForceplatesData=[];
Colors.num_s_mass_center=[];
Colors.nb_ms=[];
Colors.NbPointsPrediction=[];

if options.mod_marker_anim || options.exp_marker_anim || options.mass_centers_anim
    if options.mod_marker_anim || options.exp_marker_anim
        nb_set= options.mod_marker_anim + options.exp_marker_anim;
        % Creating a mesh with all the marker to do only one gpatch
        nbmk=numel(Markers_set);
        Colors.fmk=1:1:nbmk*nb_set;
        Colors.C_mk = zeros(nbmk*nb_set,3); % RGB;
        if options.mod_marker_anim && ~options.exp_marker_anim
            Colors.C_mk(1:nbmk,:)=repmat([255 102 0]/255,[nbmk 1]);
        elseif ~options.mod_marker_anim && options.exp_marker_anim
            Colors.C_mk(1:nbmk,:)=repmat([0 153 255]/255,[nbmk 1]);
        elseif options.mod_marker_anim && options.exp_marker_anim
            Colors.C_mk(1:nbmk,:)=repmat([255 102 0]/255,[nbmk 1]);
            Colors.C_mk(nbmk+1:nbmk*nb_set,:)=repmat([0 153 255]/255,[nbmk 1]);
        end
    end
    if options.mass_centers_anim
        Colors.num_s_mass_center=find([Human_model.Visual]);
        Colors.nb_ms = length(Colors.num_s_mass_center);
        Colors.C_ms(1:Colors.nb_ms,:)=repmat([34,139,34]/255,[Colors.nb_ms 1]);
    end
end




if options.Force_Prediction_points
    %% Creation of a structure to add contact points
    for i=1:numel(AnalysisParameters.Prediction.ContactPoint)
        Colors.Prediction(i).points_prediction_efforts = AnalysisParameters.Prediction.ContactPoint{i}; %#ok<AGROW>
    end
    Colors.Prediction=verif_Prediction_Humanmodel(Human_model,Colors.Prediction);
    Colors.NbPointsPrediction = numel(Colors.Prediction);
    Colors.C_pt_p(1:Colors.NbPointsPrediction,:)=repmat([100,139,34]/255,[Colors.NbPointsPrediction 1]);
end

if options.muscles_anim
    Colors.color0 = [0.9 0.9 0.9];
    Colors.color1 = [1 0 0];
    if isfield(AnimateParameters,'Mode') && isequal(AnimateParameters.Mode, 'GenerateParameters')
        Colors.Aopt = ones(numel(Muscles),1);
    else
        load([filename '/MuscleForcesComputationResults.mat']); %#ok<LOAD>
        Colors.Aopt = MuscleForcesComputationResults.MuscleActivations;
    end
end


%% External forces

if options.external_forces_anim
    load([filename '/ExternalForcesComputationResults.mat']); %#ok<LOAD>
    if ~isfield(ExternalForcesComputationResults,'ExternalForcesExperiments')
        error('External Forces from the Experiments have not been computed on this trial')
    end
    Colors.external_forces = ExternalForcesComputationResults.ExternalForcesExperiments;
    Colors.color_vect_force = [53 210 55]/255;
end


if options.external_forces_p
    Colors.color_vect_force_p = 1-([53 210 55]/255);
    load([filename '/ExternalForcesComputationResults.mat']); %#ok<LOAD>
    if ~isfield(ExternalForcesComputationResults,'ExternalForcesPrediction')
        error('ExternalForcesPrediction have not been computed on this trial')
    end
    Colors.external_forces_pred = ExternalForcesComputationResults.ExternalForcesPrediction;
end


if options.external_forces_anim || options.external_forces_p  %vector normalization
    Colors.lmax_vector_visual = 1; % longueur max du vecteur (en m)
    Colors.coef_f_visual=(ModelParameters.Mass*9.81)/Colors.lmax_vector_visual;
end


if options.forceplate
    if isequal(AnalysisParameters.ExternalForces.Method, @DataInC3D)
        h = btkReadAcquisition([filename '.c3d']);
        Colors.ForceplatesData = btkGetForcePlatforms(h);
    elseif isequal(AnalysisParameters.ExternalForces.Method, @PF_IRSST)
        load([filename '.mat']); %#ok<LOAD>
    end
end



end