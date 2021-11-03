% constraints of coefficient matrices in mean 
% assure that the largest eigenvector of sum(A_i) is inside the unique
% circle
function [c, ceq] = stationary_constraint(parameters, p, q, k, kx, ky)
if ky == 0
    para = reshapeparas(parameters, p, q, k);
    for i = 1 : q
        BEKK(:,:,i) = kron(para.B(:,:,i), para.B(:,:,i));
    end
else
    para = reshapeparasXY(parameters, p, q, k, kx, ky);
    for i = 1 :q
%         BEKK(:,:,i) = [kron(para.BX(:,:,i),para.BX(:,:,i));...
%             zeros(2*kx*ky,k*k);
%             kron(para.BY(:,:,i),para.BY(:,:,i))];
        clear temp
        clear temp2
        temp = [para.BX(:,:,i), zeros(kx,k); zeros(ky,k), para.BY(:,:,i)];
        temp2 = kron([eye(k);zeros(k)],[eye(k);zeros(k)]);
        temp2 = temp2 + kron([zeros(k);eye(k)],[zeros(k);eye(k)]);
        BEKK(:,:,i) = kron(temp, temp) * temp2;
    end
end
for i = 1 : p
    AR{i} = para.A(:,:,i);
end
Spec = varm('AR', AR);
isstable1 = isstable(Spec);
sum1 = [0];
for i = 1 : p
    sum1 = sum1 + kron(AR{i}', AR{i}');
end
for i = 1 : q
    sum1 = sum1 + BEKK(:,:,i);
end
% Spec = vgxset('AR', BEKK);
% isstable2 = vgxqual(Spec);
if abs(eigs(sum1,1)) < 1
    isstable2 = 1;
else
    isstable2 = 0;
end
if isstable1 && isstable2
    c = -1;
else
    c = 1000;
end
ceq = [];