function Q = mgi_orth_basis(C)
%MGI_ORTH_BASIS Orthonormal basis of the column space of C.
    [Q,R] = qr(C,0);
    d = abs(diag(R));
    if isempty(d) || max(d) == 0
        Q = zeros(size(C,1),0);
        return;
    end
    Q = Q(:,d > 1e-10*max(d));
end
