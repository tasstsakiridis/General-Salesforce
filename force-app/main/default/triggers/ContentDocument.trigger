trigger ContentDocument on ContentDocument (before delete) {

    Set<Id> SODIds = new Set<Id>();
    Set<Id> promoIds = new Set<Id>();
    Set<Id> documentIds = Trigger.oldmap.keySet();
    List<ContentVersion> versions = [SELECT Id, FirstPublishLocationId FROM ContentVersion WHERE FirstPublishLocationId != null AND ContentDocumentId =:documentIds];
    
    for(ContentVersion cv : versions) {
        try{
            
            //Compensating Controls - Levites
            if(cv.FirstPublishLocationId.getSobjectType().getDescribe().getName() == 'SOD__c'){
                SODIds.add(cv.FirstPublishLocationId);
            }
            
            if(cv.FirstPublishLocationId.getSobjectType().getDescribe().getName() == 'Promotion__c'){
                promoIds.add(cv.FirstPublishLocationId);
            }
			
        }catch(Exception e){
            system.debug('Exception looping through trigger.new: '+e);	
        }		        
    }
    
    if(!SODIds.isEmpty()){
        try{
            List<SOD__c> SODSet = new List<SOD__c>();
            for(SOD__c r:[SELECT Id, Files_Attached__c, (SELECT Id, ContentDocumentId FROM AttachedContentDocuments) FROM SOD__c WHERE Id in:SODIds]){
                if(r.AttachedContentDocuments.isEmpty() || (r.AttachedContentDocuments.size() == 1 && Trigger.oldmap.containsKey(r.AttachedContentDocuments.get(0).ContentDocumentId))){
                    r.Files_Attached__c = false;
                }
                if (!SODSet.contains(r)) {
                	SODSet.add(r);                    
                }
            }
            update SODSet;
            
        }catch(Exception e){
            system.debug('Exception querying for SOD: '+e);			
        }
    }
    
    System.debug('promotions:' +promoIds);
    if (!promoIds.isEmpty()) {
        try {
            List<Promotion__c> promotionsToUpdate = new List<Promotion__c>();
            for(Promotion__c p : [SELECT Id, Image_Attached__c, Image_Upload_Date__c, (SELECT Id, ContentDocumentId FROM AttachedContentDocuments) FROM Promotion__c WHERE Id=:promoIds]) {
                System.debug('p.attachedcontentdocuments: ' + p.AttachedContentDocuments);
                System.debug('Trigger.oldmap' + Trigger.oldMap.keySet());
                if (p.AttachedContentDocuments.isEmpty() || (p.AttachedContentDocuments.size() == 1 && Trigger.oldMap.containsKey(p.AttachedContentDocuments.get(0).ContentDocumentId))) {
                    p.Image_Attached__c = false;

                    if (!promotionsToUpdate.contains(p)) {
                        promotionsToUpdate.add(p);
                    }
                }
            }

            System.debug('promotions to update: ' + promotionsToUpdate);
            if (!promotionsToUpdate.isEmpty()) {
                update promotionsToUpdate;
            }
        }catch(Exception ex) {
            System.debug('Exception trying to update promotions. ' + ex);
        }
    }
   
}