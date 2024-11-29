function [ActiveBuyer,ActiveSeller] = AdmissionRule(t,E,Buyer,Seller,activeBuyer,activeSeller,leftBuyer,leftSeller)
%% input 
% t:      Integer, current time period
% E:      Matrix, matching pattern 
% Buyer:  Structure, set of active shippers' types
% Seller: Structure, set of active carriers' types
% activeBuyer:  Structure, set of history active shippers' types
% activeSeller: Structure, set of history active carriers' types
% leftBuyer:  Structure, set of left Shippers' types
% leftSeller: Structure, set of left Carriers' types
%% output
% ActiveBuyer:  Structure, set of the active shippers' types in period t
% ActiveSeller: Structure, set of the active carriers' types in period t


global M K 

buyerTotalValue = Buyer(t).totalValue;
buyerNumber = Buyer(t).number;
buyerBundle = Buyer(t).bundle';
buyerArrivaltime = Buyer(t).arrivalTime;
buyerDepaturetime = Buyer(t).depatureTime;
buyerLaneMatrix = Buyer(t).laneMatrix;
buyerLane = Buyer(t).lane;

sellerNumber = Seller(t).number;
sellerCost = Seller(t).cost;
sellerBundle = Seller(t).bundle;
sellerArrivaltime = Seller(t).arrivalTime;
sellerDepaturetime = Seller(t).depatureTime;



for i = 1:buyerNumber
    if buyerDepaturetime(i) - buyerArrivaltime(i) == K || buyerArrivaltime(i) == 1
        p_i(i) = 0;
    else
        p_i_invetral = zeros(1,buyerArrivaltime(i) - 1);
        for j = max(buyerDepaturetime(i) - K,1): (buyerArrivaltime(i) - 1)
            pastBuyer.number = activeBuyer(j).number+1;
            pastBuyer.totalValue = [activeBuyer(j).totalValue;buyerTotalValue(i)];
            pastBuyer.bundle = [activeBuyer(j).bundle;buyerBundle(i)];
            [p_I,p_J] = StaticPricingMethod_Gurobi(E,pastBuyer,activeSeller(j));
            p_i_invetral(j) = p_I(end);
        end
        p_i(i) = max(p_i_invetral);
    end
end


for i = 1:sellerNumber
    if sellerDepaturetime(i) - sellerArrivaltime(i) == K || sellerArrivaltime(i) == 1
        p_j(i) = M;
    else
        p_j_invetral  = M*ones(1,sellerArrivaltime(i) - 1);
        for j = max(sellerDepaturetime(i) - K,1): (sellerArrivaltime(i) - 1)
            pastSeller.number = activeSeller(j).number+1;
            pastSeller.cost = [activeSeller(j).cost;sellerCost(i)];
            pastSeller.bundle = [activeSeller(j).bundle;sellerBundle(i)];
            [p_I,p_J] = StaticPricingMethod_Gurobi(E,activeBuyer(j),pastSeller);
            p_j_invetral(j) = p_J(end);
        end
        p_j(i) = min(p_j_invetral);
        
    end
end


activeBuyerset = [];
pricedOut_buyer = [];

for i = 1:buyerNumber
    if  buyerTotalValue(i) > p_i(i)
        activeBuyerset = [activeBuyerset,i];
    else
        pricedOut_buyer = [pricedOut_buyer,i];
    end
end

ActiveBuyer.number = length(activeBuyerset);

ActiveBuyer.totalValue = zeros(ActiveBuyer.number,1);
ActiveBuyer.bundle = zeros(ActiveBuyer.number,1);
ActiveBuyer.p_i = zeros(ActiveBuyer.number,1);
ActiveBuyer.depatureTime = zeros(ActiveBuyer.number,1);
ActiveBuyer.arrivalTime =  zeros(ActiveBuyer.number,1);
ActiveBuyer.lane =  zeros(ActiveBuyer.number,1);

for i = 1:ActiveBuyer.number
    ActiveBuyer.totalValue(i) = buyerTotalValue(activeBuyerset(i));
    ActiveBuyer.bundle(i) = buyerBundle(activeBuyerset(i));
    ActiveBuyer.p_i(i) = p_i(activeBuyerset(i));
    ActiveBuyer.depatureTime(i) = buyerDepaturetime(activeBuyerset(i));
    ActiveBuyer.arrivalTime(i) =  buyerArrivaltime(activeBuyerset(i));
    ActiveBuyer.laneMatrix(i,:) = buyerLaneMatrix(activeBuyerset(i),:);
    ActiveBuyer.lane(i) = buyerLane(activeBuyerset(i));
end

if ~isempty(leftBuyer)
    ActiveBuyer.number = ActiveBuyer.number + leftBuyer.number;
    ActiveBuyer.totalValue = [ActiveBuyer.totalValue;leftBuyer.totalValue] ;
    ActiveBuyer.bundle = [ActiveBuyer.bundle;leftBuyer.bundle];
    ActiveBuyer.p_i = [ActiveBuyer.p_i;leftBuyer.p_i];
    ActiveBuyer.depatureTime = [ActiveBuyer.depatureTime;leftBuyer.depatureTime];
    ActiveBuyer.arrivalTime=  [ActiveBuyer.arrivalTime;leftBuyer.arrivalTime];
    ActiveBuyer.laneMatrix =[ActiveBuyer.laneMatrix;leftBuyer.laneMatrix];
    ActiveBuyer.lane = [ActiveBuyer.lane;leftBuyer.lane];

end

activeSellerset = [];
pricedOut_seller = [];
for i = 1:sellerNumber
    
    if  sellerCost(i) < p_j(i)
        activeSellerset = [activeSellerset,i];
    else
        pricedOut_seller = [pricedOut_seller,i];
    end
end


ActiveSeller.number = length(activeSellerset);

ActiveSeller.cost = zeros(ActiveSeller.number,1);
ActiveSeller.bundle = zeros(ActiveSeller.number,1);
ActiveSeller.p_j = zeros(ActiveSeller.number,1);
ActiveSeller.depatureTime = zeros(ActiveSeller.number,1);
ActiveSeller.arrivalTime =  zeros(ActiveSeller.number,1);

for i = 1:ActiveSeller.number
    ActiveSeller.cost(i) = sellerCost(activeSellerset(i));
    ActiveSeller.bundle(i) = sellerBundle(activeSellerset(i));
    ActiveSeller.p_j(i) = p_j(activeSellerset(i));
    ActiveSeller.depatureTime(i) = sellerDepaturetime(activeSellerset(i));
    ActiveSeller.arrivalTime(i) =  sellerArrivaltime(activeSellerset(i));
end
if ~isempty(leftSeller)
    ActiveSeller.number = ActiveSeller.number + leftSeller.number;
    ActiveSeller.cost = [ActiveSeller.cost;leftSeller.cost];
    ActiveSeller.bundle = [ActiveSeller.bundle;leftSeller.bundle];
    ActiveSeller.p_j = [ActiveSeller.p_j;leftSeller.p_j];
    ActiveSeller.arrivalTime =  [ActiveSeller.arrivalTime;leftSeller.arrivalTime];
    ActiveSeller.depatureTime = [ActiveSeller.depatureTime;leftSeller.depatureTime];
end
end
