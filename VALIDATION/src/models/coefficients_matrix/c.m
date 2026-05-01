function c_val = c(psi)
% c(psi) - Capacité capillaire: c = dtheta/dpsi
%
% theta(psi) = 1 / (1 - psi^ell)
% => c(psi)   = ell*psi^(ell-1) / (1 - psi^ell)^2
%
% Convention:
%   - non saturé : psi < 0  -> formule ci-dessus
%   - saturé     : psi >= 0 -> régularisation epsilon (évite singularités)
% -------------------------------------------------------------------------
ell=3;
psi = psi(:);
c_val = zeros(size(psi));

I = (psi < 0);
ps = psi(I);

den = (1 - ps.^ell).^2;

% (optionnel) protection si den trop petit
% den = max(den, 1e-14);

c_val(I) = (ell .* ps.^(ell-1)) ./ den;

% Saturé : régularisation (choix numérique)
c_val(~I) = 1e-8;

c_val = c_val(:);
end


