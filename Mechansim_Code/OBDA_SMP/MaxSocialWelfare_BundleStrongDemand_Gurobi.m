function [maxSocialwelfare] = MaxSocialWelfare_BundleStrongDemand_Gurobi(t,Buyer, Seller)
%% input 
% t:      Integer, total time period
% Buyer:  Structure, set of all shippers' types
% Seller: Structure, set of all carriers' types

%% output
% maxSocialwelfare:   Integer, ex-post maximum social welfare
global laneNumber

buyerNumber = Buyer.number;
buyerLanematrix = Buyer.laneMatrix;
buyerArrivalTime = Buyer.arrivalTime;
buyerDepatureTime = min(Buyer.depatureTime,t);
buyerTotalvalue = Buyer.totalValue;

for i = 1:buyerNumber
    buyerLane(i) = find(buyerLanematrix(i,:)>0);
    buyerDemand(i) = sum(buyerLanematrix(i,:));
end

Buyer_singleDemand =[];
Buyer_multiDemand = [];
for i = 1:Buyer.number
    if buyerDemand(i) == 1
    Buyer_singleDemand = [Buyer_singleDemand,i];
    else
    Buyer_multiDemand = [Buyer_multiDemand,i];  
    end
end
%Buyer_singleDemand is 1£»Buyer_multiDemand is 2

buyerNumber1 = length(Buyer_singleDemand);
buyerLaneMatrix1 = Buyer.laneMatrix(Buyer_singleDemand,:);

buyerArrivalTime1 = Buyer.arrivalTime(Buyer_singleDemand);
buyerDepatureTime1 = min(Buyer.depatureTime(Buyer_singleDemand),t);
buyerTotalvalue1 = Buyer.totalValue(Buyer_singleDemand);
buyerLane1 = buyerLane(Buyer_singleDemand);
buyerDemand1 = buyerDemand(Buyer_singleDemand);

for i = 1:laneNumber
    for j = 1:t

    Highestprice(i,j) = max(buyerTotalvalue1(buyerLane1'==i & buyerArrivalTime1<=j & buyerDepatureTime1>=j));
    end
end

buyerNumber2 = length(Buyer_multiDemand);
buyerLaneMatrix2 = Buyer.laneMatrix(Buyer_multiDemand,:);
buyerArrivalTime2 = Buyer.arrivalTime(Buyer_multiDemand);
buyerDepatureTime2 = min(Buyer.depatureTime(Buyer_multiDemand),t);
buyerTotalvalue2 = Buyer.totalValue(Buyer_multiDemand);
buyerLane2 = buyerLane(Buyer_multiDemand);
buyerDemand2 = buyerDemand(Buyer_multiDemand);

    
sellerNumber = Seller.number;
sellerCost = Seller.cost;
sellerLaneMatrix = Seller.laneMatrix;
sellerArrivalTime = Seller.arrivalTime;
sellerDepatureTime = min(Seller.depatureTime,t);
sellerLane = zeros(sellerNumber,2);
sellerLanes = zeros(sellerNumber,2);
for i= 1:sellerNumber
    index = find(sellerLaneMatrix(i,:)>0);
  
    for j = 1:length(index)
       sellerLane(i,j) = index(j); 
       sellerLanes(i,j) = sellerLaneMatrix(i,index(j)); 
    end
end

h = 1;
for i = 1:buyerNumber1
    for k = buyerArrivalTime1(i): buyerDepatureTime1(i)
        x_it(1,h) = i;
        x_it(2,h) = k;
        valueMatrix1(1,h) = buyerTotalvalue1(i);
        h = h+1;
    end
end

h = 1;
for i = 1:buyerNumber2
    for j = 1:sellerNumber
        for k = buyerArrivalTime2(i): buyerDepatureTime2(i)
            if k>= sellerArrivalTime(j) && k <= sellerDepatureTime(j)
                if sellerLaneMatrix(j,:)-  buyerLaneMatrix2(i,:) >=0 
                    if buyerTotalvalue2(i) + (sellerLaneMatrix(j,:)- buyerLaneMatrix2(i,:))*Highestprice(:,k)- sellerCost(j)>=0
                    z_ijt(1,h) = i;
                    z_ijt(2,h) = j;
                    z_ijt(3,h) = k;
                    valueMatrix2(1,h) = buyerTotalvalue2(i);
                    h = h+1;
                    end
                end
            end
        end
    end
end

h = 1;
for i = 1:sellerNumber
    for j = sellerArrivalTime(i):sellerDepatureTime(i)
        y_jt(1,h) = 1;
        y_jt(2,h) = i;
        y_jt(3,h) = j;
        costMatrix(1,h) = -sellerCost(i);
        h = h+1;
    end
end


cons1_1 = zeros(buyerNumber1,size(x_it,2));

for i = 1:buyerNumber1
    cons1_1(i,x_it(1,:)==i) =1;
end

cons1_1= sparse(cons1_1);

cons1_1 = horzcat(cons1_1,sparse(zeros(buyerNumber1,size(z_ijt,2)+size(y_jt,2))));

%cons1_1 = [cons1_1,zeros(buyerNumber1,size(z_ijt,2)+size(y_jt,2))];

cons1_2 = zeros(buyerNumber2,size(z_ijt,2));

for i = 1:buyerNumber2
    cons1_2(i,z_ijt(1,:)==i) =1;
end


cons1_2= sparse(cons1_2);

cons1_2 = horzcat(sparse(zeros(buyerNumber2,size(x_it,2))),cons1_2,sparse(zeros(buyerNumber2,size(y_jt,2))));

%cons1_2 =[zeros(buyerNumber2,size(x_it,2)),cons1_2,zeros(buyerNumber2,size(y_jt,2))];


cons1_3 = zeros(sellerNumber,size(y_jt,2));
for i = 1:sellerNumber
    cons1_3(i,y_jt(2,:)==i) = 1;
end

%cons1_3 =[zeros(sellerNumber,size(z_ijt,2)+size(x_it,2)),cons1_3 ];

cons1_3= sparse(cons1_3);

cons1_3 = horzcat(sparse(zeros(sellerNumber,size(z_ijt,2)+size(x_it,2))),cons1_3);


cons1 = vertcat(cons1_1,cons1_2,cons1_3);

%%

cons2_1 = zeros(2,size(x_it,2));
for j = 1:buyerNumber2
    for k = 1:sellerNumber
        for i = 1:size(z_ijt,2)
            if z_ijt(1,i) == j && z_ijt(2,i) == k
                dk = zeros(2,1);
                dk(find(sellerLane(k,:)==buyerLane2(j)))=buyerDemand2(j);
                cons2_1 = [cons2_1,dk];
            end
        end
    end
end



for i = 1:sellerNumber
    for j = 1:sellerDepatureTime(i)-sellerArrivalTime(i)+1
        cons2_1 = [cons2_1,sellerLanes(i,:)'];
    end
end



cons2_2 = zeros(size(y_jt,2),size(z_ijt,2));

h = 1;
for i = 1:sellerNumber
    for j = sellerArrivalTime(i):sellerDepatureTime(i)
      for k = 1:size(z_ijt,2)
          if z_ijt(2,k) == i && z_ijt(3,k) == j
              cons2_2(h,k) = 1;
          end
      end
      h = h+1;
    end
end


cons2_3 = zeros(size(y_jt,2),size(y_jt,2));
h = 1;
for i = 1:sellerNumber
    for j = sellerArrivalTime(i):sellerDepatureTime(i)
        cons2_3(h,h) = -1;
        h = h+1;
    end
end

cons2_4 = [zeros(size(y_jt,2),size(x_it,2))];



cons2= [];

cons2 = sparse(cons2);
for i = 1:size(y_jt,2)
        cons2 = vertcat(cons2,sparse(cons2_1.*[cons2_4(i,:),cons2_2(i,:),cons2_3(i,:)]));
end

%%
cons3 = [];
for i = 1:buyerNumber1
    for j = 1:buyerDepatureTime1(i)-buyerArrivalTime1(i)+1
            cons3 = [cons3,buyerLaneMatrix1(i,:)'];
    end
end

for i = 1:buyerNumber2
    
    for j = 1:size(z_ijt,2)
        if z_ijt(1,j) == i
            
            cons3 = [cons3,buyerLaneMatrix2(i,:)'];
        end
    end
end
             
for i = 1:sellerNumber
    for j = 1:sellerDepatureTime(i)-sellerArrivalTime(i)+1
        cons3 = [cons3,-sellerLaneMatrix(i,:)'];
    end
end


cons4_1 = zeros(t,size(x_it,2));

for i = 1:t
    for j = 1:size(x_it,2)
        if x_it(2,j) == i
            cons4_1(i,j) = 1;
        end
    end
end

cons4_2 = zeros(t,size(z_ijt,2));

for i = 1:t
    for j = 1:size(z_ijt,2)
        if z_ijt(3,j) == i
            cons4_2(i,j) = 1;
        end
    end
end


cons4_3 = zeros(t,size(y_jt,2));

for i = 1:t
    for j = 1:size(y_jt,2)
        if y_jt(3,j) == i
            cons4_3(i,j) = 1;
        end
    end
end

cons4 = [cons4_1,cons4_2,cons4_3]; 


cons5 = [];
for i = 1:t
    cons5 = [cons5;cons3.*cons4(i,:)];
end

cons5 = sparse(cons5);

%cons4 = vertcat(cons4,sparse(cons2_1.*cons3(k,:)));


Sense = "<";
for i = 1:sellerNumber+buyerNumber+size(y_jt,2)*2-1
    Sense = Sense+"<";
end

for i = 1:laneNumber*t
    Sense = Sense+"=";
end


model.A = vertcat(cons1,cons2,cons5);
model.obj = [valueMatrix1,valueMatrix2,costMatrix];
model.rhs = [ones(buyerNumber+sellerNumber,1);zeros(size(y_jt,2)*2, 1);zeros(laneNumber*t, 1)];%%Î´¸Ä
model.sense = char(Sense);
model.vtype = 'B';
model.modelsense = 'max';
% model.varnames = names;

% gurobi_write(model, 'mip1.lp');

params.outputflag = 0;

result = gurobi(model, params);
maxSocialwelfare = result.objval;
A = result.x;

for j = 1:buyerNumber1
    X_it{j} = [];
    for i = 1:size(x_it,2)
        if x_it(1,i) == j
        X_it{j} = [X_it{j},result.x(i)];
        end
    end

end


for j = 1:buyerNumber2
    Z_ijt{j} = [];
    for i = 1:size(z_ijt,2)
        if z_ijt(1,i) == j
        Z_ijt{j} = [Z_ijt{j},result.x(size(x_it,2)+i)];
        end
    end

end


for j = 1:sellerNumber
    Y_jt{j} = [];
    for i = 1:size(y_jt,2)
        if y_jt(2,i) == j
        Y_jt{j} = [Y_jt{j},result.x(size(x_it,2)+size(z_ijt,2)+i)];
        end
    end


end

end