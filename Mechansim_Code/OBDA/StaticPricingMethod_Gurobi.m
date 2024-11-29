function [p_I,p_J] = StaticPricingMethod_Gurobi(Buyer,Seller)
%% input 
% Buyer:  Structure, a set of shippers' types
% Seller: Structure, a set of carriers' types

%% output
% f_I:    List, each shipper' pre-buying price
% f_J:    List, each carrier' pre-selling price 

global M laneNumber sellerBundlenumber bundle

buyerNumber = Buyer.number;
buyerValue = Buyer.value;
buyerLane = Buyer.lane;
buyerDemand = Buyer.demand;

buyerLanematrix = Buyer.laneMatrix;

sellerNumber = Seller.number;
sellerCost = Seller.cost;
sellerBundle = Seller.bundle;
sellerLanematrix = Seller.laneMatrix;

%% Optimization program

model.A = sparse([buyerLanematrix',-1*sellerLanematrix']);
model.obj = [buyerValue',-1*sellerCost'];
model.rhs = zeros(laneNumber, 1);
model.sense = '=';
model.vtype = 'B';
model.modelsense = 'max';
%model.varnames = names;

% gurobi_write(model, 'mip1.lp');

params.outputflag = 0;

result = gurobi(model, params);
result.objval;
x_i = result.x(1:buyerNumber);
y_j = result.x(buyerNumber+1:end);

sellerSet = [1:sellerNumber];
leftSellerset = sellerSet(value(y_j)>0);
leftSellercost = sellerCost(leftSellerset);
leftSellerlaneMatrix = sellerLanematrix(leftSellerset,:);
leftSellerbundle = sellerBundle(leftSellerset);

removeBundle = [];
for i = 1:sellerBundlenumber
    if sum(leftSellerbundle == i) == 0
        p_Bundle(i) = M;
    else %% ÊÇ·ñ¿¼ÂÇµÈÓÚ1
        if sum(leftSellerbundle == i) == 1
            removeBundle = [removeBundle,i];
            p_Bundle(i) = M;
        else
            removeBundle = [removeBundle,i];
            p_Bundle(i) = max(leftSellercost(leftSellerbundle == i));
        end
    end
end


removeLane = zeros(1,laneNumber);
for i = 1:length(removeBundle)
   removeLane = removeLane + bundle(removeBundle(i),:);
end


buyerSet = [1:buyerNumber];
leftBuyerset = buyerSet(value(x_i)>0);
leftBuyervalue = buyerValue(leftBuyerset);
buyerAllocation = value(x_i);
leftBuyerdemand = buyerAllocation(buyerAllocation>0);
leftBuyerlaneMatrix = buyerLanematrix(leftBuyerset,:);
leftBuyerlane = buyerLane(leftBuyerset);


for i = 1:laneNumber
    index = find(leftBuyerlane == i);
    leftBuyervalue_specifiedLane = leftBuyervalue(index);
    leftBuyerdemand_specifiedLane = leftBuyerdemand(index);
    [leftBuyervalue_specifiedLane_sort, leftBuyervalue_specifiedLane_index] = sort(leftBuyervalue_specifiedLane,'descend');
    leftBuyerdemand_specifiedLane_sort = leftBuyerdemand_specifiedLane(leftBuyervalue_specifiedLane_index);
    leftBuyertotalDemand = sum(leftBuyerdemand_specifiedLane_sort);
    if leftBuyertotalDemand == removeLane(i)
        p_Lane(i) = 0;
    else
        Index = find(cumsum(leftBuyerdemand_specifiedLane_sort)>(leftBuyertotalDemand-removeLane(i)),1);
        p_Lane(i) = leftBuyervalue_specifiedLane_sort(Index);
    end
    
end

  
for i = 1:buyerNumber
    p_I(i) = p_Lane(buyerLane(i));
end

for i = 1:sellerNumber
    p_J(i) =  p_Bundle(sellerBundle(i));
end
end
    
    


