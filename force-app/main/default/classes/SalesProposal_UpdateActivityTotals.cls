public with sharing class SalesProposal_UpdateActivityTotals {
    @InvocableMethod
    public static void UpdateActivityTotals(List<String> activityIds) {
        List<Promotion_Activity__c> activities = [SELECT Id, Name, Total_Discount__c, Total_Cost_of_Goods__c, Total_Net_Sales__c, Total_Free_Bottle_COGS__c,
                                                    Total_Free_Bottle_COGS_9L__c, Total_Free_Bottle_Cost__c, Total_Free_Bottle_Quantity__c, Total_Free_Bottle_Quantity_9L__c,
                                                    Total_A_P_Discount_Ex_FreeGoods__c, Total_A_P_Discount_Ex_FreeGoods_9L__c, Total_A_P_Quantity__c,
                                                    Total_Remaining_A_P__c, Total_Remaining_Discount__c, Total_Remaining_Free_Bottle__c, Total_Remaining_Volume__c,
                                                    Total_A_P_Discount__c, 
                                                    (SELECT Id, Plan_COGS__c, Plan_Qty__c, Plan_Qty_9L__c, Plan_Net_Sales__c, Free_Bottle_Quantity__c, Free_Bottle_Quantity_9L__c,
                                                            Total_Outlet_Incentive__c, Total_Outlet_Incentive_9L__c, Free_Bottle_COGS__c, Free_Bottle_COGS_9L__c, Free_Bottle_Cost__c,
                                                            Remaining_A_P__c, Remaining_Discount__c, Remaining_Volume__c, Remaining_Free_Bottle_Qty__c, Target_Qty__c, Target_Qty_9L__c
                                                       FROM Promotion_Material_Items__r),
                                                    (SELECT Id, Promotion_Material_Item__c, A_P_Item_Total__c, A_P_Item_Total_9L__c, Quantity__c, Is_Incentive_Product__c, Item_Type__c
                                                       FROM Promotion_Material_A_P_Items__r),
                                                    (SELECT Id, Promotion_Material_Item__c, Act_Qty__c, Actual_A_P__c, Actual_Discount__c, Actual_Free_Bottle_Qty__c
                                                       FROM PMI_Actuals__r)
                                                FROM Promotion_Activity__c
                                                WHERE Id =:activityIds
                                                LIMIT 1];

        Decimal totalActualAP = 0;
        Decimal totalActualQty = 0;
        Decimal totalActualDiscount = 0;
        Decimal totalActualFreeBottleQty = 0;
        Decimal totalCOGS = 0;
        Decimal totalDiscount = 0;
        Decimal totalDiscount9L = 0;
        Decimal totalQuantity = 0;
        Decimal totalNetSales = 0;
        Decimal totalFreeBottleQuantity = 0;
        Decimal totalFreeBottleQuantity9L = 0;
        Decimal totalVolume9L = 0;
        Decimal totalFreeBottleCOGS = 0;
        Decimal totalFreeBottleCOGS9L = 0;
        Decimal totalFreeBottleCost = 0;
        Decimal totalAPDiscount = 0;
        Decimal totalAPDiscount9L = 0;
        Decimal totalAPQuantity = 0;
        Decimal actualFreeBottleQty = 0;
        Decimal actualQty = 0;
        Decimal actualAP = 0;
        Decimal actualDiscount = 0;

        Map<Id, Promotion_Material_Item__c> materialItems = new Map<Id, Promotion_Material_Item__c>();
        Promotion_Material_Item__c materialItem;

        for(Promotion_Activity__c theActivity : activities) {

            totalActualAP = 0;
            totalActualQty = 0;
            totalActualDiscount = 0;
            totalActualFreeBottleQty = 0;
            totalActualFreeBottleQty = 0;
            totalCOGS = 0;
            totalDiscount = 0;
            totalDiscount9L = 0;
            totalQuantity = 0;
            totalNetSales = 0;
            totalVolume9L = 0;
            totalFreeBottleQuantity = 0;
            totalFreeBottleQuantity9L = 0;
            totalFreeBottleCOGS = 0;
            totalFreeBottleCOGS9L = 0;
            totalFreeBottleCost = 0;
            totalAPDiscount = 0;
            totalAPDiscount9L = 0;
            totalAPQuantity = 0;

            materialItems.clear();

            for (Promotion_Material_Item__c pmi : theActivity.Promotion_Material_Items__r) {
                totalCOGS += pmi.Plan_COGS__c == null ? 0 : pmi.Plan_COGS__c;
                totalDiscount += pmi.Total_Outlet_Incentive__c == null ? 0 : pmi.Total_Outlet_Incentive__c;
                totalDiscount9L += pmi.Total_Outlet_Incentive_9L__c == null ? 0 : pmi.Total_Outlet_Incentive_9L__c;
                totalQuantity += pmi.Target_Qty__c == null ? 0 : pmi.Target_Qty__c;
                totalNetSales += pmi.Plan_Net_Sales__c == null ? 0 : pmi.Plan_Net_Sales__c;
                totalVolume9L += pmi.Target_Qty_9L__c == null ? 0 : pmi.Target_Qty_9L__c;
                totalFreeBottleQuantity += pmi.Free_Bottle_Quantity__c == null ? 0 : pmi.Free_Bottle_Quantity__c;
                totalFreeBottleQuantity9L += pmi.Free_Bottle_Quantity_9L__c == null ? 0 : pmi.Free_Bottle_Quantity_9L__c;
                totalFreeBottleCOGS += pmi.Free_Bottle_COGS__c == null ? 0 : pmi.Free_Bottle_COGS__c;
                totalFreeBottleCOGS9L += pmi.Free_Bottle_COGS_9L__c == null ? 0 : pmi.Free_Bottle_COGS_9L__c;
                totalFreeBottleCost += pmi.Free_Bottle_Cost__c == null ? 0 : pmi.Free_Bottle_Cost__c;    

                pmi.Remaining_Volume__c = pmi.Target_Qty__c;
                pmi.Remaining_Discount__c = pmi.Total_Outlet_Incentive__c;
                pmi.Remaining_Free_Bottle_Qty__c = pmi.Free_Bottle_Quantity__c;
                materialItems.put(pmi.Id, pmi);            
            }

            for(Promotion_Material_A_P__c pma : theActivity.Promotion_Material_A_P_Items__r) {
                if (pma.Is_Incentive_Product__c) {
                    totalDiscount += pma.A_P_Item_Total__c;
                    totalDiscount9L += pma.A_P_Item_Total_9L__c;
                    totalQuantity += pma.Quantity__c;
                } else {
                    if (pma.Item_Type__c == 'Discount') {
                        totalDiscount += pma.A_P_Item_Total__c;
                        totalDiscount9L += pma.A_P_Item_Total_9L__c;
                    } else {
                        totalAPDiscount += pma.A_P_Item_Total__c;
                        totalAPDiscount9L += pma.A_P_Item_Total_9L__c;
                    }
                    totalAPQuantity += pma.Quantity__c;
                }

                if (materialItems.containsKey(pma.Promotion_Material_Item__c)) {
                    materialItem = materialItems.get(pma.Promotion_Material_Item__c);
                    materialItem.Remaining_A_P__c += pma.A_P_Item_Total__c;
                    materialItems.put(pma.Promotion_Material_Item__c, materialItem);
                }
                
            }

            if (theActivity.PMI_Actuals__r != null) {
                for(PMI_Actual__c pmia : theActivity.PMI_Actuals__r) {
                    actualAP = pmia.Actual_A_P__c == null ? 0 : pmia.Actual_A_P__c;
                    actualQty = pmia.Act_Qty__c == null ? 0 : pmia.Act_Qty__c;
                    actualFreeBottleQty = pmia.Actual_Free_Bottle_Qty__c == null ? 0 : pmia.Actual_Free_Bottle_Qty__c;
                    actualDiscount = pmia.Actual_Discount__c == null ? 0 : pmia.Actual_Discount__c;

                    totalActualAP += actualAP;
                    totalActualQty += actualQty;
                    totalActualDiscount += actualDiscount;
                    totalActualFreeBottleQty += actualFreeBottleQty;

                    if (materialItems.containsKey(pmia.Promotion_Material_Item__c)) {
                        materialItem = materialItems.get(pmia.Promotion_Material_Item__c);
                        if (materialItem.Remaining_A_P__c != null && materialItem.Remaining_A_P__c > 0) {
                            materialItem.Remaining_A_P__c -= actualAP;
                        }
                        if (materialItem.Remaining_Discount__c != null && materialItem.Remaining_Discount__c > 0) {
                            materialItem.Remaining_Discount__c -= actualDiscount;
                        }
                        if (materialItem.Remaining_Volume__c != null && materialItem.Remaining_Volume__c > 0) {
                            materialItem.Remaining_Volume__c -= actualQty;
                        }
                        if (materialItem.Remaining_Free_Bottle_Qty__c != null && materialItem.Remaining_Free_Bottle_Qty__c > 0) {
                            materialItem.Remaining_Free_Bottle_Qty__c -= actualFreeBottleQty;
                        }
                        materialItems.put(pmia.Promotion_Material_Item__c, materialItem);
                    }
                }
            }

            theActivity.Total_A_P_Discount_Ex_FreeGoods_9L__c = totalAPDiscount9L;
            theActivity.Total_A_P_Discount_Ex_FreeGoods__c = totalAPDiscount;
            theActivity.Total_A_P_Quantity__c = totalAPQuantity;
            theActivity.Total_Cost_of_Goods__c = totalCOGS;
            theActivity.Total_Discount__c = totalDiscount;
            theActivity.Total_Free_Bottle_COGS_9L__c = totalFreeBottleCOGS9L;
            theActivity.Total_Free_Bottle_COGS__c = totalFreeBottleCOGS;
            theActivity.Total_Free_Bottle_Cost__c = totalFreeBottleCost;
            theActivity.Total_Free_Bottle_Quantity_9L__c = totalFreeBottleQuantity9L;
            theActivity.Total_Free_Bottle_Quantity__c = totalFreeBottleQuantity;
            theActivity.Total_Net_Sales__c = totalNetSales;
            theActivity.Total_Volume_9L__c = totalVolume9L;
            theActivity.Total_Volume__c = totalQuantity;
            theActivity.Total_Remaining_A_P__c = (totalAPDiscount + totalFreeBottleCOGS) - totalActualAP;
            theActivity.Total_Remaining_Discount__c = theActivity.Total_Discount__c - totalActualDiscount;
            theActivity.Total_Remaining_Volume__c = theActivity.Total_Volume__c - totalActualQty;
            theActivity.Total_Remaining_Free_Bottle__c = theActivity.Total_Free_Bottle_Quantity__c - totalActualFreeBottleQty;
            theActivity.SalesProposal_Products_Updated__c = false;
        }

        update activities;

        if (!materialItems.isEmpty()) {
            update materialItems.values()   ;
        }
    }
}
