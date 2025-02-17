function [leftBuyer,leftSeller] = SurvivalRule(t,Buyer,Seller,f_I,f_J)
%% input 
% t:      Integer, current time period
% Buyer:  Structure, set of active shippers' types
% Seller: Structure, set of active carriers' types
% f_I:    List, shippers' pre-buying prices in time period t
% f_J:    List, carriers' pre-selling prices for time period t 
%% output
% leftBuyer:  Structure, set of left Shippers' types
% leftSeller: Structure, set of left Carriers' types

global M 

buyerTotalValue = Buyer.totalValue;
buyerNumber = Buyer.number;
buyerBundle = Buyer.bundle;
buyerArrivaltime = Buyer.arrivalTime;
buyerDepaturetime = Buyer.depatureTime;
p_i = Buyer.p_i;
buyerLane = Buyer.lane;
buyerLaneMatrix = Buyer.laneMatrix;

sellerNumber = Seller.number;
sellerCost = Seller.cost;
sellerBundle = Seller.bundle;
sellerArrivaltime = Seller.arrivalTime;
sellerDepaturetime = Seller.depatureTime;
p_j = Seller.p_j;



leftBuyerset = [];
for i = 1:buyerNumber
    if t < buyerDepaturetime(i) & f_I(i) == 0
        leftBuyerset = [leftBuyerset,i];
    end
end


if isempty(leftBuyerset)
    leftBuyer = [];
else
    leftBuyer.number = length(leftBuyerset);
    leftBuyer.totalValue = zeros(leftBuyer.number,1);
    leftBuyer.bundle = zeros(leftBuyer.number,1);
    leftBuyer.lane = zeros(leftBuyer.number,1);
    leftBuyer.p_i =  zeros(leftBuyer.number,1);
    leftBuyer.depatureTime = zeros(leftBuyer.number,1);
    leftBuyer.arrivalTime = zeros(leftBuyer.number,1);
    leftBuyer.laneMatrix = zeros(leftBuyer.number,size(buyerLaneMatrix,2));
    for i = 1:leftBuyer.number
        leftBuyer.totalValue(i) = buyerTotalValue(leftBuyerset(i));
        leftBuyer.bundle(i) = buyerBundle(leftBuyerset(i));
        leftBuyer.p_i(i) = p_i(leftBuyerset(i));
        leftBuyer.depatureTime(i) = buyerDepaturetime(leftBuyerset(i));
        leftBuyer.arrivalTime(i) =  buyerArrivaltime(leftBuyerset(i));
        leftBuyer.lane(i) = buyerLane(leftBuyerset(i));
        leftBuyer.laneMatrix(i,:) = buyerLaneMatrix(leftBuyerset(i),:);
    end
end



leftSellerset = [];
for i = 1:sellerNumber
    if t <sellerDepaturetime(i) & f_J(i) == M
        leftSellerset = [leftSellerset,i];
    end
end
if isempty(leftSellerset)
    leftSeller = [];
else
    leftSeller.number = length(leftSellerset);
    leftSeller.cost = zeros(leftSeller.number,1);
    leftSeller.bundle = zeros(leftSeller.number,1);
    leftSeller.p_j = zeros(leftSeller.number,1);
    leftSeller.depatureTime = zeros(leftSeller.number,1);
    leftSeller.arrivalTime =  zeros(leftSeller.number,1);
    
    for i = 1:leftSeller.number
        leftSeller.cost(i) = sellerCost(leftSellerset(i));
        leftSeller.bundle(i) = sellerBundle(leftSellerset(i));
        leftSeller.p_j(i) = p_j(leftSellerset(i));
        leftSeller.depatureTime(i) = sellerDepaturetime(leftSellerset(i));
        leftSeller.arrivalTime(i) =  sellerArrivaltime(leftSellerset(i));
    end
end
end
