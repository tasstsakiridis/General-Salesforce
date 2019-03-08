global with sharing class PromotionMaterialItemHTML_Controller {
    public Promotion__c thisPromotion               { get; set; }
    public List<Promotion_Material_Item__c> pmiList { get; set; }
    public List<Product__c> productList             { get; set; }
    
    public String serializedPromotion               { get; set; }
    public String serializedMaterialItemFS          { get; set; }
    public String serializedReadOnlyFieldList	    { get; set; }
    public String serializedProductList             { get; set; }
    public String serializedMaterialItemList        { get; set; }
    
    public String urlPrefix           				{ get; set; }
    public String channel             				{ get; set; }
    public String marketName          				{ get; set; }
    public String promotionType       				{ get; set; }
    public String pmiRecordTypeId     				{ get; set; }
    public String productFieldNameToUse             { get; set; }
    public String userCurrency						{ get; set; }
    
    public Boolean usaMarket		                { get; set; }
    public Boolean isApprover                       { get; set; }
    public Boolean lockPMI							{ get; set; }
    
    public PromotionMaterialItemHTML_Controller(ApexPages.StandardController controller) {
        usaMarket = false;
		userCurrency = UserInfo.getDefaultCurrency();
        
        thisPromotion = [SELECT Id, Name, RecordTypeId, RecordType.Name, Promotion_Start_Date__c, Promotion_End_Date__c, Account__c, AccountName__c, Account__r.Channel__c, Account__r.Market__c, Account__r.Market__r.Name, Channel__c, CallCard__c, Status__c, Approval_Status__c, Promotion_Type__c, Number_of_Periods__c FROM Promotion__c WHERE Id =:controller.getId()];
        
        channel = thisPromotion.Account__r.Channel__c;
        marketName = thisPromotion.Account__r.Market__r.Name;
        promotionType = thisPromotion.RecordType.Name;

        //find out if logged in user is the current approver or delegate and unlock record if so
        isApprover = false;
        lockPMI = true;
        List<User> approvers = [SELECT Id, DelegatedApproverId FROM User WHERE Id IN 
        							(SELECT ActorId FROM ProcessInstanceWorkItem 
        								WHERE ProcessInstance.TargetObjectId = :thisPromotion.Id AND ProcessInstance.Status = 'Pending')];

        if(thisPromotion.Status__c == 'New' || thisPromotion.Status__c == '' || marketName == 'Australia'){
        	lockPMI = false;
        }else{
        	if(thisPromotion.Status__c == 'Pending'){
		        for(User u:approvers){
			        if(UserInfo.getUserId() == u.Id || UserInfo.getUserId() == u.DelegatedApproverId){
			        	isApprover = true;
			        	lockPMI = false;
			        }
		        }
        	}else{
        		if(thisPromotion.Status__c == 'Approved'){
        			lockPMI = true;
        		}else{
        			lockPMI = false;
        		}
        		
        	}
        }

        Map<String, Schema.RecordTypeInfo> rtList = Promotion_Material_Item__c.SObjectType.getDescribe().getRecordTypeInfosByName();
        String pmiRecordTypeName = promotionType;
        if (marketName == 'China') {
            if (promotionType.equalsIgnoreCase('agreement som')) { lockPMI = false;}
            if (promotionType.startsWithIgnoreCase('agreement')) { promotionType = promotionType.substringBefore(' '); }
            pmiRecordTypeName = 'CHN - ' + promotionType;
        }
        if (marketName == 'Brazil') {
            pmiRecordTypeName = 'BRA ' + promotionType;
        }                
        Schema.RecordTypeInfo rt = rtList.get(pmiRecordTypeName);
        pmiRecordTypeId = '';
        if (rt != null) {            
            pmiRecordTypeId = rt.getRecordTypeId();
        }
        
        serializedPromotion = JSON.serialize(thisPromotion);
        
        if (channel.toLowerCase() == 'on premise') {
            channel = 'On';
        } else if (channel.toLowerCase() == 'off premise') {
            channel = 'Off';
        }
        String productChannel = channel;
        if (channel.toLowerCase() == 'combera') { productChannel = 'Off'; }

        String fieldSetName = marketName + '_' + promotionType;
        fieldSetName = fieldSetName.replace(' ','_');
        fieldSetName = fieldSetName.replace('-','_');
        System.debug('fieldSetName: ' + fieldSetName);
        List<Schema.FieldSetMember> pmiFS = FieldSetHelper.getFieldSetFields('Promotion_Material_Item__c', fieldSetName);
        if (pmiFS == null) { pmiFS = new List<Schema.FieldSetMember>(); }
        serializedMaterialItemFS = JSON.serialize(pmiFS);

        List<String> readOnlyFields = FieldSetHelper.getFieldSetFieldNames('Promotion_Material_Item__c', fieldSetName.toLowerCase() + '_ROF');
        if (readOnlyFields == null) { readOnlyFields = new List<String>(); }
        serializedReadOnlyFieldList = JSON.serialize(readOnlyFields);
        
        if (marketName == 'China') {
	        String productRecordType = 'Wet Goods';
            if (promotionType == 'Sales Promotion') { 
                productRecordType = 'Dry Goods'; 
	            productList = [SELECT Id, Name, ProductCode__c, Pack_Quantity__c, RecordType.Name, Channel__c, Brand__r.Name, Brand__r.Spirit_Type__c, Supplier__c, Unit_Size__c, Used_For__c, Unit_Cost__c FROM Product__c WHERE IsActive__c = true AND Market__c =: thisPromotion.Account__r.Market__c AND (Channel__c =:productChannel OR Channel__c = 'Both') AND RecordType.Name =:productRecordType AND Used_For__c EXCLUDES ('Fee') ORDER BY Name ASC];                            
            } else {
	            productList = [SELECT Id, Name, ProductCode__c, Pack_Quantity__c, RecordType.Name, Channel__c, Brand__r.Name, Brand__r.Spirit_Type__c, Supplier__c, Unit_Size__c, Used_For__c, Unit_Cost__c FROM Product__c WHERE IsActive__c = true AND Market__c =: thisPromotion.Account__r.Market__c AND (Channel__c =:productChannel OR Channel__c = 'Both') AND (RecordType.Name =:productRecordType OR Used_For__c INCLUDES ('Fee','Incentive')) ORDER BY Name ASC];                            
            }

        } else if (marketName == 'Poland') {
	        productList = [SELECT Id, Name, ProductCode__c, Pack_Quantity__c, RecordType.Name, Channel__c, Brand__r.Name, Brand__r.Spirit_Type__c, Supplier__c, Unit_Size__c, Used_For__c FROM Product__c WHERE IsActive__c = true AND Market__c =: thisPromotion.Account__r.Market__c AND (Channel__c =:productChannel OR Channel__c = 'Both') AND Used_For__c INCLUDES ('Promotion') ORDER BY Name ASC];            
        } else {
	        productList = [SELECT Id, Name, ProductCode__c, Pack_Quantity__c, RecordType.Name, Channel__c, Brand__r.Name, Brand__r.Spirit_Type__c, Supplier__c, Unit_Size__c, Used_For__c FROM Product__c WHERE IsActive__c = true AND Market__c =: thisPromotion.Account__r.Market__c AND (Channel__c =:productChannel OR Channel__c = 'Both') ORDER BY Name ASC];            
        }
        if (productList == null) {
            serializedProductList = '';
        } else {
            serializedProductList = JSON.serialize(productList);
        }
        String soql = 'SELECT Id, Name, Product__c, Product__r.Name, Product_Custom__c, Product_Custom__r.Name, ';
        for(Schema.FieldSetMember fsm : pmiFS) {
            soql += fsm.getFieldPath() + ',';
        }
        soql = soql.removeEnd(',');
        soql += ' FROM Promotion_Material_Item__c WHERE Promotion__c = \'' + thisPromotion.Id + '\'';
        pmiList = Database.query(soql);
        if (pmiList == null) {
            serializedMaterialItemList = '';
        } else {
            serializedMaterialItemList = JSON.serialize(pmiList);
        }
    }
    
    @RemoteAction
    global static list<Promotion_Material_Item__c> savePMI (List<Promotion_Material_Item__c> pmiList, List<Promotion_Material_Item__c> itemsToDelete, String promotionId, String marketName, String recordType){
    System.debug('[savePMI] # of pmis: ' + pmiList.size());
        
        if (itemsToDelete != null && itemsToDelete.size() > 0) {
            delete itemsToDelete;
        }
        
    	upsert pmiList;        
        
        if (recordType == 'Agreement' && marketName == 'China') {
            Map<String, Object> params = new Map<String, Object>();
            params.put('promotionId', promotionId);
            Flow.Interview.Check_Promotion_Product_Discount_Tolerance flow = new Flow.Interview.Check_Promotion_Product_Discount_Tolerance(params);
            flow.start();            
        }
        
        
    	return pmiList;
    }    
}