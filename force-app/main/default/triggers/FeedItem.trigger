trigger FeedItem on FeedItem (after insert, after update, after delete) {
	
    //check to see if feedItem is related to task object, if so call email alert class
    if(!trigger.isDelete){
        Id recTypeId = Schema.SObjectType.Task__c.getRecordTypeInfosByName().get('Digital Marketing').getRecordTypeId();
        map<id, feedItem> taskMap = new map<id, feedItem>();
        
        for(Feeditem fc: trigger.new){
            system.debug(fc.parentid);
            string taskPrefix = Task__c.sObjectType.getDescribe().getKeyPrefix();
            
            if(String.valueOf(fc.ParentId).substring(0,3) == taskPrefix){
                taskMap.put(fc.ParentId,fc);
            }
        }
        
        if(!taskMap.isEmpty()){
            Digital_Marketing_Email_Alert.buildEmails(taskMap);
        }
    }
    
    set<Id> promoIds = new set<Id>();
    if(!trigger.isDelete){
		for(FeedItem f :trigger.new){
			try{
				if((f.ContentType.contains('image') || f.ContentType.contains('JPG') || f.ContentType.contains('JPEG') || f.ContentType.contains('PNG')) && 
                   	f.ParentId.getSobjectType().getDescribe().getName() == 'Promotion__c'){
					promoIds.add(f.ParentId);
				}
			}catch(Exception e){
				system.debug('Exception looping through trigger.new: '+e);	
			}		
		}	
	}else{
		for(FeedItem f:trigger.old){
            system.debug('f: '+f);
			try{
				if((f.ContentType.contains('image') || f.ContentType.contains('JPG') || f.ContentType.contains('JPEG') || f.ContentType.contains('PNG')) && 
                   	f.ParentId.getSobjectType().getDescribe().getName() == 'Promotion__c'){
					promoIds.add(f.ParentId);
				}				
			}catch(Exception e){
				system.debug('Exception looping through trigger.old: '+e);	
			}
		}
	}
	
	if(!promoIds.isEmpty()){
		try{
			set<Promotion__c> promoSet = new set<Promotion__c>();
			for(Promotion__c p:[SELECT Id, Image_Attached__c, Image_Upload_Date__c,
                                	(SELECT Id FROM AttachedContentDocuments WHERE FileType = 'JPG' OR FileType = 'JPEG' OR FileType = 'PNG'), 
                                	(SELECT Id FROM Attachments WHERE ContentType LIKE 'image%') 
                                FROM Promotion__c WHERE Id in:promoIds]){
                system.debug('p: '+p);
				if(!p.Attachments.isEmpty() || !p.AttachedContentDocuments.isEmpty()){
					p.Image_Attached__c = true;
                    if(p.Image_Upload_Date__c == null) {
                    	p.Image_Upload_Date__c = DateTime.now();
                    }
				}else{
					p.Image_Attached__c = false;
                    p.Image_Upload_Date__c = null;
				}
				promoSet.add(p);
			}
			list<Promotion__c> promosToUpdate = new list<Promotion__c>();
			promosToUpdate.addAll(promoSet);
			update promosToUpdate;
			
		}catch(Exception e){
			system.debug('Exception querying for promotions: '+e);			
		}
	}
}