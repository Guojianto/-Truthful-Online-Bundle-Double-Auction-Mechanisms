function [maxSocialwelfare,allocation,sellingBundle] = MaxSocialWelfare_MultiDemand_Gurobi(t,Buyer, Seller)

%% input 
% t:      Integer, total time period
% Buyer:  Structure, set of all shippers' types
% Seller: Structure, set of all carriers' types

%% output
% maxSocialwelfare:   Integer, ex-post maximum social welfare

global laneNumber

buyerNumber = Buyer.number;
buyerArrivalTime = Buyer.arrivalTime;
buyerDepatureTime = min(Buyer.depatureTime,t);
buyerValue = Buyer.value;
buyerLaneMatrix = Buyer.laneMatrix ;


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


model.A = sparse([cons1;cons4]);
model.obj = [valueMatrix,costMatrix];
model.rhs = [ones(buyerNumber+sellerNumber,1);zeros(t*laneNumber, 1)];

model.sense = char(Sense);
model.vtype = 'B';
model.modelsense = 'max';
% model.varnames = names;

% gurobi_write(model, 'mip1.lp');

params.outputflag = 0;

result = gurobi(model, params);
maxSocialwelfare = result.objval;


for j = 1:buyerNumber
    X_it{j} = [];
    for i = 1:size(x_it,2)
        if x_it(1,i) == j
        X_it{j} = [X_it{j},result.x(i)];
        end
        x_it2(1,j) = sum(X_it{j}); 
    end
    allocation(j,:) = Buyer.laneMatrix(j,:).*x_it2(1,j);
end
allocation = sum(allocation,1);
sellingBundle = zeros(1,13);
for j = 1:sellerNumber
    Y_jt{j} = [];
    for i = 1:size(y_jt,2)
        if y_jt(1,i) == j
        Y_jt{j} = [Y_jt{j},result.x(size(x_it,2)+i)];
        end
    end
    y_jt2(1,j) = sum(Y_jt{j});
    sellingBundle(1,Seller.bundle(j)) = sellingBundle(1,Seller.bundle(j)) + y_jt2(1,j);
end


end