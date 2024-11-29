function [x,y,payment,revenue,f_I,f_J,buyerUtility,sellerUtility,platformPayoff,socialWelfare_realized]=PricingAllocationRlue(Buyer,Seller)
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

global M
buyerNumber =Buyer.number;
buyerValue = Buyer.value;
p_i = Buyer.p_i;

sellerNumber = Seller.number;
sellerCost = Seller.cost;
p_j = Seller.p_j;

[f_I,f_J] = StaticPricingMethod_Gurobi(Buyer,Seller);
for i = 1:buyerNumber
    if f_I(i) ~= 0 && buyerValue(i)>f_I(i)
        x(i) = 1;
        payment(i) = max(p_i(i),f_I(i));
        allocation(i,:) = Buyer.laneMatrix(i,:);
    else
        x(i) = 0;
        payment(i) = 0;
        allocation(i,:) = 0.*Buyer.laneMatrix(i,:);
    end
    buyingPrice(i,:) = payment(i).*allocation(i,:);
end
buyingPrice = sum(buyingPrice,1);
allocation = sum(allocation,1);
buyerUtility = sum(buyerValue.*x' - payment');
sellingPrice = zeros(1,13);
sellingBundle = zeros(1,13);
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

platformPayoff = sum(payment) - sum(revenue);

socialWelfare_realized = platformPayoff + buyerUtility + sellerUtility;

end
    