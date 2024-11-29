function [x,y,payment,revenue,f_I,f_J,buyerUtility,sellerUtility,platformPayoff,socialWelfare_realized,allocation]=PricingAllocationRlue(Buyer,Seller)
%% input 

% Buyer:  Structure, set of active shippers' types
% Seller: Structure, set of active carriers' types

%% output
% maxSocialwelfare:   Integer, ex-post maximum social welfare
% x: List, Quantity procured each shipper
% y: List,Whether or not each carrier trade
% payment: List,Payment of each shipper
% revenue: List, Revenue of each carrier
% f_I:    List, each shipper' pre-buying price
% f_J:    List, each carrier' pre-selling price 
% buyerUtility: List, Utility of each shipper
% sellerUtility: Lsit,Utility of each carrier
% platformPayoff: Double, Platform Profit
% socialWelfare_realized: Double social welfare received by the mechanism

global M laneNumber S
buyerNumber =Buyer.number;
buyerValue = Buyer.value;
p_i = Buyer.p_i;

sellerNumber = Seller.number;
sellerCost = Seller.cost;
p_j = Seller.p_j;

[f_I,f_J] = StaticPricingMethod_Gurobi(Buyer,Seller,S);

for i = 1:sellerNumber
    if f_J(i) ~= M && sellerCost(i)<f_J(i)
        y(i) = 1;
        revenue(i) = min(p_j(i),f_J(i));
    else
        y(i) = 0;
        revenue(i) = 0;
    end

end


sellerUtility = sum(revenue' - sellerCost.*y');
totalAllocationsupply = sum(y'.*Seller.laneMatrix);

buyerSet = [];
for i = 1:buyerNumber
    if f_I(i) ~= 0 && buyerValue(i)>f_I(i)
        buyerSet = [buyerSet,i];
    end
end
k = zeros(1,laneNumber);
for j = 1:laneNumber 
for i = 1:length(buyerSet) 
        if Buyer.lane(buyerSet(i)) == j
            k(j) = k(j) +Buyer.demand(buyerSet(i));
           
        end
      
end
end

x = zeros(1,buyerNumber);
for i = 1:laneNumber  
    j = 1;
    while totalAllocationsupply(i)~=0

        if Buyer.lane(buyerSet(j)) == i
            x(buyerSet(j)) = min(totalAllocationsupply(i),Buyer.demand(buyerSet(j)));
            totalAllocationsupply(i) = totalAllocationsupply(i) - x(buyerSet(j));
        end
        j = j+1;
    end
end
    
buyingPrice = zeros(1,20);
allocation = zeros(1,20);

for i = 1:buyerNumber
   
payment(i) = max(p_i(i),f_I(i))*x(i);

buyingPrice(1,Buyer.lane(i)) = buyingPrice(1,Buyer.lane(i)) + payment(i);
allocation(1,Buyer.lane(i)) = allocation(1,Buyer.lane(i)) + x(i);

end
buyingPrice = sum(buyingPrice,1);
allocation = sum(allocation,1);
buyerUtility = sum(buyerValue.*x' - payment');


platformPayoff = sum(payment) - sum(revenue);

socialWelfare_realized = platformPayoff + buyerUtility + sellerUtility;

end
    