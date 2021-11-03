function  output = arma_bekk_mvgarch_likelihoodXY4Repeat4X(parameters, data, p, q, kx, ky, Nr, Nl, indexX, indexY)

[T,k] = size(data);
m = max(p,q);
errors = zeros(T,k); % the first m errors are zeros, since we are calculating the conditional QML
Ht_x = zeros(kx,kx,T); 
Ht_y = zeros(ky,ky,T);
LLF_x = 0;
LLF_y = 0;
likelihoods_x = zeros(T,1);
likelihoods_y = zeros(T,1);

para_armabekk = reshapeparasXY(parameters, p, q, k, kx, ky);
A = para_armabekk.A;
BX = para_armabekk.BX;
BY = para_armabekk.BY;
constx = para_armabekk.constx;
consty = para_armabekk.consty;


for i = 1 : Nr
    for j = Nl(i,1)+m : Nl(i,2)
        errors(j,:) = data(j,:) - data(j-1,:) * A(:,:,1);
        for l = 2 : p
            errors(j,:) = errors(j,:)- data(j-l,:) * A(:,:,l);
        end
    end
end
uncond = cov(errors);
for i = 1 : Nr
    for j = Nl(i,1) : Nl(i,2)
        if j < Nl(i,1)+m
            Ht_x(:,:,j) = uncond(indexX,indexX);
            Ht_y(:,:,j) = uncond(indexY,indexY);
         else   
             hx = constx;
             hy = consty;
             for l = 1 : q
                 Z = (data(j-l,:))'*(data(j-l,:));
                 hx = hx + BX(:,:,l)* Z * BX(:,:,l)';
                 hy = hy + BY(:,:,l)* Z * BY(:,:,l)';
             end
             Ht_x(:,:,j) = hx;
             Ht_y(:,:,j) = hy;
             likelihoods_x(j) = kx*log(2*pi)+(log(det(Ht_x(:,:,j))) + errors(j,indexX)*Ht_x(:,:,j)^(-1)*errors(j,indexX)');
             LLF_x = LLF_x+likelihoods_x(j);
             likelihoods_y(j) = ky*log(2*pi)+(log(det(Ht_y(:,:,j))) + errors(j,indexY)*Ht_y(:,:,j)^(-1)*errors(j,indexY)');
             LLF_y = LLF_y+likelihoods_y(j);
        end
    end
end
            
LLF_x = 0.5*(LLF_x);
likelihoods_x = 0.5*likelihoods_x;
if isnan(LLF_x)
    LLF_x = 1e6;
end
LLF_y = 0.5*(LLF_y);
likelihoods_y = 0.5*likelihoods_y;
if isnan(LLF_y)
    LLF_y = 1e6;
end
output.LLF_x = LLF_x;
output.LLF_y = LLF_y;
output.likelihoods_x = likelihoods_x;
output.likelihoods_y = likelihoods_y;