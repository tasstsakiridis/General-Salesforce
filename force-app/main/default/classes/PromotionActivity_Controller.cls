global with sharing class PromotionActivity_Controller {
    public Promotion_Activity__c thisActivity 				{ get; set; }
    
    public Boolean newActivity								{ get; set; }
    public Boolean hasAccounts								{ get; set; }
    public Boolean lockActivity								{ get; set; }
    public Boolean useIntNumFormat							{ get; set; }
    
    public String activityId								{ get; set; }
    public String recordTypeId								{ get; set; }
    public String recordTypeName							{ get; set; }
    public String marketName								{ get; set; }
    public String marketId									{ get; set; }
    public String marketISO3Code							{ get; set; }
    public String userType									{ get; set; }
    public String urlPrefix									{ get; set; }
    
    public String serializedActivity                        { get; set; }
    public String serializedActivityFS                      { get; set; }
    public String serializedReadOnlyFieldList			    { get; set; }
    public String serializedRelationshipList				{ get; set; }
    
	public List<FieldSetWrapper> activityFieldSet 	        { get; set; }
    public List<String> readOnlyFieldSet 	                { get; set; }
    public List<String> lookupFieldSet						{ get; set; }
    public List<RelationshipWrapper> relationships			{ get; set; }
    
    public PromotionActivity_Controller(ApexPages.StandardController controller) {
        userType = UserInfo.getUserType();
        if(userType != 'Standard'){
            urlPrefix = '/sales';
        }else{
            urlPrefix = '';
        }                
        
        Map<String,String> pageParams = ApexPages.currentPage().getParameters();
		activityId    = pageParams.get('id');
        recordTypeName  = pageParams.get('recordType');

        if (recordTypeName == null) {
            for (Schema.RecordTypeInfo rti : Promotion_Activity__c.SObjectType.getDescribe().getRecordTypeInfos()) {
                if (rti.isDefaultRecordTypeMapping()) {
                    recordTypeId = rti.getRecordTypeId();
                    recordTypeName = rti.getName();
                }
            }
            
            if (recordTypeId == null) {
                Map<String, Schema.RecordTypeInfo> rtiList = Promotion_Activity__c.SObjectType.getDescribe().getRecordTypeInfosByName();
                if (rtiList.containsKey('Sales Proposal')) {
                    recordTypeId = rtiList.get('Sales Proposal').getRecordTypeId();
                    recordTypename = 'Sales Proposal';
                }
            }
        }
        
        hasAccounts = false;
        
        marketId = ''; marketName = '';
        if (activityId != null && activityId != '') {
            thisActivity = [SELECT Id, Name, RecordTypeId, RecordType.Name, Status__c, Begin_Date__c, End_Date__c, Account_Region__c, Channel__c, Premise__c, Wholesaler__c, Wholesaler__r.Name, Payment_Type__c, Proposal_Mechanics__c, Proposal_Objectives__c, Market__c, Market__r.Name, Market__r.Country_ISO_Code_3__c, (SELECT Id FROM Promotions__r) FROM Promotion_Activity__c WHERE Id = :activityId];
            recordTypeId = thisActivity.RecordTypeId;
			recordTypeName = thisActivity.RecordType.Name;
            marketId = thisActivity.Market__c;
            marketName = thisActivity.Market__r.Name;
            marketISO3Code = thisActivity.Market__r.Country_ISO_Code_3__c;
            newActivity = false;
            
            if (thisActivity.Promotions__r != null && thisActivity.Promotions__r.size() > 0) {
                hasAccounts = true;
            }
        } else { 
            if (recordTypeName == 'SalesProposal') { recordTypeName = 'Sales Proposal'; }
            Map<String, RecordTypeInfo> recordTypes = Promotion_Activity__c.SObjectType.getDescribe().getRecordTypeInfosByName();
            if (recordTypes.containsKey(recordTypeName)) {
                recordTypeId = recordTypes.get(recordTypeName).getRecordTypeId();
            } else {
                // error
            }                
            
        	List<User> thisUser = [SELECT Market__c FROM User WHERE Id =: UserInfo.getUserId()];
            if (thisUser != null) {
                List<Market__c> market = [SELECT Id, Name, Country_ISO_Code_3__c FROM Market__c WHERE Name =: thisUser[0].Market__c];
                if (market != null) {
                    marketId = market[0].Id;
                    marketName = market[0].Name;
                    marketISO3Code = market[0].Country_ISO_Code_3__c;
                }
            }
            
            thisActivity = new Promotion_Activity__c(RecordTypeId=recordTypeId,Status__c='New',Market__c=marketId);
            newActivity = true;
            
        }
        
        lockActivity = thisActivity.Status__c == 'Submitted';
        
        //Check to see if we need to use '.' instead of ',' for large numbers
		setIntNumFormat();
        if (recordTypeName == null || recordTypeName.length() == 0) { recordTypeName = 'Sales Proposal'; }
        String fieldSetName = marketName + '_' + recordTypeName;
        fieldSetName = fieldSetName.replace(' ','_');
        fieldSetName = fieldSetName.replace('-','_');

        Set<String> toexclude = new Set<String>{(fieldSetName + '_rof').toLowerCase()};
            if (fieldSetName.indexOf('Locked') < 0) {
                toexclude.add((fieldSetName + '_locked').toLowerCase());
                toexclude.add((fieldSetName + '_locked_rof').toLowerCase());
            }
        activityFieldSet = FieldSetHelper.getFieldSetsWithLabelAndIndex('Promotion_Activity__c', fieldSetName.toLowerCase(), toexclude);
        if (activityFieldSet == null || activityFieldSet.size() == 0) {
            activityFieldSet = FieldSetHelper.getFieldSetsWithLabelAndIndex('Promotion_Activity__c', 'Default', toexclude);
        }

        readOnlyFieldSet = FieldSetHelper.getFieldSetFieldNames('Promotion_Activity__c', fieldSetName.toLowerCase() + '_ROF');

        // Use the lookup field set to build the where clause of the lookup.
        // each field in this fieldset should have the format of:  Object.Fieldname.  eg:  Contact__r.AccountId
        // 
        // Build list of where clauses for all lookup fields in the promotions object 
        System.debug('marketId: ' + marketId);
        String wholesalerRecordTypeId = '';
        Map<String, RecordTypeInfo> recordTypes = Account.SObjectType.getDescribe().getRecordTypeInfosByName();
		String wholesalerRecordTypeName = marketISO3Code + ' - Wholesaler';
        if (recordTypes.containsKey(wholesalerRecordTypeName)) {
            wholesalerRecordTypeId = recordTypes.get(wholesalerRecordTypeName).getRecordTypeId();
        } else {
            wholesalerRecordTypeId = recordTypes.get('Wholesalers').getRecordTypeId();
        }
        
        relationships = new List<RelationshipWrapper>();
        relationships.add(new RelationshipWrapper('Wholesaler__c', 'Account', 'suppliers', 'WHERE Market__c = \'' + String.escapeSingleQuotes(marketId) + '\' AND Is_Active__c=true AND RecordTypeId = \'' + wholesalerRecordTypeId + '\''));
        serializedRelationshipList = JSON.serialize(relationships);

        if (readOnlyFieldSet != null) {
            serializedReadOnlyFieldList = JSON.serialize(readOnlyFieldSet);            
        }        

        serializedActivityFS = JSON.serialize(activityFieldSet);            
        if(!newActivity){
            //Build query for Promotion fields, unique set to ensure that fields aren't repeated in the field set
            String activityQuery = 'SELECT';
            set<string> uniqueFields = new set<string>();
            uniqueFields.add('Id');
            uniqueFields.add('Name');
            uniqueFields.add('RecordTypeId');
            uniqueFields.add('RecordType.Name');
            uniqueFields.add('Market__c');
            for(FieldSetWrapper fsm : activityFieldSet) {
                for(Schema.FieldSetMember asf : fsm.fields) {
                    if(!uniqueFields.contains(asf.getFieldPath())){
                        uniqueFields.add(asf.getFieldPath());
                    }                    
                }
            }
            for(string s:uniqueFields){
                activityQuery += ' ' + s + ',';
            }
            activityQuery = activityQuery.substring(0, activityQuery.length()-1); 
            activityQuery += ' FROM Promotion_Activity__c WHERE Id = \'' + thisActivity.Id + '\'';
            
            thisActivity = Database.query(activityQuery);			            
        }  		        	  
        
        try {
            serializedActivity = JSON.serialize(thisActivity);            
        }catch(NullPointerException ex) {
            serializedActivity = '';
        }        
        
    }
    
    public void setIntNumFormat(){
        if(International_Number_Format__c.getInstance(marketName) == null){
            useIntNumFormat = false;
        }else{
            useIntNumFormat = true;
        }
    }

    @RemoteAction
    global static Promotion_Activity__c saveActivity (String fields){
        Promotion_Activity__c activity = (Promotion_Activity__c)JSON.deserialize(fields, Promotion_Activity__c.class);

    	upsert activity;
    	return activity;
    }
    
 	@RemoteAction
    global static void submitForApproval(String proposalId) {
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting SalesProposal approval request.');
        req1.setObjectId(proposalId);
        Approval.process(req1);
        
    }
}