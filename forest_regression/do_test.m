function [pred_w] = do_test(forest, X, weight, FOREST_CONFIG)

    numPatch = size(X,1);
    startVote_w = zeros(1,numPatch);
    endVote_w = zeros(1,numPatch);

    for i = 1 : numPatch
        % skip segments with 0 weight
        if(weight(i) == 0)
            continue;
        end

        for t = 1 : FOREST_CONFIG.numTree
            % find the leaf node
            leaf = forest(t).regression(X(i,:));
            % only consider those with at least FOREST_CONFIG.minSample
            if(size(leaf.m_displace,1) >= FOREST_CONFIG.minSample)
                disp(['Num patches: ', num2str(size(leaf.m_displace,1))])

                sd = mean(leaf.m_displace(:,1));        % onset mean distance
                ed = mean(leaf.m_displace(:,2));        % offset mean distance
                startPos = i - sd + 1;                              
                endPos = i + ed -1;
                startStd = std(leaf.m_displace(:,1));   % onset distance standard deviation
                endStd = std(leaf.m_displace(:,2));    % offset distance standard deviation

                % range to compute the osnet Gaussian distribution
                startPosRange = [max(leaf.m_displace(:,1)) min(leaf.m_displace(:,1))];
                startPosRange = [(i+1) (i+1)] -  startPosRange;
                startPosRange = max([startPosRange;[1,1]]); % take care of limit

                % range to compute the offset Gaussian distribution
               endPosRange = [min(leaf.m_displace(:,2)) max(leaf.m_displace(:,2))];
                endPosRange = [(i-1) (i-1)] + endPosRange;
                endPosRange = min([endPosRange;[numPatch,numPatch]]);

                % calculating onset Gaussian distributions, weighting, and
                % accummulating them into the onset estimation scores
                if(startPosRange(2) >= startPosRange(1))
                    startVote_w(startPosRange(1):startPosRange(2)) = startVote_w(startPosRange(1):startPosRange(2)) + ... 
                        weight(i)*normpdf(startPosRange(1):startPosRange(2),startPos,startStd);
                end

                % calculating offset Gaussian distributions, weighting, and
                % accummulating them into the offset estimation scores
                if(endPosRange(2) >= endPosRange(1))
                    endVote_w(endPosRange(1):endPosRange(2)) = endVote_w(endPosRange(1):endPosRange(2)) + ...
                        weight(i)*normpdf(endPosRange(1):endPosRange(2),endPos,endStd);
                end
            end        
        end

    end

    pred_w = [startVote_w;endVote_w];

end

