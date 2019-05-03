public with sharing class SalesProposal_Actuals_Controller {
    public Promotion_Activity__c thisActivity       		{ get; set; }
    public List<Promotion_Material_Item__c> pmiList 		{ get; set; }
    public List<Promotion_Material_A_P__c> apItemList		{ get; set; }
    public List<Product__c> productList             		{ get; set; }
    
    public String serializedActivity                		{ get; set; }
    public String serializedItems                           { get; set; }
    public String serializedPMAFS       					{ get; set; }
    public String serializedReadOnlyFieldList	    		{ get; set; }
    public String serializedPMIActualsDescribe		        { get; set; }
    
    public String proposalId                                { get; set; }
    public String urlPrefix           						{ get; set; }
    public String channel             						{ get; set; }
    public String marketName          						{ get; set; }
    public String activityType								{ get; set; }
    public String userCurrency								{ get; set; }

    public class SalesProposalAccountWrapper {
        public String id                { get; set; }
        public String accountId         { get; set; }
        public String accountName       { get; set; }
        public Decimal actQty           { get; set; }
        public Decimal actAP            { get; set; }
        public Decimal actFreeQty       { get; set; }
        public Decimal actDiscount      { get; set; }
        public Date paymentDate         { get; set; }

        public void SalesProposalAccountWrapper() {
            this.id = '';
            this.accountId = '';
            this.accountName = '';
            this.actQty = 0;
            this.actAP = 0;
            this.actFreeQty = 0;
            this.actDiscount = 0;
            this.paymentDate = null;
        }
        public void SalesProposalAccountWrapper(PMI_Actual__c pmia) {
            this.id = pmia.Id;
            this.accountId = pmia.Account__c;
            this.accountName = pmia.Account_Name__c;
            this.actQty = pmia.Act_Qty__c;
            this.actAP = pmia.Actual_A_P__c;
            this.actFreeQty = pmia.Actual_Free_Bottle_Qty__c;
            this.actDiscount = pmia.Actual_Discount__c;
            this.paymentDate = pmia.Payment_Date__c;        
        }
        public void SalesProposalAccountWrapper(String id, String accountId, String accountName, Decimal actQty, Decimal actAP, Decimal actFreeQty, Decimal actDiscount, Date paymentDate) {
            this.id = id;
            this.accountId = accountId;
            this.accountName = accountName;
            this.actQty = actQty;
            this.actAP = actAP;
            this.actFreeQty = actFreeQty;
            this.actDiscount = actDiscount;
            this.paymentDate = paymentDate;
        }
    }  
    public class SalesProposalPeriodWrapper {
        String period                               { get; set; }
        String month                                { get; set; }
        String year                                 { get; set; }
        List<SalesProposalAccountWrapper> accounts  { get; set; }

        public void SalesProposalPeriodWrapper() {
            this.period = '';
            this.month = '';
            this.year = '';
            this.accounts = new List<SalesProposalAccountWrapper>();
        }
        public void SalesProposalPeriodWrapper(String period, String month, String year) {
            this.period = period;
            this.month = month;
            this.year = year;
            this.accounts = new List<SalesProposalAccountWrapper>();
        }
    }
    public class SalesProposalProductWrapper {
        String id                                       { get; set; }
        String productName                              { get; set; }
        Map<String, SalesProposalPeriodWrapper> periods { get; set; }

        public SalesProposalProductWrapper() {
            this.id = '';
            this.productName = '';
            this.periods = new Map<String, SalesProposalPeriodWrapper>();
        }
        public SalesProposalProductWrapper(String id, String name) {
            this.id = id;
            this.productName = name;
            this.periods = new Map<String, SalesProposalPeriodWrapper>();
        }
    }
    public SalesProposal_Actuals_Controller(ApexPages.StandardController controller) {
        proposalId = controller.getId();
        thisActivity = [SELECT Id, Name, Sales_Proposal_Id__c, CreatedById, CreatedBy.Name, CreatedDate, Channel__c, Begin_Date__c, End_Date__c, Proposal_Objectives__c, Proposal_Mechanics__c, Wholesaler_Name__c, eclips_Description__c, 
                           (SELECT Id, Name, Account__c, AccountName__c FROM Promotions__r), 
                           (SELECT Id, Product_Custom__c, Brand__c, Product_Name__c, Product_Custom__r.Is_External_Product__c, Plan_Qty__c, Plan_Rebate__c, Free_Bottle_Quantity__c, Free_Bottle_Cost__c, Free_Bottle_COGS__c, Plan_Qty_9L__c, Target_Qty__c, Target_Qty_9L__c, Total_Outlet_Incentive__c, Total_Outlet_Incentive_9L__c, Wholesaler_Discount__c, Product_Gross_Selling_Price__c, Product_Pack_Qty__c, Product_Unit_Cost__c, Cost_of_Goods_Per_Bottle__c, Plan_COGS__c, Plan_Net_Sales__c, Plan_Gross_Profit__c, Plan_Brand_Profit__c, Plan_Gross_Profit_vs_Plan_Net_Sales__c, Total_Plan_Discount__c FROM Promotion_Material_Items__r),
                           (SELECT Id, Product__c, Product_Name__c, Promotion_Material_Item__c, Promotion_Material_Item__r.Brand__c, A_P_Item__c, A_P_Item_Brand__c, A_P_Item_Name__c, Quantity__c, A_P_Item_Unit_Cost__c, A_P_Item_Total__c, A_P_Item_Total_9L__c FROM Promotion_Material_A_P_Items__r), 
                           (SELECT Id, Activity__c, Promotion__c, Account_Name__c, Promotion_Material_Item__c, Product_Name__c, Period__c, Act_Qty__c, Actual_A_P__c, Act_Date__c, Actual_Free_Bottle_Qty__c, Month_Name__c, Year__c, Payment_Date__c FROM PMI_Actuals__r ORDER BY Promotion_Material_Item__c, Period__c, Promotion__c)
                           FROM Promotion_Activity__c 
                           WHERE Id =:proposalId LIMIT 1];

        marketName = thisActivity.Market__r.Name;

        serializedActivity = JSON.serialize(thisActivity);

        bfObjectDescribe objDescribe = new bfObjectDescribe('PMI_Actual__c');
        objDescribe.getDescribe(true, false, false);
        serializedPMIActualsDescribe = JSON.serialize(objDescribe);

        try {
            Map<String,String> pageParams = ApexPages.currentPage().getParameters();
            String dept       = pageParams.get('dept');
            if (dept == null) { dept = ''; }

            String fieldSetName = marketName + '_SalesProposal';
            fieldSetName = fieldSetName.replace(' ','_');
            fieldSetName = fieldSetName.replace('-','_');
            if (dept != null && dept.length() > 0) { fieldSetName = fieldSetName + '_' + dept; }
            system.debug('fieldSetName: '+fieldSetName);
        
            List<Schema.FieldSetMember> pmaFS = FieldSetHelper.getFieldSetFields('PMI_Actual__c', fieldSetName);
            serializedPMAFS = JSON.serialize(pmaFS);
    
            List<String> readOnlyFields = FieldSetHelper.getFieldSetFieldNames('PMI_Actual__c', fieldSetName.toLowerCase() + '_ROF');
            serializedReadOnlyFieldList = JSON.serialize(readOnlyFields);


            Map<String, SalesProposalProductWrapper> items = new Map<String, SalesProposalProductWrapper>();
            for(Promotion_Material_Item__c pmi : thisActivity.Promotion_Material_Items__r) {
                items.put(pmi.Id, new SalesProposalProductWrapper(pmi.Id, pmi.Product_Name__c));
            }

            SalesProposalProductWrapper productWrapper;
            SalesProposalPeriodWrapper periodWrapper;
            String period = '';
            for(PMI_Actual__c pmia : thisActivity.PMI_Actuals__r) {
                productWrapper = items.get(pmia.Promotion_Material_Item__c);
                period = String.valueOf(pmia.Period__c);
                if (productWrapper != null) {
                    if (productWrapper.periods.containsKey(period)) {
                        periodWrapper = productWrapper.periods.get(period);
                    } else {
                        periodWrapper = new SalesProposalPeriodWrapper(period, pmia.Month_Name__c, String.valueOf(pmia.Year__c));
                    }

                    periodWrapper.accounts.add(new SalesProposalAccountWrapper(pmia));
                    productWrapper.periods.put(period, periodWrapper);
                }
            }

            serializedItems = JSON.serialize(items);
        }catch(Exception ex) {
            System.debug('exception raised getting proposal: ' + ex.getMessage());
        }
    }

}
