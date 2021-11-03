function output = reshapeparas(prcs, p, q, k)
prA1 = prcs(1 : k*k*p);
prC1 = prcs(k*k*p+1 : k*k*p+k*(k+1)/2);
prB1 = prcs(k*k*p+k*(k+1)/2+1 : end);
prtempA = zeros(k,k,p);
prtempB = zeros(k,k,q);
for i=1:p
    prtempA(:,:,i) = reshape(prA1((k*k*(i-1)+1):(k*k*i)),k,k);
end
for i=1:q
    prtempB(:,:,i) = reshape(prB1((k*k*(i-1)+1):(k*k*i)),k,k);
end
prA1 = prtempA;
prB1 = prtempB;
prC1 = ivech(prC1);
prC1 = tril(prC1);
output.A = prA1;
output.B = prB1;
output.C = prC1;