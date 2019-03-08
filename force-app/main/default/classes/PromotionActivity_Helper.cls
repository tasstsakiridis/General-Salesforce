global class PromotionActivity_Helper {

    @InvocableMethod
    public static void createPMIActuals(String activityId) {
        List<PMI_Actual__c> actuals = new List<PMI_Actual__c>();
        Promotion_Activity__c theActivity = [SELECT Id, Begin_Date__c, End_Date__c, CurrencyIsoCode, 
                                                    (SELECT Account__c FROM Promotions__r), 
                                                    (SELECT Product_Custom__c FROM Promotion_Material_Items__r), 
                                                    (SELECT Id, External_Key__c FROM PMI_Actuals__r) 
                                               FROM Promotion_Activity__c 
                                              WHERE Id=:activityId
                                              LIMIT 1];
        
        Integer numberOfPeriods = 0;
        String externalKey = '';
        Boolean found = false;
        
        numberOfPeriods = activity.Begin_Date__c.monthsBetween(theActivity.End_Date__c);
        if (numberOfPeriods == 0) { numberOfPeriods = 1; }
        for(Integer i = 0; i < numberOfPeriods; i++) {
            for(Promotion_Material_Item__c pmi : theActivity.Promotion_Material_Items__r) {
                for(Promotion__c p : theActivity.Promotions__r) {
                    externalKey = pmi.Id + '_' + p.Id + '_' + i;
                    found = false;
                    if (activity.PMI_Actuals__r != null) {
                        for(PMI_Actual__c pmia : theActivity.PMI_Actuals__r) {
                            if (pmia.External_Key__c == externalKey) {
                                found = true; break;
                            }
                        }
                    }
                    if (!found) {
                        PMI_Actual__c pma = new PMI_Actual__c();
                        pma.External_Key__c = pmi.Id + '_' + p.Id + '_' + i;
                        pma.Activity__c = theActivity.Id;
                        pma.Period__c = i;
                        pma.Promotion_Material_Item__c = pmi.Id;
                        pma.Promotion__c = p.Id;
                        pma.CurrencyIsoCode = theActivity.CurrencyIsoCode;
                        
                        actuals.add(pma);                           
                    }
                }
            }        
        }            
    
        if (actuals.size() > 0) {
            insert actuals;
        }

    }
    
}
