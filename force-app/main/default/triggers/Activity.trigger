/* Description  : Activity used for roll up summary activity to parent market campaign on each activity created,edited, deleted.
 * */
trigger Activity on Promotion_Activity__c (before insert, before update, after insert, after update, before delete, after delete) {
    if (Trigger.isInsert && Trigger.isAfter) {
        System.debug('New Activity ' + Trigger.newMap.size());
        MRM_MarketCampaign_Helper.addMarketCampaignSummary(Trigger.newMap);
    } else if (Trigger.isDelete && Trigger.isBefore) {
        System.debug('Delete old Activity ' + Trigger.oldMap.size());
        MRM_MarketCampaign_Helper.subtractMarketCampaignSummary(Trigger.oldMap);
    } else if (Trigger.isUpdate) {
        Map<Id, Promotion_Activity__c> oldActivityMap = Trigger.oldMap;
        Map<Id, Promotion_Activity__c> newActivityMap = Trigger.newMap;
        if (Trigger.isBefore) {

            Promotion_Activity__c oldActvty;
            Map<Id, Promotion_Activity__c> reParentedActivities = new Map<Id, Promotion_Activity__c>();
            for (Promotion_Activity__c newActvty : newActivityMap.values()) {
                if (oldActivityMap.containsKey(newActvty.Id)) {
                    oldActvty = oldActivityMap.get(newActvty.Id);
                    if (oldActvty.Market_Campaign__c != newActvty.Market_Campaign__c) {
                        reParentedActivities.put(oldActvty.Id, oldActvty);
                    }
                }
            }
            MRM_MarketCampaign_Helper.subtractMarketCampaignSummary(reParentedActivities);
        } else {
            MRM_MarketCampaign_Helper.addMarketCampaignSummary(newActivityMap);
        }
    }
}