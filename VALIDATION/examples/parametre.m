function [Theta_SL,e_SL,Theta_AE,e_AE,Theta_LM,e_LM,Theta_MS,e_MS,...
          alpha_0,Kr,K0,Theta_r,Theta_s,n,m,Ks] = parametre()
% PARAMETRE  Definition of hydraulic and shrinkage parameters
%            for the Braudeau vertisol shrinkage model.
%
% This function returns the characteristic points (SL, AE, LM, MS)
% defining the soil shrinkage curve e = e(Theta), together with the
% hydraulic parameters used in the Richards-type formulation.
%
% The four critical states :
%   SL  : Shrinkage limit
%   AE  : Air-entry point
%   LM  : Limit of macroporosity contribution
%   MS  : Maximum swelling state
%
% are defined by their water content (Theta_*) and void ratio (e_*).
%
% The function also provides the van Genuchten parameters
% (alpha_0, n, m, Ks) and additional shrinkage coefficients (Kr, K0).
%
% -------------------------------------------------------------------------

% ========= REFERENCE SOIL SAMPLE =========

Theta_r = 0.0;      % Residual water content
Theta_s = 1.26;     % Saturated water content

alpha_0 = 0.0262;   % van Genuchten parameter
n       = 2.088;    % van Genuchten parameter
Ks      = 0.0095;   % Saturated hydraulic conductivity

m       = 1 - 1./n; % Mualem exponent

% --- Characteristic shrinkage points (Braudeau model) ---

Theta_SL = 0.191;   e_SL = 0.32;     % Shrinkage limit
Theta_AE = 0.37;    e_AE = 0.42;     % Air-entry
Theta_LM = 1.15;    e_LM = 1.221;    % Macroporosity limit
Theta_MS = 1.195;   e_MS = 1.276;    % Maximum swelling

% --- Shrinkage parameters ---

Kr = 1.039;         % Slope coefficient in structural shrinkage
K0 = 1.134;         % Post-MS slope coefficient
