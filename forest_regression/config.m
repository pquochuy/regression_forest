%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION file for regression forest
%%%%%%%%%%%%%%%%%%%%

FOREST_CONFIG.numTree = 10;        % number of tree
FOREST_CONFIG.dataPerTree = 0.5; % frequency to sample
FOREST_CONFIG.inDim = 53;              % dimension of input feature vector
FOREST_CONFIG.iteration = 2000;      % the number of interations for generating random splitting thresholds
FOREST_CONFIG.numThreshold = 10; % the number of random thresholds generated for each interation (i.e. the will be 2000 x 10 = 20000 thresholds in total) 
FOREST_CONFIG.maxDepth = 12;       % maximum depth of the trees
FOREST_CONFIG.minSample = 20;      % the minimum number of samples to stop splitting
FOREST_CONFIG.factory = {'unary'};     % splitting function type
