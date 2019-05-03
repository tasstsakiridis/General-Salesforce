trigger newPromotionImage on ContentVersion (after insert) {
    //System.debug('Tigger: ContentVersion after insert');
    //System.debug('trigger.new: ' + trigger.new);

    // Gather list of ContentDocuments being inserted
    set<Id> contentDocumentIds = new set<Id>();
    for(ContentVersion a :Trigger.new){
        contentDocumentIds.add(a.ContentDocumentId);
    }

    //System.debug('contentDocumentIds: ' + contentDocumentIds);

    // Determine if any contentDocumentIds here belong to a Promotion__C
    List<ContentVersion> contentVersions = [SELECT FirstPublishLocationId FROM ContentVersion WHERE FirstPublishLocationId != null AND ContentDocumentId IN :contentDocumentIds];
    Set<Id> promoIds = new Set<Id>();
    for(ContentVersion cv : contentVersions) {
        if(cv.FirstPublishLocationId.getSobjectType().getDescribe().getName() == 'Promotion__c')
            promoIds.add(cv.FirstPublishLocationId);
    }

    //System.debug('promoIds: ' + promoIds);

    // Send to helper class to update Attachment status on Promotion__c objects that changed
    if(!promoIds.isEmpty()){
         Set<String> fileFilter = new Set<String>();
        fileFilter.add('image%');
        fileFilter.add('jpg');
        fileFilter.add('jpeg');
        fileFilter.add('png');
        fileFilter.add('gif');
        if(!Test.isRunningTest())
        	GenericAttachmentUtility.updateAttachmentStatus(promoIds, new PromotionAttachmentBehavior(), fileFilter);
	}
}