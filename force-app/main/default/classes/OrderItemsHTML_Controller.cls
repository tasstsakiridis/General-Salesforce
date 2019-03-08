global with sharing class OrderItemsHTML_Controller {
    public Order__c thisOrder						{ get; set; }
    public List<Order_Item__c> orderItemsList		{ get; set; }
    public List<Product__c> productList				{ get; set; }
    
    public String serializedOrder		            { get; set; }
    public String serializedOrderItemFS	          	{ get; set; }
    public String serializedReadOnlyFieldList	    { get; set; }
    public String serializedProductList             { get; set; }
    public String serializedOrderItemList        	{ get; set; }
    public String serializedDealList				{ get; set; }
    public String serializedToleranceList			{ get; set; }
    
    public String urlPrefix           				{ get; set; }
    public String channel             				{ get; set; }
    public String marketName          				{ get; set; }
    public String orderType       					{ get; set; }
    public String itemRecordTypeId     				{ get; set; }
    public String productFieldNameToUse             { get; set; }
    public String fixMaterialErrors					{ get; set; }
    
    public Boolean lockOrder						{ get; set; }
    public Boolean isCustomerService				{ get; set; }
    
    public OrderItemsHTML_Controller(ApexPages.StandardController controller) {
        thisOrder = [SELECT Id, Name, RecordTypeId, RecordType.Name, Account__c, Account__r.Market__c, Status__c, Order_Type__c, Account_Name__c, Account_Channel__c, Order_Date__c, Market__c, CallCard__c, Wholesalers__c, Wholesalers__r.Wholesaler__c, Banner_Partner__c, Wholesaler__c, National_Management_Group__c, State_Management_Group__c, Material_Errors__c FROM Order__c WHERE Id =:controller.getId()];
        
        marketName = thisOrder.Market__c;
        channel = thisOrder.Account_Channel__c;
        orderType = thisOrder.Order_Type__c;
        lockOrder = (thisOrder.RecordType.Name == 'Locked');
        
        Map<String,String> pageParams = ApexPages.currentPage().getParameters();
        if (pageParams.containsKey('fixMaterialErrors')) {
            fixMaterialErrors = pageParams.get('fixMaterialErrors');
            lockOrder = (fixMaterialErrors == null || fixMaterialErrors == '0');            
        }
        
        isCustomerService = false;
        List<Profile> l_Profiles = [SELECT Id, Name FROM Profile WHERE Id =: UserInfo.getProfileId()];
        if (l_Profiles.size() > 0) {
            for(Profile p : l_Profiles) {
                if (p.Name.startsWithIgnoreCase('aud-customer service')) {
                    isCustomerService = true; 
                    lockOrder = false; 
                    break;
                }
            }
        }

        Map<String, Schema.RecordTypeInfo> rtList = Order_Item__c.SObjectType.getDescribe().getRecordTypeInfosByName();
        itemRecordTypeId = rtList.get('New').getRecordTypeId();
        if (thisOrder.RecordType.Name.indexOf('Locked') >= 0) {
            itemRecordTypeId = rtList.get('Locked').getRecordTypeId();
        }
        
        serializedOrder = JSON.serialize(thisOrder);
        
        if (channel.toLowerCase() == 'on premise') {
            channel = 'On';
        } else if (channel.toLowerCase() == 'off premise' || channel.toLowerCase() == 'combera') {
            channel = 'Off';
        } else if (channel.toLowerCase() == 'integrated') {
            channel = 'Both';
        }

        String fieldSetName = marketName + '_' + orderType;
        fieldSetName = fieldSetName.replace(' ','_');
        fieldSetName = fieldSetName.replace('-','_');

        List<Schema.FieldSetMember> oiFS = FieldSetHelper.getFieldSetFields('Order_Item__c', fieldSetName);
        if (oiFS == null || oiFS.size() == 0) { 
            fieldSetName = marketName + '_' + thisOrder.RecordType.Name;
		    fieldSetName = fieldSetName.replace(' ','_');
        	fieldSetName = fieldSetName.replace('-','_');
            
            oiFS = FieldSetHelper.getFieldSetFields('Order_Item__c', fieldSetName); 
        }
        if (oiFS == null || oiFS.size() == 0) { oiFS = new List<Schema.FieldSetMember>(); }
        serializedOrderItemFS = JSON.serialize(oiFS);

        List<String> readOnlyFields = FieldSetHelper.getFieldSetFieldNames('Order_Item__c', fieldSetName.toLowerCase() + '_ROF');
        if (readOnlyFields == null) { readOnlyFields = new List<String>(); }
        serializedReadOnlyFieldList = JSON.serialize(readOnlyFields);
        
        System.debug('market: ' + thisOrder.Account__r.Market__c);
        System.debug('channel: ' + channel);
        productList = [SELECT Id, Name, ProductCode__c, Pack_Quantity__c, RecordType.Name, Channel__c, Brand_Name__c, Brand__r.Name, Brand__r.Spirit_Type__c, Supplier__c, Unit_Size__c, Used_For__c, Price_Material_Group__c FROM Product__c WHERE IsActive__c = true AND Market__c =: thisOrder.Account__r.Market__c AND (Channel__c =:channel OR Channel__c = 'Both') AND Used_For__c INCLUDES ('Order') ORDER BY Name ASC];            
        if (productList == null) {
            serializedProductList = '';
        } else {
            serializedProductList = JSON.serialize(productList);
        }

        String sql = 'SELECT Id, Name, Product__c, Product__r.ProductCode__c, Product__r.Name, Product__r.Pack_Quantity__c, Product__r.Brand_Name__c, Product__r.Unit_Size__c, Product__r.Supplier__c,Product__r.Price_Material_Group__c,';
        for(Schema.FieldSetMember fsm : oiFS) {
            sql += fsm.getFieldPath() + ',';
        }
        sql = sql.removeEnd(',');
        sql += ' FROM Order_Item__c WHERE Order__c = \'' + thisOrder.Id + '\'';
        System.debug('soql: ' + sql);
        List<Order_Item__c> orderItemList = Database.query(sql);
        if (orderItemList == null) {
            serializedOrderItemList = '';
        } else {
            serializedOrderItemList = JSON.serialize(orderItemList);
        }
        
        if (marketName == 'Australia') {
            List<Price_Tolerance__c> tolerances = [SELECT Id, Reference_Material_Group__c, Budgeted_PA_Per_Case__c, Max_PA_Per_Case__c, (SELECT Id, Banner_Group__c, Budgeted_PA_Per_Case__c, Max_PA_Per_Case__c FROM Price_Tolerance_Groups__r) FROM Price_Tolerance__c WHERE Reference_Material_Group__r.Is_Active__c = true];
            if (tolerances == null) {
                serializedToleranceList = '';
            } else {
                serializedToleranceList = JSON.serialize(tolerances);
            }
            
            List<Group_Promotions__c> deals = [SELECT RecordTypeName__c, Customer_Level__c, Status__c, Buy_Period_Start_Date__c,Buy_Period_End_Date__c,(SELECT Id, Account_Wholesaler__c,Banner_Group__c, State_Management_Group__c FROM Deal_Related_To__r),(SELECT Id, Reference_Material_Group__c, Discount_Amount__c, Ongoing__c, Start_Date__c, End_Date__c FROM Group_Promotion_Items__r) FROM Group_Promotions__c WHERE Application__c LIKE 'On Retailers Invoice%' AND (Status__c ='Approved' OR Status__c ='Closed') AND Buy_Period_Start_Date__c <= TODAY AND Buy_Period_End_Date__c >= TODAY AND Id IN (SELECT Group_Promotion__c FROM Group_Promotion_Distributors__c WHERE Wholesaler__c =:thisOrder.Wholesalers__r.Wholesaler__c)];
            if (deals == null) {
                serializedDealList = '';
            } else {
                serializedDealList = JSON.serialize(deals);            
            }
        }
    }
    
    @RemoteAction
    global static List<Order_Item__c> saveOrderItems (List<Order_Item__c> oiList, List<Order_Item__c> itemsToDelete){
        if (itemsToDelete != null && itemsToDelete.size() > 0) {
            delete itemsToDelete;
        }
        
        for(Order_Item__c oi : oiList) {
            System.debug('orderitem: ' + oi.Product__c + ', carton: ' + oi.Carton__c + ', discount: ' + oi.Discount__c + ', tolerance: ' + oi.Max_PA_Per_Case__c);
        }
    	upsert oiList;        
    	return oiList;
    }    
    
    @RemoteAction
    global static void processOrder(String orderId, Boolean requiresApproval) {
        Order__c order = [SELECT Status__c, Material_Errors__c, Order_Date__c, Is_Flagged_For_Approval__c FROM Order__c WHERE Id =: orderId];
        if (requiresApproval) {
            order.Status__c = 'New';
        } else {
        	order.Status__c = 'Process Order';
            if (order.Material_Errors__c > 0) {
                order.Status__c = 'Customer Service';
            } else if (order.Order_Date__c > Date.today()) {
                order.Status__c = 'Future Order';
            }
        }
        order.Is_Flagged_for_Approval__c = requiresApproval;
        update order;
    }
}