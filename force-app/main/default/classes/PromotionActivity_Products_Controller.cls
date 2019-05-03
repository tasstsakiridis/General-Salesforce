global with sharing class PromotionActivity_Products_Controller {
    public Promotion_Activity__c thisActivity       		{ get; set; }
    public List<Promotion_Material_Item__c> pmiList 		{ get; set; }
    public List<Promotion_Material_A_P__c> apItemList		{ get; set; }
    public List<Product__c> productList             		{ get; set; }
    
    public String serializedActivity                		{ get; set; }
    public String serializedPMIFS       					{ get; set; }
    public String serializedAPItemFS						{ get; set; }
    public String serializedReadOnlyFieldList	    		{ get; set; }
    public String serializedProductList             		{ get; set; }
    public String serializedPMIList     					{ get; set; }
    public String serializedAPItemList						{ get; set; }
    
    public String urlPrefix           						{ get; set; }
    public String channel             						{ get; set; }
    public String marketName          						{ get; set; }
    public String region									{ get; set; }
    public String activityType								{ get; set; }
    public String pmiRecordTypeId							{ get; set; }
    public String pmiRecordTypeName							{ get; set; }
    public String productFieldNameToUse             		{ get; set; }
    public String userCurrency								{ get; set; }
    public String linkToPromotionId							{ get; set; }
    public Boolean lockActivity								{ get; set; }
        
    public PromotionActivity_Products_Controller(ApexPages.StandardController controller) {
		userCurrency = UserInfo.getDefaultCurrency();
            
        thisActivity = [SELECT Id, Name, RecordTypeId, RecordType.Name, Channel__c, Account_Region__c, Begin_Date__c, End_Date__c, Status__c, Market__c, Market__r.Name, Wholesaler__c, Wholesaler__r.Name, (SELECT Id FROM Promotions__r) FROM Promotion_Activity__c WHERE Id =:controller.getId()];
    	
        marketName = thisActivity.Market__r.Name;
        channel = thisActivity.Channel__c;
        region = thisActivity.Account_Region__c;
		activityType = thisActivity.RecordType.Name;
        
        lockActivity = thisActivity.Status__c == 'Approved' || thisActivity.Status__c == 'Submitted';
        
        serializedActivity = JSON.serialize(thisActivity);
        
        if (thisActivity.Promotions__r != null && thisActivity.Promotions__r.size() > 0) {
            linkToPromotionId = thisActivity.Promotions__r[0].Id;
        }
        
        Map<String, RecordTypeInfo> rtList = Promotion_Material_Item__c.SObjectType.getDescribe().getRecordTypeInfosByName();
        Map<String, RecordTypeInfo> rtAPList = Promotion_Material_A_P__c.SObjectType.getDescribe().getRecordTypeInfosByName();
        Map<String,String> pageParams = ApexPages.currentPage().getParameters();
		String pageType = pageParams.get('type');
        String pmiObjectName = 'Promotion_Material_Item__c';
        String productRecordType = 'Wet Goods';
        pmiRecordTypeName = 'Sales Proposal';
        pmiRecordTypeId = rtList.get(pmiRecordTypeName).getRecordTypeId();
        if (pageType == 'APItem') {
            pmiObjectName = 'Promotion_Material_A_P__c';
            productRecordType = 'Dry Goods';
            pmiRecordTypeId = rtAPList.get(pmiRecordTypeName).getRecordTypeId();
        }
        String fieldSetName = marketName + '_' + pmiRecordTypeName + '_' + channel;
        fieldSetName = fieldSetName.replace(' ','_');
        fieldSetName = fieldSetName.replace('-','_');
System.debug('fieldsetname: ' + fieldSetName);
        
		List<Schema.FieldSetMember> pmiFS;
        List<Schema.FieldSetMember> apItemFS;
        List<String> readOnlyFields;
        String theFieldSetName = FieldSetHelper.validateFieldSetName('Promotion_Material_Item__c', fieldSetName, true);
        System.debug('[PA_Products_Controller] theFieldSetName: ' + theFieldSetName);
        if (theFieldSetName.length() > 0) {
            pmiFS = FieldSetHelper.getFieldSetFields('Promotion_Material_Item__c', theFieldSetName);
            if (pmiFS == null) { pmiFS = new List<Schema.FieldSetMember>(); }
            serializedPMIFS = JSON.serialize(pmiFS);
            
            apItemFS = FieldSetHelper.getFieldSetFields('Promotion_Material_A_P__c', theFieldSetName);
            if (apItemFS == null) { apItemFS = new List<Schema.FieldSetMember>(); }
            serializedAPItemFS = JSON.serialize(apItemFS);        
            
            readOnlyFields = FieldSetHelper.getFieldSetFieldNames(pmiObjectName, theFieldSetName.toLowerCase() + '_ROF');
            if (readOnlyFields == null) { readOnlyFields = new List<String>(); }
            serializedReadOnlyFieldList = JSON.serialize(readOnlyFields);
            
        }
        
        productList = [SELECT Id, Name, ProductCode__c, Pack_Quantity__c, RecordType.Name, Channel__c, Brand_Name__c, Brand__r.Name, Brand__r.Spirit_Type__c, Supplier__c, Unit_Size__c, Unit_Cost__c, Used_For__c, Price__c, Wholesale_Price__c FROM Product__c WHERE IsActive__c = true AND Market__c =: thisActivity.Market__c AND (Channel__c =:channel OR Channel__c = 'Both') AND RecordType.Name =:productRecordType ORDER BY Name ASC];                            
        if (productList == null) {
            serializedProductList = '';
        } else {
            serializedProductList = JSON.serialize(productList);
        }
        String soql = 'SELECT Id, Name, RecordTypeId, RecordType.Name, Product_Custom__c, Product_Custom__r.Name, Product_Custom__r.Brand_Name__c, Product_Custom__r.Pack_Quantity__c, Product_Custom__r.Unit_Size__c, Product_Custom__r.Unit_Cost__c, ';
        for(Schema.FieldSetMember fsm : pmiFS) {
            soql += fsm.getFieldPath() + ',';
        }
        soql += '(SELECT Id, Name, A_P_Item__c, A_P_Item__r.Name,';
        for(Schema.FieldSetMember fsm : apItemFS) {
            soql += fsm.getFieldPath() + ',';
        }
        soql = soql.removeEnd(',');
        soql += ' FROM Promotion_Material_A_P_Items__r) ';
        soql += ' FROM Promotion_Material_Item__c WHERE Activity__c = \'' + thisActivity.Id + '\' ORDER BY RecordType.Name DESC';
        pmiList = Database.query(soql);
        if (pmiList == null) {
            serializedPMIList = '';
        } else {
            serializedPMIList = JSON.serialize(pmiList);
        }
        
    }
    
    @RemoteAction
    global static List<Promotion_Material_Item__c> saveProducts(String activityId, List<Promotion_Material_Item__c> itemsToAdd, List<Promotion_Material_Item__c> itemsToDelete, Boolean updateActivityTotals){
        if (itemsToDelete != null && itemsToDelete.size() > 0) {
            List<Id> productIds = new List<Id>();
            for(Promotion_Material_Item__c cp : itemsToDelete) {
                productIds.add(cp.Product_Custom__c);
            }
            
            delete itemsToDelete;
        }
        
        for(Promotion_Material_Item__c pmi : itemsToAdd) {
            pmi.Remaining_Discount__c = pmi.Total_Plan_Discount__c;
            pmi.Remaining_Volume__c = pmi.Target_Qty__c;
            pmi.Remaining_Free_Bottle_Qty__c = pmi.Free_Bottle_Quantity__c;
        }
    	upsert itemsToAdd;   

        if (updateActivityTotals) {
            Promotion_Activity__c theActivity = [SELECT Id, SalesProposal_Products_Updated__c FROM Promotion_Activity__c WHERE Id = :activityId LIMIT 1];
            theActivity.SalesProposal_Products_Updated__c = true;
            update theActivity;
        }
    	return itemsToAdd;
    }    
    @RemoteAction
    global static List<Promotion_Material_A_P__c> saveAPItems(string activityId, List<Promotion_Material_A_P__c> itemsToAdd, List<Promotion_Material_A_P__c> itemsToDelete, Boolean updateActivityTotals) {
        if (itemsToDelete != null && itemsToDelete.size() > 0) {
            delete itemsToDelete;
        }

        upsert itemsToAdd;

        Promotion_Activity__c theActivity = [SELECT Id, Requires_Marketing_Approval__c, SalesProposal_Products_Updated__c, (SELECT Id, Remaining_A_P___c FROM Promotion_Material_Items__r) FROM Promotion_Activity__c WHERE Id =:activityId LIMIT 1];
        Boolean requiresMarketingApproval = false;
        Map<Id, Decimal> pmis = new Map<Id, Decimal>();
        Decimal remainingAP = 0;
        for(Promotion_Material_A_P__c ap : itemsToAdd) {
            if (ap.Budget_Type__c == 'Marketing') {
                requiresMarketingApproval = true;
                break;
            }

            remainingAP = 0;
            if (pmis.containsKey(ap.Promotion_Material_Item__c)) {
                remainingAP = pmis.get(ap.Promotion_Material_Item__c);
            }

            remainingAP += ap.Quantity__c;
            pmis.put(ap.Promotion_Material_Item__c, remainingAP);
        }

        for(Promotion_Material_Item__c pmi : theActivity.Promotion_Material_Items__r) {
            pmi.Remaining_A_P__c = pmis.get(pmi.Id);
        }
        update theActivity.Promotion_Material_A_P_Items__r;

        theActivity.Requires_Marketing_Approval__c = requiresMarketingApproval;
        theActivity.Is_Taking_From_Marketing_Budget__c = requiresMarketingApproval;
        theActivity.SalesProposal_Products_Updated__c = updateActivityTotals;
        update theActivity;
        
        return itemsToAdd;
    }
}