function [obj,x_i,y_j] = OptimizationInterprogram(e,Buyer,Seller)
%% input 
% e:      List, optimal matching pattern
% Buyer:  Structure, set of all shippers' types
% Seller: Structure, set of all carriers' types
% t:      Integer, current time period
%% output
% obj:    Double£¬Maximum social welfare under the matching pattern e
% x_i:    List£¬Whether each shipper trades
% y_j:    List£¬Whether each carrier trades


global laneNumber demandBundleLaneMaxNumber
buyerNumber = Buyer.number;
buyerBundle = Buyer.bundle;
buyerTotalValue = Buyer.totalValue;
buyerLanematrix = zeros(buyerNumber,laneNumber*demandBundleLaneMaxNumber);
for i = 1:buyerNumber
    buyerLanematrix(i,buyerBundle(i)) = 1;
end


sellerNumber = Seller.number;
sellerCost = Seller.cost;
sellerBundle = Seller.bundle;


sellerLanematrix = zeros(sellerNumber,laneNumber*demandBundleLaneMaxNumber);
for i = 1:sellerNumber
     sellerLanematrix(i,:) = e(:,sellerBundle(i))';
end


%% Optimization program

model.A = sparse([buyerLanematrix',-1*sellerLanematrix']);
model.obj = [buyerTotalValue',-1*sellerCost'];
model.rhs = [zeros(laneNumber*demandBundleLaneMaxNumber, 1)];

model.sense = '=';
model.vtype = 'B';
model.modelsense = 'max';
%model.varnames = names;

% gurobi_write(model, 'mip1.lp');

params.outputflag = 0;

result = gurobi(model, params);

obj = result.objval;
x_i = result.x(1:buyerNumber);
y_j = result.x(buyerNumber+1:end);
end