function [cumulativeBinaryImage] = DrawMultPolygons(originalImage)
fontSize = 12;
% Display images to prepare for the demo.
[rows, columns, numberOfColorChannels] = size(originalImage);
subplot(1, 2, 1);
imshow(originalImage);
title('Original Image.  DRAW POLYGON HERE!!!', 'FontSize', fontSize);
subplot(1, 2, 2);
imshow(originalImage);
title('Original Image with regions burned into image', 'FontSize', fontSize);
set(gcf, 'units','normalized','outerposition',[0 0 1 1]); % Maximize figure.
set(gcf,'name','Image Analysis Demo','numbertitle','off') 

%----- Ask user to draw polygons ---------------------------------------------------------------------
% Create a binary image for all the regions we will draw.
% Create region mask, h, as an ROI object over the second image in the bottom row.
cumulativeBinaryImage = false(rows, columns);
axis on;
again = true;
regionCount = 0;
while again && regionCount < 20
	promptMessage = sprintf('Draw region #%d in the upper right image,\nor Quit?', regionCount + 1);
	titleBarCaption = 'Continue?';
	button = questdlg(promptMessage, titleBarCaption, 'Draw', 'Quit', 'Draw');
	if strcmpi(button, 'Quit')
		break;
	end
	regionCount = regionCount + 1;

	% Ask user to draw freehand mask.
	message = sprintf('Left click vertices in the upper left image.\nRight click the last vertex to finish.\nThen double click in the middle to accept it.');
	uiwait(msgbox(message));
	subplot(1, 2, 1); % Switch to image axes.
	% Use roipoly() if you want to close the polygon at the right click
	% but give the user the opportunity to adjust the positions of the vertices, and then
	% the user needs to double-click inside the shape to confirm/accpet it.
	[thisSinglePolygonImage, xi, yi] = roipoly();

	% Draw the polygon over the image in the upper right.
	subplot(1, 2, 2); % Switch to upper right image axes.
	hold on;
	plot(xi, yi, 'r-', 'LineWidth', 2);

	caption = sprintf('Original Image with %d regions in overlay.', regionCount);
	title(caption, 'FontSize', fontSize);
	% OR it in to the "all regions" binary image mask we're building up.
	cumulativeBinaryImage = cumulativeBinaryImage | thisSinglePolygonImage;

end
% cumulativeBinaryImage is your final binary image mask that contains all the individual masks you drew.