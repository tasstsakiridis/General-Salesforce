public with sharing class Call_Card_Controller {

    public String marketName 			{get;set;}
    public Boolean useNRAfields 		{get;set;} 
    public Boolean contactRequired 		{get;set;} 

    public Id recordTypeId;
    public String nraRecordType = 'Call Card - US CMG';
    
    private CallCard__c callCard;
    private final Account parentAccount;
    private Id parentAccountID;
    private String retURL;
    private List<Promotion__c> openPromotions = new list<Promotion__c>();
  
    public Call_Card_Controller(ApexPages.StandardController stdController) {
        this.retURL = ApexPages.currentPage().getParameters().get('retURL');
        this.callCard = (CallCard__c) stdController.getRecord();
        if(callCard.id!=null) { //Edit Call Card
            this.parentAccountID = callCard.Account__c;
        } else {
            String acctObject = Call_Card_Settings__c.getAll().values()[0].Account_Object_ID__c;
            system.debug('acctObject: ' + acctObject);
            this.parentAccountID = ApexPages.currentPage().getParameters().get(acctObject + '_lkid'); 
        }
        
        system.debug('parentAccountID: ' +parentAccountID);
        parentAccount = [Select Id, Market__r.Name, Call_Card_Objectives__c, RecordType.Name from Account where Id = :parentAccountID];
        system.debug('parentAccount: ' +parentAccount);
        this.marketName = parentAccount.Market__r.Name;
        this.callCard.Objectives__c = parentAccount.Call_Card_Objectives__c;
        
        contactRequired = false;
        if(marketName == 'Australia'){
            contactRequired = true;
        }
        
        // Get the CallCard record types by name
        Map<String,Schema.RecordTypeInfo> ccRTMap = Schema.SObjectType.CallCard__c.getRecordTypeInfosByName();
        // Get the record type ids
        
        useNRAfields = false;    
        if(parentAccount.RecordType.Name == 'USA - Parents Off' || parentAccount.RecordType.Name == 'USA - Parents On'){
            useNRAfields = true;
            if(ccRTMap.containsKey('Call Card - US CMG')){
                this.callCard.RecordTypeId = ccRTMap.get('Call Card - US CMG').getRecordTypeId();
            }  
        }
    }
  
    public List<SelectOption> getContacts() {
        List<SelectOption> optionList = new List<SelectOption>();
        optionList.add(new SelectOption('',''));       
        if(parentAccount !=null) {
            for(Contact y :[Select r.Name, r.Id From Contact r where AccountId =: parentAccountID and Is_Active__c = true order by r.Name]) {
                optionList.add(new SelectOption(y.Id,y.Name));
            }
        }
        return optionList;
    }  
    
    //grab all open promotions for this account and assign them to this call card
    public void getPromotions(){      
        for(Promotion__c p :[SELECT Account__c,CallCard__c,Id,Promotion_Status__c FROM Promotion__c WHERE Account__c = :parentAccountID AND Status__c = 'Not Visited']){
            p.CallCard__c = callCard.Id;
            openPromotions.add(p);
        }
        if(!openPromotions.isEmpty()){
            update openPromotions;
        }
    }

    public PageReference saveAndClose() {
        saveCallCard();
        if (ApexPages.hasMessages()) {
            return null;
        } else {
            retUrl = '/' + this.callCard.Id;
            return new PageReference(retURL);
        }
    }
  
    public PageReference saveAndCreateAccountSurvey() {
        saveCallCard();
        if (ApexPages.hasMessages()) {
            return null;
        } else {
            String ccObject = Call_Card_Settings__c.getAll().values()[0].Call_Card_Object_ID__c;
            if (this.marketName == 'Australia') {
                retUrl = '/apex/AccountSurvey_Redirect?accountId='+this.parentAccountID+'&ccId='+this.callCard.Id+'&retURL=' + this.callCard.Id + '&' + ccObject + '_lkid=' + this.callCard.Id + '&scontrolCaching=1&sfdc.override=1';            
            } else {
                retUrl = '/apex/AccountSurvey?accountId='+this.parentAccountID+'&ccId='+this.callCard.Id+'&retURL=' + this.callCard.Id + '&' + ccObject + '_lkid=' + this.callCard.Id + '&scontrolCaching=1&sfdc.override=1';            
            }
            return new PageReference(retURL);
        }
    }
  
  
    public void saveCallCard() {
        try {
            if (this.callCard.Id == null) {
                List<CallCard__c> callCards = [SELECT Id 
                                                 FROM CallCard__c 
                                                WHERE Account__c =:this.parentAccountID 
                                                  AND CreatedDate = TODAY
                                             ORDER BY CreatedDate  
                                                LIMIT 1];
    
                if (callCards != null && callCards.size() > 0) {
                    this.callCard.Id = callCards[0].Id;
                }                
            }
            
            upsert this.callCard;
            if(marketName == 'France'){
                getPromotions();
            }
        } catch (System.Dmlexception e) {
            ApexPages.addMessages(e);
        }      
    }
}