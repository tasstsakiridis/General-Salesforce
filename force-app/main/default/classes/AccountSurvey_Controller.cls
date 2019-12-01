public with sharing class AccountSurvey_Controller {
    
    public Account_Survey__c accSurvey                      { get; set; }
    public Account_Survey__c lastaccSurvey                  { get; set; }
    
    public CallCard__c callCard                             { get; set; }
    
    public List<Product__c> prodList                        { get; set; }
    
    public String serializedAccSurvey                       { get; set; }
    public String serializedLastAccSurvey                   { get; set; }
    public String serializedProdList                        { get; set; }
    public String serializedAccSurveyFS                     { get; set; }
    public String serializedASIFS                           { get; set; }
    public String serializedAccSurveyDIVFS                  { get; set; }
    public String serializedMenuJSON                        { get; set; }
    public String serializedCallCard                        { get; set; }
    public String serializedASIROFFS                        { get; set; }
    
    public Boolean cashAndCarry                             { get; set; }
    public Boolean useIntNumFormat                          { get; set; }
    public Boolean newAs                                    { get; set; }
    public Boolean firstSurvey                              { get; set; }
    public String userType                                  { get; set; }
    public String urlPrefix                                 { get; set; }
    public String userTheme {get;set;}//AMV
    
    //values come from URL params
    public String surveyId                                  { get; set; }
    public String ccId                                      { get; set; }
    public String surveyChannel                             { get; set; }

    public Boolean newSurvey                                { get; set; }
    public Boolean usaMarket                                { get; set; }
    public String accId                                     { get; set; }
    public String accountName                               { get; set; }   //needed for field sets
    public String marketName                                { get; set; }   //needed for field sets
    public String langISOCode								{ get; set; }
    public String accountCurrencyISOCode    				{ get; set; }
    public String channel                                   { get; set; }   //needed for field sets
    public String storeType                                 { get; set; }   //needed for field sets
    public String accountGroup                              { get; set; }   //needed for field sets
    public String surveyType                                { get; set; }   //needed for field sets
    public String productUsedFor                            { get; set; }
    public String venueId                                   { get; set; }
    public String venueName                                 { get; set; }
    public String recordTypeId                              { get; set; }
    public String recordTypeName                            { get; set; }
    public String asiRecordTypeId                           { get; set; }
    
    //field set variables
    public List<Schema.fieldSetMember> accSurveyFieldSet    { get; set; }
    public List<Schema.fieldSetMember> accSurveyDIVFieldSet { get; set; }
    public List<Schema.fieldSetMember> asiFieldSet          { get; set; }
    public List<Schema.fieldSetMember> asiROFFieldSet       { get; set; }
    public String fieldSetName                              { get; set; }
    public String fieldSetChannel                           { get; set; }
    public String fieldSetSubChannel                        { get; set; }
    public String accSurveyQuery                            { get; set; }
    public String lastAccSurveyQuery                        { get; set; }
    public String asiQuery                                  { get; set; }
    
    public AccountSurvey_Controller(ApexPages.StandardController controller) {
        //this.accSurvey = (Account_Survey__c)controller.getRecord();    
        accSurvey = new Account_Survey__c();
        langISOCode = 'en';
        
        userType = UserInfo.getUserType();
        userTheme= UserInfo.getUiThemeDisplayed();//AMV
        
        if(userType != 'Standard'){
            urlPrefix = '/sales';
        }else{
            urlPrefix = '';
        }

        //get URL param values
        //newSurvey =   Boolean.valueOf(ApexPages.currentPage().getParameters().get('newSurvey'));
        surveyId =                      ApexPages.currentPage().getParameters().get('surveyId');
        ccId =                          ApexPages.currentPage().getParameters().get('ccId');
        surveyType =                    ApexPages.currentPage().getParameters().get('surveyType');
        surveyChannel =                 ApexPages.currentPage().getParameters().get('channel');
        //accId =                       ApexPages.currentPage().getParameters().get('accId');
        //marketName =                  ApexPages.currentPage().getParameters().get('marketName');
        //channel =                     ApexPages.currentPage().getParameters().get('channel');
        //storeType =                   ApexPages.currentPage().getParameters().get('storeType');
        //venueId =                       ApexPages.currentPage().getParameters().get('venueId');
        //venueName =                     ApexPages.currentPage().getParameters().get('venueName');
        if (ApexPages.currentPage().getParameters().containsKey('id') == true) {
            surveyId = ApexPages.currentPage().getParameters().get('id');
            Account_Survey__c survey = [SELECT Id, Name, CallCard__c FROM Account_Survey__c WHERE Id =:surveyId][0];
            /*
            if (Account_Survey__c.getSObjectType().getDescribe().fields.getMap().get('Venue__c').getDescribe().isAccessible() == true) {
                survey = [SELECT Id, Name, CallCard__c, Venue__c, Venue_Name__c FROM Account_Survey__c WHERE Id =:surveyId][0];
                venueId = survey.Venue__c;
                venueName = survey.Venue_Name__c;
            } else {
                survey = [SELECT Id, Name, CallCard__c FROM Account_Survey__c WHERE Id =:surveyId][0];                
            }
            */
            ccId = survey.CallCard__c;
        } else if(surveyId == null) {
            for(String k : ApexPages.currentPage().getParameters().keySet()) {
                if (k.endsWith('_lkid')) {
                    ccId = ApexPages.currentPage().getParameters().get(k);
                    break;
                }
            }
        }
        
        Map<String, RecordTypeInfo> rtAccountSurveyItems = Account_Survey_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        
        callCard = [SELECT Id, Account__c, Account__r.CurrencyIsoCode, Account__r.Channel__c, Account__r.Name, Account__r.Store_Type__c, Account__r.Group__c, Account__r.Market__r.Name, Account__r.Market__r.Country__c, Account__r.Market__r.Strict_Product_Used_For_Account_Surveys__c FROM CallCard__c WHERE Id = :ccId];
        serializedCallCard = JSON.serialize(callCard);
        accId = callCard.Account__c;
        accountName = callCard.Account__r.Name;
        marketName = callCard.Account__r.Market__r.Name;
        recordTypeName = marketName;
        accountCurrencyISOCode = callCard.Account__r.CurrencyIsoCode;
        System.debug('callcard: ' + ccId + ', market: ' + marketName + ', country: ' + callCard.Account__r.Market__r.Country__c);
        usaMarket = false;
        if(callCard.Account__r.Market__r.Country__c == 'United States'){
            usaMarket = true;           
            recordTypeName = 'USA';
        }else{
            usaMarket = false;
        }

        if (rtAccountSurveyItems.containsKey(recordTypeName)) {
            asiRecordTypeId = rtAccountSurveyItems.get(recordTypeName).getRecordTypeId();
        }
        
        channel = callCard.Account__r.Channel__c;
        storeType = callCard.Account__r.Store_Type__c;
        accountGroup = callCard.Account__r.Group__c;
        System.debug('[ascontroller] surveyId: ' + surveyId);
        System.debug('[ascontroller] accountGroup: ' + accountGroup);
        if(surveyId == null){
            System.debug('[ascontroller] surveyid is null');
            newSurvey = true;
            accSurvey.Account__c = accId;
            accSurvey.CallCard__c = callCard.Id; 
            accSurvey.Survey_Channel__c = surveyChannel;
        }else{
            newSurvey = false;
            System.debug('[ascontroller] surveyid is not null');
        }

        // Bring in overflow menu
        Set<SFAOverflowMenuItem> overflowButtons = SFAMetaSettingHelper.findOverflowButtons('Account_Visit', marketName, channel, storeType);
        System.debug(overflowButtons);
        serializedMenuJSON = overflowButtons == null ? '[]' : JSON.serialize(overflowButtons);
                
        //Check to see if we need to use '.' instead of ',' for large numbers
        setIntNumFormat();
        
        System.debug('channel: ' + channel + ', surveyChannel: ' + surveyChannel);
        if (channel.startsWithIgnoreCase('integrated') && surveyChannel != null) {
            channel = surveyChannel;
        }
        if (channel.startsWithIgnoreCase('on')) {
            channel = 'On';
        } else if (channel.startsWithIgnoreCase('off')) {
            channel = 'Off';
        }
        fieldSetChannel = channel;
        fieldSetSubChannel = '';
        //String[] fieldSetSubChannels = new String[]{'Grossiste', 'LKA', 'Cash and Carry'};
        cashAndCarry = false;       
        //if(storeType == 'Cash and Carry' || storeType == 'Wholesalers'|| storeType == 'Cavistes'){
        if(accountGroup == 'Wholesalers'){
            if (fieldSetChannel.startsWithIgnoreCase('on')) {
                fieldSetChannel = 'On';
            } else {
                fieldSetChannel = 'Off';                
            }
            cashAndCarry = true;
        } else if (accountGroup != null && accountGroup != '') {
            //Integer fsPos = fieldSetSubChannels.indexOf(storeType);
            //if (fsPos >= 0) {
                fieldSetSubChannel = '_' + accountGroup.replaceAll(' ','_');
            //}
            cashAndCarry = false;
        }                               
        
        if(surveyType == 'CPT'){
            fieldSetName = 'CPT';
            productUsedFor = 'CPT';
        }else{
            fieldSetName = marketName + '_' + fieldSetChannel + fieldSetSubChannel;
            fieldSetName = fieldSetName.replace(' ','_');
            productUsedFor = 'Account Survey';
        }
        system.debug('fieldSetName: '+fieldSetName);
        accSurveyFieldSet = getFieldSet('Account_Survey__c', fieldSetName, true, false, false);
        asiFieldSet = getFieldSet('Account_Survey_Item__c', fieldSetName, true, false, false); 
        accSurveyDIVFieldSet = getFieldSet('Account_Survey__c', fieldSetName, false, true, false);
        asiROFFieldSet = getFieldSet('Account_Survey_Item__c', fieldSetName, false, false, true);

        serializedAccSurveyFS = JSON.serialize(accSurveyFieldSet);
        serializedASIFS = JSON.serialize(asiFieldSet);
        serializedAccSurveyDIVFS = JSON.serialize(accSurveyDIVFieldSet);
        serializedASIROFFS = JSON.serialize(asiROFFieldSet);
        
        accSurvey.Id = surveyId;
        //accSurvey.Survey_Type__c = surveyType;
        //system.debug('surveyType: '+accSurvey.Survey_Type__c);
        //Check to see if we are creating a new survey or editing an existing survey
        // If we are creating a new survey, get last survey so we can prepopulate values    
        //  Check if lastAccountSurvey should be kept for the field set
        //  Use Account Survey Setting for the field set to set Limits
        //  If user has "AccountSurvey - Always Show Last Visit Values" ignore LIMIT
        CustomPermissionsReader cpr = new CustomPermissionsReader();
        Boolean historyLimitIgnorePerm = cpr.hasPermission('AccountSurvey_Always_Show_Last_Visit_Values');
        System.debug('historyLimitIgnorePerm: ' + historyLimitIgnorePerm);
        
        String retention = SFAMetaSettingHelper.findAccountSurveyRetention(marketName, channel, storeType);
        if(retention.length() > 0) {
            System.debug('History Retention: ' + retention);
        } else {
            System.debug('History Retention: No limit');
        }
                
        firstSurvey = false;    
        if(newSurvey){
            accSurvey.Visit_Date__c = system.today();
            try{
                // Base query
                String asHistoryQuery = 'SELECT Id FROM Account_Survey__c WHERE Last_Visit__c = true AND Account__c = \'' + accID + '\'';
                // Special thing for AUS
                if(marketName == 'Australia' && surveyChannel != null && surveyChannel != '') {
                    asHistoryQuery += ' AND Survey_Channel__c = \'' + surveyChannel + '\'';
                }
                // Filter based on retention settings
                if(!historyLimitIgnorePerm && retention.length() > 0) {
                    asHistoryQuery += ' AND LastModifiedDate ' + retention;
                }
                System.debug('asHistoryQuery: ' + asHistoryQuery);
                lastAccSurvey = Database.query(asHistoryQuery);
            }catch(Exception e){
                lastAccSurvey = null;
                firstSurvey = true;
            }
        }        
        
        //Build query for Account Survey fields, unique set to ensure that fields aren't repeated in the field set
        accSurveyQuery = 'SELECT';
        set<string> uniqueFields = new set<string>();
        uniqueFields.add('Id');
        uniqueFields.add('Name');
        uniqueFields.add('Visit_Date__c');
        uniqueFields.add('CallCard__c');
        uniqueFields.add('Account__r.Market__c');       
        uniqueFields.add('Account__r.Name');    
        uniqueFields.add('Survey_Type__c'); 
        
        if (marketName == 'Australia') {
            uniqueFields.add('Survey_Channel__c');
        }
        
        for(Schema.FieldSetMember asf:accSurveyFieldSet){
            if(!uniqueFields.contains(asf.getFieldPath())){
                uniqueFields.add(asf.getFieldPath());
            }
        } 
        for(string s:uniqueFields){
            accSurveyQuery += ' '+s+',';
        }
        accSurveyQuery = accSurveyQuery.substring(0,accSurveyQuery.length()-1); 
        if(newSurvey){
            if(!firstSurvey){
                accSurveyQuery += ' FROM Account_Survey__c WHERE Id = \''+lastAccSurvey.Id+'\'';
            }
        }else{
            accSurveyQuery += ' FROM Account_Survey__c WHERE Id = \''+accSurvey.Id+'\'';
        }                     
        system.debug('accSurveyQuery: '+accSurveyQuery);
        
        if(!firstSurvey){
            accSurvey = Database.query(accSurveyQuery);
        }
        if(newSurvey){
            accSurvey.Visit_Date__c = system.today();               
        }
        
        serializedAccSurvey = JSON.serialize(accSurvey);
        System.debug(serializedAccSurvey);
        //system.debug('accSurvey: '+accSurvey.Account__r.Market__c);
        
        //Build query for Account Survey Item fields
        asiQuery = 'SELECT Id, Name, Unit_Size__c, UOM__c, Brand__r.Name, Brand__r.Spirit_Type__c, Brand__r.Supplier__r.Name, Sort_Order__c';
        string asiSubQuery = ', (SELECT Id';
        for(Schema.FieldSetMember asif:asiFieldSet){
            asiSubQuery += ', ' + asif.getFieldPath();
        }   
        
        /* The productRuleMarketList set contains the markets that have opted-in to only show Active products that 
         * have a Used For value of AccountSurvey
         */
        Set<String> productRuleMarketList = new Set<String>();
        productRuleMarketList.add('Australia');
        productRuleMarketList.add('Poland');
        
        string mandProdQuery = '';  
        //Create new DateTime variable so we can get right format in query string
        Time myTime = Time.newInstance(0, 0, 0, 0);   
        string mandatoryProductDate = DateTime.newInstance(accSurvey.Visit_Date__c,myTime).format('yyyy-MM-dd');        
        //If newAs, grab Products for Market and ASI's from last Account Survey and Mandatory Products that are valid today for this account                                           
        if(newSurvey && lastAccSurvey != null){
            asiQuery += asiSubQuery;
            asiQuery += ' FROM Store_Survey_Items__r WHERE Account_Survey__c = \''+lastAccSurvey.Id+'\' LIMIT 1)';               
            mandProdQuery = ', (SELECT Id, Product_Status__c FROM Mandatory_Products__r WHERE Account__c = \''+accId+
                            '\' AND ((Listing_In__c <= '+mandatoryProductDate+' OR Listing_In__c = null) AND (Listing_Out__c >= '+mandatoryProductDate+' OR Listing_Out__c = null)) LIMIT 1)';
        }else{
            //First ever Account Survey for this Account
            if(newSurvey && lastAccSurvey == null){
                mandProdQuery = ', (SELECT Id, Product_Status__c FROM Mandatory_Products__r WHERE Account__c = \''+accId+
                                '\' AND ((Listing_In__c <= '+mandatoryProductDate+' OR Listing_In__c = null) AND (Listing_Out__c >= '+mandatoryProductDate+' OR Listing_Out__c = null)) LIMIT 1)';
            }else{
                //If editing existing survey, grab Products for Market and ASI's for this survey (including Product_Status__c) and Mandatory Products for this account 
                asiQuery += asiSubQuery;
                asiQuery += ', Product_Status__c FROM Store_Survey_Items__r WHERE Account_Survey__c = \''+accSurvey.Id+'\' LIMIT 1)';                
                mandProdQuery = ', (SELECT Id, Product_Status__c FROM Mandatory_Products__r WHERE Account__c = \''+accId+'\' LIMIT 1)';
            }
        }
        asiQuery += mandProdQuery;
        asiQuery += ' FROM Product__c WHERE IsActive__c = true AND RecordType.Name = \'Wet Goods\' AND Market__r.Name = \''+ marketName+'\' AND (Channel__c = \''+(fieldSetChannel == 'Combera' ? 'Off' : fieldSetChannel)+'\' OR Channel__c = \'Both\') ';
        //if (productRuleMarketList.contains(marketName)) {
        if (callcard.Account__r.Market__r.Strict_Product_Used_For_Account_Surveys__c == true) {
            asiQuery += ' AND Used_For__c INCLUDES (\''+productUsedFor+'\') ';
        } else {
            asiQuery += ' AND (Used_For__c INCLUDES (\''+productUsedFor+'\') OR Used_For__c = null) ';
        }
        asiQuery += 'ORDER BY Sort_Order__c, Name';
        system.debug('asiQuery: ' + asiQuery);
        prodList = Database.query(asiQuery);
        serializedProdList = JSON.serialize(prodList);
    }

    public List<Schema.FieldSetMember> getFieldSet(string objectName, string fieldSetName, boolean useDefault, boolean isDV, boolean isROF){
        List<Schema.FieldSetMember> fieldset = new List<Schema.FieldSetMember>();
        Map<String, Schema.FieldSet> fsMap = Schema.getGlobalDescribe().get(objectName).getDescribe().FieldSets.getMap();
        String fsName = fieldSetName;
        System.debug('[getFieldSet] fsName: ' + fsName + ', useDefault: ' + useDefault + ', isDV: ' + isDV + ', isROF: ' + isROF);
        if (isDV) { fsName += '_DV'; }
        if (isROF) { fsName += '_ROF'; }
        if(fsMap.containsKey(fsName)){
            fieldset = fsMap.get(fsName).getFields();        
        } else {
            List<String> fsParts = fieldSetName.split('_');
            while(fsParts.size() > 0) {
                if (fsParts.size() > 1) {
                    fsParts.remove(fsParts.size() - 1);
                    fieldSetName = '';
                    for(String s : fsParts) {
                        fieldSetName += s + '_';
                    }            
                    fieldSetName = fieldSetName.removeEnd('_');
                    fsName = fieldSetName;
                } else {
                    fsParts.clear();
                    fieldSetName = 'Default';
                    fsName = fieldSetName;
                }
                
                if (isDV) {
                    fsName += '_DV';
                }
                if (isROF) {
                    fsName += '_ROF';
                }
                if (fsMap.containsKey(fsName)) { break; }
            }
            
            if (fsMap.containsKey(fsName)) {
                fieldset = fsMap.get(fsName).getFields();
            }
        } 
        return fieldset;
    }
    
    public void setIntNumFormat(){
        if(International_Number_Format__c.getInstance(marketName) == null){
            useIntNumFormat = false;
        }else{
            useIntNumFormat = true;
        }
    }
    
    @RemoteAction
    public static Account_Survey__c saveSurvey (Account_Survey__c survey){
        system.debug('survey: '+survey);
        upsert survey;
        system.debug(survey);
        return survey;
    }
    
    @RemoteAction
    public static list<Account_Survey_Item__c> saveASI (list<Account_Survey_Item__c> asiList){
        system.debug('asiList: '+asiList);
        /*
        for(Account_Survey_Item__c asi : asiList) {
            if (asi.Delisted__c) {
                asi.Price_Label_Date__c = null;
            }
        }
        */
        upsert asiList;
        return asiList;
    }   
}