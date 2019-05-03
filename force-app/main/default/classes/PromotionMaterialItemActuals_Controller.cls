global with sharing class PromotionMaterialItemActuals_Controller {
    public Promotion__c thisPromotion               { get; set; }
    public List<Promotion_Material_Item__c> pmiList { get; set; }
    //public List<PMI_Actual__c> pmaList              { get; set; }
    public List<PMAWrapper> pmaList                 { get; set; }
    
    public String serializedPromotion               { get; set; }
    public String serializedMaterialItemList        { get; set; }
    public String serializedActualsList             { get; set; }
    public String serializedPMAFS                   { get; set; }
    public String serializedReadOnlyFieldList	    { get; set; }
    public String serializedPMIActualsDescribe		{ get; set; }
    
    public String urlPrefix           				{ get; set; }
    public String promotionType						{ get; set; }
    public String promotionId                       { get; set; }
    public String accountId                         { get; set; }
    public String accountName                       { get; set; }
    public String approvalStatus                    { get; set; }
    public String marketName                        { get; set; }
    
    Map<Integer, String> monthNames;
    
    public class PMAWrapper {
        public String pmiId { get; set; }
        public List<PMI_Actual__c> pmaList { get; set; }
        
        public PMAWrapper() {
            this.pmiId = '';
            this.pmaList = new List<PMI_Actual__c>();
        }
        public PMAWrapper(String pmiId, List<PMI_Actual__c> pmaList) {
            this.pmiId = pmiId;
            this.pmaList = pmaList;
        }
        
    }
    
    public PromotionMaterialItemActuals_Controller(ApexPages.StandardController controller) {
        thisPromotion = [SELECT Id, Name, Market__c, RecordTypeId, RecordType.Name, Status__c, Approval_Status__c, Account__c, AccountName__c, Account__r.Name, Promotion_Activity__c, Promotion_Start_Date__c, Promotion_End_Date__c FROM Promotion__c WHERE Id =: controller.getId()];
                
        bfObjectDescribe objDescribe = new bfObjectDescribe('PMI_Actual__c');
        objDescribe.getDescribe(true, false, false);
        serializedPMIActualsDescribe = JSON.serialize(objDescribe);
        
        try {
            Map<String,String> pageParams = ApexPages.currentPage().getParameters();
            String dept       = pageParams.get('dept');
            if (dept == null) { dept = ''; }
            
            promotionId = thisPromotion.Id;
            accountId = thisPromotion.Account__c;
            accountName = thisPromotion.Account__r.Name;
            approvalStatus = thisPromotion.Approval_Status__c;
            marketName = thisPromotion.Market__c;
        
            promotionType = thisPromotion.RecordType.Name;
            if (promotionType.endsWithIgnoreCase('Locked')) {
                promotionType = promotionType.substringBefore(' ');
            }
        
            String fieldSetName = marketName + '_' + promotionType;
            fieldSetName = fieldSetName.replace(' ','_');
            fieldSetName = fieldSetName.replace('-','_');
            if (dept != null && dept.length() > 0) { fieldSetName = fieldSetName + '_' + dept; }
            system.debug('fieldSetName: '+fieldSetName);
        
            List<Schema.FieldSetMember> pmaFS = FieldSetHelper.getFieldSetFields('PMI_Actual__c', fieldSetName);
            serializedPMAFS = JSON.serialize(pmaFS);
    
            List<String> readOnlyFields = FieldSetHelper.getFieldSetFieldNames('PMI_Actual__c', fieldSetName.toLowerCase() + '_ReadOnlyFields');
            serializedReadOnlyFieldList = JSON.serialize(readOnlyFields);
        
        pmiList = [SELECT Id, Name, Promotion__c, Product_Custom__c, Product_Custom__r.Name, Plan_Qty__c, Monthly_Bottle_Qty__c, Monthly_Per_Bottle_Discount__c  FROM Promotion_Material_Item__c WHERE Promotion__c =: thisPromotion.Id];
        if (pmiList == null) {
            pmiList = new List<Promotion_Material_Item__c>();
        }
        
        List<PMI_Actual__c> pmas = new List<PMI_Actual__c>();
		pmaList = new List<PMAWrapper>();
        if (thisPromotion.Approval_Status__c == 'Approved') {
            Boolean found = false;
        	String soql = 'SELECT Id, Name, Promotion__c, Promotion_Material_Item__c, Period__c, Month_Name__c, Month_Number__c, Year__c, External_Key__c, ';
            for(Schema.FieldSetMember fsm : pmaFS) {
                soql += fsm.getFieldPath() + ',';
            }
            soql = soql.removeEnd(',');
	        soql += ' FROM PMI_Actual__c WHERE Promotion__c = \'' + thisPromotion.Id + '\'';
        	pmas = Database.query(soql);
            
	        //List<PMI_Actual__c> pmas = [SELECT Id, Name, Promotion__c, Promotion_Material_Item__c, Actual__c, Period__c, External_Key__c FROM PMI_Actual__c WHERE Promotion__c =: thisPromotion.Id ORDER BY Promotion_Material_Item__c, Period__c];            
            
            if (pmas == null || pmas.size() == 0) {
            } else {
                for(PMI_Actual__c pma : pmas) {
                    found = false;
                    for(PMAWrapper pmaw : pmaList) {
                        if (pmaw.pmiId == pma.Promotion_Material_Item__c) {
                            found = true;
                            pmaw.pmaList.add(pma);
                            break;
                        }
                    }
                    
                    if (found == false) {
                        PMAWrapper pmaw = new PMAWrapper();
                        pmaw.pmiId = pma.Promotion_Material_Item__c;
                        pmaw.pmaList.add(pma);
                        pmaList.add(pmaw);
                    }
                }                
            }
        }
        
        
        serializedPromotion = JSON.serialize(thisPromotion);
        serializedMaterialItemList = JSON.serialize(pmiList);
        serializedActualsList = JSON.serialize(pmaList);
         }catch(Exception ex) {
            System.debug('exception in pma actuals: ' + ex.getMessage());
        }
       
    }
     
    @RemoteAction
    //global static void savePMIActuals(List<PMI_Actual__c> pmaList){
    global static void savePMIActuals(String pmaList, String promotionId) {
    	system.debug('pmaList: '+pmaList);
    
        List<PMI_Actual__c> newList = (List<PMI_Actual__c>)JSON.deserialize(pmaList, List<PMI_Actual__c>.class);
        update newList;  
        
		Promotion__c thePromotion = [SELECT Id, Actuals_Updated__c FROM Promotion__c WHERE Id =:promotionId];
        thePromotion.Actuals_Updated__c = true;
        update thePromotion;
    }    
    
}