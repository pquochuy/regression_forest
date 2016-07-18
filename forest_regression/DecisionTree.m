classdef DecisionTree < handle
    properties(SetAccess = 'private') % fields with default vals
		% number of leaf nodes
		m_numLeaves = 0;
		% number of nodes
		m_numNodes = 1;
		% root node
		m_root;
		% stop growing when number of patches is less than min_samples
		m_minSamples = 5;
        m_maxDepth = 15;
		% we use only 1 feature channels in regression tree, so no  bagging
        m_numThreshold = 10;	% number of random threshold
		m_iteration = 2000;	% number of random feature channel selection
        m_factory = {'unary'};
		m_inDim = 1;
    end
    
    methods(Static)

    end
    %%%%%%%%%% Public Methods %%%%%%%%%%
    methods        
        % construction
		function DT = DecisionTree(maxDepth, minSamples, inDim, numThreshold, iteration, factory)
            if nargin > 0
                DT.m_maxDepth = maxDepth;
				DT.m_minSamples = minSamples;
				DT.m_inDim = inDim;
				DT.m_numThreshold = numThreshold;
				DT.m_iteration = iteration;
				DT.m_factory = factory;
            end
        end
        
        % train the tree with depth-first fashion
        function DT = trainDepthFirst(DT, data)
            % Reset the tree
            DT.m_numNodes = 1;
			DT.m_numLeaves = 0;
            DT.m_root = DT.computeDepthFirst(TreeNode(), data, 0);            
        end
        
        % calibrate the tree with all training data
        function fillAll(DT, data)
            DT.fill(DT.m_root, data);
        end              
	
		% do regression
		function leaf = regression(DT, X)
			data.X = X;
            leaf = DT.findLeafDist(DT.m_root, data);
        end

    end 
    %%%%%%%%%% end of Public methods %%%%%%%%%%
    
    
    %%%%%%%%%% Private methods %%%%%%%%%%
    methods(Access=private)
		function [test, method] = generateTest(DT, dim, numFactory)
			test = zeros(2,1);
			% generate feature channel m1
			test(1) = randi(dim,1);
			% generate feature channel m2
			test(2) = randi(dim,1);
			% geneate method to use
			method = randi(numFactory,1);
        end
		
        % evaluate a test function
		function [val] = evaluateTest(DT, data, test, method)
			val = zeros(size(data.X,1),1);
			A = data.X(:,test(1));
			B = data.X(:,test(2));
			switch DT.m_factory{method}
			  %case 1% 'unary'
              case 'unary'
				val = A;
			  %case 2% 'addTwo'
              case 'addTwo'
				val = A + B;
			  %case 3% 'subAbs'
              case 'subAbs'
				val = abs(A - B);        
			  %case 4%'sub'
              case 'sub'
				val = A - B;
			end
			val = double(val(:));
        end
        
        % calculate the quality of the test
        function [score] = measureSet(DT, data, dataL, dataR)
			score = -DT.meanDistance(dataL,dataR);
        end
		
        % compute mean total distance variation
        function [dist] = meanDistance(DT, dataL, dataR)
            meanL = mean(dataL.d);
            meanR = mean(dataR.d);
            
            dL = dataL.d - repmat(meanL,size(dataL.d,1),1);
            dR = dataR.d - repmat(meanR,size(dataR.d,1),1);
            dL = dL .* dL;
            dR = dR .* dR;
            dist = sum(dL(:)) + sum(dR(:));
            dist = dist/(size(dataL.d,1) + size(dataR.d,1));
        end
		
        % generate, evaluate random tests and then pick the optimal one
		function [bestScore,bestDecider,bestDataL,bestDataR] = optimalTest(DT, data)
			bestScore = -Inf; bestDecider = [];
			bestDataL = []; bestDataR = [];
			numFactory = numel(DT.m_factory);
			% find the best test
			for i = 1 : DT.m_iteration
				% generate binary test for channels locations m1 and m2 and method
				[tmpTest,method] = DT.generateTest(DT.m_inDim,numFactory);
				% compute feature response values for the test
				values = DT.evaluateTest(data,tmpTest,method);
				vmin = min(values); vmax = max(values);
				if(vmax - vmin > 0)
					for t = 1 : DT.m_numThreshold
						% generate some random thresholds with uniform distribution
						th = vmin + (vmax-vmin)*rand;
						% Split training data into two sets toLeft,toRight according to threshold t
						toLeft = (values < th);
						toRight = ~toLeft;
						% Do not allow empty set split (all patches end up in set toLeft or toRight)
						if(sum(toLeft) > 0 &&  sum(toRight) > 0)
							dataL.X = data.X(toLeft,:); dataL.d = data.d(toLeft,:);
							dataR.X = data.X(toRight,:); dataR.d = data.d(toRight,:);
							% Measure quality of split with measure_mode 0 - classification, 1 - regression
							score = DT.measureSet(data,dataL,dataR);
							if(score > bestScore)
								bestScore = score;
								bestDecider.method = method;
								bestDecider.feat = tmpTest;
								bestDecider.threshold = th;
								bestDataL = dataL;
								bestDataR = dataR;
							end
						end
					end
				end
			end
		end
	
        % grow a tree with depth-first fashion
        function node = computeDepthFirst(DT, node, data, depth)
			meanDist = mean(data.d);
            dist = data.d - repmat(meanDist,size(data.d,1),1);
            dist = dist .* dist;
            dist = sum(dist(:));
            dist = dist/(2*size(data.d,1));
            
            numSample = size(data.d,1);
		
            if(depth < DT.m_maxDepth && numSample > DT.m_minSamples)
				disp(['Split ', num2str(depth), ' meandistance ', num2str(dist)]);
				% find optimal test
				[bestScore,bestDecider,dataL,dataR] = DT.optimalTest(data);
				if(~isempty(bestDecider))
					% create decisive node
					node.m_decider = bestDecider;
					node.m_id = DT.m_numNodes;
					node.m_level = depth;
					DT.m_numNodes = DT.m_numNodes + 1;
					
					if(size(dataL.d,1) > DT.m_minSamples)
						node.m_left = DT.computeDepthFirst(TreeNode(), dataL, depth + 1);
					else
						node.m_left = DT.makeLeaf(TreeNode(), dataL, depth + 1);
					end
					
					if(size(dataR.d,1) > DT.m_minSamples)
						node.m_right = DT.computeDepthFirst(TreeNode(), dataR, depth + 1);
					else
						node.m_right = DT.makeLeaf(TreeNode(), dataR, depth + 1);
					end
				else
					node = DT.makeLeaf(node, data, depth);
				end
			else
				node = DT.makeLeaf(node, data, depth);
			end
        end

		% create a leaf node
		function [node] = makeLeaf(DT, node, data, depth)
			node = TreeNode(data, DT.m_numNodes, depth);
			DT.m_numNodes = DT.m_numNodes + 1;
		end
		
        %%fill the tree with all training data and calibrate distributions at each leaf
        function fill(DT, node, data)
			if node.m_isLeaf
				node.m_displace = data.d;
            else
                values = DT.evaluateTest(data, node.m_decider.feat, node.m_decider.method);
                toLeft = (values < node.m_decider.threshold);
                toRight = ~toLeft;
				% split data
				dataL.X = data.X(toLeft,:);
				dataL.d = data.d(toLeft,:);
				dataR.X = data.X(toRight,:);
				dataR.d = data.d(toRight,:);
				% turn left
				DT.fill(node.m_left, dataL);
				% turn right
				DT.fill(node.m_right, dataR);
            end
        end
        		
		% find the leaft node for regression task
		function leaf = findLeafDist(DT, node, data)
            if node.m_isLeaf
                leaf = node;
				return;
            end
			values = DT.evaluateTest(data, node.m_decider.feat, node.m_decider.method);
            toLeft = (values < node.m_decider.threshold);
			if sum(toLeft) ~= 0 % turn left
				dataL.X = data.X(toLeft,:);
				leaf = DT.findLeafDist(node.m_left,dataL);
			end
			if sum(~toLeft) ~= 0 % turn right
				dataR.X = data.X(~toLeft,:);
				leaf = DT.findLeafDist(node.m_right,dataR);
			end
        end
        
    end    
    %%%%%%%%%% end of Private methods %%%%%%%%%%        
end

    
    
