function [maxSocialwelfare,X_it, Y_jt,allocation,sellingBundle] = MaxSocialWelfare_MultiDemand_Gurobi(t,Buyer, Seller)
%% input 
% t:      Integer, total time period
% Buyer:  Structure, set of all shippers' types
% Seller: Structure, set of all carriers' types

%% output
% maxSocialwelfare:   Integer, ex-post maximum social welfare
global laneNumber

buyerNumber = Buyer.number;
buyerValue = Buyer.value;
buyerDemand = Buyer.demand;
buyerLaneMatrix = Buyer.laneMatrix./buyerDemand;
buyerArrivalTime = Buyer.arrivalTime;
buyerDepatureTime = min(Buyer.depatureTime,t);


sellerNumber = Seller.number;
sellerCost = Seller.cost;
sellerArrivalTime = Seller.arrivalTime;
sellerDepatureTime = min(Seller.depatureTime,t);
sellerLaneMatrix = Seller.laneMatrix;

h = 1;
for i = 1:buyerNumber
    for k = buyerArrivalTime(i): buyerDepatureTime(i)
        x_it(1,h) = i;
        x_it(2,h) = k;
        valueMatrix(1,h) = buyerValue(i);
        h = h+1;
    end
end


h = 1;
for i = 1:sellerNumber
    for j = sellerArrivalTime(i):sellerDepatureTime(i)
        y_jt(1,h) = i;
        y_jt(2,h) = j;
        costMatrix(1,h) = -sellerCost(i);
        h = h+1;
    end
end


%cons1明确最大采购和最大售出约束。
cons1_1 = zeros(buyerNumber,size(x_it,2));

for i = 1:buyerNumber
    cons1_1(i,x_it(1,:)==i) = 1;

end
cons1_1 =[cons1_1, zeros(buyerNumber,size(y_jt,2))];


cons1_2 = zeros(sellerNumber,size(y_jt,2));

for i = 1:sellerNumber
    cons1_2(i,y_jt(1,:)==i) = 1;
end
cons1_2 =[zeros(sellerNumber,size(x_it,2)),cons1_2 ];
cons1 = [cons1_1;cons1_2];

%% cons明确在每个时段每条路的交易数量平衡的

cons2 = [];
for i = 1:buyerNumber
    for j = 1:buyerDepatureTime(i)-buyerArrivalTime(i)+1
            cons2 = [cons2,buyerLaneMatrix(i,:)'];
    end
end

for i = 1:sellerNumber
    for j = 1:sellerDepatureTime(i)-sellerArrivalTime(i)+1
        cons2 = [cons2,sellerLaneMatrix(i,:)'];
    end
end



cons3_1 = zeros(t,size(x_it,2));

for i = 1:t
    for j = 1:size(x_it,2)
        if x_it(2,j) == i
            cons3_1(i,j) = 1;
        end
    end
end

cons3_2 = zeros(t,size(y_jt,2));

for i = 1:t
    for j = 1:size(y_jt,2)
        if y_jt(2,j) == i
            cons3_2(i,j) = -1;
        end
    end
end

cons3 = [cons3_1,cons3_2]; 


cons4 = [];
for i = 1:t
        cons4 = [cons4;cons2.*cons3(i,:)];
end




Sense = "<";
for i = 1:sellerNumber+buyerNumber-1
    Sense = Sense+"<";
end

for i = 1:t*laneNumber
    Sense = Sense+"=";
end

Vtype = "I";
for i = 1: size(x_it,2)-1
    Vtype = Vtype+"I";
end

for i = 1:size(y_jt,2)
    Vtype =Vtype +"B";
end

model.A = sparse([cons1;cons4]);
model.obj = [valueMatrix,costMatrix];
model.rhs = [buyerDemand;ones(sellerNumber,1);zeros(t*laneNumber, 1)];

model.sense = char(Sense);
model.vtype = char(Vtype);
model.modelsense = 'max';
% model.varnames = names;

% gurobi_write(model, 'mip1.lp');

params.outputflag = 0;

result = gurobi(model, params);
maxSocialwelfare = result.objval;

allocation = zeros(1,20);
for j = 1:buyerNumber
    X_it{j} = [];
    for i = 1:size(x_it,2)
        if x_it(1,i) == j
        X_it{j} = [X_it{j},result.x(i)];
        end
    end
allocation(1,Buyer.lane(j)) = allocation(1,Buyer.lane(j)) + sum(X_it{j});
end

sellingBundle = zeros(1,13);
for j = 1:sellerNumber
    Y_jt{j} = [];
    for i = 1:size(y_jt,2)
        if y_jt(1,i) == j
        Y_jt{j} = [Y_jt{j},result.x(size(x_it,2)+i)];
        end
    end
    sellingBundle(1,Seller.bundle(j)) = sellingBundle(1,Seller.bundle(j)) + sum(Y_jt{j});
end


end