%% 
% This script demonstrates how to use the regression forests package for
% event detection in continuous streams. This package was used as basic for
% our papers:
% [1]. Huy Phan, Marco Maass, Radoslaw Mazur, and Alfred Mertins, Acoustic Event Detection and Localization with Regression Forests, Proc. 15th Annual Conference of the International Speech Communication Association (INTERSPEECH 2014), Singapore, pp. 2524-2528, September 2014
% [2]. Huy Phan, Marco Maaﬂ, Radoslaw Mazur, and Alfred Mertins, Random Regression Forests for Acoustic Event Detection and Classification, IEEE/ACM Transactions on Audio, Speech, and Language Processing (TASLP), vol. 23, no. 1, pp. 20-31, January 2015
% [3]. Huy Phan, Marco Maass, Radoslaw Mazur, and Alfred Mertins, Early Event Detection in Audio Streams, Proc. IEEE International Conference on Multimedia and Expo (ICME 2015), Turin, Italy, pp. 1-6, July 2015 
% [4]. Huy Phan, Marco Maass, Lars Hertel, Radoslaw Mazur, Ian McLoughlin, and Alfred Mertins, Learning Compact Structural Representations for Audio Events Using Regressor Banks, Proc. 41st IEEE International Conference on Acoustics, Speech, and Signal Processing (ICASSP 2016), Shanghai, China, pp. 211-215, March 2016
% 
% In addition, source code for the feature set can be found here 
% https://github.com/pquochuy/Audio-Event-Features

clear all
close all
clc

% add paths
addpath(genpath('forest_regression'));

% load configuration for regression forests
reg_config_file = './forest_regression/config.m';
run(reg_config_file); % load settings
% eval(config_file);

% train regression forest
% remove regForest_1.mat if you want to run the training again
if(~exist('regForest_1.mat','file'))
    % load training data
    % this small example is for "door_knock" of ITC-Irst database
    % X: segment-wise feature vectors normalized to [0,1], segment length is 100 ms
    % y: class labels, the door_knock events correspond to the label 1 (not used for this regression task)
    % d: distance vectors to event onsets and offsets
    % eventid: unique IDs assigned to the event instances
    load('train_data_1.mat');
    
    disp(['Training regression model ', num2str(cl)]);
    regForest = do_train(X, d, FOREST_CONFIG);
    save('regForest_1.mat','regForest','-v7.3');
end

% load test data
% this is data from one of three test files of ITC-Irst database
% X: segment-wise feature vectors normalized to [0,1], segment length is 100 ms
% y: groundtruth class labels (for evaluation)
% yhat: predicted class lables outtputed by the event RF classifiers (c.f.
% the published papers), the door_knock events correspond to the label 1
% weight: class probability outtputed by the event RF classifiers (c.f. references [1-3]), first column is for the door_knock events
clear X y
load('test_data_1.mat');

% load trained regression forest
load('regForest_1.mat');
% do testing
[pred] = do_test(regForest, X, weight(:,1),FOREST_CONFIG);

% plot prediction
subplot(2,1,1)
plot(1:length(y), pred(1,:),'r'); % onset prediction
hold on
plot(1:length(y), pred(2,:),'b'); % offset prediction
hold off
title('door\_knock: onset and offset prediction');
legend('onset prediction', 'offset prediction')
% plot groundtruth
subplot(2,1,2)
y_kn = zeros(size(y));
y_kn(y == 1) = 1;
plot(1:length(y), y_kn); % onset prediction
title('door\_knock: groundtruth');
legend('groundtruth')