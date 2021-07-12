function [extension] = GetExtension(ImPath)
% Get the most frequent image extension present in the specified path:

% Get all file extensions:
files = dir(ImPath);
i=3;
while i <= size(files,1)
    [~,~,extension] = fileparts(files(i).name);
    extension_matrix(i-2) = cellstr(extension);
    i = i + 1;
end
% List of "relevant" extensions and their absolute numbers:
extension_numbers(1) = sum(strcmpi('.jpg', extension_matrix));
extension_numbers(2) = sum(strcmpi('.pbm', extension_matrix));
extension_numbers(3) = sum(strcmpi('.pgm', extension_matrix));
extension_numbers(4) = sum(strcmpi('.png', extension_matrix));
extension_numbers(5) = sum(strcmpi('.ppm', extension_matrix));
extension_numbers(6) = sum(strcmpi('.tif', extension_matrix));
extension_numbers(7) = sum(strcmpi('.bmp', extension_matrix));
% Get most frequent extension:
position = find(extension_numbers == max(extension_numbers));

% Assign the respective extension:
if position == 1
    extension = '.jpg';
elseif position == 2
    extension = '.pbm';
elseif position == 3
    extension = '.pgm';
elseif position == 4
    extension = '.png';
elseif position == 5
    extension = '.ppm';
elseif position == 6
    extension = '.tif';
elseif position == 7
    extension = '.bmp';
end