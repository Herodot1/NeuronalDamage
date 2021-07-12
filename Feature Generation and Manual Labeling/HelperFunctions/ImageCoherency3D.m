function [coh_im] = ImageCoherency3D(images,FiltSizeConv)

FiltSizeMedian = [3 3 1];

%FiltSizeConv = 9;
sigma = 2;
% Set filter:
[x,y,z] = meshgrid(-(FiltSizeConv-1)/2:(FiltSizeConv-1)/2, -(FiltSizeConv-1)/2:(FiltSizeConv-1)/2,-(FiltSizeConv-1)/2:(FiltSizeConv-1)/2); 
h = exp(-(x.^2 + y.^2 + z.^2)/(2*sigma.^2));
h = h/sum(sum(sum(h))); 

% Get image coherency:
Input = images;
% From Zhang 2015:
hS(:,:,1) = [0.0153,0,-0.0153; 0.0568,0,-0.0468; 0.0153,0,-0.0153];
hS(:,:,2) = [0.0568,0,-0.0568; 0.2117,0,-0.02117; 0.0568,0,-0.0568];
hS(:,:,3) = hS(:,:,1);
d_im_x   = convn(double(medfilt3(Input,FiltSizeMedian)),hS,'same');
d_im_y   = convn(double(medfilt3(Input,FiltSizeMedian)),permute(hS,[2,1,3]),'same');
% Get the convoluted images:
conv_im_xx = convn(d_im_x.^2,h,'same');
conv_im_yy = convn(d_im_y.^2,h,'same');
conv_im_xy = convn(d_im_x.*d_im_y,h,'same');

% Get the coherence image:
coh_im = ((conv_im_xx - conv_im_yy).^2 + 4*conv_im_xy.^2) ./ (conv_im_xx + conv_im_yy).^2;
coh_im(isnan(coh_im)) = nanmedian(coh_im(:));



