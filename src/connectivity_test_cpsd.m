% Cpsd for estimating time delays
clear
Fs = 1000;
t = 0:1/Fs:0.296;

x = cos(2*pi*t*100)+0.25*randn(size(t));
tau = 1/400;
y = cos(2*pi*100*(t-tau))+0.25*randn(size(t));

cpsd(x,y,297,0,512,Fs)

% compare with conjugate FFT - not functional
xx = fft(x' .* hamming(297));
yy = fft(y' .* hamming(297));

zz = xx.*conj(yy)./abs(xx)./abs(yy);
zz = zz(1:65);
