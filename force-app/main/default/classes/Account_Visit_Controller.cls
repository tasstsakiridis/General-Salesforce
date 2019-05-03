global with sharing class Account_Visit_Controller {
    public Account a                                     { get; set; }
    public CallCard__c cc                                { get; set; }
    public Account_Survey__c survey                      { get; set; }
    public String serializedAccount                      { get; set; }
    public String serializedCC                           { get; set; }
    public String serializedSurvey                       { get; set; }  //existing survey for this day/user?
    public String serializedPromotionActivities          { get; set; }
    public String serializedChatterGroups                { get; set; }
    public String serializedChatterTabs                  { get; set; }
    public String serializedPromotions                   { get; set; }
    public String serializedOrders                       { get; set; }
    public Boolean canEditOrders                         { get; set; }
    public String serializedCCReadOnlyFieldList          { get; set; }
    public String myManagersName                         { get; set; }
    public String myManagersId                           { get; set; }
    public Boolean communityUser                         { get; set; }
    public Boolean canUploadMultipleItems                { get; set; }
    public String ccRecordTypeName                       { get; set; }
    public String ccRecordTypeId                         { get; set; }
    public String contactRecordTypeName                  { get; set; }
    public String contactRecordTypeId                    { get; set; }
    public String surveyRecordTypeName                   { get; set; }
    public String surveyRecordTypeId                     { get; set; }
    public String defaultLandingPage                     { get; set; }
    public Boolean saveAllKeyTasks                       { get; set; }
    public Boolean enableCheckInService                  { get; set; }
    public Decimal imageResizeRatio                      { get; set; }
    public String serializedMenuJSON                     { get; set; }
    public Boolean canAutoCreatePromotionFromActivity    { get; set; }
    public Boolean hasAccessToTitlePicklist              { get; set; }
    public Integer showHistoricalPromotions              { get; set; }

    //survey variables
    public String serializedAccountSurveys               { get; set; }
    global static List<SurveyWrapper> allSurveys         { get; set; }
    global static List<PromotionWrapper> allPromotions   { get; set; }
    public String accId                                  { get; set; }
    public CallCard__c callCard;
    public PageReference accountPage;
    public PageReference callCardPage;
    public static String pricingSurveyURL                { get; set; }
    public String userType                               { get; set; }
    public String urlPrefix                              { get; set; }

    //task variables
    global static List<TaskWrapper> allTasks             { get; set; }
    public String serializedTasks                        { get; set; }
    
    //Sales Materials variables, On Task Page
    private List<Sales_Material_Junction__c> allMaterial { get; set; }
    public String serializedSalesMaterials               { get; set; }
    public Boolean showSalesMaterials                    { get; set; }

    //call card variables
    public List<Schema.fieldSetMember> ccFieldSet        { get; set; }
    public String serializedCCFieldSet                   { get; set; }
    public String fieldSetName                           { get; set; }
    public static String CCDCallCardRecordType           { get; set; }
    public Boolean storeCallCardGeolocation              { get; set; }

    public Account_Visit_Controller(ApexPages.StandardController controller){
        userType = UserInfo.getUserType();
        if(userType != 'Standard'){
            urlPrefix = '/sales';//AMV
            communityUser = true;
        }else{
            urlPrefix = '';
            communityUser = false;
        }
        
        myManagersName = '';
        User mgr = [SELECT ManagerId, Manager.Name FROM User WHERE Id =: UserInfo.getUserId()];
        if (mgr != null) { 
            myManagersId = mgr.ManagerId;
            myManagersName = mgr.Manager.Name; 
        }
        
        accId = ApexPages.currentPage().getParameters().get('id');
        /*
        this.a = [SELECT Id, Name, Actionable_Segment__c, Call_Card_Objectives__c, Channel__c, Store_Type__c, Market__r.Country__c, Market__c, Market__r.Name, RecordType.Name,
                        (SELECT Id, Name FROM Contacts WHERE Is_Active__c = true ORDER BY LastName ASC), (SELECT Id FROM Assets__r WHERE Last_Sighted__c < TODAY OR Last_Sighted__c = NULL)
                    FROM Account 
                    WHERE Id = :accId];
        */
        this.a = [SELECT Id, Name, Actionable_Segment__c, Call_Card_Objectives__c, Objectives__c, Channel__c, Store_Type__c, Market__r.Country__c, Market__c, Market__r.Name, RecordType.Name, Banner_Group__c, Banner_Group__r.National_Banner_Group__c, 
                        (SELECT Id, Name FROM Contacts WHERE Is_Active__c = true ORDER BY LastName ASC)
                    FROM Account 
                    WHERE Id = :accId];
        System.debug('account: ' + this.a);
        serializedAccount = JSON.serialize(a);

        surveyRecordTypeName = a.Market__r.Name;
        if (a.Market__r.Country__c == 'United States') {
            surveyRecordTypeName = 'USA';
        }
        
        contactRecordTypeName = '';
        List<RecordTypeInfo> rtContacts = Contact.SObjectType.getDescribe().getRecordTypeInfos();
        for(RecordTypeInfo rti : rtContacts) {
            if (rti.isAvailable() && rti.isDefaultRecordTypeMapping()) {
                contactRecordTypeId = rti.getRecordTypeId();
                contactRecordTypeName = rti.getName();
                break;
            }
        }
        hasAccessToTitlePicklist = Contact.Title__c.getDescribe().isAccessible();
        
        /*
        Map<String, RecordTypeInfo> rtAccountSurvey = Account_Survey__c.SObjectType.getDescribe().getRecordTypeInfosByName();        
        if (rtAccountSurvey.containsKey(surveyRecordTypeName)) {
            surveyRecordTypeId = rtAccountSurvey.get(surveyRecordTypeName).getRecordTypeId();
        }
        */

        ccRecordTypeName = 'Call Card - ' + a.Market__r.Name;
        if (a.Market__r.Name == 'Poland') {
            ccRecordTypeName = 'PL - CallCard';
        } else if (a.RecordType.Name == 'USA - Outlets') {
            ccRecordTypeName = 'Call Card - US';
        }

        Map<String, RecordTypeInfo> rtList = CallCard__c.SObjectType.getDescribe().getRecordTypeInfosByName();
        if (rtList.containsKey(ccRecordTypeName)) {
            ccRecordTypeId = rtList.get(ccRecordTypeName).getRecordTypeId();
        } else {
            RecordTypeInfo rtMaster;
            for(RecordTypeInfo rti : rtList.values()) {
                if (rti.isAvailable() && rti.isDefaultRecordTypeMapping()) {
                    ccRecordTypeName = rti.getName();
                    ccRecordTypeId = rti.getRecordTypeId();
                }
                if (rti.isMaster()) { rtMaster = rti; }
            }
            if (ccRecordTypeId == null || ccRecordTypeId == '') {
                ccRecordTypeId = rtMaster.getRecordTypeId();
                ccRecordTypeName = rtMaster.getName();
            }
        }
        
        Market__c thisMarket = [SELECT Can_Upload_Multiple_Items__c, Store_CallCard_Geolocation__c, ImageResizeScalar__c, Show_SalesMaterials_in_Account_Visit__c , Account_Visit_Landing_Page__c, Save_all_KeyTasks_per_AccountVisit__c, Enable_CheckIn_Service__c, Can_Auto_Create_Promotion_from_Activity__c, Show_Historical_Promotions__c FROM Market__c WHERE Id =: this.a.Market__c][0];
        canUploadMultipleItems = thisMarket.Can_Upload_Multiple_Items__c;        
        defaultLandingPage = thisMarket.Account_Visit_Landing_Page__c;
        saveAllKeyTasks = thisMarket.Save_all_KeyTasks_per_AccountVisit__c;
        enableCheckInService = thisMarket.Enable_CheckIn_Service__c;
        imageResizeRatio = thisMarket.ImageResizeScalar__c == null ? -1.0 : thisMarket.ImageResizeScalar__c;
        showSalesMaterials = thisMarket.Show_SalesMaterials_in_Account_Visit__c;
        storeCallCardGeolocation  = thisMarket.Store_CallCard_Geolocation__c;
        showSalesMaterials = thisMarket.Show_SalesMaterials_in_Account_Visit__c;
        canAutoCreatePromotionFromActivity = thisMarket.Can_Auto_Create_Promotion_from_Activity__c;
        showHistoricalPromotions = thisMarket.Show_Historical_Promotions__c == null ? 0 : (Integer)thisMarket.Show_Historical_Promotions__c;
        
        // Bring in overflow menu
        System.debug('Account_Visit' + this.a.Market__c + this.a.Channel__c + this.a.Store_Type__c);
        Set<SFAOverflowMenuItem> overflowButtons = SFAMetaSettingHelper.findOverflowButtons('Account_Visit', this.a.Market__r.Name, this.a.Channel__c, this.a.Store_Type__c);
        System.debug(overflowButtons);
        serializedMenuJSON = overflowButtons == null ? '[]' : JSON.serialize(overflowButtons);
        
        //get Sales Materials
        if(showSalesMaterials) {
            allMaterial = [SELECT Sales_Material_Description__c, Sales_Material__r.Attachment_URL__c FROM Sales_Material_Junction__c WHERE Account__c = :accId ORDER BY LastModifiedDate DESC];
            serializedSalesMaterials = JSON.serialize(allMaterial);
        } else {
            serializedSalesMaterials = JSON.serialize('[]');
        }
        
        //get tasks
        allTasks = new List<TaskWrapper>();
        //buildTasks(saveAllKeyTasks);
        buildTasks();
        serializedTasks = JSON.serialize(allTasks);
        Map<String,Schema.RecordTypeInfo> ccRTMap = Schema.SObjectType.CallCard__c.getRecordTypeInfosByName();
        if(a.RecordType.Name == 'USA - Parents Off' || a.RecordType.Name == 'USA - Parents On'){
            if(ccRTMap.containsKey('Call Card - US CMG')){
                CCDCallCardRecordType = ccRTMap.get('Call Card - US CMG').getRecordTypeId();
            }
        }
        
        String channel = a.Channel__c;
        if (channel.startsWithIgnoreCase('on')) {
            channel = 'On';
        } else if (channel.startsWithIgnoreCase('off')) {
            channel = 'Off';
        } else if (channel.toLowerCase() == 'integrated') {
            channel = 'Both';
        }
        String searchChannel = channel +'%';        
        
        if(CCDCallCardRecordType != null){
            fieldSetName = 'CCD' + '_' + a.Channel__c;
        }else{
            fieldSetName = a.Market__r.Name + '_'+ a.Channel__c;
        }
        fieldSetName = fieldSetName.replaceAll(' ', '_');
        system.debug('fieldSetName: ' + fieldSetName);
        ccFieldSet = getFieldSet('CallCard__c', fieldSetName);
        serializedCCFieldSet = JSON.serialize(ccFieldSet);

        String rofFieldSetName = fieldSetName + '_ROF';
        List<String> readOnlyFieldSet = FieldSetHelper.getFieldSetFieldNames('CallCard__c', rofFieldSetName);
        serializedCCReadOnlyFieldList = JSON.serialize(readOnlyFieldSet);
        
        string ccQueryString = 'SELECT Id, Name ';
        if (enableCheckInService == true) {
            ccQueryString += ', Check_In__c, Check_Out__c ';            
        }
        for(Schema.FieldSetMember f:ccFieldSet){
            ccQueryString+= ', '+ f.getFieldPath();              
        }
        
        ccQueryString+=', (SELECT Id, ';
        Schema.DescribeFieldResult dfr = Account_Survey__c.Survey_Channel__c.getDescribe();
        if (dfr.isAccessible()) {
            ccQueryString += 'Survey_Channel__c, ';
        }
        ccQueryString+=' Survey_Type__c FROM Account_Surveys__r WHERE CreatedById = \'' + userInfo.getUserId() + '\') FROM CallCard__c WHERE Account__c = \''+ a.Id + 
                        '\' AND Call_Card_Date__c = TODAY AND CreatedById = \'' + userInfo.getUserId() + 
                        '\' ORDER BY LastModifiedDate DESC LIMIT 1';
        cc = new CallCard__c();
        survey = new Account_Survey__c();
        System.debug('ccQueryString: ' + ccQueryString);
        try{
            cc = Database.query(ccQueryString);
            system.debug('cc: '+cc);
            try{
                survey = cc.Account_Surveys__r[0];              
            }catch(Exception exc){
                system.debug('No Account Survey found');
            }
            
        }catch(Exception ex){
            system.debug('No Call Card found');         
        }

        List<Promotion_Activity__c> promoActivities;
        if (channel == 'Both') {
            promoActivities = [SELECT Id, Name, Channel__c, Premise__c, Begin_Date__c, End_Date__c, Promotion_Type__c, Activity__c, Sub_Type__c FROM Promotion_Activity__c WHERE Active__c = true AND (Begin_Date__c <= today OR Begin_Date__c >= today) AND End_Date__c >= today AND (Market__c =:this.a.Market__c OR Market_s__c INCLUDES (:this.a.Market__r.Name)) ORDER BY Name];        
        } else {
            promoActivities = [SELECT Id, Name, Channel__c, Premise__c, Begin_Date__c, End_Date__c, Promotion_Type__c, Activity__c, Sub_Type__c FROM Promotion_Activity__c WHERE Active__c = true AND (Channel__c LIKE :searchChannel OR Channel__c = 'Both') AND (Begin_Date__c <= today OR Begin_Date__c >= today) AND End_Date__c >= today AND (Market__c =:this.a.Market__c OR Market_s__c INCLUDES (:this.a.Market__r.Name)) ORDER BY Name];
        }
        
        String orderQueryString = 'SELECT Id, Name, Status__c, Order_Date__c, CallCard__c, RecordTypeId, RecordType.Name, Market__c ';
        String promoQueryString = 'SELECT Id, Name, Channel__c, Is_Active__c, Promotion_Start_Date__c, Promotion_End_Date__c, RecordTypeId, RecordType.Name, Market__c, Image_Attached__c ';
        if (this.a.Market__r.Name == 'Australia' || this.a.Market__r.Name == 'Czech Republic') {
            orderQueryString += ',Wholesalers__c, Wholesaler_Name__c ';
        } else {
            orderQueryString += ',Account_Wholesaler_Indirect__c, Wholesaler_Customer_Name__c ';
        }
        if (this.a.Market__r.Name == 'Australia') {
            promoQueryString += ',Promotion_Activity_AUD__c, Promotion_Activity_AUD__r.Name ';
        } else {
            promoQueryString += ',Promotion_Activity__c,Promotion_Activity__r.Name ';
        }

        orderQueryString += ' FROM Order__c WHERE Account__c = \'' + this.a.Id + '\'';
        orderQueryString += ' ORDER BY Order_Date__c DESC';
        
        String promoId = ApexPages.currentPage().getParameters().get('uploadToPromotionId');
        if (showHistoricalPromotions > 0) {
            promoQueryString += ' FROM Promotion__c WHERE Is_Active__c = true AND Promotion_End_Date__c >= LAST_N_MONTHS:'+showHistoricalPromotions+' AND Account__c = \'' + this.a.Id + '\'';
        } else {
            promoQueryString += ' FROM Promotion__c WHERE Is_Active__c = true AND Promotion_End_Date__c >= today AND Account__c = \'' + this.a.Id + '\'';

        }
        promoQueryString += ' ORDER BY Promotion_Start_Date__c DESC';            
        System.debug('promoQuery: ' + promoQueryString);
        List<Order__c> orders = Database.query(orderQueryString);
        List<PromotionWrapper> orderList = new List<PromotionWrapper>();
        
        List<Promotion__c> promotions = Database.query(promoQueryString);
        List<PromotionWrapper> promotionList = new List<PromotionWrapper>();

        String activityName;
        String activityId;
        String promoUrl;
        String activityUrl;
        
        canEditOrders = Schema.SObjectType.Order__c.isUpdateable();

        if (orders != null && orders.size() > 0) {
            Map<Id, Schema.RecordTypeInfo> orderRecordTypes = Schema.SObjectType.Order__c.getRecordTypeInfosById();
            String recordTypeName = '';
            for(Order__c o : orders) {
                if (o.Market__c == 'Australia' || o.Market__c == 'Czech Republic') {
                    activityId = o.Wholesalers__c;
                    activityName = o.Wholesaler_Name__c;
                } else {
                    if (o.Account_Wholesaler_Indirect__c == null) {
                        activityId = '';
                        activityName = '';
                    } else {
                        activityId = o.Account_Wholesaler_Indirect__c;
                        activityName = o.Wholesaler_Customer_Name__c;                        
                    }
                }
                
                promoUrl = urlPrefix + '/' + o.Id;
                activityUrl = urlPrefix + '/' + activityId;
                recordTypeName = o.RecordType.Name;
                if (orderRecordTypes.containsKey(o.RecordTypeId)) {
                    recordTypeName = orderRecordTypes.get(o.RecordTypeId).getName();
                }
                
                orderList.add(new PromotionWrapper(o.Id, promoUrl, o.Name, o.Order_Date__c, o.Order_Date__c, true, recordTypeName, activityId, activityName, activityUrl, o.Status__c));
            }
        }
        if (promotions != null && promotions.size() > 0) {
            for(Promotion__c p : promotions) {
                if (p.Market__c == 'Australia') { 
                    activityId = p.Promotion_Activity_AUD__c;
                    activityName = p.Promotion_Activity_AUD__r.Name; 
                } else { 
                    activityId = p.Promotion_Activity__c;
                    activityName = p.Promotion_Activity__r.Name; 
                }
    
                promoUrl = urlPrefix + '/' + p.Id;
                activityUrl = urlPrefix + '/' + activityId;
                promotionList.add(new PromotionWrapper(p.Id, promoUrl, p.Name, p.Promotion_Start_Date__c, p.Promotion_End_Date__c, p.Is_Active__c, p.RecordType.Name, activityId, activityName, activityUrl, p.Channel__c, p.Image_Attached__c));
            }
        }

        List<CollaborationGroup> chatterGroups = [SELECT Id, Name FROM CollaborationGroup];
        List<Approved_Chatter_Groups__c> approvedChatterGroups = [SELECT Name FROM Approved_Chatter_Groups__c WHERE Market__c =: this.a.Market__c AND Is_Active__c = true];
        Set<String> approvedChatterGroupNames = new Set<String>();
        for(Approved_Chatter_Groups__c s : approvedChatterGroups) {
            approvedChatterGroupNames.add(s.Name);
        }

        List<CollaborationGroup> cgList = new List<CollaborationGroup>();
        for(CollaborationGroup cg : chatterGroups) {
            if (approvedChatterGroupNames.contains(cg.Name)) {
                cgList.add(cg);
            }            
        }

        serializedCC = JSON.serialize(cc);
        serializedSurvey = JSON.serialize(survey);
        serializedAccountSurveys = JSON.serialize(cc.Account_Surveys__r);
        serializedPromotionActivities = JSON.serialize(promoActivities);
        serializedPromotions = JSON.serialize(promotionList);
        serializedOrders = JSON.serialize(orderList);
        serializedChatterGroups = JSON.serialize(cgList);
    }

    public List<Schema.FieldSetMember> getFieldSet(string objectName, string fieldSetName){
        list<Schema.FieldSetMember> fieldset = new List<Schema.FieldSetMember>();
        if(Schema.getGlobalDescribe().get(objectName).getDescribe().FieldSets.getMap().get(fieldsetName) != null){
            fieldset = Schema.getGlobalDescribe().get(objectName).getDescribe().fieldSets.getMap().get(fieldsetName).getFields();
        }else{
            fieldset = Schema.getGlobalDescribe().get(objectName).getDescribe().fieldSets.getMap().get('Default').getFields();
        }
        return fieldset;
    }

    @RemoteAction
    global static Contact saveNewContact(String accountId, String firstName, String lastName, String phone, String mobile, String email, String title) {
        Contact c = new Contact();
        c.AccountId = accountId;
        c.FirstName = firstName;
        c.LastName = lastName;
        c.Phone = phone;
        c.MobilePhone = mobile;
        c.Email = email;

        Schema.DescribeFieldResult dfr = Contact.Title.getDescribe();
        if (dfr.isAccessible()) {
            c.Title = title;
        }
        dfr = Contact.Title__c.getDescribe();
        if (dfr.isAccessible()) {
            c.Title__c = title;
        }
        
        insert c;
        
        return c;
    }
    
    //get all open ad hoc surveys for this account whose date range fits with today's date.
    @RemoteAction
    global static list<SurveyWrapper> buildSurveys(string accountId) {
        list<Account_Ad_Hoc_Survey__c> mySurveys = [SELECT Survey__c, Account__c, Completed__c, Completed_Date__c, Survey__r.Repeatable__c, Survey_Link__c, Survey_URL__c, Survey__r.Name, Survey__r.Start_Date__c, Survey__r.End_Date__c FROM Account_Ad_Hoc_Survey__c
                WHERE (Survey__r.Start_Date__c <= today OR Survey__r.Start_Date__c = null)
                    AND (Survey__r.End_Date__c >= today OR Survey__r.End_Date__c = null)
                    AND Account__c = :accountId
                ORDER BY Survey__r.End_Date__c DESC];

        //list<Account_Ad_Hoc_Survey__c> surveys = new list<Account_Ad_Hoc_Survey__c>();
        //list<SurveyWrapper> completed = new list<SurveyWrapper>();
        allSurveys = new list<SurveyWrapper>();
        //add non-completed ad hoc surveys to surveys list, otherwise add to completed list
        for(Account_Ad_Hoc_Survey__c aahs: mySurveys){            
            allSurveys.add(new SurveyWrapper(aahs.Survey_URL__c, aahs.Survey__r.Name, aahs.Survey__r.Start_Date__c, aahs.Survey__r.End_Date__c, aahs.Completed__c, aahs.Survey__r.Repeatable__c));
        }
        return allSurveys;
    }
    
    @RemoteAction
    global static List<RecordType> getAvailableRecordTypesForObject(String objectName) {
        List<RecordType> l = new List<RecordType>();
        Map<Id, RecordType> rtList = new Map<Id, RecordType>([SELECT Id, DeveloperName, Name FROM RecordType WHERE SObjectType =:objectName AND IsActive = true]);
        String[] types = new String[]{objectName};
        Schema.DescribeSObjectResult[] describeInfos = Schema.describeSObjects(types);
        if (describeInfos != null && describeInfos.size() > 0) {
            Map<Id, RecordTypeInfo> rtInfosList = describeInfos[0].getRecordTypeInfosById();
            for (RecordTypeInfo rti : rtInfosList.values()) {
                if (rti.isAvailable() == true) {
                    RecordType rt = rtList.get(rti.getRecordTypeId());
                    if (rt != null) {
                        l.add(new RecordType(Id=rt.Id, DeveloperName=rt.DeveloperName,Name=rti.getName()));                    
                    }
                }
            }
        }
        return l;
    }
    
    @RemoteAction
    global static List<RecordType> getAvailablePromotionRecordTypes() {
        Map<Id, RecordType> rtList = new Map<Id, RecordType>([SELECT Id, DeveloperName, Name FROM RecordType WHERE SObjectType = 'Promotion__c' AND IsActive = true]);
        Map<Id, RecordTypeInfo> rtInfosList = Promotion__c.SObjectType.getDescribe().getRecordTypeInfosById();
        List<RecordType> l = new List<RecordType>();
        for (RecordTypeInfo rti : rtInfosList.values()) {
            if (rti.isAvailable() == true) {
                RecordType rt = rtList.get(rti.getRecordTypeId());
                if (rt != null) {
                    l.add(new RecordType(Id=rt.Id, DeveloperName=rt.DeveloperName,Name=rti.getName()));                    
                }
            }
        }
        return l;
    }

    @RemoteAction
    global static List<RecordType> getAvailableOrderRecordTypes() {
        Map<Id, RecordType> rtList = new Map<Id, RecordType>([SELECT Id, DeveloperName, Name FROM RecordType WHERE SObjectType = 'Order__c' AND IsActive = true]);
        Map<Id, RecordTypeInfo> rtInfosList = Order__c.SObjectType.getDescribe().getRecordTypeInfosById();
        Map<String, RecordTypeInfo> rtNameInfos = Order__c.SObjectType.getDescribe().getRecordTypeInfosByName();
        System.debug('[getavailablerecordtypes] # of order record types: ' + rtNameInfos.size());
        for(String s : rtNameInfos.keySet()) {
            System.debug('[getavailablerecordtypes] order.rtname: ' + s);
        }
        List<RecordType> l = new List<RecordType>();
        for (RecordTypeInfo rti : rtInfosList.values()) {
            if (rti.isAvailable() == true) {
                RecordType rt = rtList.get(rti.getRecordTypeId());
                if (rt != null) {
                    l.add(new RecordType(Id=rt.Id, DeveloperName=rt.DeveloperName,Name=rti.getName()));                    
                }
            }
        }
        return l;
    }

    
    @RemoteAction
    global static list<PromotionWrapper> buildPromotions(string accountId, string urlPrefix) {
        System.debug('[buildPromotions] accountId: ' + accountId);
        String query = 'SELECT Id, Image_Attached__c, Is_Active__c, Name, Account__c, Market__c, Promotion_Start_Date__c, Promotion_End_Date__c, RecordType.Name, Channel__c';
        if (Schema.SObjectType.Promotion__c.fields.Promotion_Activity__c.isAccessible()) {
            query += ', Promotion_Activity__c, Promotion_Activity__r.Name';
        }
        if (Schema.SObjectType.Promotion__c.fields.Promotion_Activity_AUD__c.isAccessible()) {
            query += ', Promotion_Activity_AUD__c, Promotion_Activity_AUD__r.Name';
        }
        query += ' FROM Promotion__c';
        query += ' WHERE Account__c =: accountId';
        query += ' ORDER BY Promotion_End_Date__c DESC';
        System.debug('query: ' + query);
        List<Promotion__c> myPromotions = Database.query(query);

        allPromotions = new List<PromotionWrapper>();
        String activityName;
        String activityId;
        String promoUrl;
        String activityUrl;
        if (myPromotions != null && myPromotions.size() > 0) {
            for(Promotion__c p : myPromotions) {
                if (p.Market__c == 'Australia') { 
                    activityId = p.Promotion_Activity_AUD__c;
                    activityName = p.Promotion_Activity_AUD__r.Name; 
                } else { 
                    activityId = p.Promotion_Activity__c;
                    activityName = p.Promotion_Activity__r.Name; 
                }
    
                promoUrl = urlPrefix + '/' + p.Id;
                activityUrl = urlPrefix + '/' + activityId;
                allPromotions.add(new PromotionWrapper(p.Id, promoUrl, p.Name, p.Promotion_Start_Date__c, p.Promotion_End_Date__c, p.Is_Active__c, p.RecordType.Name, activityId, activityName, activityUrl, p.Channel__c, p.Image_Attached__c));
            }
        }
        
        return allPromotions;
    }

    @RemoteAction
    global static string newPromotion(String promotionId, String recordTypeId, String accountId, String accountName, String urlPrefix, String retUrl) {
        string retUrlEncode;
        if (retUrl == '') {
            if (promotionId == null || promotionId == '') {
                retUrlEncode = EncodingUtil.urlEncode(urlPrefix + '/apex/Promotion?recordType=' + recordTypeId + '&accountId=' + accountId + '&retUrl=' + retUrl, 'UTF-8');                
            } else {
                retUrlEncode = EncodingUtil.urlEncode(urlPrefix + '/apex/Promotion?id=' + promotionId + '&recordType=' + recordTypeId + '&accountId=' + accountId + '&retUrl=' + retUrl, 'UTF-8');                
            }
        } else {
            retUrlEncode = EncodingUtil.urlDecode(retUrl, 'UTF-8');
        }
        
        return retUrlEncode;
    }

    @RemoteAction
    global static string newAccountSurvey(string surveyId, string surveyType, boolean skipCallCard, string accountName, string accountId, string callCardId, string urlPrefix, string retUrl, string channel){
        string retUrlEncode;
        System.debug('retUrl: ' + retUrl);
        if(retUrl == ''){
            if(callCardId == ''){
                retUrlEncode = EncodingUtil.urlEncode(urlPrefix+'/apex/AdhocSurvey?id='+accountId+'&skip='+skipCallCard, 'UTF-8');
            }else{
                retUrlEncode = EncodingUtil.urlEncode(urlPrefix+'/'+callCardId, 'UTF-8');
            }
        }else{
            retUrlEncode = EncodingUtil.urlEncode(retUrl, 'UTF-8');
        }

        if(surveyType == 'CPT'){
            skipCallCard = true;
        }
        string ccId = callCardId;
        System.debug('callcardid: ' + ccId + ', channel: ' + channel);  
        System.debug('user can create call cards?: ' + Schema.sObjectType.CallCard__c.isCreateable ());
        if(ccId == ''){
            if(skipCallCard){
                CallCard__c cc = new CallCard__c();
                cc.Account__c = accountId;
                cc.Call_Card_Date__c = system.today();
                if(surveyType == 'CPT'){
                    cc.Call_Card_Type__c = surveyType;
                }
                insert cc;
                ccId = cc.Id;
                pricingSurveyURL = urlPrefix + '/apex/AccountSurvey?ccID='+ccId+'&accountId='+accountId+'&surveyType='+surveyType+'&retUrl='+retUrlEncode+'&scontrolCaching=1&sfdc.override=1';
            }else{
                pricingSurveyURL = urlPrefix + '/apex/Call_Card?CF00Na000000B1nkH='+accountName+'&CF00Na000000B1nkH_lkid='+accountId+'&channel='+channel+'&retUrl='+retUrlEncode+'&scontrolCaching=1&sfdc.override=1';
                return pricingSurveyURL;
            }
        }else{
            pricingSurveyURL = urlPrefix + '/apex/AccountSurvey?';
            System.debug('surveyId: ' + surveyId);
            if (surveyId != '') {
                pricingSurveyURL += 'surveyId='+surveyId+'&';
            } 
            pricingSurveyURL += 'ccId='+ccId+'&accountId='+accountId+'&surveyType='+surveyType;
            if (channel != '') {
                pricingSurveyURL += '&channel='+channel;
            }
            pricingSurveyURL += '&retUrl='+retUrlEncode+'&scontrolCaching=1&sfdc.override=1';
        }
        System.debug('pricingSurveyUrl: ' + pricingSurveyURL);
        return pricingSurveyURL;
    }

    @RemoteAction
    global static CallCard__c saveCallCard(CallCard__c cc, string rtId){
        if(rtId != null && rtId != ''){
            cc.RecordTypeId = rtId;         
        }
        upsert cc;
        return cc;
    }

    @RemoteAction
    global static list<Key_Task__c> saveTasks(list<Key_Task__c> tasks){
        upsert tasks;
        return tasks;
    }

    /*
    @RemoteAction
    global static void postAttachmentToChatter(String[] documentIds, String promoId, String promoName) {
        System.debug('promoId: ' + promoId);
        System.debug('promoName: ' + promoName);
        System.debug('documentIds: ' + documentIds);
        if (documentIds == null || documentIds.size() == 0) { return; }

        FeedItem post = new FeedItem();
        post.Body = promoName;
        post.ParentId = promoId;
        post.Title = promoName;
        insert post;
        
        List<FeedAttachment> feedAttachments = new List<FeedAttachment>();        
        FeedAttachment attachment;
        
        for(String documentId : documentIds) {
            attachment = new FeedAttachment();
            attachment.FeedEntityId = post.Id;
            attachment.RecordId = documentId;
            //attachment.Title = promoName;
            attachment.Type = 'CONTENT';

            feedAttachments.add(attachment);
        }

        if (!feedAttachments.isEmpty()) {
            insert feedAttachments;
        }    

    }
    */
    
    @RemoteAction
    global static String postToChatter(String groupId, String groupName, String accountName, String promoId, String promoName, String managerId, String linkUrl, String chatterText, String urlPrefix, String contentVersionId) {
        ConnectApi.FeedItemInput feedInput = new ConnectApi.FeedItemInput();
        ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        ConnectApi.HashtagSegmentInput hashtagAccount = new ConnectApi.HashtagSegmentInput();
        ConnectApi.HashtagSegmentInput hashtagPromotion = new ConnectApi.HashtagSegmentInput();

        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                
        textSegmentInput.text = chatterText + ' ';
        messageBodyInput.messageSegments.add(textSegmentInput);

        hashtagAccount.tag = accountName;
        messageBodyInput.messageSegments.add(hashtagAccount);

        hashtagPromotion.tag = promoName;
        messageBodyInput.messageSegments.add(hashtagPromotion);

        ConnectApi.TextSegmentInput t2 = new ConnectApi.TextSegmentInput();
        t2.text = ' ';
        messageBodyInput.messageSegments.add(t2);
        
        mentionSegmentInput.id = groupId;
        messageBodyInput.messageSegments.add(mentionSegmentInput);

        ConnectApi.TextSegmentInput t3 = new ConnectApi.TextSegmentInput();
        t3.text = ' ';
        messageBodyInput.messageSegments.add(t3);

        if (managerId != '') {
            ConnectApi.MentionSegmentInput mgrMention = new ConnectApi.MentionSegmentInput();
            mgrMention.id = managerId;
            messageBodyInput.messageSegments.add(mgrMention);
        }

        feedInput.feedElementType = ConnectApi.FeedElementType.FEEDITEM;
        feedInput.body = messageBodyInput;
        feedInput.subjectId = promoId;
        //feedInput.subjectId = groupId;

        if (contentVersionId != null && contentVersionId != '') {
            List<ContentVersion> documents = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id=:contentVersionId];
            String documentId = documents.get(0).ContentDocumentId;
            
            ConnectApi.FilesCapabilityInput filesInput = new ConnectApi.FilesCapabilityInput();
            filesInput.items = new List<ConnectApi.FileIdInput>();
            ConnectApi.FileIdInput idInput = new ConnectApi.FileIdInput();
            idInput.id = documentId;
            filesInput.items.add(idInput);

            ConnectApi.FeedElementCapabilitiesInput feedElementCapabilitiesInput = new ConnectApi.FeedElementCapabilitiesInput();
            feedElementCapabilitiesInput.files = filesInput;

            feedInput.capabilities = feedElementCapabilitiesInput;
        }


        ConnectApi.Comment commentRep = null;
        ConnectApi.FeedElement feed = null;
        try {
            //commentRep = ConnectApi.ChatterFeeds.postCommentToFeedElement(null, feedItemId, commentInput, null);                    
            feed = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedInput);
        }catch(Exception ex) {
            System.debug('exception raised posting comment to feed item. ' + ex.getMessage());                    
        }
        
        if (feed == null) {
            return ''; 
        } else {
            return feed.Id;            
        }
    }

    @RemoteAction
    global static PromotionWrapper newPromotionFromActivity(String accountId, String activityId) {
        Promotion_Activity__c pa = [SELECT Id, Name, RecordTypeId, RecordType.Name, Market__c, Market__r.Name, Begin_Date__c, End_Date__c, Channel__c, Premise__c, Promotion_Type__c, Wombat_Active__c FROM Promotion_Activity__c WHERE Id =:activityId];
        Map<String, Schema.RecordTypeInfo> rtSchemaList = Schema.SObjectType.Promotion__c.getRecordTypeInfosByName();
        List<RecordType> rtList = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SobjectType = 'Promotion__c' AND IsActive = true];
        String rtName = pa.Promotion_Type__c;
        System.debug('Promotion_Type__c: '+rtName);
        
        if (rtName == 'Sales Promo') { rtName = 'Sales Promotion'; }
        Id rtId = null;
        for(RecordType rt : rtList) {
            System.debug('rt: ' + rt.Name + ', devname: ' + rt.DeveloperName);
            if (rtName == rt.Name) {
                rtId = rt.Id; break;
            }
        }
        if (rtId == null) {
            rtId = rtSchemaList.get('Sales Promotion').getRecordTypeId();            
        }
        
        Promotion__c p = new Promotion__c();
        p.RecordTypeId = rtId;
        p.Account__c = accountId;
        p.Promotion_Start_Date__c = pa.Begin_Date__c;
        p.Promotion_End_Date__c = pa.End_Date__c;
        p.Name = pa.Name;
        p.Is_Active__c = true;
        p.Channel__c = pa.Channel__c;
        if (pa.Market__r.Name == 'Australia') {
            p.Promotion_Activity_AUD__c = pa.Id;
        } else {
            p.Promotion_Activity__c = pa.Id;
        }
        System.debug('PromotionActivity.promotiont type: ' + pa.Promotion_Type__c + ', promotion.recordtype: ' + p.RecordTypeId);
        System.debug('PromotionActivity.channel: ' + pa.Channel__c + ', promotion.channel: ' + p.Channel__c);
        System.debug('PromotionActivity.wombatactive: ' + pa.Wombat_Active__c);        
        
        insert p;  
        
        PromotionWrapper pw = new PromotionWrapper(p.Id, '', p.Name, p.Promotion_Start_Date__c, p.Promotion_End_Date__c, p.Is_Active__c, rtName, pa.Id, pa.Name, '', pa.Channel__c);        
        return pw;
    }
    

    global void buildTasks(){
        set<string> uniqueTemplates = new set<string>();
        /*
        String userId = UserInfo.getUserId();
        String taskSoql = 'SELECT Complete__c, CreatedDate, LastModifiedDate, Description__c, Id, Name, Key_Task_Template__c FROM Key_Task__c';
        taskSoql += ' WHERE Account__c =:accId AND CreatedById =:userId AND Key_Task_Template__r.Is_Active__c = true ';
        if (saveAllKeyTasks) {
            taskSoql += ' AND CreatedDate = TODAY';
        }
        taskSoql += ' AND ((Key_Task_Template__r.Key_Task_Start_Date__c <= today OR Key_Task_Template__r.Key_Task_Start_Date__c = null)';
        taskSoql += ' AND (Key_Task_Template__r.Key_Task_Date__c >= today OR Key_Task_Template__r.Key_Task_Date__c = null))';
        taskSoql += ' ORDER BY CreatedDate DESC';
        System.debug('taskSoql: ' + taskSoql);
        List<Key_Task__c> l_KeyTasks = Database.query(taskSoql);
        for(Key_Task__c kt : l_KeyTasks) {
            if(!uniqueTemplates.contains(kt.Key_Task_Template__c)){
                allTasks.add(new taskWrapper(kt.Id, kt.Key_Task_Template__c, kt.Name, kt.Complete__c, kt.CreatedDate, kt.Description__c));
                uniqueTemplates.add(kt.Key_Task_Template__c);
            }            
        }
        */
        /*
        for(Key_Task__c kt:[SELECT Complete__c, CreatedDate, LastModifiedDate, Description__c, Id, Name, Key_Task_Template__c FROM Key_Task__c
                            WHERE Account__c = :accId
                                AND CreatedById =:userInfo.getUserId()
                                AND Key_Task_Template__r.Is_Active__c = true
                                AND (Key_Task_Template__r.Actionable_Segment__c =:a.Actionable_Segment__c OR Key_Task_Template__r.Actionable_Segment__c = '')
                                AND ((Key_Task_Template__r.Key_Task_Start_Date__c <= today OR Key_Task_Template__r.Key_Task_Start_Date__c = null)
                                AND (Key_Task_Template__r.Key_Task_Date__c >= today OR Key_Task_Template__r.Key_Task_Date__c = null))
                            ORDER BY CreatedDate DESC]){
            if(!uniqueTemplates.contains(kt.Key_Task_Template__c)){
                allTasks.add(new taskWrapper(kt.Id, kt.Key_Task_Template__c, kt.Name, kt.Complete__c, kt.CreatedDate, kt.Description__c));
                uniqueTemplates.add(kt.Key_Task_Template__c);
            }
        }
            for(Key_Task_Template__c ktt: [SELECT Description__c, Id, Name FROM Key_Task_Template__c
                                            WHERE Market__c = :a.Market__c
                                                AND Is_Active__c = true
                                                AND (Channel__c = 'Both' OR Channel__c = :a.Channel__c)
                                                AND (Actionable_Segment__c = :a.Actionable_Segment__c OR Actionable_Segment__c = '')
                                                AND ((Key_Task_Start_Date__c <= today OR Key_Task_Start_Date__c = null)
                                                AND (Key_Task_Date__c >= today OR Key_Task_Date__c = null))]){
                if(!uniqueTemplates.contains(ktt.Id)){
                    allTasks.add(new taskWrapper(ktt.Name, ktt.Id, ktt.Description__c));
                    uniqueTemplates.add(ktt.Id);
                }
            }
        */
        String soql = 'SELECT Id, Name, Key_Task_Template__c, Complete__c, CreatedDate, LastModifiedDate, Description__c ' +
            'FROM Key_Task__c ' +
            'WHERE Account__c = \'' + accId + '\'' +
            '  AND CreatedById = \'' + userInfo.getUserId() + '\'' + 
			'  AND Key_Task_Template__r.Is_Active__c = true' +
			'  AND (Key_Task_Template__r.Actionable_Segment__c = \'' + this.a.Actionable_Segment__c + '\' OR Key_Task_Template__r.Actionable_Segment__c = \'\')' +
			' AND ((Key_Task_Template__r.Key_Task_Start_Date__c <= today OR Key_Task_Template__r.Key_Task_Start_Date__c = null) ' + 
			'  AND (Key_Task_Template__r.Key_Task_Date__c >= today OR Key_Task_Template__r.Key_Task_Date__c = null)) ';
        if (this.a.Market__r.Name == 'Australia') {
            if (this.a.Banner_Group__r != null && this.a.Banner_Group__r.National_Banner_Group__c != null) {
                soql += ' AND (Key_Task_Template__r.National_Banner_Group__c = \'' + this.a.Banner_Group__r.National_Banner_Group__c + '\' OR Key_Task_Template__r.National_Banner_Group__c = null)';
            } else {
                soql += ' AND (Key_Task_Template__r.National_Banner_Group__c = \'\'';
            }
        }
             
        soql += ' ORDER BY CreatedDate DESC';
        List<Key_Task__c> l_KeyTask = Database.query(soql);
        for(Key_Task__c kt : l_KeyTask) {
            if(!uniqueTemplates.contains(kt.Key_Task_Template__c)){
                allTasks.add(new taskWrapper(kt.Id, kt.Key_Task_Template__c, kt.Name, kt.Complete__c, kt.CreatedDate, kt.Description__c));
                uniqueTemplates.add(kt.Key_Task_Template__c);
            }            
        }
        
        soql = 'SELECT Id, Name, Description__c FROM Key_Task_Template__c ' + 
            ' WHERE Market__c = \'' + this.a.Market__c + '\'' +
            '   AND Is_Active__c = true ' + 
            '   AND (Channel__c = \'Both\' OR Channel__c = \'' + this.a.Channel__c + '\')' +
            '   AND (Actionable_Segment__c = \'' + this.a.Actionable_Segment__c + '\' OR Actionable_Segment__c = \'\')' +
            '   AND ((Key_Task_Start_Date__c <= today OR Key_Task_Start_Date__c = null) ' +
            '   AND (Key_Task_Date__c >= today OR Key_Task_Date__c = null)) ';
        if (this.a.Market__r.Name == 'Australia') {
            if (this.a.Banner_Group__r != null && this.a.Banner_Group__r.National_Banner_Group__c != null) {
                soql += ' AND (National_Banner_Group__c = \'' + this.a.Banner_Group__r.National_Banner_Group__c + '\' OR National_Banner_Group__c = null)';
            } else {
                soql += ' AND National_Banner_Group__c != \'\'';
            }
        }
        System.debug('templats soql: ' + soql);
		List<Key_Task_Template__c> l_Templates = Database.query(soql);
        for(Key_Task_Template__c ktt : l_Templates) {
            if (!uniqueTemplates.contains(ktt.Id)) {
                allTasks.add(new taskWrapper(ktt.Name, ktt.Id, ktt.Description__c));
                uniqueTemplates.add(ktt.Id);
            }
        }
        
        allTasks.sort();
    }
    @RemoteAction
    global static void callEinstein(List<FeedItem> items) {
    }    
    @RemoteAction
    global static void storeShelfScannerImages(List<FeedItem> items) {
    }    
    /*
    @RemoteAction
    global static void storeShelfScannerImages(List<EinsteinFeedWrapper> items) {
        List<ContentVersion> l_Images = new List<ContentVersion>();
        List<Shelf_Scan__c> l_Scans = new List<Shelf_Scan__c>();
        Map<String, Scan_Result__c> m_ScanResults = new Map<String, Scan_Result__c>();        
        
        Scan_Result__c scanResult;
        Shelf_Scan__c shelfScan;
        String parentId;
        
        List<String> itemIds = new List<String>();
        for(EinsteinFeedWrapper efw : items) {
            itemIds.add(efw.fi);            
        }
        
        List<FeedItem> l_Feeds = [SELECT Id, Title, ContentData, ParentId FROM FeedItem WHERE Id =:itemIds];
        for(FeedItem fi : l_Feeds) {
            shelfScan = new Shelf_Scan__c();
            parentId = fi.ParentId;
            if (parentId != null && parentId.startsWith('a09')) {
                shelfScan.Promotion__c = parentId;                    
            }
            l_Scans.add(shelfScan);            

            ContentVersion cont = new ContentVersion();
            cont.Title = fi.Title;
            cont.PathOnClient = 'file_'+fi.Title;
            cont.VersionData = fi.ContentData;
            cont.FirstPublishLocationId = fi.ParentId;
            l_Images.add(cont);               
        }
        if (l_Scans.size() > 0) {
            insert l_Scans;
        }        
        if (l_Images.size() > 0) {
            insert l_Images;            
        }
        
        FeedItem fi;
        for(EinsteinFeedWrapper efw : items) {
            for(FeedItem tFI : l_Feeds) {
                if (tFI.Id == efw.fi) {
                    fi = tFI;
                    break;
                }
            }    
            
            if (efw.epr != null) {
                for(Einstein_Probability probability : efw.epr.probabilities) {
                    if (m_ScanResults.containsKey(probability.label)) {
                        scanResult = m_ScanResults.get(probability.label);
                    } else {
                        scanResult = new Scan_Result__c();
                        scanResult.Name = probability.label;
                        scanResult.Count__c = 0;
                    }
                    
                    for(Shelf_Scan__c ss : l_Scans) {
                        if (ss.Promotion__c == fi.ParentId) {
                            scanResult.Shelf_Scan__c = ss.Id;
                            break;
                        }
                    }
                    scanResult.Count__c += 1;
                    scanResult.Confidence__c = probability.probability;
                    m_ScanResults.put(probability.label, scanResult);
                }
            }
        }

        if (m_ScanResults.size() > 0) {
            insert m_ScanResults.values();
        }
        
    }
    
    @RemoteAction
    global static List<EinsteinFeedWrapper> callEinstein(List<FeedItem> items) {

        List<EinsteinFeedWrapper> l_EinsteinFeeds = new List<EinsteinFeedWrapper>();

        List<String> itemIds = new List<String>();
        for(FeedItem fi : items) {
            itemIds.add(fi.Id);            
        }

        String base64;
        for(FeedItem fi : [SELECT Id, Title, ContentData, ParentId FROM FeedItem WHERE Id =:itemIds]) {
            
            base64 = EncodingUtil.base64Encode(fi.ContentData);
            Einstein_PredictionResult result = ShelfScanner.detectShelfObjects('TJBKD25DYDK3OD74RAT4RY6YJE', base64);
    System.debug('[callEinstein] result: ' + result);
            EinsteinFeedWrapper efw = new EinsteinFeedWrapper(fi.Id, null, result);
            l_EinsteinFeeds.add(efw);
        }
        
        return l_EinsteinFeeds;
    
    }
    global class EinsteinFeedWrapper {
        public String fi                        { get; set; }
        public Scan_Result__c sr                { get; set; }
        public Einstein_PredictionResult epr    { get; set; }
        
        public EinsteinFeedWrapper(String f, Scan_Result__c s, Einstein_PredictionResult r) {
            fi = f;
            sr = s;
            epr = r;
        }
    }
    */  
    global class SurveyWrapper{
        public string link {get;set;}
        public string linkName {get;set;}
        public date startDate {get;set;}
        public date endDate {get;set;}
        public string displayStartDate {get;set;}
        public string displayEndDate {get;set;}
        public boolean completed {get;set;}
        public boolean repeatable {get;set;}

        public SurveyWrapper(string l, string n, Date s, Date e, boolean c, boolean r){
            link = l;
            linkName = n;
            startDate = s;
            endDate = e;
            displayStartDate = s == null ? '' : s.format();
            displayEndDate = e == null ? '' : e.format();
            completed = c;
            repeatable = r;
        }
    }

    global class taskWrapper implements Comparable{
        public string taskId            {get;set;}
        public string templateId        {get;set;}
        public string name              {get;set;}
        public boolean complete         {get;set;}
        public datetime lastCompleted   {get;set;}
        public string displayDate       {get;set;}
        public string description       {get;set;}

        //constructor for existing Key Tasks
        public taskWrapper(string i, string t, string n, boolean s, datetime l, string d){
            taskId = i;
            templateId = t;
            name = n;
            complete = s;
            description = d;
            lastCompleted = l;
            if(complete){
                displayDate = l.format();
            }
        }
        //constructor for Key Task Templates
        public taskWrapper(string n, string t, string d){
            templateId = t;
            name = n;
            description = d;
        }
        
        public Integer compareTo(Object compareTo) {
            taskWrapper compareToWrapper = (taskWrapper) compareTo;
            Integer returnValue = 0;
            
            if (description > compareToWrapper.description) {
                returnValue = 1;                
            } else {
                returnValue = -1;
            }

            return returnValue;
        }
    }

    global class PromotionWrapper{
        public string id { get; set; }
        public string link {get;set;}
        public string linkName {get;set;}
        public date startDate {get;set;}
        public date endDate {get;set;}
        public string displayStartDate {get;set;}
        public string displayEndDate {get;set;}
        public boolean isActive {get;set;}
        public string recordTypeName { get; set; }
        public String activityId { get; set; }
        public String activityName { get; set; }
        public String activityLink { get; set; }
        public String promoChannel  { get; set; }
        public boolean imageAttached  { get; set; }
        
        public PromotionWrapper(string i, string l, string ln, Date s, Date e, boolean ia, String rt, String actId, String act, String al, String c){
            id = i;
            link = l;
            linkName = ln;
            startDate = s;
            endDate = e;
            if (s != null) { displayStartDate = s.format(); }
            if (e != null) { displayEndDate = e.format(); }
            isActive = ia;
            recordTypeName = rt;
            activityId = actId;
            activityName = act;
            activityLink = al;
            promoChannel = c;
            imageAttached = false;
        }
        
        public PromotionWrapper(string i, string l, string ln, Date s, Date e, boolean ia, String rt, String actId, String act, String al, String c, Boolean imgAttach){
            id = i;
            link = l;
            linkName = ln;
            startDate = s;
            endDate = e;
            if (s != null) { displayStartDate = s.format(); }
            if (e != null) { displayEndDate = e.format(); }
            isActive = ia;
            recordTypeName = rt;
            activityId = actId;
            activityName = act;
            activityLink = al;
            promoChannel = c;
            imageAttached = imgAttach;
        }
    }
}