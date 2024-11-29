% %% Main
%% Data Input
clc
clear all
BB = [0,1,2,3];
BB = [20,30,40];
for bb =1
    for aa = 1
        global M K laneNumber sellerBundlenumber bundle
        load("OBDA_1_10_"+string(BB(bb))+"_"+string(aa)+".mat");
        % load("ODBA_"+string(BB(bb))+"_13_30_"+string(aa)+".mat");
        
        sellerBundlenumber = bundleNumber;
        
        
        %% OBDA Mechanism
        leftBuyer = [];
        leftSeller = [];
        activeBuyer = struct();
        activeBuyer.number = 0;
        activeBuyer.value = [];
        activeBuyer.demand = [];
        activeBuyer.laneMatrix = [];
        activeBuyer.arrivalTime = [];
        activeBuyer.depatureTime = [];
        activeBuyer.lane = [];
        activeBuyer.p_i = [];
        
        activeSeller = struct();
        activeSeller.number = 0;
        activeSeller.cost = [];
        activeSeller.bundle = [];
        activeSeller.laneMatrix = [];
        activeSeller.arrivalTime = [];
        activeSeller.depatureTime = [];
        activeSeller.p_j = [];
        historyBuyer = struct();
        historySeller = struct();
        historyBuyer.number = 0;
        historyBuyer.value = [];
        historyBuyer.demand = [];
        historyBuyer.laneMatrix = [];
        historyBuyer.arrivalTime = [];
        historyBuyer.depatureTime = [];
        
        historySeller.number = 0;
        historySeller.cost = [];
        historySeller.laneMatrix = [];
        historySeller.arrivalTime = [];
        historySeller.depatureTime = [];
        historySeller.bundle = [];
        Allocation = struct();
        Pricing = struct();
        Result = struct();
        RESULT = struct();
        tic
        for i = 1:t
            [activeBuyer_singlePeriod,activeSeller_singlePeriod] = AdmissionRule(i,Buyer,Seller,activeBuyer,activeSeller,leftBuyer,leftSeller);
            activeBuyer(i) = activeBuyer_singlePeriod;
            activeSeller(i) = activeSeller_singlePeriod;
            [Allocation(i).x,Allocation(i).y,Pricing(i).payment,Pricing(i).revenue,f_I,f_J, ...
                Result(i).buyerUtility,Result(i).sellerUtility,Result(i).platformPayoff,Result(i).socialWelfare_realized] = PricingAllocationRlue(activeBuyer_singlePeriod,activeSeller_singlePeriod);
            
            [leftBuyer,leftSeller] = SurvivalRule(i,activeBuyer_singlePeriod,activeSeller_singlePeriod,f_I,f_J);
            Left(i).Buyer = leftBuyer;
            Left(i).Seller = leftSeller;
            historyBuyer.number =historyBuyer.number + Buyer(i).number;
            historyBuyer.value = [historyBuyer.value; Buyer(i).value];
            historyBuyer.demand = [historyBuyer.demand; Buyer(i).demand];
            historyBuyer.laneMatrix = [historyBuyer.laneMatrix; Buyer(i).laneMatrix];
            
            historyBuyer.arrivalTime = [historyBuyer.arrivalTime; Buyer(i).arrivalTime];
            historyBuyer.depatureTime = [historyBuyer.depatureTime; Buyer(i).depatureTime];
            
            historySeller.number = historySeller.number+Seller(i).number;
            historySeller.cost = [historySeller.cost; Seller(i).cost];
            historySeller.laneMatrix = [historySeller.laneMatrix; Seller(i).laneMatrix];
            historySeller.arrivalTime = [historySeller.arrivalTime; Seller(i).arrivalTime];
            historySeller.depatureTime = [historySeller.depatureTime; Seller(i).depatureTime];
            historySeller.bundle = [historySeller.depatureTime; Seller(i).bundle];
            
        end
        toc
        [maxSocialwelfare,optimal_x,optimal_y] = MaxSocialWelfare_MultiDemand_Gurobi(t,historyBuyer, historySeller);
        RESULT.buyerUtility = 0;
        RESULT.sellerUtility = 0;
        RESULT.platformPayoff =  0;
        RESULT.socialWelfare_realized = 0;
        
        
        for i = 1:t
            RESULT.buyerUtility = RESULT.buyerUtility + Result(i).buyerUtility;
            RESULT.sellerUtility = RESULT.sellerUtility + Result(i).sellerUtility;
            RESULT.platformPayoff =  RESULT.platformPayoff + Result(i).platformPayoff;
            RESULT.socialWelfare_realized = RESULT.socialWelfare_realized + Result(i).socialWelfare_realized;
            
        end
        RESULT.efficiency = RESULT.socialWelfare_realized/maxSocialwelfare;
        R(aa,:) = [RESULT.buyerUtility,RESULT.sellerUtility ,RESULT.platformPayoff,RESULT.socialWelfare_realized,RESULT.efficiency,maxSocialwelfare ];
        
    end
    
    
    R = [R;[mean(R(:,1)),mean(R(:,2)),mean(R(:,3)),mean(R(:,4)),mean(R(:,5)),mean(R(:,6))]];
    R = [R;[R(21,1)/R(21,4),R(21,2)/R(21,4),sum([R(21,1)/R(21,4),R(21,2)/R(21,4)]),R(21,3)/R(21,4),R(21,3),R(21,5)]];
    RR{bb,1} = R;
    
    R = [];
end
    