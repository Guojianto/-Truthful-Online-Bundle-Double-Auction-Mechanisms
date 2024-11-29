function [p_I,p_J] = StaticPricingMethod_Gurobi(Buyer,Seller,S)
%% input 
% Buyer:  Structure, a set of shippers' types
% Seller: Structure, a set of carriers' types
% S:      List, padding vector    
%% output
% f_I:    List, each shipper' pre-buying price
% f_J:    List, each carrier' pre-selling price 


global M laneNumber sellerBundlenumber bundle 

buyerNumber = Buyer.number;
buyerValue = Buyer.value;
buyerLane = Buyer.lane;
buyerDemand = Buyer.demand;

buyerLanematrix = Buyer.laneMatrix./Buyer.demand;



sellerNumber = Seller.number;
sellerCost = Seller.cost;
sellerBundle = Seller.bundle;
sellerLanematrix = Seller.laneMatrix;
maxLaneNumber = zeros(1,laneNumber);
for i = 1:laneNumber
    for j = 1:buyerNumber
        if buyerLane(j) == i
          maxLaneNumber(i) = maxLaneNumber(i) + buyerDemand(j) ; 
        end
    end
end

for i = 1:laneNumber
        if maxLaneNumber(i)<S(i)
          S(i) = maxLaneNumber(i); 
        end
end
ub = [buyerDemand;ones(sellerNumber,1)];
    
%% Optimization program
Vtype = "I";
for i = 1:buyerNumber-1
    Vtype = Vtype+"I";
end

for i = 1:sellerNumber
    Vtype =Vtype +"B";
end
cons = zeros(buyerNumber,buyerNumber+sellerNumber);
for i = 1:buyerNumber
    cons(i,i) = 1;
end


Sense = "=";
for i = 1:laneNumber-1
    Sense = Sense+"=";
end



model.A = sparse([[buyerLanematrix',-1*sellerLanematrix']]);
model.obj = [buyerValue',-1*sellerCost'];
model.rhs = [S];

model.ub = ub;

model.sense = char(Sense);
model.vtype = char(Vtype);
model.modelsense = 'max';
%model.varnames = names;

% gurobi_write(model, 'mip1.lp');

params.outputflag = 0;

result = gurobi(model, params);


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
    else %% �Ƿ��ǵ���1
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
    if leftBuyertotalDemand == S(i)+removeLane(i)
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
    
    


