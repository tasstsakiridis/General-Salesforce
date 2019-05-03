trigger ContentVersion on ContentVersion (after insert) {
    String kpPromotion = Promotion__c.SObjectType.getDescribe().getKeyPrefix();

    Boolean hasEinsteinPermission = FeatureManagement.checkPermission('EinsteinPredictionService');
    for(ContentVersion cv : Trigger.new) {
        if (hasEinsteinPermission && cv.FirstPublishLocationId != null) {
            String parentId = String.valueOf(cv.FirstPublishLocationId);
            System.debug('[ContentVersion.trigger] parentId: ' + parentId + ', keyPrefix: ' + kpPromotion);
            if (parentId.startsWith(kpPromotion) && !Test.isRunningTest() && cv.VersionData != null) {
                Einstein_Helper.callEinsteinImagePredictionService(parentId, EncodingUtil.base64Encode(cv.VersionData));
            }
        } 
    }        
}