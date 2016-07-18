classdef TreeNode < handle
    properties
		m_left;
		m_right;		
        m_isLeaf = false;
        % decider is a struct that holds
        % .method = string specifying which function to cuse in computeFeature.m
        % .feat = channels to use
        % .threshold 
        m_decider;
		% displacement of all patch arriving this node
		m_displace;
        % onset displacement information
        m_sdMean;
        m_sdStd;
        m_sdRange;
        m_sdGauss;
        % offset displacement information
        m_edMean;
        m_edStd;
        m_edRange;
        m_edGauss;
        
		m_level;	% not used for regression tree
		m_id;		% not used for regression tree
    end
    
    methods
		% inData.X: NxD matrix of features (not used)
		% inData.y: 1xD matrix of labels (not used)
		% inData.d: 2xD matrix of displacement from start and end points of events to the center of the patch (not used)
        function node = TreeNode(inData, id, level)
            if nargin > 0
				d = inData.d;
                % pre-compute and store the gaussian distribution for speed
                % onset
                node.m_sdMean = mean(d(:,1));
                node.m_sdStd = std(d(:,1));
                node.m_sdRange = [min(d(:,1)), max(d(:,1))];
                node.m_sdGauss = normpdf([node.m_sdRange(1) : node.m_sdRange(2)],node.m_sdMean,node.m_sdStd);
                
                % offset
                node.m_edMean = mean(d(:,2));
                node.m_edStd = std(d(:,2));
                node.m_edRange = [min(d(:,2)), max(d(:,2))];
                node.m_edGauss = normpdf([node.m_edRange(1) : node.m_edRange(2)],node.m_edMean,node.m_edStd);
                
                node.m_displace = inData.d;
                node.m_isLeaf = true;
                node.m_id = id;
                node.m_level = level;
            end
        end
    end    
end

