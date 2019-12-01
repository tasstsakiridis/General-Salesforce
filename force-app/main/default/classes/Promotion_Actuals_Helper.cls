public with sharing class Promotion_Actuals_Helper {
    class brandTotals {
        public String brandId                   { get; set; }
        public Decimal totalPlannedQty          { get; set; }
        public Decimal totalPlannedPayment      { get; set; }
        public Decimal hopeQuantity             { get; set; }
        public Decimal ytdQty                   { get; set; }
        public Decimal ytdPayment               { get; set; }
        public Decimal remainingPlannedQty      { get; set; }
        public Decimal remainingPlannedPayment  { get; set; }
        
        public brandTotals(String id) {
            this.brandId = id;
            this.totalPlannedPayment = 0;
            this.totalPlannedQty = 0;
            this.hopeQuantity = 0;
            this.ytdPayment = 0;
            this.ytdQty = 0;
            this.remainingPlannedPayment = 0;
            this.remainingPlannedQty = 0;
        }
    }
    class promotionTotals {
    	public String promotionId               { get; set; }
        public Decimal totalPlannedQty          { get; set; }
        public Decimal totalPlannedPayment      { get; set; }
        public Decimal ytdQty                   { get; set; }
        public Decimal ytdPayment               { get; set; }
        public Decimal remainingPlannedQty      { get; set; }
        public Decimal remainingPlannedPayment  { get; set; }
        public Map<String, brandTotals> brands  { get; set; }
        
        public promotionTotals(String id) {
            this.promotionId = id;
            this.totalPlannedPayment = 0;
            this.totalPlannedQty = 0;
            this.ytdPayment = 0;
            this.ytdQty = 0;
            this.remainingPlannedPayment = 0;
            this.remainingPlannedQty = 0;
            this.brands = new Map<String, brandTotals>();
        }
    }
    
    public static Map<String, Promotion__c> createPromotionCostsForPromotion(Map<String, Promotion__c> m_Promotions) {
        System.debug('[Promotion_Actuals_Helper.createPromotionCostsForPromotion] # of promotions: ' + m_Promotions.size());
        if (m_Promotions == null || m_Promotions.size() == 0) { return m_Promotions; }
                
        Map<String, promotionTotals> m_Totals = new Map<String, promotionTotals>();
        Set<String> l_PromotionIds = m_Promotions.keySet();
        
        List<Promotion_Material_Item__c> l_PMI = [SELECT Id, Promotion__c, Product_Custom__r.Brand__c, Brand__c, Total_Planned_Quantity__c, Monthly_Per_Bottle_Discount__c, Standard_Bottle_Multiplier__c, Product_Unit_Size__c, Is_Product_Fee__c FROM Promotion_Material_Item__c WHERE Promotion__c =:l_PromotionIds];
        List<Promotion_Costs__c> l_Costs = [SELECT Id, Promotion__c, Name, Brand__c FROM Promotion_Costs__c WHERE Promotion__c IN :l_PromotionIds];
		        
        Boolean found = false; Boolean upsertNewCosts = false;
        promotionTotals pt;
        brandTotals bt;
        Double bottleMultiplier = 1;
        Double total = 0;
        for(Promotion_Material_Item__c pmi : l_PMI) {
            if (!pmi.Is_Product_Fee__c) {
                bottleMultiplier = pmi.Standard_Bottle_Multiplier__c;
                if (pmi.Standard_Bottle_Multiplier__c == null || pmi.Standard_Bottle_Multiplier__c == 0) { bottleMultiplier = 1; }
                if (m_Totals.containsKey(pmi.Promotion__c)) {
                    pt = m_Totals.get(pmi.Promotion__c);
                } else {
                    pt = new promotionTotals(pmi.Promotion__c);
                }
                total = pmi.Total_Planned_Quantity__c * (pmi.Product_Unit_Size__c / bottleMultiplier);
                
                pt.totalPlannedQty += pmi.Total_Planned_Quantity__c * (pmi.Product_Unit_Size__c / bottleMultiplier);
                System.debug('plannedQty: ' + pmi.Total_Planned_Quantity__c + ', unitSize: ' + pmi.Product_Unit_Size__c + ', multiplier: ' + bottleMultiplier + ', total: ' + total + ', brandTotal: ' + pt.totalPlannedQty);
                if (pt.totalPlannedPayment == null) { pt.totalPlannedPayment = 0; }
                pt.totalPlannedPayment += (pmi.Total_Planned_Quantity__c * pmi.Monthly_Per_Bottle_Discount__c);                                    
                
                if (pt.brands.containsKey(pmi.Product_Custom__r.Brand__c)) {
                    bt = pt.brands.get(pmi.Product_Custom__r.Brand__c);
                } else {
                    bt = new brandTotals(pmi.Product_Custom__r.Brand__c);
                }
                bt.totalPlannedQty += pmi.Total_Planned_Quantity__c * (pmi.Product_Unit_Size__c / bottleMultiplier);
                bt.totalPlannedPayment += (pmi.Total_Planned_Quantity__c * pmi.Monthly_Per_Bottle_Discount__c);
                bt.hopeQuantity += pmi.Total_Planned_Quantity__c * (pmi.Product_Unit_Size__c / bottleMultiplier);
                pt.brands.put(pmi.Product_Custom__r.Brand__c, bt); 
                m_Totals.put(pmi.Promotion__c, pt);
            }
        }
        
        Promotion__c p;
        if (m_Totals.size() > 0) {            
            for(promotionTotals pTotal : m_Totals.values()) {
                for(brandTotals bTotal : pTotal.brands.values()) {
                    found = false;
                    for(Promotion_Costs__c pc : l_Costs) {
                        if (bTotal.brandId == pc.Brand__c) {
                            pc.Total_Planned_Qty__c = bTotal.totalPlannedQty;
                            pc.Total_Planned_Payment__c = bTotal.totalPlannedPayment;
                            found = true; break;
                        }
                    }
                    
                    if (!found) {
                        l_Costs.add(new Promotion_Costs__c(Promotion__c=pTotal.promotionId, Brand__c=bTotal.brandId, Total_Planned_Qty__c=bTotal.totalPlannedQty, Total_Planned_Payment__c=bTotal.totalPlannedPayment, Remaining_Planned_Qty__c=bTotal.totalPlannedQty, Remaining_Planned_Payment__c=bTotal.totalPlannedPayment, Hope_Quantity__c=bTotal.hopeQuantity));
                    }
                }
                
                p = m_Promotions.get(pTotal.promotionId);
                p.Approval_Status__c = 'Approved';
                p.Total_Planned_Qty__c = pTotal.totalPlannedQty;
                p.Total_Planned_Payment__c = pTotal.totalPlannedPayment;
                p.Total_Remaining_Planned_Qty__c = pTotal.totalPlannedQty;
                p.Total_Remaining_Planned_Payment__c = pTotal.totalPlannedPayment;
                m_Promotions.put(pTotal.promotionId, p);
            } 
        } else {
            for(Promotion__c promo : m_Promotions.values()) {
                promo.Approval_Status__c = 'Approved';
            }
        }
        
        System.debug('# of l_costs to create: ' + l_Costs.size());
        upsert l_Costs;
        
        return m_Promotions;
        
    }
    
    public static List<PMI_Actual__c> createPMIActualsForPeriods(Promotion__c p, List<Promotion_Material_Item__c> pmiList, Set<String> pmaExternalKeys, List<PMI_Actual__c> pmaList) {
	    //List<Id> pmiIds = new List<Id>();
        if (pmiList == null) { pmiList = new List<Promotion_Material_Item__c>(); }
        List<PMI_Actual__c> actuals;
        if (pmaList == null) {
            actuals = new List<PMI_Actual__c>();
        } else {
            actuals = pmaList;
        }

        integer startMonth = 1;
        integer numberOfPeriods = 1;
        integer monthIdx = 0;
        if (p.Promotion_Start_Date__c != null) {
            startMonth = p.Promotion_Start_Date__c.month();
        }
        if (p.Promotion_End_Date__c != null) {
            numberOfPeriods = p.Promotion_Start_Date__c.monthsBetween(p.Promotion_End_Date__c) + 1;
        }
        //List<Promotion_Material_Item__c> items = [SELECT Id, Product_Custom__c, Product_Custom__r.Used_For__c FROM Promotion_Material_Item__c WHERE Promotion__c =: p.Id];
        String externalKey = '';
        for(Promotion_Material_Item__c pmi : pmiList) {
            if (pmi.Product_Custom__r.Used_For__c != null && pmi.Product_Custom__r.Used_For__c.contains('Fee')) {
                externalKey = p.Id + '_' + pmi.Id + '_0';
                if (!pmaExternalKeys.contains(externalKey)) {
                    PMI_Actual__c pma = new PMI_Actual__c();
                    pma.Promotion__c = p.Id;
                    pma.Promotion_Material_Item__c = pmi.Id;
                    pma.Period__c = 0;
                    pma.External_Key__c = externalKey;
                    actuals.add(pma);                    
                }                
            } else {                
                for(integer i = 0; i < numberOfPeriods; i++) {
                    monthIdx = startMonth + i;
                    if (monthIdx > 12) { monthIdx -= 12; }
                    externalKey = p.Id + '_' + pmi.Id + '_' + i;
                    if (!pmaExternalKeys.contains(externalKey)) {
                        PMI_Actual__c pma = new PMI_Actual__c();
                        pma.Promotion__c = p.Id;
                        pma.Promotion_Material_Item__c = pmi.Id;
                        pma.Period__c = i;
                        pma.External_Key__c = externalKey;
                        actuals.add(pma);                        
                    }
                }            
            }
        }

        return actuals;
    }
    
    public static Map<String, Promotion__c> updatePromotionAverageDiscount(Map <String, Promotion__c> promotions) {
        if (promotions == null || promotions.size() == 0) { return promotions; }
         
        List<Promotion_Costs__c> l_PromotionCosts = new List<Promotion_Costs__c>();
        
        for(Promotion__c thePromotion : promotions.values()) {
    	    System.debug('[pac] thePromotion.Id: ' + thePromotion.Id);
			System.debug('[pac] thePromotion.costs: ' + thePromotion.Promotion_Costs__r);
            System.debug('[pac] thePromotion.actuals: ' + thePromotion.PMI_Actuals__r);
            Promotion__c thePromotionDetails = [SELECT Id, (SELECT Id, Promotion__c, Brand__c, Brand_Name__c, Hope_Quantity__c, Remaining_Planned_Qty__c, Remaining_Planned_Payment__c, YTD_Actual_Qty__c, YTD_Actual_Payment__c, Total_Actual_Qty__c, Total_Actual_Payment__c FROM Promotion_Costs__r), (SELECT Id, Product_Custom__r.Brand__c, Monthly_Bottle_Qty__c, Monthly_Per_Bottle_Discount__c, Is_Product_Fee__c, Product_Unit_Size__c, Standard_Bottle_Multiplier__c FROM Promotion_Material_Items__r), (SELECT Id, Brand__c, Period__c, Brand_Name__c, Act_Qty__c, Act_Payment__c, Monthly_Bottle_Qty__c, Monthly_Per_Bottle_Discount__c, Product_Unit_Size__c, Standard_Bottle_Multiplier__c, Is_Product_Fee__c FROM PMI_Actuals__r) FROM Promotion__c WHERE Id =:thePromotion.Id];
            
            Double ytdQty = 0;
            Double ytdPayment = 0;
            Double remainingQty = 0;
            Double remainingPayment = 0;
            Double qty = 0;
            Double pv_qty = 0;
            Double actQty = 0;
            Double prev_Actual_Qty = 0;
            Double prev_Actual_Payment = 0;
            Double unitMultiplier = 1;
            Double bottleMultiplier = 1;
            Date today = Date.today();
            Integer periodsRemaining = today.monthsBetween(thePromotion.Promotion_End_Date__c);
            System.debug('[pac] periodsRemaining: ' + periodsRemaining);
            if (periodsRemaining == 0) {
                periodsRemaining = 1;
            } else if (periodsRemaining < 0) {
                periodsRemaining = 0;
            } else {
                periodsRemaining++;
            }
            //Decimal periodsRemaining = thePromotion.Number_of_Periods__c - thePromotion.Current_Period__c;
        
            thePromotion.YTD_Actual_QTY__c = 0;
            thePromotion.YTD_Actual_Payment__c = 0;
            thePromotion.Total_Remaining_Planned_Qty__c = 0;
            thePromotion.Total_Remaining_Planned_Payment__c = 0;

			promotionTotals p_Totals = new promotionTotals(thePromotion.Id);
            System.debug('[pac] init pTotals: ' + p_Totals.promotionId + ', remainingQty: ' + p_Totals.remainingPlannedQty + ', remainingPayment: ' + p_Totals.remainingPlannedPayment);
    	    brandTotals b_Totals;
System.debug('[pac] periodsRemaining: ' + periodsRemaining);        
        
            for(PMI_Actual__c pmia : thePromotionDetails.PMI_Actuals__r) {			            
            	System.debug('[pac] pmia.Id: ' + pmia.Id + ', period: ' + pmia.Period__c + ', brand: ' + pmia.Brand_Name__c + ', actqty: ' + pmia.Act_Qty__c + ', monthlyQty: ' + pmia.Monthly_Bottle_Qty__c);
                if (!pmia.Is_Product_Fee__c) {
                    qty = pmia.Act_Qty__c == 0 ? pmia.Monthly_Bottle_Qty__c : pmia.Act_Qty__c;
                    if (qty == null) { qty = 0; }
                    
                    bottleMultiplier = pmia.Standard_Bottle_Multiplier__c;
                    if (bottleMultiplier == null || bottleMultiplier == 0) { bottleMultiplier = 1;}
                    unitMultiplier = pmia.Product_Unit_Size__c / bottleMultiplier;
                    
                    //remainingQty = qty;
                    //remainingPayment = qty * pmia.Monthly_Per_Bottle_Discount__c;
    
                    //System.debug('[pac] remainingQty: ' + remainingQty + ', remainingPayment: ' + remainingPayment);
                    
                    if (p_Totals.brands.containsKey(pmia.Brand__c)) {
                        b_Totals = p_Totals.brands.get(pmia.Brand__c);
                    } else {
                        b_Totals = new brandTotals(pmia.Brand__c);
                    }
                
                    System.debug('[pac] qty: ' + qty + ', unitMultiplier: ' + unitMultiplier);
                    actQty = pmia.Act_Qty__c;
                    if (pmia.Act_Qty__c == null || pmia.Act_Qty__c == 0) {
	                    b_Totals.hopeQuantity += qty * unitMultiplier;   
                        actQty = 0;
                    }

                    if (pmia.Period__c <= thePromotion.Current_Period__c) {
                        b_Totals.ytdQty += actQty * unitMultiplier;
                        b_Totals.ytdPayment += pmia.Act_Payment__c;
                        
                        p_Totals.ytdQty += actQty * unitMultiplier;
                        p_Totals.ytdPayment += pmia.Act_Payment__c;
                    }
                
                    /*
                    if (pmia.Act_Qty__c == 0) {
                        b_Totals.remainingPlannedQty += remainingQty;
                        b_Totals.remainingPlannedPayment += remainingPayment;                    
    
                        p_Totals.remainingPlannedQty += remainingQty;
                        p_Totals.remainingPlannedPayment += remainingPayment;
                    }                
                    */
                    p_Totals.brands.put(b_Totals.brandId, b_Totals);    
                    
                    //System.debug('[pac] post actuals b_Totals.brand: ' + b_Totals.brandId + ', remainingQty: ' + b_Totals.remainingPlannedQty + ', remainingPayment: ' + b_Totals.remainingPlannedPayment);
                    //System.debug('[pac] post actuals pTotals: ' + p_Totals.promotionId + ', remainingQty: ' + p_Totals.remainingPlannedQty + ', remainingPayment: ' + p_Totals.remainingPlannedPayment);
                    
                }
            }
        
            p_Totals.remainingPlannedQty = 0;
            p_Totals.remainingPlannedPayment = 0;
            remainingQty = 0;
            System.debug('[pac] # of pmi: ' + thePromotionDetails.Promotion_Material_Items__r.size());
            for(Promotion_Material_Item__c pmi : thePromotionDetails.Promotion_Material_Items__r) {
                if (!pmi.Is_Product_Fee__c) {
                    System.debug('[pac] pmi.brand: ' + pmi.Product_Custom__r.Brand__c);
                    remainingQty = periodsRemaining * pmi.Monthly_Bottle_Qty__c;
                    remainingPayment = remainingQty * pmi.Monthly_Per_Bottle_Discount__c;
                    
                    bottleMultiplier = pmi.Standard_Bottle_Multiplier__c;
                    if (bottleMultiplier == null || bottleMultiplier == 0) { bottleMultiplier = 1; }
                    unitMultiplier = pmi.Product_Unit_Size__c / bottleMultiplier;
                    System.debug('[pac] pmi.remainingQty: ' + remainingQty + ', remainingPayment: ' + remainingPayment);
                    if (p_Totals.brands.containsKey(pmi.Product_Custom__r.Brand__c)) {
                        b_Totals = p_Totals.brands.get(pmi.Product_Custom__r.Brand__c);
                    } else {
                        b_Totals = new brandTotals(pmi.Product_Custom__r.Brand__c);                    
                    }
                    b_Totals.remainingPlannedQty += remainingQty * unitMultiplier;
                    b_Totals.remainingPlannedPayment += remainingPayment;
                
                    p_Totals.remainingPlannedQty += remainingQty * unitMultiplier;
                    p_Totals.remainingPlannedPayment += remainingPayment;
                    
                    p_Totals.brands.put(b_Totals.brandId, b_Totals);
                }
            }
                
            thePromotion.YTD_Actual_QTY__c = p_Totals.ytdQty;
            thePromotion.YTD_Actual_Payment__c = p_Totals.ytdPayment;
            thePromotion.Total_Remaining_Planned_Qty__c = p_Totals.remainingPlannedQty;
            thePromotion.Total_Remaining_Planned_Payment__c = p_Totals.remainingPlannedPayment;

            for(Promotion_Costs__c pc : thePromotionDetails.Promotion_Costs__r) {
                b_Totals = p_Totals.brands.get(pc.Brand__c);
                pc.YTD_Actual_QTY__c = b_Totals.ytdQty;
                pc.YTD_Actual_Payment__c = b_Totals.ytdPayment;
                pc.Remaining_Planned_Qty__c = b_Totals.remainingPlannedQty;
                pc.Remaining_Planned_Payment__c = b_Totals.remainingPlannedPayment;
                pc.Hope_Quantity__c = b_Totals.hopeQuantity;
            }                
            
            l_PromotionCosts.addAll(thePromotionDetails.Promotion_Costs__r);
            
            thePromotion.Actuals_Updated__c = false;
        }
        for(Promotion_Costs__c pc : l_PromotionCosts) {
            System.debug('[pac] pc.id: ' + pc.Id + ', brand: ' + pc.Brand_Name__c + ', promotion: ' + pc.Promotion__c);
        }
        update l_PromotionCosts;
        
        return promotions;
    }
}