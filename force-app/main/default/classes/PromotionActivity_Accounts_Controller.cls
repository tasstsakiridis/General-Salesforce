global with sharing class PromotionActivity_Accounts_Controller {
    public Promotion_Activity__c thisActivity		{ get; set; }
    public List<Promotion__c> promotionList			{ get; set; }
    
    public Boolean lockActivity						{ get; set; }
    
    public String channel							{ get; set; }
    public String region							{ get; set; }
    public String marketName						{ get; set; }
    public String activityType						{ get; set; }
    public String urlPrefix							{ get; set; }
    public String promotionRecordTypeId				{ get; set; }
    
    public String serializedActivity				{ get; set; }
    public String serializedPromotionList			{ get; set; }
    public String serializedAccountList				{ get; set; }
    public String serializedPromotionFS				{ get; set; }
    public String serializedReadOnlyFieldList		{ get; set; }

    public PromotionActivity_Accounts_Controller(ApexPages.StandardController controller) {
        System.debug('proposalId: ' + controller.getId());
        thisActivity = [SELECT Id, Name, RecordTypeId, RecordType.Name, Channel__c, Account_Region__c, Begin_Date__c, End_Date__c, Status__c, Market__c, Market__r.Name, Wholesaler__c, Wholesaler__r.Name FROM Promotion_Activity__c WHERE Id =:controller.getId()];
    	
        marketName = thisActivity.Market__r.Name;
        channel = thisActivity.Channel__c;
        region = thisActivity.Account_Region__c;
		activityType = thisActivity.RecordType.Name;
        
        lockActivity = thisActivity.Status__c == 'Approved' || thisActivity.Status__c == 'Submitted';
        
        promotionRecordTypeId = Promotion__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Proposal').getRecordTypeId();
        
        serializedActivity = JSON.serialize(thisActivity);
        
        String fieldSetName = marketName + '_' + thisActivity.RecordType.Name;
        fieldSetName = fieldSetName.replace(' ','_');
        fieldSetName = fieldSetName.replace('-','_');

        List<Schema.FieldSetMember> caFS = FieldSetHelper.getFieldSetFields('Promotion__c', fieldSetName);
        if (caFS == null) { caFS = new List<Schema.FieldSetMember>(); }
        serializedPromotionFS = JSON.serialize(caFS);

        List<String> readOnlyFields = FieldSetHelper.getFieldSetFieldNames('Promotion__c', fieldSetName.toLowerCase() + '_ROF');
        if (readOnlyFields == null) { readOnlyFields = new List<String>(); }
        serializedReadOnlyFieldList = JSON.serialize(readOnlyFields);
        
        List<Promotion__c> promotionList = [SELECT Id, Account__c, Account__r.Name, City__c, Area__c, Group__c, SubGroup__c, Outlet_Class__c FROM Promotion__c WHERE Promotion_Activity__c =: thisActivity.Id];
        if (promotionList == null) {
            serializedPromotionList = '';
        } else {
            serializedPromotionList = JSON.serialize(promotionList);
        }
        
		List<String> regions = region.split(';');
        
        String regionList = region.replaceAll(';', '\',\'');
        regionList = '\'' + regionList + '\'';
        System.debug('channel: ' + channel);
        System.debug('marketName: ' + marketName);
        System.debug('regionlist:' + regionList);
        List<Account> accountList = [SELECT Id, Name, Channel__c, Region__c, City__c, Area__c, Group__c, SubGroup__c, Outlet_Class__c, Outlet_Class__r.Name FROM Account WHERE Market__r.Name =: marketName AND Is_Active__c = true AND Channel__c =: channel AND Region__c IN :regions];
        if (accountList == null) {
            serializedAccountList = '';
        } else {
            serializedAccountList = JSON.serialize(accountList);
        }
                
    }
    
    @RemoteAction
    global static List<Promotion__c> save(List<Promotion__c> accountsToAdd, List<Promotion__c> accountsToDelete, String activityId) {
        List<Activity_Account__c> aaList;
        if (accountsToDelete != null && accountsToDelete.size() > 0) {
            /*
            List<Id> aaToDelete = new List<Id>();
            for(Promotion__c p : accountsToDelete) {
                aaToDelete.add(p.Account__c);
            }
            aaList = [SELECT Id FROM Activity_Account__c WHERE Activity__c =:activityId AND Account_No_Filter__c =:aaToDelete];
            delete aaList;			
			*/
            delete accountsToDelete;
        }
        /*
        Activity_Account__c aa;
        aaList = new List<Activity_Account__c>();
        for(Promotion__c p : accountsToAdd) {
            aa = new Activity_Account__c();
            aa.Activity__c = activityId;
            aa.Account_No_Filter__c = p.Account__c;
            
            aaList.add(aa);
        }
        upsert aaList;		
		*/
        upsert accountsToAdd;
        return accountsToAdd;
    }
}