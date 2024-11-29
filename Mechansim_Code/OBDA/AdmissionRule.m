function [ActiveBuyer,ActiveSeller] = AdmissionRule(t,Buyer,Seller,activeBuyer,activeSeller,leftBuyer,leftSeller)
%% input 
% t:      Integer, current time period
% Buyer:  Structure, set of active shippers' types
% Seller: Structure, set of active carriers' types
% activeBuyer:  Structure, set of history active shippers' types
% activeSeller: Structure, set of history active carriers' types
% leftBuyer:  Structure, set of left Shippers' types
% leftSeller: Structure, set of left Carriers' types
%% output
% ActiveBuyer:  Structure, set of the active shippers' types in period t
% ActiveSeller: Structure, set of the active carriers' types in period t

global M K laneNumber

buyerNumber = Buyer(t).number;
buyerValue = Buyer(t).value;
buyerLane = Buyer(t).lane;
buyerDemand = Buyer(t).demand;
buyerLanematrix = Buyer(t).laneMatrix;
buyerArrivaltime = Buyer(t).arrivalTime;
buyerDepaturetime = Buyer(t).depatureTime;

sellerNumber = Seller(t).number;
sellerCost = Seller(t).cost;
sellerBundle = Seller(t).bundle;
sellerLanematrix = Seller(t).laneMatrix;
sellerArrivaltime = Seller(t).arrivalTime;
sellerDepaturetime = Seller(t).depatureTime;



for i = 1:buyerNumber
    if buyerDepaturetime(i) - buyerArrivaltime(i) == K || buyerArrivaltime(i) == 1
        p_i(i) = 0;
    else
        p_i_invetral = zeros(1,buyerArrivaltime(i) - 1);

        for j = max(buyerDepaturetime(i) - K,1): (buyerArrivaltime(i) - 1)
            pastBuyer.number = activeBuyer(j).number+1;
            pastBuyer.value = [activeBuyer(j).value;buyerValue(i)];

            pastBuyer.lane = [activeBuyer(j).lane;buyerLane(i)];
            pastBuyer.demand = [activeBuyer(j).demand;buyerDemand(i)];
            pastBuyer.laneMatrix = [activeBuyer(j).laneMatrix;buyerLanematrix(i,:)];
            [p_I,p_J] = StaticPricingMethod_Gurobi(pastBuyer,activeSeller(j));
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
            pastSeller.laneMatrix = [activeSeller(j).laneMatrix;sellerLanematrix(i,:)];
            [p_I,p_J] = StaticPricingMethod_Gurobi(activeBuyer(j),pastSeller);
            p_j_invetral(j) = p_J(end);
        end
        p_j(i) = min(p_j_invetral);
        
    end
end


activeBuyerset = [];
pricedOut_buyer = [];
for i = 1:buyerNumber
    if  buyerValue(i) > p_i(i)
        activeBuyerset = [activeBuyerset,i];
    else
        pricedOut_buyer = [pricedOut_buyer,i];
    end
end

ActiveBuyer.number = length(activeBuyerset);

ActiveBuyer.value = zeros(ActiveBuyer.number,1);
ActiveBuyer.lane = zeros(ActiveBuyer.number,1);
ActiveBuyer.demand = zeros(ActiveBuyer.number,1);
ActiveBuyer.laneMatrix = zeros(ActiveBuyer.number,laneNumber);
ActiveBuyer.p_i = zeros(ActiveBuyer.number,1);
ActiveBuyer.depatureTime = zeros(ActiveBuyer.number,1);
ActiveBuyer.arrivalTime =  zeros(ActiveBuyer.number,1);

for i = 1:ActiveBuyer.number
    ActiveBuyer.value(i) = buyerValue(activeBuyerset(i));
    ActiveBuyer.lane(i) = buyerLane(activeBuyerset(i));
    ActiveBuyer.demand(i) = buyerDemand(activeBuyerset(i));
    ActiveBuyer.laneMatrix(i,:) = buyerLanematrix(activeBuyerset(i),:);
    ActiveBuyer.p_i(i) = p_i(activeBuyerset(i));
    ActiveBuyer.depatureTime(i) = buyerDepaturetime(activeBuyerset(i));
    ActiveBuyer.arrivalTime(i) =  buyerArrivaltime(activeBuyerset(i));
end


if ~isempty(leftBuyer)
 
    ActiveBuyer.number = ActiveBuyer.number + leftBuyer.number;
    ActiveBuyer.value = [ActiveBuyer.value;leftBuyer.value] ;
    ActiveBuyer.lane = [ActiveBuyer.lane;leftBuyer.lane];
    ActiveBuyer.demand = [ActiveBuyer.demand;leftBuyer.demand];
    ActiveBuyer.laneMatrix = [ActiveBuyer.laneMatrix;leftBuyer.laneMatrix];
    ActiveBuyer.p_i = [ActiveBuyer.p_i;leftBuyer.p_i];
    ActiveBuyer.depatureTime = [ActiveBuyer.depatureTime;leftBuyer.depatureTime];
    ActiveBuyer.arrivalTime=  [ActiveBuyer.arrivalTime;leftBuyer.arrivalTime];
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
ActiveSeller.laneMatrix = zeros(ActiveSeller.number,laneNumber);
ActiveSeller.p_j = zeros(ActiveSeller.number,1);
ActiveSeller.depatureTime = zeros(ActiveSeller.number,1);
ActiveSeller.arrivalTime =  zeros(ActiveSeller.number,1);

for i = 1:ActiveSeller.number
    ActiveSeller.cost(i) = sellerCost(activeSellerset(i));
    ActiveSeller.bundle(i) = sellerBundle(activeSellerset(i));
    ActiveSeller.laneMatrix(i,:) = sellerLanematrix(activeSellerset(i),:);
    ActiveSeller.p_j(i) = p_j(activeSellerset(i));
    ActiveSeller.depatureTime(i) = sellerDepaturetime(activeSellerset(i));
    ActiveSeller.arrivalTime(i) =  sellerArrivaltime(activeSellerset(i));
end
if ~isempty(leftSeller)
    ActiveSeller.number = ActiveSeller.number + leftSeller.number;
    ActiveSeller.cost = [ActiveSeller.cost;leftSeller.cost];
    ActiveSeller.bundle = [ActiveSeller.bundle;leftSeller.bundle];
    ActiveSeller.laneMatrix = [ActiveSeller.laneMatrix; leftSeller.laneMatrix];
    ActiveSeller.p_j = [ActiveSeller.p_j;leftSeller.p_j];
    ActiveSeller.arrivalTime =  [ActiveSeller.arrivalTime;leftSeller.arrivalTime];
    ActiveSeller.depatureTime = [ActiveSeller.depatureTime;leftSeller.depatureTime];
end
end
