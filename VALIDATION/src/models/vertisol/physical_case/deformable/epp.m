function epp_val = epp(u)
%EPP Vectorized function for second derivative of e(Theta)
%   [Theta_SL,e_SL,Theta_AE,e_AE,Theta_LM,e_LM,Theta_MS,e_MS, ...
%            alpha_0,Kr,K0,Theta_r,Theta_s, n,m,Ks]

[Theta_SL,~,Theta_AE,~,Theta_LM,~,Theta_MS,~,alpha,Kr,K0,~,~,n,m,~] = parametre();

Theta = (1+(alpha*abs(u)).^n).^(-m);
absu   = abs(u);
signu = sign(u);
X = (alpha*absu).^n;
C = m.*n.*alpha.^n;
dTheta = -C.*absu.^(n-1).*signu.*(1+X).^(-m-1);

% d2Se/dh2 = -C*(n-1)|h|^(n-2)(1+X)^(-m-1) + C*(m+1)*n*alpha^n |h|^(2n-2)(1+X)^(-m-2)
term1 = -(C).*(n-1).*(absu.^(n-2)).*(1+X).^(-m-1);
term2 =  (C).*(m+1).*n.*(alpha.^n).*(absu.^(2*n-2)).*(1+X).^(-m-2);
d2Theta = term1 + term2;

% Initialize result with same size as Theta
epp_val = zeros(size(Theta));

% Logical masks with CLOSED intervals at transitions
mask_SL = (Theta <= Theta_SL);
mask_AE = (Theta > Theta_SL) & (Theta <= Theta_AE);
mask_LM = (Theta > Theta_AE) & (Theta <= Theta_LM);
mask_MS = (Theta > Theta_LM) & (Theta <= Theta_MS);
mask_above = (Theta > Theta_MS);

% SL region
epp_val(mask_SL) = 1e-8;

% SL-AE region
if any(mask_AE(:))
    Vn = (Theta(mask_AE)-Theta_SL)/(Theta_AE-Theta_SL);
    dVn = dTheta(mask_AE)/(Theta_AE-Theta_SL);
    d2Vn = d2Theta(mask_AE)/(Theta_AE-Theta_SL);
    
    % Main term + second derivative term
    term1 = d2Vn.*exp(Vn)+(dVn.^2).*exp(Vn)-d2Vn;
    epp_val(mask_AE) = Kr*((Theta_AE-Theta_SL)/(exp(1)-1))*term1;
end

% AE-LM region
if any(mask_LM(:))
    epp_val(mask_LM) = Kr*d2Theta(mask_LM);
end

% LM-MS region
if any(mask_MS(:))
    Vm = (Theta(mask_MS)-Theta_MS)/(Theta_LM-Theta_MS);
    dVm = dTheta(mask_MS)/(Theta_LM-Theta_MS);
    d2Vm = d2Theta(mask_MS)/(Theta_LM-Theta_MS);
    
    % Main term + second derivative term
    term1 = d2Vm.*exp(Vm)+(dVm.^2).*exp(Vm);
    term2 = d2Vm;
    epp_val(mask_MS) = ((Theta_LM-Theta_MS)/(exp(1)-1))* ...
                      ((Kr-K0)*term1-term2*(Kr-K0*exp(1)));
end

% Above MS region
if any(mask_above(:))
    epp_val(mask_above) = K0*d2Theta(mask_above);
end