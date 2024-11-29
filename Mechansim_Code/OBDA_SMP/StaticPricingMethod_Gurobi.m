function [p_I,p_J] = StaticPricingMethod_Gurobi(E,Buyer,Seller)
%% input 
% E:      Matrix, matching pattern 
% Buyer:  Structure, a set of shippers' types
% Seller: Structure, a set of carriers' types

%% output
% f_I:    List, each shipper' pre-buying price
% f_J:    List, each carrier' pre-selling price 


global M laneNumber sellerBundlenumber  demandBundleLaneMaxNumber

%% Optimization program
[obj,x_i,y_j] = OptimizationInterprogram(E,Buyer,Seller);

global_obj = obj;
global_e = E;
global_x_i = x_i;
global_y_j = y_j;
   
    

buyerNumber = Buyer.number;
buyerBundle = Buyer.bundle;
buyerTotalValue = Buyer.totalValue;
buyerLaneMatrix = zeros(buyerNumber,laneNumber*demandBundleLaneMaxNumber);
for i = 1:buyerNumber
    buyerLaneMatrix(i,buyerBundle(i)) = 1;
end


sellerNumber = Seller.number;
sellerCost = Seller.cost;
sellerBundle = Seller.bundle;


sellerLaneMatrix = zeros(sellerNumber,laneNumber*demandBundleLaneMaxNumber);
for i = 1:sellerNumber
    sellerLaneMatrix(i,:) = global_e(:,sellerBundle(i))';
end


p_I = [];
for i = 1:buyerNumber
    p_I(i) = 0;
end
p_J = [];
for i = 1:sellerNumber
    p_J(i) =  M;
end



sellerSet = [1:sellerNumber];
leftSellerset = sellerSet(global_y_j>0);
leftSellercost = sellerCost(leftSellerset);
leftSellerlaneMatrix = sellerLaneMatrix(leftSellerset,:);
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

 

removeDemandBundle = zeros(1,laneNumber*demandBundleLaneMaxNumber);
for i = 1:length(removeBundle)
    removeDemandBundle = removeDemandBundle + global_e(:,removeBundle(i))';
end



buyerSet = [1:buyerNumber];
leftBuyerset = buyerSet(global_x_i>0);
leftBuyerTotalValue = buyerTotalValue(leftBuyerset);

leftBuyerdemand = global_x_i(global_x_i>0);
leftBuyerBundle = buyerBundle(leftBuyerset);


for i = 1:laneNumber*demandBundleLaneMaxNumber
    index = find(leftBuyerBundle == i);
    leftBuyervalue_specifiedBundle = leftBuyerTotalValue(index);
    leftBuyerdemand_specifiedBundle = leftBuyerdemand(index);
    
    [leftBuyervalue_specifiedLane_sort, ~] = sort(leftBuyervalue_specifiedBundle,'descend');
 
    leftBuyertotalDemand = sum(leftBuyerdemand_specifiedBundle);
    if leftBuyertotalDemand == removeDemandBundle(i)
        p_Lane(i) = 0;
    else
        p_Lane(i) = leftBuyervalue_specifiedLane_sort(end-removeDemandBundle(i)+1);
    end
    
end


for i = 1:buyerNumber
    p_I(i) = p_Lane(buyerBundle(i));
end

for i = 1:sellerNumber
    p_J(i) =  p_Bundle(sellerBundle(i));
end
end
    
    


