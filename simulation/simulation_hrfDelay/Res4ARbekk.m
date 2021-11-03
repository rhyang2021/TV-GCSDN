function [DW1,DW2,H1,p1,H2,p2] = Res4ARbekk(para_reshape,data)
x = data(1,1);
y = data(1,2);
len = size(data,1);
A = para_reshape.A;
BX = para_reshape.BX;
BY = para_reshape.BY;
constx = para_reshape.constx;
consty = para_reshape.consty;

for i=1:len-1
    Z = [x(i),y(i)]'*[x(i),y(i)];
    Htx = BX*Z*BX'+constx;
    Hty = BY*Z*BY'+consty;
    x(i+1) = data(i,1)*A(1,1) + data(i,2)*A(1,2) + sqrt(Htx)*randn(1);
    y(i+1) = data(i,1)*A(2,1) + data(i,2)*A(2,2) + sqrt(Hty)*randn(1);
end
% Durbin-Waston
res1 = data(:,1)-x';
diffRes1 = diff(res1);
SSE1 = res1'*res1;
DW1 = (diffRes1'*diffRes1)/SSE1;
%lbq test
[H1,p1] = lbqtest(res1);
% subplot(2,3,1)
% plot(res1)
% subplot(2,3,2)
% res1 = (res1-mean(res1))/std(res1);
% qqplot(res1)
% subplot(2,3,3)
% stdr1 = (res1-mean(res1))/std(res1);
% autocorr(stdr1)
res2 = data(:,2)-y';
diffRes2 = diff(res2);
SSE2 = res2'*res2;
DW2 = (diffRes2'*diffRes2)/SSE2;
[H2,p2] = lbqtest(res2);
% subplot(2,3,4)
% plot(res2)
% subplot(2,3,5)
% res2 = (res2-mean(res2))/std(res2);
% qqplot(res2)
% subplot(2,3,6)
% stdr2 = (res2-mean(res2))/std(res2);
% autocorr(stdr2)