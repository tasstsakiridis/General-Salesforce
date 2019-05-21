public class SalesProposal_CreatePMIActuals {
    @InvocableMethod
    public static void createProposalActuals(List<Id> proposalIds) {
        List<PMI_Actual__c> actuals = new List<PMI_Actual__c>();
        List<Promotion_Activity__c> activities = [SELECT Id, Begin_Date__c, End_Date__c, CurrencyIsoCode, (SELECT Account__c FROM Promotions__r), (SELECT Product_Custom__c FROM Promotion_Material_Items__r), (SELECT Id, External_Key__c FROM PMI_Actuals__r) FROM Promotion_Activity__c WHERE Id=:proposalIds];
        Map<String, Schema.RecordTypeInfo> rtSchemaList = Schema.SObjectType.PMI_Actual__c.getRecordTypeInfosByName();
        String rtSalesProposalId = rtSchemaList.get('Sales Proposal').getRecordTypeId();
        
        Integer numberOfPeriods = 0;
        String externalKey = '';
        Boolean found = false;
        
        for(Promotion_Activity__c activity : activities) {
            numberOfPeriods = activity.Begin_Date__c.monthsBetween(activity.End_Date__c);
            if (numberOfPeriods == 0) { numberOfPeriods = 1; }
            for(Integer i = 0; i < numberOfPeriods; i++) {
                for(Promotion_Material_Item__c pmi : activity.Promotion_Material_Items__r) {
                    for(Promotion__c p : activity.Promotions__r) {
                        externalKey = pmi.Id + '_' + p.Id + '_' + i;
        				found = false;
                        if (activity.PMI_Actuals__r != null) {
                            for(PMI_Actual__c pmia : activity.PMI_Actuals__r) {
                                if (pmia.External_Key__c == externalKey) {
                                    found = true; break;
                                }
                            }
                        }
                        if (!found) {
                            PMI_Actual__c pma = new PMI_Actual__c();
                            pma.RecordTypeId = rtSalesProposalId;
                            pma.External_Key__c = pmi.Id + '_' + p.Id + '_' + i;
                            pma.Activity__c = activity.Id;
                            pma.Period__c = i;
                            pma.Promotion_Material_Item__c = pmi.Id;
                            pma.Promotion__c = p.Id;
                            pma.CurrencyIsoCode = activity.CurrencyIsoCode;
                            pma.Approval_Status__c = 'New';
                            
                            actuals.add(pma);                           
                        }
                    }
                }        
            }  

            activity.Build_PMI_Actuals__c = false;          
        }
        
        if (actuals.size() > 0) {
            insert actuals;
        }
    }
}
