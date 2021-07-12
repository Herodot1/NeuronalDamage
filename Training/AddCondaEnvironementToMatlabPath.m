% For a conda environment named "useFromMATLAB", the following code works 
% in Windows 10/Anaconda 3.  Note that if you are debugging Python at the 
% same time, and making changes to "some_awesome_python_module," you have 
% to reload it every time (code below starting with clear classes is how to
% do that).


function AddCondaEnvironementToMatlabPath(CondaPath,EnvName,ModuleName) 
% Input:
% CondaPath = Path to the anaconda installation, e.g. ''C:\ProgramData\anaconda3'
% EnvName = Name of the environement used (non-default one, aka not
% "root"), e.g. 'UseFromMatlab'
% ModuleName =  Name of a specific module, library, etc to load

% Output:
% None. Yet, the function should set your python environement in matlab
% identical to that of your anaconda environement. 

%pyversion('C:\ProgramData\anaconda3\envs\UseFromMatlab\pythonw.exe')
% pyenv('Version','C:\ProgramData\anaconda3\envs\UseFromMatlab\pythonw.exe')
% pyenv('Version',strcat(CondaPath,'\envs\',EnvName,'\pythonw.exe'))
%py_root_useFromMATLAB = fileparts('C:\ProgramData\anaconda3\envs\UseFromMatlab\conda.exe');
py_root_useFromMATLAB = fileparts(strcat(CondaPath,'\envs\',EnvName,'\conda.exe'));
ENV = getenv('PATH');
ENV = strsplit(ENV, ';');
items_to_add_to_path = {
    fullfile(py_root_useFromMATLAB, 'Library', 'mingw-w64', 'bin')
    fullfile(py_root_useFromMATLAB, 'Library', 'usr', 'bin')
    fullfile(py_root_useFromMATLAB, 'Library', 'bin')
    fullfile(py_root_useFromMATLAB, 'Scripts')
    };
ENV = [items_to_add_to_path(:); ENV(:)];
ENV = unique(ENV, 'stable');
ENV = strjoin(ENV, ';');
setenv('PATH', ENV);
% clear classes
% module_to_load = 'sklearn';
module_to_load = ModuleName;
python_module_to_use = py.importlib.import_module(module_to_load);
py.importlib.reload(python_module_to_use);
% Now you can use it like output = py.some_awesome_python_module.some_awesome_python_function(input)


% % Some test examples just for showcase:
% % Call function with keyqord arguments from matlab (e.g. n_samples = 123):
% n_samples = 400;
% n_features = 2;
% centers = 2;
% % Take care that the right input classes in python are used!!!!!!!
% x= py.sklearn.datasets.make_blobs(pyargs('n_samples',int32(n_samples),'n_features',int32(n_features),'centers',int32(centers)));
% a = cell(x);
% b = double(a{1}); % First argument
% c = double(a{2});
% 
% % call help function in python for specific function/method/etc:
% % py.help('sklearn.datasets.make_blobs')
% 
% 
% % works:
% test = py.sklearn.cluster.DBSCAN; % works
% test = py.sklearn.cluster.DBSCAN(pyargs('eps',3,'min_samples',int32(2))); % works
% DataIn = [1,2; 2,2; 2,3; 8,7; 8,8; 25,80];
% Input = py.numpy.array(DataIn);
% clustering = test.fit(Input);
% labels = double(clustering.labels_)
% CoreSampleIndices = double(clustering.core_sample_indices_)


