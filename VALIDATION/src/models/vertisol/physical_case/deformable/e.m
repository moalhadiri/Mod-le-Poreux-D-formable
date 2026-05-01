function eb = e(u)
%E Vectorized function for e(Theta) according to Braudeau (1988) model
% Handles both scalars and vectors
% [Theta_SL,e_SL,Theta_AE,e_AE,Theta_LM,e_LM,Theta_MS,e_MS, ...
%          alpha_0,Kr,K0,Theta_r,Theta_s,n,m,Ks]

[Theta_SL,e_SL,Theta_AE,e_AE,Theta_LM,e_LM,Theta_MS,e_MS,alpha,Kr,K0,~,~,n,m,~] = parametre();

%Theta=(theta_vg(u)-ur)/(us-ur);
Theta = (1+(alpha*abs(u)).^n).^(-m);

% Initialize result with same size as Theta
eb = zeros(size(Theta));

% Logical masks with CLOSED intervals at transitions
mask_SL = (Theta<=Theta_SL);
mask_AE = (Theta>Theta_SL)&(Theta<=Theta_AE);
mask_LM = (Theta>Theta_AE)&(Theta<=Theta_LM);
mask_MS = (Theta>Theta_LM)&(Theta<=Theta_MS);
mask_above = (Theta>Theta_MS);

% SL region
eb(mask_SL) = e_SL;

% SL-AE region
if any(mask_AE(:))
    Vn = (Theta(mask_AE)-Theta_SL)/(Theta_AE-Theta_SL);
    eb(mask_AE) = e_SL+Kr*((Theta_AE-Theta_SL)/(exp(1)-1))*(exp(Vn)-1-Vn);
end

% AE-LM region
if any(mask_LM(:))
    eb(mask_LM) = e_AE+Kr*(Theta(mask_LM)-Theta_AE);
end

% LM-MS region
if any(mask_MS(:))
    Vm = (Theta(mask_MS)-Theta_MS)/(Theta_LM-Theta_MS);
    term = (Theta(mask_MS)-Theta_LM)/(Theta_LM-Theta_MS);
    eb(mask_MS) = e_LM+((Theta_LM-Theta_MS)/(exp(1)-1))*...
                  ((Kr-K0)*(exp(Vm)-exp(1))-term*(Kr-K0*exp(1)));
end

% Above MS region
if any(mask_above(:))
    eb(mask_above) = e_MS+K0*(Theta(mask_above)-Theta_MS);
end