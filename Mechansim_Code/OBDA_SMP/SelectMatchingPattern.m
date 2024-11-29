function [global_E] = SelectMatchingPattern(E,Buyer,Seller,t)
%% input 
% E:      Cell, all matching patterns 
% Buyer:  Structure, set of all shippers' types
% Seller: Structure, set of all carriers' types
% t:      Integer, current time period
%% output
% global_E:  List, optimal matching pattern

%% Optimization program
for i = 1:length(E)
    for j = 1:t
        
    [obj(j)] = OptimizationInterprogram(E{i},Buyer(j),Seller(j));
    end
    global_obj(i) = sum(obj);  
end


    [~,global_e] = max(global_obj);

   global_E = E{global_e};
end