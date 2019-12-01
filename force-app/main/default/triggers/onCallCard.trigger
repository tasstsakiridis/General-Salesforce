trigger onCallCard on CallCard__c (after insert, after update, before delete, after delete, after undelete, before update, before insert) {
    /*
     * Test Classes to use to test for code coverage:
     * - Test_CallCard
     * - Account_Visit_Controller_Test
    */  
  
    if (Trigger.isDelete) {
        Account_Survey__c[] surveysToDelete = [Select ID,Name From Account_Survey__c where CallCard__c in :Trigger.oldMap.keySet() ];
        delete surveysToDelete;
    }
    if (Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) {
        System.debug('[onCallCard trigger] time tracking update');
        // preparations
        Set<String> ownerids = new Set<String>();
        Set<Integer> monthlist = new Set<Integer>();
        Map<String, Time_Tracking__c> ttmap = new Map<String, Time_Tracking__c>();
        system.debug('trigger.new: '+trigger.new);
        for (CallCard__c cc: trigger.new) {                
            Id ccCreatedById;
            if(trigger.isInsert)
                ccCreatedById = UserInfo.getUserId();
            else
                ccCreatedById = cc.CreatedById;
            
      		system.debug('ccCreatedById: '+ccCreatedById);
            if (!ownerids.contains(String.valueOf(ccCreatedById))) {
                ownerids.add(String.valueOf(ccCreatedById));
            }
            if (!monthlist.contains(cc.Call_Card_Date__c.month() + cc.Call_Card_Date__c.year()*100)) {
                monthlist.add(cc.Call_Card_Date__c.month() + cc.Call_Card_Date__c.year()*100);
            }
            system.debug('ownerids: '+ownerids);
            system.debug('monthlist: '+monthlist);
        }

        // now get the time tracking records and connect them to the ov
        if (!ownerids.isEmpty() && !monthlist.isEmpty()) {
            for (Time_Tracking__c tt: [SELECT Id, StartDate__c, OwnerId, StartDate_Month__c FROM Time_Tracking__c
                                        WHERE OwnerId IN :ownerids AND StartDate_Month__c IN :monthlist]) {
                if (!ttmap.containsKey(tt.OwnerId + String.valueOf(tt.StartDate_Month__c)))
                    ttmap.put(tt.OwnerId + String.valueOf(tt.StartDate_Month__c),tt);
            }
        }
        system.debug('ttMap: '+ttMap);
        // can't avoid this second run ...
        if (ttMap.size() > 0) {
            for (CallCard__c cc: trigger.new) {
                Id ccCreatedById;
                if(trigger.isInsert)
                    ccCreatedById = UserInfo.getUserId();
                else
                    ccCreatedById = cc.CreatedById;
                
                if (ttmap.containsKey(String.valueOf(ccCreatedById) + String.valueOf(cc.Call_Card_Date__c.month()+ cc.Call_Card_Date__c.Year()*100)))
                    cc.Time_Tracking__c=ttmap.get(String.valueOf(ccCreatedById) + String.valueOf(cc.Call_Card_Date__c.month()+ cc.Call_Card_Date__c.year()*100)).id;
                else //If no time tracking card is available, remove the assigned record
                    cc.Time_Tracking__c=null;
            }
        }
    } else if (Trigger.isAfter) {
        String rtPLEvent = Event.SobjectType.getDescribe().getRecordTypeInfosByName().get('PL Event').getRecordTypeId();
        String rtPLCallCard = '';
        Map<String, RecordTypeInfo> ccRecordTypes = CallCard__c.SObjectType.getDescribe().getRecordTypeInfosByName();
        if (ccRecordTypes.containsKey('PL - CallCard')) {
            rtPLCallCard = ccRecordTypes.get('PL - CallCard').getRecordTypeId();
        }

        Set<Id> accountIds = new Set<Id>();

        if (!Call_Card_Helper.hasAlreadyRun) {
            if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
                for (CallCard__c cc : Trigger.new) {
                    if (cc.Account__c != null && !accountIds.contains(cc.Account__c)) {
                        accountIds.add(cc.Account__c);
                    }
                }
            }
            if (Trigger.isDelete) {
                for(CallCard__c cc : Trigger.old) {
                    if (cc.Account__c != null && !accountIds.contains(cc.Account__c)) {
                        accountIds.add(cc.Account__c);
                    }
                }
            }

            Call_Card_Helper.hasAlreadyRun = true;
            Call_Card_Helper.main(accountIds);
        }

        if (!Trigger.isDelete) {
            Map<Id, Event> eventsToUpdate = new Map<Id, Event>();
            List<Event> eventsToCreate = new List<Event>();
            List<Event> eventList = [SELECT Id, ShowAs, Closed__c, ActivityDate, AccountId FROM Event WHERE OwnerId =: UserInfo.getUserId() AND IsRecurrence = false AND Closed__c = false AND AccountId IN :accountIds];    
            for (CallCard__c cc : Trigger.new) {
                if (Trigger.isInsert || cc.Call_Card_Date__c != Trigger.oldMap.get(cc.Id).Call_Card_Date__c) {
                    date earlyDate = cc.Call_Card_Date__c.addDays(-1);
                    date lateDate = cc.Call_Card_Date__c.addDays(0);

                    for (Event e : eventList) {
                        if (e.AccountId == cc.Account__c && e.ActivityDate >= earlyDate && e.ActivityDate <= lateDate) {
                            e.Closed__c = true;
                            if (e.ActivityDate == cc.Call_Card_Date__c) {
                                e.ShowAs = 'Free';  // White
                            } else {
                                e.ShowAs = 'OutOfOffice';  // Red
                            }

                            if (cc.RecordTypeId == rtPLCallCard && cc.Check_Out__c != null) {
                                e.EndDateTime = cc.Check_Out__c;
                                e.DurationInMinutes = (Integer)((e.EndDateTime.getTime() - e.StartDateTime.getTime()) / 60000);
                            }

                            eventsToUpdate.put(e.Id, e);
                        }
                    }

                    if (cc.RecordTypeId == rtPLCallCard && (eventsToUpdate == null || eventsToUpdate.size() == 0)) {
                        Integer duration = 30;
                        DateTime startDateTime = DateTime.now();
                        if (cc.Check_In__c != null) {
                            startDateTime = cc.Check_In__c;
                        }
                        
                        DateTime endDateTime = startDateTime.addMinutes(duration);
                        if (cc.Check_Out__c != null) {
                            endDateTime = cc.Check_Out__c;
                        }
                        duration = (Integer)((endDateTime.getTime() - startDateTime.getTime()) / 60000);
                    	eventsToCreate.add(new Event(RecordTypeId=rtPLEvent,OwnerId=UserInfo.getUserId(),ActivityDate=cc.Call_Card_Date__c,ActivityDateTime=startDateTime,WhatId=cc.Account__c,ShowAs='Free',Closed__c=true,DurationInMinutes=duration,StartDateTime=startDateTime,EndDateTime=endDateTime));
                    }
                }
            }

            if (!eventsToUpdate.isEmpty()) {
                update eventsToUpdate.values();
            }
            if (!eventsToCreate.isEmpty()) {
                insert eventsToCreate;
            }
        }

    }

    /*
    //Call the Call Card Helper class in order to mark last visit, next to last visit on Call Card as well as last visit date on Account
    if(trigger.isAfter){
        system.debug('inside call card trigger');
        Set<Id> accountIds = new Set<Id>();
        List<Account> accountsToUpdate = new List<Account>();
        system.debug(' Call_Card_Helper.hasAlreadyRun: '+ Call_Card_Helper.hasAlreadyRun);
        if((trigger.isInsert || trigger.isUpdate || trigger.isUnDelete) && !Call_Card_Helper.hasAlreadyRun){
            for(CallCard__c cc:trigger.new){
                if(cc.Account__c != null){
                    if(!accountIds.contains(cc.Account__c)){
                        accountIds.add(cc.Account__c);
                    }
                }
            }
        }
        
        if(trigger.isDelete && !Call_Card_Helper.hasAlreadyRun){
            //Call_Card_Helper.hasAlreadyRun = true;
            
            for(CallCard__c cc:trigger.old){
                if(cc.Account__c !=null){
                    if(!accountIds.contains(cc.Account__c)){
                        accountIds.add(cc.Account__c);
                    }
                }
            }
        }
        //system.debug('accountIds: '+accountIds);
        if(!Call_Card_Helper.hasAlreadyRun){
          Call_Card_Helper.hasAlreadyRun = true;
          Call_Card_Helper.main(accountIds);          
        }

        List<Event> eventList = [SELECT Id, ShowAs, Closed__c, ActivityDate, AccountId FROM Event WHERE OwnerId =: UserInfo.getUserId() AND IsRecurrence = false AND AccountId IN :accountIds];    
        System.debug('[onCallCard trigger] query for events. # of events found: ' + eventList.size());
        if(!trigger.isDelete) {   
        	for(CallCard__c callCard :trigger.new) {
            	if(trigger.isInsert || callCard.Call_Card_Date__c != trigger.oldMap.get(callCard.Id).Call_Card_Date__c){
            		date earlyDate = callCard.Call_Card_Date__c.addDays(-1);
                	date lateDate = callCard.Call_Card_Date__c.addDays(0);
            		//callCard.CreatedByID
                	//for(Event e:[select id, showas, closed__c,activitydate from event where accountid = :callCard.Account__c and ownerId =: UserInfo.getUserId() and activitydate >= :earlyDate and activitydate <= :lateDate and isrecurrence = false]) 
                	for(Event e:eventList){
                  		if(e.AccountId == callCard.Account__c && e.ActivityDate >= earlyDate && e.ActivityDate <= lateDate){
                      		e.Closed__c = true;
                      		if(e.ActivityDate == callCard.Call_Card_Date__c) {
                          		e.ShowAs = 'Free'; //white                  
                      		} else {
                          		e.ShowAs = 'OutOfOffice'; //red
                      		}
                            if (callCard.RecordType.Name == 'PL - CallCard' && callCard.Check_Out__c != null) {
                                e.EndDateTime = callCard.Check_Out__c;
                                e.DurationInMinutes = (Integer)((e.EndDateTime.getTime() - e.StartDateTime.getTime()) / 60000);
                            }
                      		eventsToUpdate.put(e.Id, e);
                  		}
                	}
                	if (callCard.RecordTypeId == rtPLCallCard && (eventsToUpdate == null || eventsToUpdate.size() == 0)) {
                        Integer duration = 30;
                        DateTime startDateTime = DateTime.now();
                        if (callCard.Check_In__c != null) {
                            startDateTime = callCard.Check_In__c;
                        }
                        DateTime endDateTime = startDateTime.addMinutes(duration);
                        if (callCard.Check_Out__c != null) {
                            endDateTime = callCard.Check_Out__c;
                        }
                        duration = (Integer)((endDateTime.getTime() - startDateTime.getTime()) / 60000);
                        //System.debug('startDateTime: ' + startDateTime.format() + ' : ' + startDateTime.getTime());
                        //System.debug('endDateTime: ' + endDateTime.format() + ' : ' + endDateTime.getTime());
                        //System.debug('duration: ' + duration);
                    	eventsToCreate.add(new Event(RecordTypeId=rtPLEvent,OwnerId=UserInfo.getUserId(),ActivityDate=callCard.Call_Card_Date__c,ActivityDateTime=startDateTime,WhatId=callCard.Account__c,ShowAs='Free',Closed__c=true,DurationInMinutes=duration,StartDateTime=startDateTime,EndDateTime=endDateTime));
                	}
            	}
          	}        
            System.debug('[onCallCard trigger] # of events to update: ' + eventsToUpdate.size());
        	if(!eventsToUpdate.isEmpty()) {            
            	update eventsToUpdate.values();    
      		}
            System.debug('[onCallCard trigger] # of events to create: ' + eventsToCreate.size());
            if (!eventsToCreate.isEmpty()) {
                insert eventsToCreate;
            }
    	}        
    }

    if(trigger.isDelete) {
        Account_Survey__c[] surveysToDelete = [Select ID,Name From Account_Survey__c where CallCard__c in :Trigger.oldMap.keySet() ];
        delete surveysToDelete;
    }
    
    //selecting time tracking records and append the call cards to them      
    if ((trigger.isUpdate || trigger.isInsert) && trigger.isBefore) {
        System.debug('[onCallCard trigger] time tracking update');
        // preparations
        Set<String> ownerids = new Set<String>();
        Set<Integer> monthlist = new Set<Integer>();
        Map<String, Time_Tracking__c> ttmap = new Map<String, Time_Tracking__c>();
        system.debug('trigger.new: '+trigger.new);
        for (CallCard__c cc: trigger.new) {                
            Id ccCreatedById;
            if(trigger.isInsert)
                ccCreatedById = UserInfo.getUserId();
            else
                ccCreatedById = cc.CreatedById;
            
      		system.debug('ccCreatedById: '+ccCreatedById);
            if (!ownerids.contains(String.valueOf(ccCreatedById))) {
                ownerids.add(String.valueOf(ccCreatedById));
            }
            if (!monthlist.contains(cc.Call_Card_Date__c.month() + cc.Call_Card_Date__c.year()*100)) {
                monthlist.add(cc.Call_Card_Date__c.month() + cc.Call_Card_Date__c.year()*100);
            }
            system.debug('ownerids: '+ownerids);
            system.debug('monthlist: '+monthlist);
        }

        // now get the time tracking records and connect them to the ov
        if (!ownerids.isEmpty() && !monthlist.isEmpty()) {
            for (Time_Tracking__c tt: [SELECT Id, StartDate__c, OwnerId, StartDate_Month__c FROM Time_Tracking__c
                                        WHERE OwnerId IN :ownerids AND StartDate_Month__c IN :monthlist]) {
                if (!ttmap.containsKey(tt.OwnerId + String.valueOf(tt.StartDate_Month__c)))
                    ttmap.put(tt.OwnerId + String.valueOf(tt.StartDate_Month__c),tt);
            }
        }
        system.debug('ttMap: '+ttMap);
        // can't avoid this second run ...
        //if (!ttmap.isEmpty()) {
        for (CallCard__c cc: trigger.new) {
            Id ccCreatedById;
            if(trigger.isInsert)
                ccCreatedById = UserInfo.getUserId();
            else
                ccCreatedById = cc.CreatedById;
            
            if (ttmap.containsKey(String.valueOf(ccCreatedById) + String.valueOf(cc.Call_Card_Date__c.month()+ cc.Call_Card_Date__c.Year()*100)))
                cc.Time_Tracking__c=ttmap.get(String.valueOf(ccCreatedById) + String.valueOf(cc.Call_Card_Date__c.month()+ cc.Call_Card_Date__c.year()*100)).id;
            else //If no time tracking card is available, remove the assigned record
                cc.Time_Tracking__c=null;
        }
        //}
    }
    */
}