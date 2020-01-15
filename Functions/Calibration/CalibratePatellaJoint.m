function [BiomechanicalModel]=CalibratePatellaJoint(BiomechanicalModel)
% Generation of the function between Knee Angle and Patella Angle with the
% femur based on newton algorithm: length of the patellar tendon as
% to remain constant
%
%   INPUT
%   - BiomechanicalModel with its field OsteoarticularModel is need
%   OUTPUT
%   The musculoskeletal model is automatically actualized in the variable
%   'BiomechanicalModel'.
%   Author
%   Pierre Puchaud
%________________________________________________________
%
% Licence
% Toolbox distributed under GPL 3.0 Licence
%________________________________________________________
%
% Authors : Antoine Muller, Charles Pontonnier, Pierre Puchaud and
% Georges Dumont
%________________________________________________________


OsteoArticularModel=BiomechanicalModel.OsteoArticularModel;
solid_list={OsteoArticularModel.name}';

side={'R','L'};
for i_s=1:2
    [~,ind1]=intersect(solid_list,[side{i_s} 'Patella']);
    if ~isempty(ind1)
        
        [~,ind11]=...
            intersect(OsteoArticularModel(ind1).anat_position(:,1),...
            [side{i_s} 'PatellarLigament1']);
        
        [~,ind2]=intersect(solid_list,[side{i_s} 'Shank']);
        [~,ind22]=...
            intersect(OsteoArticularModel(ind2).anat_position(:,1),...
            [side{i_s} 'PatellarLigament2']);
        
        [~,ind_Rthigh]=intersect(solid_list,[side{i_s} 'Thigh']);
        
        %Initialisation
        % On calcule la longueur du ligament patellaire pour les valeurs d'angles
        % nulles, configuration initiale
        q0=zeros(length(OsteoArticularModel),1);
        [p1]=ForwardKinematicsPoint(OsteoArticularModel,ind_Rthigh,ind1,ind11,q0);
        [p2]=ForwardKinematicsPoint(OsteoArticularModel,ind_Rthigh,ind2,ind22,q0);
        %Longeur du ligament
        L0 = norm(p1 - p2);
        
        % On cr�e les variables du probl�me
        % les coordonn�es articulaires
        q_config =sym('q',[numel(OsteoArticularModel) 1]);
        % theta_p symbolique
        theta_p=sym('theta_p','real');
        q_config(ind1,:)=theta_p;
        % theta_g symbolique
        theta_g=sym('theta_g','real');
        q_config(ind2,:)=theta_g;
        % tous les autres valeurs nulles
        X=intersect([1:ind1-1,ind1+1:numel(OsteoArticularModel)],[1:ind2-1,ind2+1:numel(OsteoArticularModel)]);
        q_config(X)=0;
        
        % Calcul de la position du ligament patellaire dans le rep�re femur
        % depends de theta_p et theta_g
        [p1]=ForwardKinematicsPoint(OsteoArticularModel,ind_Rthigh,ind1,ind11,q_config);
        [p2]=ForwardKinematicsPoint(OsteoArticularModel,ind_Rthigh,ind2,ind22,q_config);
        fp2=matlabFunction(p2);
        
        % theta_p pour theta_g [-pi,pi] [flexion,extension]
        theta_g=[-pi:pi/180:pi/4]';
        %nombre de boucle pour la m�thode de newton
        n_bcle=3; % plus de variation apr�s 4 chiffre apr�s la virgule
        % initialisation des theta_p estim�s
        theta_p_est=zeros(length(theta_g),n_bcle);
        theta_p_est(1,1)=theta_g(1);
        
        for ii =1:length(theta_g)
            % Calcul de la position du ligament patellaire dans le rep�re femur
            % depends de theta_g
            % On le recalcule pour chaque nouvelle valeur la position du point 2.
            % Longueur du ligament estim�e.
            L = norm(p1 - fp2(theta_g(ii))); %fonction de theta_p
            % On souhaite cette longueur constante depend de la configuration
            % initiale.
            % fonction de theta_p
            e = L-L0; % erreur
            de = diff(e,'theta_p'); %de/dtheta_p variation de l'erreur
            
            % On cr�e les fonction qui dependent de theta_p pour les reestimer �
            % chaque nouvelle estimation de theta_p
            fe=matlabFunction(e);
            fde=matlabFunction(de);
            
            % Algorihtme de Newton
            % x(i+1)=x(i)-e(x(i))/de(x(i));
            for jj=1:n_bcle
                theta_p_est(ii,jj+1)=theta_p_est(ii,jj)...
                    - double(fe(theta_p_est(ii,jj))) / double(fde(theta_p_est(ii,jj)));
                %         plot(theta_g(ii), theta_p_est(ii,jj+1),'r*')
                %         hold on
            end
            % la solution initiale de la valeur d'angle suivante est celle de la
            % pr�c�dente.
            if ii~=length(theta_g)
                theta_p_est(ii+1,1)=theta_p_est(ii,n_bcle);
            end
        end
        
        theta_p_fin=theta_p_est(:,n_bcle);
        OsteoArticularModel(ind1).kinematic_dependancy.Joint=ind2;
        OsteoArticularModel(ind1).kinematic_dependancy.numerical_estimates=[theta_g ,theta_p_fin]';
        
        % Regression 5 order polynome
        [p,S]=polyfit(theta_g,theta_p_fin,5);
        [y, delta]=polyval(p,theta_g,S);
        alpha_g=sym('alpha_g','real');
        
        alpha_p=sym(zeros(1,1));
        order=length(p);
        for ii=1:length(p)
            alpha_p = alpha_g^(order-ii)*p(ii) + alpha_p;
        end
        % Handle function
        q=matlabFunction(alpha_p);
        OsteoArticularModel(ind1).kinematic_dependancy.q=q;

        OsteoArticularModel(ind1).kinematic_dependancy.L_tendon=L0;
        
    end
end
BiomechanicalModel.OsteoArticularModel=OsteoArticularModel;
end
% plot(theta_g,theta_p_fin,'k-')
% xlabel('Angle du genou (rad)')
% ylabel('Angle de la patella')
% title ('Angle de la patella en fonction du genou pour longueur de ligament patellaire constant')
%
% % On recupere la cin�matique de la patella pour un essai donn�
% load('C:\These_Safran\GitLab\Problem_new_version\POCH_TLEM\marche01\InverseKinematicsResults.mat');
% % On r�cup�re l'angle du genou
% xq=InverseKinematicsResults.JointCoordinates(ind2,:);
% % On interpole sur la courbe pour obtenir les valeurs d'angle de la patella
% vq = interp1(theta_g,theta_p_fin,xq,'pchip');
%
%
%
% plot(xq,vq,'*')
