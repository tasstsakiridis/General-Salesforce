trigger delPromotionImage on ContentDocument (before delete) {
    //System.debug('Tigger: ContentDocument before delete');
    //System.debug('trigger.old: ' + trigger.old);

    // Gather list of ContentDocuments being deleted
    set<Id> contentDocumentIds = new set<Id>();
    for(ContentDocument a :Trigger.old){
        contentDocumentIds.add(a.Id);
    }

    //System.debug('contentDocumentIds: ' + contentDocumentIds);

    // Determine if any contentDocumentIds here belong to a Promotion__C, save ContentDocumentIds from Promotion__c objects
    List<ContentVersion> contentVersions = [SELECT ContentDocumentId, FirstPublishLocationId FROM ContentVersion WHERE FirstPublishLocationId != null AND ContentDocumentId IN :contentDocumentIds];
    Set<Id> promoIds = new Set<Id>();
    Set<Id> promoContentIds = new Set<Id>();
    for(ContentVersion cv : contentVersions) {
        if(cv.FirstPublishLocationId.getSobjectType().getDescribe().getName() == 'Promotion__c') {
            promoIds.add(cv.FirstPublishLocationId);
            promoContentIds.add(cv.ContentDocumentId);
        }
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
            GenericAttachmentUtility.updateAttachmentStatus(promoIds, new PromotionAttachmentBehavior(), fileFilter, promoContentIds);
    }
}