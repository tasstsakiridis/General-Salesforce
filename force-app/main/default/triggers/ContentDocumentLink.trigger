trigger ContentDocumentLink on ContentDocumentLink (after delete, after insert, after update) {
    String kpPromotion = Promotion__c.SObjectType.getDescribe().getKeyPrefix();
    System.debug('[ContentDocumentLink trigger]');
    //Compensating Controls - Levites
    Set<Id> SODIds = new Set<Id>();
    Set<Id> promoIds = new Set<Id>();
    Set<Id> documentIds = new Set<Id>();
    Set<String> imageTypes = new Set<String>{'png','jpg','jpeg','gif','tif'};

    String fileType = '';
    String parentId = '';
       
	if(!Trigger.isDelete){
		for(ContentDocumentLink a :Trigger.new){			
			try{				
                //Compensating Controls - Levites
                if(a.LinkedEntityId.getSobjectType().getDescribe().getName() == 'SOD__c'){
					SODIds.add(a.LinkedEntityId);
				}
                if (a.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Promotion__c') {
                    promoIds.add(a.LinkedEntityId);
                    documentIds.add(a.ContentDocumentId);
                    
                }
			}catch(Exception e){
				system.debug('Exception looping through trigger.new: '+e);	
			}		
		}	
	}else{
		for(ContentDocumentLink a:Trigger.old){
			try{
                System.debug('linkedType: ' + a.LinkedEntityId.getSobjectType().getDescribe().getName());
                System.debug('id: ' + a.LinkedEntityId);
                System.debug('document.filetype: ' + a.ContentDocument.FileType);
                  
                //Compensating Controls - Levites
                if(a.LinkedEntityId.getSobjectType().getDescribe().getName() == 'SOD__c'){
					SODIds.add(a.LinkedEntityId);
				}
                if (a.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Promotion__c') {
                    promoIds.add(a.LinkedEntityId);
                }
                
			}catch(Exception e){
				system.debug('Exception looping through trigger.old: '+e);	
			}
		}
	}
        
    if(!SODIds.isEmpty()){
        try{
            set<SOD__c> SODSet = new set<SOD__c>();
            for(SOD__c r:[SELECT Id, Files_Attached__c, (SELECT Id FROM AttachedContentDocuments) FROM SOD__c WHERE Id in:SODIds]){
                if(!r.AttachedContentDocuments.isEmpty()){
                    r.Files_Attached__c = true;
                    system.debug('In the True Statement');	
                }else{
                    r.Files_Attached__c = false;
                    system.debug('In the False Statement');	
                }
                SODSet.add(r);
            }
            list<SOD__c> SODToUpdate = new list<SOD__c>();
            SODToUpdate.addAll(SODSet);
            update SODToUpdate;
            
        }catch(Exception e){
            system.debug('Exception querying for SOD: '+e);			
        }
    }
    if (!promoIds.isEmpty()) {
        try {
            List<Promotion__c> promotions = [SELECT Id, Image_Attached__c, Image_Upload_Date__c, (SELECT Id, ContentDocumentId, FileType FROM AttachedContentDocuments) FROM Promotion__c WHERE Id =:promoIds];
            List<Promotion__c> promotionsToUpdate = new List<Promotion__c>();
            Set<Id> linkedIds = new Set<Id>();
            for(Promotion__c p: promotions) {
                System.debug('has attached documents: ' + p.AttachedContentDocuments.isEmpty());
                if (p.AttachedContentDocuments.isEmpty()) {
                    p.Image_Attached__c = false;
                    promotionsToUpdate.add(p);
                } else {
                    for(Integer i = 0; i < p.AttachedContentDocuments.size();i++) {
                        System.debug('document: ' + p.AttachedContentDocuments.get(i).ContentDocumentId + ' fileType: ' + p.AttachedContentDocuments.get(i).FileType);
                        if (imageTypes.contains(p.AttachedContentDocuments.get(i).FileType.toLowerCase())) {
                            if (!p.Image_Attached__c) {
                                p.Image_Attached__c = true;
                                promotionsToUpdate.add(p);
                            }
                        }
                    }
                }
            }
            System.debug('promotions to update: ' + promotionsToUpdate);
            
            if (!promotionsToUpdate.isEmpty()) {
                update promotionsToUpdate;
            }
        } catch(Exception ex) {
            System.debug('Exception updating Promotions Image Attached: ' + ex);
        }
    }
}