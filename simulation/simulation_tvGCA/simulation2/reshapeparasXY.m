function output = reshapeparasXY(parameters, p, q, k, kx, ky)
%% Reshape the parameters 
% input: k,kx,ky,p,q,parameters
% output: A, B, const
A = parameters(1 : k*k*p);
C = parameters(k*k*p+1 : k*k*p+kx*(kx+1)/2+ky*(ky+1)/2);
B = parameters(k*k*p+kx*(kx+1)/2+ky*(ky+1)/2+1 : end);
tempA = zeros(k,k,p);
for i=1:p
    tempA(:,:,i) = reshape(A((k*k*(i-1)+1):(k*k*i)),k,k);
end
A = tempA;
Cx = ivech(C(1 : kx*(kx+1)/2));
Cx = tril(Cx);
constx = Cx*Cx';
Cy = ivech(C(1+kx*(kx+1)/2 : end));
Cy = tril(Cy);
consty = Cy*Cy';
% const = [constx, zeros(kx,ky); zeros(ky,kx), consty];
if q > 0
    tempBx = zeros(kx,k,q);
    for i=1:q
        tempBx(:,:,i) = reshape(B((kx*k*(i-1)+1):(kx*k*i)),kx,k);
    end
    tempBy = zeros(ky,k,q);
    for i=1:q
        tempBy(:,:,i) = reshape(B((ky*k*(i-1)+1+kx*k*q):(ky*k*i+kx*k*q)),ky,k);
    end
    BX = tempBx;
    BY = tempBy;
else
    BX = [];
    BY = [];
end

output.A = A;
output.BX = BX;
output.BY = BY;
output.Cx = Cx;
output.Cy = Cy;
output.constx = constx;
output.consty = consty;