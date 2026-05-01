function [Theta_SL,e_SL,Theta_AE,e_AE,Theta_LM,e_LM, Theta_MS,e_MS, alpha_0,Kr,K0,Theta_r,Theta_s, n,m,Ks] = parametre()
% Paramètres van Genuchten de base
Theta_r = 0.0;
Theta_s = 1.26;
alpha_0 = 0.0262;
n = 2.088;
Ks=0.0095;
m=1-1./n;

% Paramètres du modèle de courbe de retrait de Braudeau (évaporation)
Theta_SL = 0.191;   % Limite de retrait (teneur en eau)
e_SL = 0.32;        % Limite de retrait (indice des vides)
Theta_AE = 0.37;    % Entrée d'air (teneur en eau)
e_AE = 0.42;        % Entrée d'air (indice des vides)
Theta_LM = 1.15;    % Limite de macroporosité (teneur en eau)
e_LM = 1.221;       % Limite de macroporosité (indice des vides)
Theta_MS = 1.195;   % Gonflement maximum des microagrégats (teneur en eau)
e_MS = 1.276;       % Gonflement maximum des microagrégats (indice des vides)
Kr = 1.039;         % Pente de la déformation principale
K0 = 1.134;         % Pente de la déformation structurelle