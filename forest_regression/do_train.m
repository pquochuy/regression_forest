function forest = do_train(tr_X, tr_d, FOREST_CONFIG)

    fprintf('building the random forest\n');
    forest(1, FOREST_CONFIG.numTree) = DecisionTree();
    % use parfor for parallel training instead
    %parfor i = 1:FOREST_CONFIG.numTree
    for i = 1 : FOREST_CONFIG.numTree
        tree = DecisionTree(FOREST_CONFIG.maxDepth, FOREST_CONFIG.minSample, ...
                    FOREST_CONFIG.inDim, FOREST_CONFIG.numThreshold, ...
                    FOREST_CONFIG.iteration, FOREST_CONFIG.factory);
        % randomly pick dataPerTree amount of training data for each tree
		ind = (rand(size(tr_X,1), 1) <= FOREST_CONFIG.dataPerTree);
        % learn the tree with the selected subset of data
		forest(i) = parallelTrain(tree, tr_X(ind,:), tr_d(ind,:));
    end

    % calibrate the trees with the whole training data
    fprintf('calibrating the forest\n');
    data.X = X_tr;
    data.d = d_tr;
	for i = 1 : FOREST_CONFIG.numTree
        forest(i).fillAll(data); 
        disp(['finished learning tree: %d']);
    end
end

function tree = parallelTrain(tree,X,d)
    data.X = X;
	data.d = d;
    tree.trainDepthFirst(data);
end