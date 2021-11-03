function [FX2Y,FY2X, p_x2y, p_y2x, FX2Yv, FY2Xv] = arma_garch_grangercausality(output, outputX, outputY, ar_order, bekk_order, k, kx, ky)
%% version 1 variance
para_armabekk = reshapeparasXY(output.parameters, ar_order, bekk_order, k, kx, ky);
 % Y --> X
para_armabekk2 = reshapeparas(outputX.parameters, ar_order, bekk_order, kx);
constx = para_armabekk2.C * para_armabekk2.C';
consty2x = para_armabekk.constx;
FY2Xv = log(trace(constx) / trace(consty2x));
% X --> Y
para_armabekk3 = reshapeparas(outputY.parameters, ar_order, bekk_order, ky);
consty = para_armabekk3.C * para_armabekk3.C';
constx2y = para_armabekk.consty;
FX2Yv = log(trace(consty) / trace(constx2y));

%% version 2 LLF
dfx = kx*kx*ar_order + kx*kx*bekk_order + (kx*kx+kx)/2;
dfy = ky*ky*ar_order + ky*ky*bekk_order + (ky*ky+ky)/2;
dfy2x = kx*k*ar_order + kx*k*bekk_order + (kx*kx+kx)/2;
dfx2y = ky*k*ar_order + ky*k*bekk_order + (ky*ky+ky)/2;

FY2X = -2*(outputX.LLF - output.LLF_x);    p_y2x =  1 - chi2cdf(FY2X,dfy2x-dfx);
FX2Y = -2*(outputY.LLF - output.LLF_y);    p_x2y =  1 - chi2cdf(FX2Y,dfx2y-dfy);





