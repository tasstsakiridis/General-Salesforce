({
    getSalesProposal : function(component) {
        var proposalId = component.get('v.recordId');
        var action = component.get("c.getSalesProposal");
        action.setParams({
            "proposalId" : proposalId
        });
        action.setCallback(this, function(response){
            var callState = response.getState();
            console.log('[SalesProposalSummary.helper.getApprovalHistory] getApprovalHistory action callback returned with state', callState);
            
            if (callState === "SUCCESS") {
                try {        
                    let theProposal = response.getReturnValue();
                    component.set("v.theProposal", theProposal);                
                    console.log('[PromotionActivity_Actuals.helper.getSalesProposal] returnmsg', theProposal);

                    var found = false;
                    var theActuals = [];
                    var activeSectionNames = [];
                    var periodSectionNames = [];
                    theProposal.Promotion_Material_Items__r.forEach(function(pmi) {
                        console.log('[PromotionActivity_Actuals.helper.getSalesProposal] pmi', pmi);
                        theActuals.push({
                            id: pmi.Id,
                            productName: pmi.Product_Name__c,
                            periods: []
                        });
                        activeSectionNames.push(pmi.Id);
                    });

                    var pmi;
                    theProposal.PMI_Actuals__r.forEach(function(actual) {
                        found = false;
                        pmi = null;
                        for(var i = 0; i < theActuals.length; i++) {
                            if (theActuals[i].id == actual.Promotion_Material_Item__c) {
                                pmi = theActuals[i]; found = true; break;                                
                            }
                        }

                        if (pmi) {
                            if (pmi.periods[actual.Period__c] == null) {
                                pmi.periods[actual.Period__c] = {
                                    title: actual.Month_Name__c + ' - ' + actual.Year__c,
                                    month: actual.Month_Name__c,
                                    year: actual.Year__c,
                                    accounts: []
                                };
                                if (periodSectionNames.indexOf(pmi.periods[actual.Period__c].title) < 0) {
                                    periodSectionNames.push(pmi.periods[actual.Period__c].title);
                                }
                            }

                            pmi.periods[actual.Period__c].accounts.push({
                                accountName: actual.Account_Name__c,
                                actQty: actual.Act_Qty__c,
                                freeBottleQty: actual.Actual_Free_Bottle_Qty__c,
                                actAP: actual.Actual_A_P__c,
                                paymentDate: actual.Payment_Date__c
                            });
                        }
                    });

                    component.set("v.theActuals", theActuals);
                    component.set("v.activeSections", activeSectionNames);
                    component.set("v.periodSections", periodSectionNames);
                    console.log('activeSectionNames', activeSectionNames);
                    console.log('periodNames', periodSectionNames);
                } catch(ex1) {
                    console.log('[PromotionActivity_Actuals.helper.getSalesProposal] exception', ex1);
                }
                
            } else if (callState === "INCOMPLETE") {
                console.log('[PromotionActivity_Actuals.helper.getSalesProposal] callback state is incomplete');    
            } else if (callState === "ERROR") {
                var errors = response.getError();
                console.log('[PromotionActivity_Actuals.helper.getSalesProposal] callback returned errors. ', errors);                    
                component.set("v.errors", errors);                    
            }
            
        });
        $A.enqueueAction(action);

    }
})
