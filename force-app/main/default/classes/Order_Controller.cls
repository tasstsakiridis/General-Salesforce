global with sharing class Order_Controller {
    public Order__c thisOrder					{ get; set; }
    public Account thisAccount					{ get; set; }
    public CallCard__c thisCallCard				{ get; set; }
    
    public String serializedOrder				{ get; set; }
    public String serializedOrderFS				{ get; set; }
    public String serializedAccount				{ get; set; }
    public String serializedReadOnlyFieldList	{ get; set; }
    public String serializedRelationshipList	{ get; set; }
    public String serializedMenuJSON            { get; set; }
    
    public String urlPrefix						{ get; set; }
    public String orderId						{ get; set; }
    public String callCardId					{ get; set; }
    public String accountId						{ get; set; }
    public String accountName					{ get; set; }
    public String accountNumber					{ get; set; }
    public String marketId						{ get; set; }
    public String marketName					{ get; set; }
    public String orderType						{ get; set; }
    public String recordTypeId					{ get; set; }
    public String recordTypeName				{ get; set; }
    public String returnToId					{ get; set; }
    public String channel						{ get; set; }
    
    public Boolean isNewOrder					{ get; set; }
    public Boolean hasLineItems					{ get; set; }
    public Boolean lockOrder					{ get; set; }
    public Boolean allowEditStatus				{ get; set; }
    
    public Order_Controller(ApexPages.StandardController controller) {
        Map<String,String> pageParams = ApexPages.currentPage().getParameters();
        recordTypeId  	= pageParams.get('recordTypeId');
      	
        Schema.DescribeFieldResult dfr_Status = Order__c.Status__c.getDescribe();
        
        channel = 'All';
        isNewOrder = true;
        hasLineItems = false;
        lockOrder = false;
        allowEditStatus = dfr_Status.isUpdateable();
        orderId = ''; callCardId = ''; accountId = ''; orderType = '';
        for(String s : pageParams.keySet()) {
            System.debug('pageparam. ' + s + ' : ' + pageParams.get(s));
        }
        if (pageParams.containsKey('id')) {
            orderId = pageParams.get('id');            
            returnToId = orderId;
            
            if (orderId != null && orderId != '') {
                thisOrder = [SELECT Id, Name, RecordTypeId, RecordType.Name, Order_Type__c, Status__c, Market__c, Account__c, Contact__c, Contact__r.Name, Contact__r.FirstName, Contact__r.LastName, CallCard__c, (SELECT Id, Product__c, Carton__c, Carton_Bonus__c, Unit__c, Unit_Bonus__c, Max_PA_Per_Case__c FROM Order_Items__r) FROM Order__c WHERE Id =:orderId];
                recordTypeName = thisOrder.RecordType.Name;
                orderType = thisOrder.Order_Type__c;            
                isNewOrder = false;
                accountId = thisOrder.Account__c;
                callCardId = thisOrder.CallCard__c;
                marketName = thisOrder.Market__c;
                hasLineItems = thisOrder.Order_Items__r.size() > 0;
                
                System.debug('recordTypeId: ' + recordTypeId + ', thisOrder.recordTypeId: ' + thisOrder.RecordTypeId);
                if (recordTypeId == null || recordTypeId == '' || recordTypeId == 'null') {
                    System.debug('recordTypeid is null, setting it to the recordtype of this order');
                    recordTypeId = thisOrder.RecordTypeId;
                } else {
					 if (thisOrder.RecordTypeId != recordTypeId) {
                    	thisOrder.RecordTypeId = recordTypeId;
                    	Map<Id, RecordTypeInfo> rtInfos = Order__c.SObjectType.getDescribe().getRecordTypeInfosById();
                    	recordTypeName = rtInfos.get(recordTypeId).getName();
                     }
                }

                System.debug('recordTypeId: ' + recordTypeId + ', thisOrder.recordTypeId: ' + thisOrder.RecordTypeId);
                System.debug('recordTypeName: ' + recordTypeName);
                lockOrder = (recordTypeName == 'Locked');
            } 
        } else {
            orderType = pageParams.get('orderType');
            accountId = pageParams.get('accountId');
            
            if (pageParams.containsKey('callCardId')) {
                callCardId = pageParams.get('callCardId');
                returnToId = callCardId;
            } else {
                String callCardPrefix = CallCard__c.SObjectType.getDescribe().getKeyPrefix();
                String accountPrefix = Account.SObjectType.getDescribe().getKeyPrefix();
                String lkid = '';
                for(String s : pageParams.keySet()) {
                    if (s.endsWithIgnoreCase('_lkid')) {
                        lkid = pageParams.get(s);
                        break;
                    }                
                }
                
                if (lkid != '') {
                    if (lkid.startsWith(callCardPrefix)) {
                        callCardId = lkid;
                    } else if (lkid.startsWith(accountPrefix)) {
                        accountId = lkid;
                    }
                    
                    returnToId = lkid;
                }
            }            
        }

        if (callCardId != null && callCardId != '') {
            thisCallCard = [SELECT Id, Account__c, Account__r.AccountNumber, Account__r.Channel__c, Account__r.Name, Account__r.Market__c, Account__r.Market__r.Name FROM CallCard__c WHERE Id =:callCardId];
            accountId = thisCallCard.Account__c;
            accountName = thisCallCard.Account__r.Name;
            accountNumber = thisCallCard.Account__r.AccountNumber;
            marketId = thisCallCard.Account__r.Market__c;
            marketName = thisCallCard.Account__r.Market__r.Name;
            channel = thisCallCard.Account__r.Channel__c;
        } else if (accountId != null && accountId != '') {
        	thisAccount = [SELECT Id, Name, AccountNumber, Channel__c, Market__c, Market__r.Name FROM Account WHERE Id =: accountId];  
            accountName = thisAccount.Name;
            accountNumber = thisAccount.AccountNumber;
            marketId = thisAccount.Market__c;
            marketName = thisAccount.Market__r.Name;
            channel = thisAccount.Channel__c;
        }
System.debug('Orderid: ' + orderId);
        System.debug('marketName: ' + marketName);
        System.debug('accountid: ' + accountId);
        if (thisOrder == null) {
            if (recordTypeId == null) {
                Map<String, RecordTypeInfo> rtInfos = Order__c.SObjectType.getDescribe().getRecordTypeInfosByName();
                if (orderType == 'Direct') {
                    recordTypeName = 'New Direct Order';
                } else {
                    recordTypeName = 'New InDirect Order';
                }
                
	            List<RecordType> rtList = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Order__c' AND IsActive = true AND DeveloperName =:recordTypeName];
                if (rtList != null && rtList.size() > 0) {
                    recordTypeId = rtList.get(0).Id;                    
                }
                //recordTypeId = rtInfos.get(recordTypeName).getRecordTypeId();
            } else {
                RecordType rt = [SELECT Id, Name, DeveloperName FROM RecordType WHERE Id =:recordTypeId][0];
                //Map<Id, RecordTypeInfo> rtInfos = Order__c.SObjectType.getDescribe().getRecordTypeInfosById();
                //recordTypeName = rtInfos.get(recordTypeId).getName();                
                recordTypeName = rt.DeveloperName.replaceAll('_', ' ');
            }
            if (marketName == null) { marketName = 'Poland'; }
            orderType = recordTypeName;
            System.debug('recordTypeName: ' + recordTypeName);
            if (recordTypeName.containsIgnoreCase('indirect') || marketName == 'Czech Republic') {
                orderType = 'In-Direct';
            }
            
            thisOrder = new Order__c(RecordTypeId=recordTypeId, Account__c=accountId, Status__c='New', Order_Type__c=orderType);            
            if (callCardId != null && callCardId != '') { thisOrder.CallCard__c = callCardId; }
        }
        
        String fieldSetName = marketName + '_' + recordTypeName;
        System.debug('fieldsetname: ' + fieldSetName);
        fieldSetName = fieldSetName.replaceAll(' ', '_');
        fieldSetName = fieldSetName.replaceAll('-', '');
        fieldSetName = fieldSetName.replaceAll('__', '_');
        System.debug('fieldsetname: ' + fieldSetName);
        String rofFieldSetName = fieldSetName + '_ROF';
        Set<String> toExclude = new Set<String>{rofFieldSetName.toLowerCase()};
        List<FieldSetWrapper> orderFieldSet = FieldSetHelper.getFieldSetsWithLabelAndIndex('Order__c', fieldSetName.toLowerCase(), toExclude);
        if (orderFieldSet == null || orderFieldSet.size() == 0) {
            fieldSetName = 'default_global';
            toExclude.clear();
            toExclude.add((fieldSetName + '_rof').toLowerCase());
            orderFieldSet = FieldSetHelper.getFieldSetsWithLabelAndIndex('Order__c', fieldSetName, toExclude);
        }
        
        List<String> readOnlyFieldSet = FieldSetHelper.getFieldSetFieldNames('Order__c', rofFieldSetName);

        // Use the lookup field set to build the where clause of the lookup.
        // each field in this fieldset should have the format of:  Object.Fieldname.  eg:  Contact__r.AccountId
        // 
        // Build list of where clauses for all lookup fields in the promotions object 
        List<RelationshipWrapper> relationships = new List<RelationshipWrapper>();
        relationships.add(new RelationshipWrapper('Contact__c', 'Contact', 'people', 'WHERE AccountId = \'' + String.escapeSingleQuotes(accountId) + '\' AND Is_Active__c = true'));
        relationships.add(new RelationshipWrapper('Account_Wholesaler_Indirect__c', 'Account_Wholesaler__c', 'account', 'WHERE Account__c = \'' + String.escapeSingleQuotes(accountId) + '\' AND Is_Active__c = true', 'Wholesaler_Name__c'));
        relationships.add(new RelationshipWrapper('Wholesalers__c', 'Account_Wholesaler__c', 'account', 'WHERE Account__c = \'' + String.escapeSingleQuotes(accountId) + '\' AND Is_Active__c = true', 'Wholesaler_Name__c'));
        
        serializedRelationshipList = JSON.serialize(relationships);
        if (readOnlyFieldSet != null) {
            serializedReadOnlyFieldList = JSON.serialize(readOnlyFieldSet);
        }
        if (orderFieldSet != null) {
            serializedOrderFS = JSON.serialize(orderFieldSet);
        }
        if (!isNewOrder) {
            String sql = 'SELECT';
            Set<String> uniqueFields = new Set<String>();
            uniqueFields.add('Id');
            uniqueFields.add('Name');
            uniqueFields.add('CallCard__c');
            uniqueFields.add('Account__c');
            uniqueFields.add('Account__r.Name');
            uniqueFields.add('Account__r.Market__c');
            uniqueFields.add('Contact__c');
            uniqueFields.add('Contact__r.Name');
            uniqueFields.add('RecordTypeId');
            uniqueFields.add('RecordType.Name');
            
            if (Schema.SObjectType.Order__c.fields.Account_Wholesaler_Indirect__c.isAccessible()) {
                uniqueFields.add('Account_Wholesaler_Indirect__c');
                uniqueFields.add('Account_Wholesaler_Indirect__r.Wholesaler_Name__c');
            }
            if (Schema.SObjectType.Order__c.fields.Wholesalers__c.isAccessible()) {
                uniqueFields.add('Wholesalers__c');
                uniqueFields.add('Wholesalers__r.Wholesaler_Name__c');
            }
            for(FieldSetWrapper fsw : orderFieldSet) {
                for(Schema.FieldSetMember fsm : fsw.fields) {
                    if (!uniqueFields.contains(fsm.getFieldPath())) {
                        uniqueFields.add(fsm.getFieldPath());
                    }
                }
            }
            
            for(String s : uniqueFields) {
                sql += ' ' + s + ',';
            }
            if (marketName.equalsIgnoreCase('australia')) {
                sql += '(SELECT Id, Max_PA_Per_Case__c, Discount__c, Carton_Bonus__c, Unit_Bonus__c FROM Order_Items__r) ';
            } else {
	            sql = sql.removeEnd(',');                
            }
            sql += ' FROM Order__c WHERE Id = \'' + thisOrder.Id + '\'';
            System.debug('sql: ' + sql);
            thisOrder = Database.query(sql);
        }
        
        try {
            serializedOrder = JSON.serialize(thisOrder);
        }catch(NullPointerException ex) {
            serializedOrder = '';
        }
        
        // Bring in overflow menu
        Set<SFAOverflowMenuItem> overflowButtons = SFAMetaSettingHelper.findOverflowButtons('Account_Visit', marketName, channel, 'All');
        System.debug(overflowButtons);
        serializedMenuJSON = overflowButtons == null ? '[]' : JSON.serialize(overflowButtons);
        
    }
    
    @RemoteAction
    global static Order__c saveOrder(String fields) {
        Order__c order = (Order__c)JSON.deserialize(fields, Order__c.class);
            
        upsert order;
        return order;
    }
    @RemoteAction
    global static void processOrder(String orderId, Boolean requiresApproval) {
        Order__c order = [SELECT Id, Market__c, Is_Flagged_for_Approval__c, Status__c FROM Order__c WHERE Id =: orderId];
        if (requiresApproval == false) {
            //order.Status__c = 'New';
	        order.Status__c = 'Process Order';       
            if (order.Order_Date__c > Date.today()) {
                order.Status__c = 'Future Order';
            }
        }
        System.debug('order market name: ' + order.Market__c);
        order.Is_Flagged_for_Approval__c = requiresApproval;
        System.debug('requiresapproval: ' + order.Is_Flagged_for_Approval__c);
        if (order.Market__c == 'Australia') {
            order.RecordTypeId = Order__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Locked').getRecordTypeId();     
        }
        update order;
    }
    
}