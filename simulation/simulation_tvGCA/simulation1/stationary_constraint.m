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
        BEKK(:,:,i) = [kron(para.BX(:,:,i),para.BX(:,:,i));...
            zeros(2*kx*ky,k*k);
            kron(para.BY(:,:,i),para.BY(:,:,i))];
    end
end
for i = 1 : p
    AR{i} = para.A(:,:,i);
end
Spec = varm('AR', AR);
isstable1 = isstable(Spec);
sum1 = [0];
sumx = [0];
sumy = [0];
for i = 1 : p
    sum1 = sum1 + kron(AR{i}', AR{i}');
    sumx=sumx+kron(AR{i}(1:kx,1:kx)',AR{i}(1:kx,1:kx)');
    sumy=sumy+kron(AR{i}(kx+1:k,kx+1:k)',AR{i}(kx+1:k,kx+1:k)');
end
for i = 1 : q
    sum1 = sum1 + BEKK(:,:,i);
    if ky==1
        BX=para.BX(:,:,i);
        BY=para.BY(:,:,i);
        sumx = sumx+kron(BX(1:kx,1:kx), BX(1:kx,1:kx));
        sumy = sumy+kron(BY(1:kx,1:kx), BY(1:kx,1:kx));
    end
end
% Spec = vgxset('AR', BEKK);
% isstable2 = vgxqual(Spec);
if ky==0
    if abs(eigs(sum1,1))<1
        isstable2 = 1;
    else
        isstable2 = 0;
    end
    if isstable1 && isstable2
        c = -1;
    else
        c = 1000;
    end
else
    if abs(eigs(sum1,1))<1 && abs(eigs(sumx))<1 && abs(eig(sumy)) < 1
        isstable2 = 1;
    else
        isstable2 = 0;
    end
    if isstable1 && isstable2
        c = -1;
    else
        c = 1000;
    end
end
ceq = [];
