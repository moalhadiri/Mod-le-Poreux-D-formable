function eb = e(u)
% Fonction e(Theta) vectorisée selon le modèle de Braudeau (1988)
% Gère aussi bien les scalaires que les vecteurs
 % [Theta_SL,e_SL,Theta_AE,e_AE,Theta_LM,e_LM, Theta_MS,e_MS, ...
 %          alpha_0,Kr,K0,Theta_r,Theta_s, n,m,Ks] 

[Theta_SL,e_SL,Theta_AE,e_AE,Theta_LM,e_LM,Theta_MS,e_MS,alpha,Kr,K0,~,~,n,m,~] = parametre();

%Theta=(theta_vg(u)-ur)/(us-ur);
Theta = (1+(alpha*abs(u)).^n).^(-m);
% Initialisation du résultat avec la même taille que Theta
eb = zeros(size(Theta));

% Masques logiques avec intervalles FERMÉS aux transitions
mask_SL = (Theta<=Theta_SL);
mask_AE = (Theta>Theta_SL)&(Theta <= Theta_AE);
mask_LM = (Theta>Theta_AE)&(Theta <= Theta_LM);
mask_MS = (Theta>Theta_LM)&(Theta <= Theta_MS);
mask_above = (Theta>Theta_MS);

% Région SL
eb(mask_SL) = e_SL;

% Région SL-AE
if any(mask_AE(:))
    Vn = (Theta(mask_AE)-Theta_SL)/(Theta_AE-Theta_SL);
    eb(mask_AE)=e_SL+Kr*((Theta_AE-Theta_SL)/(exp(1)-1))*(exp(Vn)-1-Vn);
end

% Région AE-LM
if any(mask_LM(:))
    eb(mask_LM) = e_AE+Kr*(Theta(mask_LM)-Theta_AE);
end

% Région LM-MS
if any(mask_MS(:))
    Vm = (Theta(mask_MS)-Theta_MS)/(Theta_LM - Theta_MS);
    term = (Theta(mask_MS)-Theta_LM)/(Theta_LM-Theta_MS);
    eb(mask_MS) = e_LM+((Theta_LM-Theta_MS)/(exp(1)-1)) * ...
                  ((Kr-K0)*(exp(Vm)-exp(1))-term*(Kr-K0*exp(1)));
end

% Au-dessus de MS
if any(mask_above(:))
    eb(mask_above) = e_MS+K0*(Theta(mask_above)-Theta_MS);
end

end