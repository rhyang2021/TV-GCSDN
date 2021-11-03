function w = weightfun(id, wid)
h = 4;
w = exp(-(id-wid).^2./h^2)/(sqrt(2*pi)*h);