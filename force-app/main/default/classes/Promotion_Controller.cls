global with sharing class Promotion_Controller {

    public Promotion__c thisPromotion                       { get; set; }
    public CallCard__c thisCallCard                         { get; set; }
    public Account thisAccount                              { get; set; }

    public List<String> sectionNames						{ get; set; }    
    public String serializedPromotion                       { get; set; }
    public String serializedPromotionFS                     { get; set; }
    public String serializedAccount							{ get; set; }
    public String serializedReadOnlyFieldList			    { get; set; }
    public String serializedRelationshipList				{ get; set; }
    public String serializedMenuJSON                     	{ get; set; }
    public String userType 					                { get; set; }
    public String urlPrefix 				                { get; set; }
    public String promoId                                   { get; set; }
    public String callCardId                                { get; set; }
    public String recordTypeId                              { get; set; }
    public String promotionType								{ get; set; }
    public String accountId                                 { get; set; }
    public String accountName                               { get; set; }
    public String channel                                   { get; set; }
    public String storeType                                 { get; set; }
    public String marketId 									{ get; set; }
    public String marketName								{ get; set; }
	public String fieldSetName								{ get; set; }
	public String fieldSetChannel							{ get; set; }
	public String fieldSetSubChannel						{ get; set; }
    
	public Boolean useIntNumFormat			                { get; set; }
    public Boolean cashAndCarry						 	    { get; set; }
    public Boolean usaMarket								{ get; set; }
    public Boolean newPromotion								{ get; set; }
    public Boolean canAddMaterialItems                      { get; set; }
    
	public List<FieldSetWrapper> promotionFieldSet 	        { get; set; }
    public List<String> pmiFieldSet							{ get; set; }
    public List<String> readOnlyFieldSet 	                { get; set; }
    public List<String> lookupFieldSet						{ get; set; }
    public List<RelationshipWrapper> relationships			{ get; set; }
    public String promotionQuery  							{ get; set; }
    
    public class RelationshipWrapper {
        public String name { get; set; }
        public String objectName { get; set; }
        public String objectLabel { get; set; }
        public String objectPluralLabel { get; set; }
        public String filter { get; set; }
        public String svgClass { get; set; }
        
        public RelationshipWrapper(String name, String objectName, String svgClass, String filter) {
            this.name = name;
            this.objectName = objectName;
            this.filter = filter;
            this.svgClass = svgClass;
            
            try {
				Schema.DescribeSObjectResult r = Schema.getGlobalDescribe().get(objectName).getDescribe();
                this.objectLabel = r.getLabel();
                this.objectPluralLabel = r.getLabelPlural();
            }catch(Exception ex) {
                this.objectLabel = objectName;
                this.objectPluralLabel = objectName;
            }
        }
    }
    
    public Promotion_Controller(ApexPages.StandardController controller) {
        userType = UserInfo.getUserType();
        if(userType != 'Standard'){
        	urlPrefix = '/sales';
        }else{
        	urlPrefix = '';
        }

        Map<String,String> pageParams = ApexPages.currentPage().getParameters();
		promoId       = pageParams.get('id');
		callCardId    = pageParams.get('callCardId');
	    accountId     = pageParams.get('accountId');
        promotionType = pageParams.get('promotionType');
        recordTypeId  = pageParams.get('recordTypeId');
        System.debug('[PromotionController] recordTypeId: ' + recordTypeId);
        System.debug('[PromotionController] promotionType: ' + promotionType);
        if(callCardId == 'undefined') { callCardId = null; }
        
        String marketCountry = '';
        if (callCardId != null && callCardId != '') {
            thisCallCard = [SELECT Id, Account__c, Account__r.Channel__c, Account__r.Name, Account__r.Store_Type__c, Account__r.Market__c, Account__r.Market__r.Name, Account__r.Market__r.Country__c FROM CallCard__c WHERE Id = :callCardId];
            accountId = thisCallCard.Account__c;
            accountName = thisCallCard.Account__r.Name;
            channel = thisCallCard.Account__r.Channel__c;
            storeType = thisCallCard.Account__r.Store_Type__c;
            marketId = thisCallCard.Account__r.Market__c;
            marketName = thisCallCard.Account__r.Market__r.Name;
            marketCountry = thisCallCard.Account__r.Market__r.Country__c;
        } else {
            thisAccount = [SELECT Id, Name, Channel__c, Store_Type__c, Market__c, Market__r.Name, Market__r.Country__c FROM Account WHERE Id = :accountId];
            accountName = thisAccount.Name;
            channel = thisAccount.Channel__c;
            storeType = thisAccount.Store_Type__c;
            marketId = thisAccount.Market__c;
            marketName = thisAccount.Market__r.Name;
            marketCountry = thisAccount.Market__r.Country__c;
        }
        
        if (promoId != null && promoId != '') {
            thisPromotion = [SELECT Id, Name, RecordTypeId, RecordType.Name, Promotion_Start_Date__c FROM Promotion__c WHERE Id = :promoId];
            recordTypeId = thisPromotion.RecordTypeId;
			promotionType = thisPromotion.RecordType.Name;
            newPromotion = false;
        } else {
            thisPromotion = new Promotion__c(RecordTypeId=recordTypeId,Account__c=accountId,Status__c='New',Approval_Status__c='New');
            newPromotion = true;
            	
            System.debug('[PromotionController.building new promotion] record TypeId: ' + recordTypeId);
            if (recordTypeId != null && recordTypeId != '') {
        		RecordType rt = [SELECT Id, DeveloperName, Name FROM RecordType WHERE Id =:recordTypeId LIMIT 1];
                if (rt != null) {
                    promotionType = rt.Name;
                    System.debug('rt.name: ' + rt.Name + ', rt.DeveloperName: ' + rt.DeveloperName);
                } else {
                    System.debug('[PromotionController] rtList does not contain recordtype with id: ' + recordTypeId);
                }
            }
        }

        System.debug('[PromotionController.after init of promotion] promotionType: ' + promotionType);
        //Check to see if we need to use '.' instead of ',' for large numbers
		setIntNumFormat();
		
		usaMarket = false;
		if(marketCountry == 'United States'){
			usaMarket = true;			
		}else{
			usaMarket = false;
		}
        
        if (channel.toLowerCase() == 'on premise') {
            channel = 'On';
        } else if (channel.toLowerCase() == 'off premise') {
            channel = 'Off';
        } else if (channel.toLowerCase() == 'integrated') {
            channel = 'Both';
        }
        
        // Bring in overflow menu
        Set<SFAOverflowMenuItem> overflowButtons = SFAMetaSettingHelper.findOverflowButtons('Account_Visit', marketName, channel, '');
        System.debug(overflowButtons);
        serializedMenuJSON = overflowButtons == null ? '[]' : JSON.serialize(overflowButtons);
        
        String fsPromotionType = promotionType;
        if (marketName == 'Poland' && promotionType.startsWithIgnoreCase('posm')) {
        	 fsPromotionType = promotionType.replace(' ','');            
        }
        fieldSetName = marketName + '_' + channel + '_' + fsPromotionType + '_';
        fieldSetName = fieldSetName.replace(' ','_');
        fieldSetName = fieldSetName.replace('-','_');
        String rofFieldSetName = (fieldSetName + 'rof').toLowerCase();
        Set<String> toexclude = new Set<String>{rofFieldSetName};
        promotionFieldSet = FieldSetHelper.getFieldSetsWithLabelAndIndex('Promotion__c', fieldSetName.toLowerCase(), toexclude);
        if (promotionFieldSet == null || promotionFieldSet.size() == 0) {
            fieldSetName = marketName + '_' + fsPromotionType + '_';
            fieldSetName = fieldSetName.replace(' ','_');
            fieldSetName = fieldSetName.replace('-','_');
            
            rofFieldSetName = (fieldSetName + 'rof').toLowerCase();
            toexclude.clear();
            toexclude.add(rofFieldSetName);
            promotionFieldSet = FieldSetHelper.getFieldSetsWithLabelAndIndex('Promotion__c', fieldSetName, toexclude);
            if (promotionFieldSet == null || promotionFieldSet.size() == 0) {
                fieldSetName = 'default_global';
		        promotionFieldSet = FieldSetHelper.getFieldSetsWithLabelAndIndex('Promotion__c', fieldSetName, toexclude);
            }
        }

        readOnlyFieldSet = FieldSetHelper.getFieldSetFieldNames('Promotion__c', rofFieldSetName);

        pmiFieldSet = FieldSetHelper.getFieldSetFieldNames('Promotion_Material_Item__c', fieldSetName.toLowerCase());

        canAddMaterialItems = (pmiFieldSet != null && pmiFieldSet.size() > 0);

        // Use the lookup field set to build the where clause of the lookup.
        // each field in this fieldset should have the format of:  Object.Fieldname.  eg:  Contact__r.AccountId
        // 
        // Build list of where clauses for all lookup fields in the promotions object 
        relationships = new List<RelationshipWrapper>();
        relationships.add(new RelationshipWrapper('Contact__c', 'Contact', 'people', 'WHERE AccountId = \'' + String.escapeSingleQuotes(accountId) + '\' AND Is_Active__c=true'));
        if (marketName == 'Australia') {
            if (channel.toLowerCase() == 'integrated') {
                relationships.add(new RelationshipWrapper('Venue__c', 'Venue__c', 'account', 'WHERE Account__c = \'' + String.escapeSingleQuotes(accountId) + '\' AND Is_Active__c=true'));            
            } else {
                relationships.add(new RelationshipWrapper('Venue__c', 'Venue__c', 'account', 'WHERE Account__c = \'' + String.escapeSingleQuotes(accountId) + '\' AND Is_Active__c=true AND Channel__c=\'' + String.escapeSingleQuotes(channel) + '\''));            
            }            
        }
        if (marketName == 'Poland') {
        	relationships.add(new RelationshipWrapper('Local_POS_Type_PL__c', 'Product__c', 'product', 'WHERE For_Promotion_PL__c = \'BudExpo\' AND IsActive__c=true AND Market__c=\''+String.escapeSingleQuotes(marketId)+'\''));    
            relationships.add(new RelationshipWrapper('Central_POS_Type__c', 'Product__c', 'product', 'WHERE For_Promotion_PL__c = \'POSM\' AND IsActive__c=true AND Market__c=\''+String.escapeSingleQuotes(marketId)+'\''));
            relationships.add(new RelationshipWrapper('Horeca_POS_Type__c', 'Product__c', 'product', 'WHERE For_Promotion_PL__c = \'POSM On\' AND IsActive__c=true AND Market__c=\''+String.escapeSingleQuotes(marketId)+'\''));
            relationships.add(new RelationshipWrapper('Retail_POS_Type__c', 'Product__c', 'product', 'WHERE For_Promotion_PL__c = \'POSM TT\' AND IsActive__c=true AND Market__c=\''+String.escapeSingleQuotes(marketId)+'\''));
        }
        
        String promoType = promotionType;
        String[] salesPromoTypes = new String[]{'Sales Promotion','Merchandiser Request','Educational Request'};
        if (promotionType == 'Sales Promotion') {
            promoType = 'Sales Promo';
        }
        
        String whereClause = 'WHERE Active__c = true AND Market__c = \'' + String.escapeSingleQuotes(marketId) + '\'';
        if (promotionType == 'Merchandiser Request') {
            promoType = 'Sales Promo';
            whereClause += ' AND Promotion_Type__c = \'' + String.escapeSingleQuotes(promoType) + '\' AND Can_Request_Merchandiser__c = true';
        }
        if (promotionType == 'Educational Request') {
            promoType = 'Sales Promo';
            whereClause += ' AND Promotion_Type__c = \'' + String.escapeSingleQuotes(promoType) + '\' AND Mechanics__c = \'Educational\'';
        }
        if (marketName == 'Australia') {
            whereClause += ' AND Wombat_Active__c = true';
        }
        relationships.add(new RelationshipWrapper('Promotion_Activity_AUD__c', 'Promotion_Activity__c', 'campaign', whereClause));
        
        String promoActivityClause = 'WHERE Active__c = true AND (Market__c = \'' + String.escapeSingleQuotes(marketId) + '\' OR Market_s__c INCLUDES (\'' + marketName + '\')) AND Promotion_Type__c = \'' + String.escapeSingleQuotes(promoType) + '\' AND Begin_Date__c <= today AND End_Date__c >= today';
        if (channel != 'Both') {
            promoActivityClause += ' AND (Channel__c = \'' + channel + '\' OR Channel__c = \'Both\')';
        }
        relationships.add(new RelationshipWrapper('Promotion_Activity__c', 'Promotion_Activity__c', 'campaign', promoActivityClause));
        serializedRelationshipList = JSON.serialize(relationships);

        if (readOnlyFieldSet != null) {
            serializedReadOnlyFieldList = JSON.serialize(readOnlyFieldSet);            
        }
        
        if (promotionFieldSet == null) {
			promotionFieldSet = FieldSetHelper.getFieldSetsWithLabelAndIndex('Promotion__c', 'default', toexclude);
        }

        serializedPromotionFS = JSON.serialize(promotionFieldSet);            
        if(!newPromotion){
            //Build query for Promotion fields, unique set to ensure that fields aren't repeated in the field set
            promotionQuery = 'SELECT';
            set<string> uniqueFields = new set<string>();
            uniqueFields.add('Id');
            uniqueFields.add('Name');
            uniqueFields.add('CallCard__c');
            uniqueFields.add('Account__r.Market__c');    	
            uniqueFields.add('Account__r.Name');    
            uniqueFields.add('RecordTypeId');
            uniqueFields.add('RecordType.Name');
            for(FieldSetWrapper fsm : promotionFieldSet) {
                for(Schema.FieldSetMember asf : fsm.fields) {
                    if(!uniqueFields.contains(asf.getFieldPath())){
                        uniqueFields.add(asf.getFieldPath());
                    }                    
                }
            }
            for(string s:uniqueFields){
                promotionQuery += ' ' + s + ',';
            }
            promotionQuery = promotionQuery.substring(0, promotionQuery.length()-1); 
            promotionQuery += ' FROM Promotion__c WHERE Id = \'' + thisPromotion.Id + '\'';
            
            thisPromotion = Database.query(promotionQuery);
        }  		        	  
        
        try {
            serializedPromotion = JSON.serialize(thisPromotion);            
        }catch(NullPointerException ex) {
            serializedPromotion = '';
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
    global static Promotion__c savePromotion (String fields){
        Promotion__c p = (Promotion__c)JSON.deserialize(fields, Promotion__c.class);

    	upsert p;
    	return p;
    }
 	@RemoteAction
    global static void submitForApproval(String promotionId) {
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting Promotion approval request.');
        req1.setObjectId(promotionId);
        Approval.process(req1);
        
    }
}