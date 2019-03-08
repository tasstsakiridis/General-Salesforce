public class SalesProposal_UpdateRemainingTotals {
    @InvocableMethod
    public static void updateSalesProposalTotals(List<String> activityIds) {

        List<Promotion_Activity__c> activities = [SELECT Id, Name, SalesProposal_Actuals_Updated__c, Total_Remaining_A_P__c, 
                                                    Total_Remaining_Discount__c, Total_Remaining_Free_Bottle__c, Total_Remaining_Volume__c,
                                                    Total_A_P_Discount__c, Total_Discount__c, Total_Volume__c, Total_Free_Bottle_Quantity__c,
                                                    (SELECT Id, Remaining_A_P__c, Remaining_Discount__c, Remaining_Volume__c, Remaining_Free_Bottle_Qty__c
                                                       FROM Promotion_Material_Items__r),
                                                    (SELECT Id, Promotion_Material_Item__c, Act_Qty__c, Actual_A_P__c, Actual_Discount__c, Actual_Free_Bottle_Qty__c
                                                       FROM PMI_Actuals__r)
                                                FROM Promotion_Activity__c
                                                WHERE Id =:activityIds
                                                LIMIT 1];

        Decimal totalActualAP = 0;
        Decimal totalActualQty = 0;
        Decimal totalActualDiscount = 0;
        Decimal totalActualFreeBottleQty = 0;

        for(Promotion_Activity__c theActivity : activities) {
            totalActualAP = 0;
            totalActualQty = 0;
            totalActualDiscount = 0;
            totalActualFreeBottleQty = 0;

            if (theActivity.PMI_Actuals__r != null) {
                for(PMI_Actual__c pmia : theActivity.PMI_Actuals__r) {
                    totalActualAP += pmia.Actual_A_P__c == null ? 0 : pmia.Actual_A_P__c;
                    totalActualQty += pmia.Act_Qty__c == null ? 0 : pmia.Act_Qty__c;
                    totalActualDiscount += pmia.Actual_Discount__c == null ? 0 : pmia.Actual_Discount__c;
                    totalActualFreeBottleQty += pmia.Actual_Free_Bottle_Qty__c;

                    for(Promotion_Material_Item__c pmi : theActivity.Promotion_Material_Items__r) {
                        if (pmi.Id == pmia.Promotion_Material_Item__c) {
                            pmi.Remaining_A_P__c -= pmia.Actual_A_P__c == null ? 0 : pmia.Actual_A_P__c;
                            pmi.Remaining_Discount__c -= pmia.Actual_Discount__c == null ? 0 : pmia.Actual_Discount__c;
                            pmi.Remaining_Volume__c -= pmia.Act_Qty__c == null ? 0 : pmia.Act_Qty__c;
                            pmi.Remaining_Free_Bottle_Qty__c -= pmia.Actual_Free_Bottle_Qty__c == null ? 0 : pmia.Actual_Free_Bottle_Qty__c;
                        }
                    }
                }

                update theActivity.Promotion_Material_Items__r;

                theActivity.Total_Remaining_A_P__c = theActivity.Total_A_P_Discount__c - totalActualAP;
                theActivity.Total_Remaining_Discount__c = theActivity.Total_Discount__c - totalActualDiscount;
                theActivity.Total_Remaining_Volume__c = theActivity.Total_Volume__c - totalActualQty;
                theActivity.Total_Remaining_Free_Bottle__c = theActivity.Total_Free_Bottle_Quantity__c - totalActualFreeBottleQty;
                theActivity.SalesProposal_Actuals_Updated__c = false;
            }
        }

        if (activities != null) {
            update activities;
        }
    }
}
