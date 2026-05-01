function eb = ep(u)
% Fonction e(Theta) vectorisée selon le modèle de Braudeau (1988)
[Theta_SL,~,Theta_AE,~,Theta_LM,~,Theta_MS,~,alpha,Kr,K0,~,~,n,m,~] = parametre();


Theta = (1+(alpha*abs(u)).^n).^(-m);
absuI   = abs(u);
signu  = sign(u);
X= (alpha*absuI).^n;
dTheta = -m.*n.*(alpha.^n).*(absuI.^(n-1)).*signu.*(1+X).^(-m-1);

% Initialisation du résultat avec la même taille que Theta
eb = zeros(size(Theta));

% Masques logiques avec intervalles FERMÉS aux transitions
mask_SL = (Theta<=Theta_SL);
mask_AE = (Theta>Theta_SL)&(Theta<=Theta_AE);
mask_LM = (Theta>Theta_AE)&(Theta<=Theta_LM);
mask_MS = (Theta>Theta_LM)&(Theta<=Theta_MS);
mask_above = (Theta>Theta_MS);

%Région SL
eb(mask_SL)=1e-8;

%Région SL-AE
if any(mask_AE(:))
    Vn=(Theta(mask_AE)-Theta_SL)/(Theta_AE-Theta_SL);
    dVn=(dTheta(mask_AE))/(Theta_AE-Theta_SL);
    
    eb(mask_AE)=Kr*((Theta_AE-Theta_SL)/(exp(1)-1)).*(dVn.*exp(Vn)-dVn);
end

% Région AE-LM
if any(mask_LM(:))
    eb(mask_LM)=Kr*(dTheta(mask_LM));
end

% Région LM-MS
if any(mask_MS(:))
    Vm=(Theta(mask_MS)-Theta_MS)/(Theta_LM-Theta_MS);
    dVm=dTheta(mask_MS)/(Theta_LM-Theta_MS);

    
    eb(mask_MS)=((Theta_LM-Theta_MS)/(exp(1)-1))*...
                  ((Kr-K0)*(dVm.*exp(Vm))-dVm.*(Kr-K0*exp(1)));
end

% Au-dessus de MS
if any(mask_above(:))
    eb(mask_above) = K0*(dTheta(mask_above));
end

end