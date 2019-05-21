public with sharing class SalesProposal_Actuals_Controller {
    public Promotion_Activity__c thisProposal       		{ get; set; }
    public List<Promotion_Material_Item__c> pmiList 		{ get; set; }
    public List<Promotion_Material_A_P__c> apItemList		{ get; set; }
    public List<Product__c> productList             		{ get; set; }
    
    public String serializedProposal                		{ get; set; }
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
    public String proposalRecordTypeId                      { get; set; }

    public class SalesProposalAccountWrapper {
        public String id                        { get; set; }
        public String accountId                 { get; set; }
        public String accountName               { get; set; }
        public Decimal planQty                  { get; set; }
        public Decimal actQty                   { get; set; }
        public Decimal actualAP                 { get; set; }
        public Decimal actualFreeQty            { get; set; }
        public Decimal actualDiscount           { get; set; }
        public Date paymentDate                 { get; set; }
        public PMI_Actual__c pmia               { get; set; }
        public String approvalStatus            { get; set; }

        public SalesProposalAccountWrapper() {
            this.id = '';
            this.accountId = '';
            this.accountName = '';
            this.planQty = 0;
            this.actQty = 0;
            this.actualAP = 0;
            this.actualFreeQty = 0;
            this.actualDiscount = 0;
            this.paymentDate = null;
            this.pmia = null;
            this.approvalStatus = 'New';
        }
        public SalesProposalAccountWrapper(PMI_Actual__c pmia) {
            this.id = pmia.Id;
            this.accountId = pmia.Account__c;
            this.accountName = pmia.Account_Name__c;
            this.planQty = pmia.Plan_Qty__c;
            this.actQty = pmia.Act_Qty__c;
            this.actualAP = pmia.Actual_A_P__c;
            this.actualFreeQty = pmia.Actual_Free_Bottle_Qty__c;
            this.actualDiscount = pmia.Actual_Discount__c;
            this.paymentDate = pmia.Payment_Date__c;  
            this.approvalStatus = pmia.Approval_Status__c;
            this.pmia = pmia;      
        }
    }  
    public class SalesProposalPeriodWrapper {
        String period                               { get; set; }
        String month                                { get; set; }
        String year                                 { get; set; }
        List<SalesProposalAccountWrapper> accounts  { get; set; }

        public SalesProposalPeriodWrapper() {
            this.period = '';
            this.month = '';
            this.year = '';
            this.accounts = new List<SalesProposalAccountWrapper>();
        }
        public SalesProposalPeriodWrapper(String period, String month, String year) {
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
        thisProposal = [SELECT Id, Name, Sales_Proposal_Id__c, RecordTypeId, RecordType.Name, CreatedById, CreatedBy.Name, CreatedDate, Channel__c, Begin_Date__c, End_Date__c, Proposal_Objectives__c, Proposal_Mechanics__c, Wholesaler_Name__c, eclips_Description__c, Market__r.Name,
                           (SELECT Id, Name, Account__c, AccountName__c FROM Promotions__r), 
                           (SELECT Id, Product_Custom__c, Brand__c, Product_Name__c, Product_Custom__r.Is_External_Product__c, Plan_Qty__c, Plan_Rebate__c, Free_Bottle_Quantity__c, Free_Bottle_Cost__c, Free_Bottle_COGS__c, Plan_Qty_9L__c, Target_Qty__c, Target_Qty_9L__c, Total_Outlet_Incentive__c, Total_Outlet_Incentive_9L__c, Wholesaler_Discount__c, Product_Gross_Selling_Price__c, Product_Pack_Qty__c, Product_Unit_Cost__c, Cost_of_Goods_Per_Bottle__c, Plan_COGS__c, Plan_Net_Sales__c, Plan_Gross_Profit__c, Plan_Brand_Profit__c, Plan_Gross_Profit_vs_Plan_Net_Sales__c, Total_Plan_Discount__c FROM Promotion_Material_Items__r),
                           (SELECT Id, Product__c, Product_Name__c, Promotion_Material_Item__c, Promotion_Material_Item__r.Brand__c, A_P_Item__c, A_P_Item_Brand__c, A_P_Item_Name__c, Quantity__c, A_P_Item_Unit_Cost__c, A_P_Item_Total__c, A_P_Item_Total_9L__c FROM Promotion_Material_A_P_Items__r), 
                           (SELECT Id, Activity__c, Promotion__c, Account__c, Account_Name__c, Promotion_Material_Item__c, Product_Name__c, Period__c, Plan_Qty__c, Proposed_Discount__c, Act_Qty__c, Actual_A_P__c, Act_Date__c, Actual_Free_Bottle_Qty__c, Actual_Discount__c, Month_Name__c, Year__c, Payment_Date__c, Approval_Status__c FROM PMI_Actuals__r ORDER BY Promotion_Material_Item__c, Period__c, Promotion__c)
                           FROM Promotion_Activity__c 
                           WHERE Id =:proposalId LIMIT 1];

        marketName = thisProposal.Market__r.Name;

        serializedProposal = JSON.serialize(thisProposal);

        bfObjectDescribe objDescribe = new bfObjectDescribe('PMI_Actual__c');
        objDescribe.getDescribe(true, false, false);
        serializedPMIActualsDescribe = JSON.serialize(objDescribe);

        Map<String, Schema.RecordTypeInfo> rtSchemaList = Schema.SObjectType.PMI_Actual__c.getRecordTypeInfosByName();
        this.proposalRecordTypeId = rtSchemaList.get('Sales Proposal').getRecordTypeId();

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
            for(Promotion_Material_Item__c pmi : thisProposal.Promotion_Material_Items__r) {
                items.put(pmi.Id, new SalesProposalProductWrapper(pmi.Id, pmi.Product_Name__c));
            }

            System.debug('# of items: ' + items.size());
            SalesProposalProductWrapper productWrapper;
            SalesProposalPeriodWrapper periodWrapper;
            String period = '';
            for(PMI_Actual__c pmia : thisProposal.PMI_Actuals__r) {
                productWrapper = items.get(pmia.Promotion_Material_Item__c);
                period = String.valueOf(pmia.Period__c);
                System.debug('product.id: ' + productWrapper.productName);
                System.debug('period: ' + period);
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
            System.debug('serializedItems: ' + serializedItems);
        }catch(Exception ex) {
            System.debug('exception raised getting proposal: ' + ex.getMessage());
        }
    }

    @RemoteAction
    public static List<PMI_Actual__c> save(String itemsToSave, String proposalId, Boolean notifyFinance) {        
        if (itemsToSave == null || itemsToSave.length() == 0) {
            return null;
        }

        List<PMI_Actual__c> items = (List<PMI_Actual__c>)JSON.deserialize(itemsToSave, List<PMI_Actual__c>.class);
        update items;

        System.debug('[save] notifyFinance: ' + notifyFinance);
        if (notifyFinance) {
            Promotion_Activity__c activity = [SELECT Id, SalesProposal_Actuals_Updated__c FROM Promotion_Activity__c WHERE Id =:proposalId LIMIT 1];
            if (activity != null) {
                activity.SalesProposal_Actuals_Updated__c = true;
                update activity;
            }            
        }

        return items;
    }
}
