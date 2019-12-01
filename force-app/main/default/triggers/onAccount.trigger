trigger onAccount on Account (after update, after insert) {
    /**
     * we run the trigger on Outlet Visit Item to update the brand depletion actuals.
     *Conditions: 
     *  +Account RecordType: EUR_Outlets (or "DEU_Outlets")
     *  +onUpdate, Brand or Facing or Channel (Account) has changed
     *
     * On delete, we have to get the event from the on Outlet Visit trigger because there is no event in the outlet Visit Item
     * We refresh always all the records of the account to make sure everything is fine for every event.
     * If the Channel is on, then Depletion actuals is 1 else it's the sum of the facing grouped by brand.
     * If the brand does not exist, it has to be created, else it has to be updated (the Depletion Actual).
     *          
     * @date            30.11.2011
     * @author          Christophe Vidal
     * @modification    Michael Mickiewicz - 04/24/2012 (Substitution Concept)
     
     * @date            2/21/2013
     * @author          Ben Whatton
     * @modification    update event objectives
     
     * @date            1/22/2014
     * @author          Ben Whatton
     * @modification    added after insert, geocode logic
     * 
     * @date            7/28/2015
     * @author          Jonathan Riehm
     * @modification    Added code for creating Account Characteristics Junction records for reporting 
	 * 
	 * @date            01/15/2018
	 * @author          Indraja Tripuraneni  
	 * @modification    Added logic to update USP in eRetailerProduct object when Account USP is updated
    */
    
    System.debug('*** onAccount trigger start ***');
    
    // if address changes, we need to get the new lat and long
    list<id> geocodeIds = new list<id>();    
    
    Boolean useCallCard = true; //Using the New Call Card Model
        
    for(User thisUser:[SELECT Market__c FROM User WHERE Id=:UserInfo.getUserId()])
    {
        if(thisUser.Market__c != null)
        {
            //Check if Outlet Visit model is to be used
            if(Markets_Using_Outlet_Visit__c.getInstance(thisUser.Market__c) != null)
            {
                useCallCard = false;
            }
        }
    }
    
    if(trigger.isUpdate){
        system.debug('In the After Update Trigger');
        list<Id> AccountIds = new list<Id>();
        //PARX - Substitution Concept - Part 1 --------------------------------------------------
        map<ID, ID> accs4Sharing = new map<ID, ID>();
        map<ID, Account> accounts = new map<ID, Account>();
        //PARX END ------------------------------------------------------------------------------
        list<Event> eventsToUpdate = new list<Event>();
        map<id, Event> eventMap = new map<id,Event>(); 
        map<Id, Account> accountObjectives = new map<Id, Account>();
        list<Id> recurringEvents = new list<Id>();
                
        //Need to query for related field because you can't access related fields inside trigger.new
        for(Account acc:[SELECT Id, Name, Area__c, Channel__c, Call_Card_Objectives__c, Objectives__c, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, 
          BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Substitution__c, Market__r.Geocode_Address__c FROM Account WHERE ID IN :trigger.new]) {
            System.debug(acc.Name + ' Area: ' + acc.Area__c);

            //PARX - Substitution Concept - Part 2 ----------------------------------------------
            accounts.put(acc.ID, acc);
            accs4Sharing.put(acc.ID, acc.Substitution__c);
            //PARX END --------------------------------------------------------------------------
            if(acc.Channel__c != trigger.oldMap.get(acc.Id).Channel__c) {
               AccountIds.add(acc.Id);
            }
            
            /*if new.obj != old.obj
                find and update all future open evts    
            */
            if(useCallCard){
              if(acc.Call_Card_Objectives__c != trigger.oldMap.get(acc.Id).Call_Card_Objectives__c)
              {
                system.debug('objectives changed');
                  accountObjectives.put(acc.Id, acc); 
              }
            }
            else{
              if(acc.Objectives__c != trigger.oldMap.get(acc.Id).Objectives__c)
              {
                system.debug('objectives changed');
                  accountObjectives.put(acc.Id, acc); 
              }
            }
            //list <Outlet_Visit__c> ovs = [select id, visit_date__c, account__c, status__c from outlet_visit__c where account__c = :acc.id and status='Complete'];
            //system.debug('Last Visit Date = '+ acc.Last_Visit_Date__c);
            //system.debug('acc: '+acc.Market__c);
            system.debug('old acc: '+trigger.oldMap.get(acc.Id));
            if(acc.Market__r.Geocode_Address__c == 'Shipping'){
              system.debug('acc.Market__r.Geocode_Address__c == Shipping');
                if(acc.ShippingStreet != trigger.oldMap.get(acc.Id).ShippingStreet || 
                    acc.ShippingCity != trigger.oldMap.get(acc.Id).ShippingCity || 
                    acc.ShippingState != trigger.oldMap.get(acc.Id).ShippingState || 
                    acc.ShippingPostalCode != trigger.oldMap.get(acc.Id).ShippingPostalCode || 
                    acc.ShippingCountry != trigger.oldMap.get(acc.Id).ShippingCountry){
                        geocodeIds.add(acc.Id);
                    }
            }else if(acc.Market__r.Geocode_Address__c == 'Billing'){
                if(acc.BillingStreet != trigger.oldMap.get(acc.Id).BillingStreet || 
                    acc.BillingCity != trigger.oldMap.get(acc.Id).BillingCity || 
                    acc.BillingState != trigger.oldMap.get(acc.Id).BillingState || 
                    acc.BillingPostalCode != trigger.oldMap.get(acc.Id).BillingPostalCode || 
                    acc.BillingCountry != trigger.oldMap.get(acc.Id).BillingCountry){
                        geocodeIds.add(acc.Id);
                    }
            }   
            system.debug('geocodeIds: '+geocodeIds);
                             
        }
        system.debug('accountObjectives: '+accountObjectives);
        //loop through all events for accounts whose objectives have changed and update event objectives
        if(!accountObjectives.isEmpty()){
            for(Event e:[SELECT ActivityDate,Closed__c,Objectives__c,Id,ShowAs,AccountId,RecurrenceActivityId FROM Event WHERE AccountId in:accountObjectives.keyset() AND Closed__c = false AND ActivityDate > TODAY AND IsRecurrence = false ORDER BY ActivityDate ASC LIMIT 1])
            {
                Account acc = accountObjectives.get(e.AccountId);               
                system.debug('e.id: ' + e.id);
                if(useCallCard){
                	e.Objectives__c = acc.Call_Card_Objectives__c;
                    eventMap.put(e.id, e);
                  /*if(e.RecurrenceActivityId != null){
                    recurringEvents.add(e.Id);
                  }
                  else{
                    e.Objectives__c = acc.Call_Card_Objectives__c;
                    eventMap.put(e.id, e);
                  } */                 
                }
                else{                  
                	e.Objectives__c = acc.Objectives__c;  
                    eventMap.put(e.id, e);              
                  /*if(e.RecurrenceActivityId != null){
                    recurringEvents.add(e.Id);
                  }
                  else{
                    e.Objectives__c = acc.Objectives__c;  
                    eventMap.put(e.id, e);                  
                  }*/
                }
            }   
            eventsToUpdate = eventMap.values();  
            system.debug('eventsToUpdate: '+eventsToUpdate);
            system.debug('recurringEvents: '+recurringEvents);
            if(!eventsToUpdate.isEmpty())
            {
                update eventsToUpdate;
            }
            if(!recurringEvents.isEmpty()){
            	if ([SELECT count() FROM AsyncApexJob WHERE JobType='BatchApex' AND (Status = 'Processing' OR Status = 'Preparing')] < 5){
          			Database.executeBatch(new RecurringEventBatch(recurringEvents),1);
        		} else {
          			System.scheduleBatch(new RecurringEventBatch(recurringEvents), 'Recurring Events Batch Scheduled',1,1);
                    //schedule this same schedulable class again in 30 mins
                    //nameOfYourSchedulableClass sc = new nameOfYourSchedulableClass();
                    //Datetime dt = Datetime.now() + (0.024305); // i.e. 30 mins
                    //String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
                    //Id schedId = System.Schedule('MatrixRetry'+timeForScheduler,timeForScheduler,sc);
                }
              //call recurring event batch
              //Database.executeBatch(new RecurringEventBatch(recurringEvents),1);
        	}
        }
        /*  Outlet Visit and Outlet Visit Item object are no longer used */
        /*
        if(!AccountIds.isEmpty()) {
            list<Id> RTIds = new list<Id>();
            for(RecordType rt:[select id from RecordType where sObjectType = 'Account' AND (developerName = 'EUR_Outlets' OR developerName = 'DEU_Outlets')]) {
                RTIds.add(rt.Id);
            }
            Outlet_Visit_Item_Helper.runIt = true;
            list<Outlet_Visit_Item__c> OVI_List = new list<Outlet_Visit_Item__c>([select id from Outlet_Visit_Item__c where Outlet_Visit__r.Account__c IN: AccountIds AND Outlet_Visit__r.Account__r.RecordTypeId IN: RTIds]);
            update OVI_List;
        } 
        */      
		//Added logic for eCatalog application
		 if(trigger.isAfter){
		   Map<Id,Account> accountsMap = new Map<Id, Account>();	
           Account_Helper accountHelper = new Account_Helper(); 
           for(Account account : Trigger.new){
              if( ((account.eRetailer_USP__c != null) && !((account.eRetailer_USP__c).equals(trigger.oldmap.get(account.id).eRetailer_USP__c))) ||
                 ((trigger.oldmap.get(account.id).eRetailer_USP__c != null) && !((trigger.oldmap.get(account.id).eRetailer_USP__c).equals(account.eRetailer_USP__c)))||
                 ((account.eRetailer_USP__c != null) && (trigger.oldmap.get(account.id).eRetailer_USP__c != null) )                      
                ){
                  
              accountsMap.put(account.Id,account);
            }
	      }
          if(accountsMap.size() > 0){
            accountHelper.updateERetailerUSP(accountsMap);
          }     
	    }
		//End of changes
        
    }
    if(trigger.isInsert){      
        for(Account a:[SELECT Id, Name, ShippingStreet, ShippingCity, BillingStreet, BillingCity, Market__r.Geocode_Address__c, Area__c FROM Account WHERE ID IN :trigger.new]){
          system.debug(a.Market__r.Geocode_Address__c);
            if(a.Market__r.Geocode_Address__c == 'Shipping'){              
                if(a.ShippingStreet != '' && a.ShippingCity != ''){
                    geocodeIds.add(a.Id);
                }
            }else if(a.Market__r.Geocode_Address__c == 'Billing'){
                if(a.BillingStreet != '' && a.BillingCity != ''){
                    geocodeIds.add(a.Id);
                }
            }
        }
    }
    
    if(!geocodeIds.isEmpty()){
            //call geocode batch
            /*string jobName = 'Geocode Batch: '+String.valueOf(Datetime.now());
            if ([SELECT count() FROM AsyncApexJob WHERE JobType='BatchApex' AND (Status = 'Processing' OR Status = 'Preparing')] < 5){
	        	Database.executeBatch(new GeocoderBatch(geocodeIds),10);
	        } else {
          		System.scheduleBatch(new GeocoderBatch(geocodeIds), jobName,1,10);  
            } */
            Database.executeBatch(new GeocoderBatch(geocodeIds),10);         
    }
    
    //***** BEGIN - MANDATORY PRODUCT LOGIC REVAMPED - Suri (PARX) August 4, 2014
    
    //Map of Account ID and ParentId
    Map<Id, Id> accountToParent = new Map<Id, Id>();
    
    //Map of Account ID and Supplier__c ID
    Map<Id, Id> accountToSupplier = new Map<Id, Id>();
     
    //Set of Account IDs where EXISTING Mandatory Products must be DELETED
    Set<Id> accountMandProdsToDel = new Set<Id>();
    
    List<Schema.FieldSetMember> mpFieldMap = Schema.SObjectType.Mandatory_Products__c.fieldSets.KAM_Mapping.getFields();
        
    for(Account acc:trigger.new) 
    {
        if(trigger.isInsert || trigger.isUpdate && acc.ParentId != trigger.oldmap.get(acc.Id).ParentId)
        {
            if(acc.ParentId != null)
            {
                accountToParent.put(acc.Id, acc.ParentId);
            }
            
            accountMandProdsToDel.add(acc.Id);
        }
        
        if(trigger.isInsert || trigger.isUpdate && acc.Supplier__c != trigger.oldmap.get(acc.Id).Supplier__c)
        {
            if(acc.Supplier__c != null)
            {
                accountToSupplier.put(acc.Id, acc.Supplier__c);
            }
            
            accountMandProdsToDel.add(acc.Id);
            
        }
    }
    
    //Map of Account ID and List of Mandatory Products
    Map<Id,List<Mandatory_Products__c>> accountMandProdsMap = new Map<Id,List<Mandatory_Products__c>>();
    
    if(accountToParent.size() > 0 || accountToSupplier.size() > 0)
    {
        String mandatoryProductQuery = 'SELECT ';
        
        for(Schema.FieldSetMember field : mpFieldMap)
        {
            mandatoryProductQuery += field.getFieldPath() + ', ';
        }
        
        Set<Id> allParentSupplierIds = new Set<Id>();
        allParentSupplierIds.addAll(accountToParent.values());
        allParentSupplierIds.addAll(accountToSupplier.values());
        
        mandatoryProductQuery += ' Id FROM Mandatory_Products__c ';
        mandatoryProductQuery += ' WHERE Account__c IN:allParentSupplierIds ';
        
        for(Mandatory_Products__c mp : Database.query(mandatoryProductQuery))
        {
            if(!accountMandProdsMap.containsKey(mp.Account__c))
            {
                accountMandProdsMap.put(mp.Account__c, new List<Mandatory_Products__c>());
            }
            
            accountMandProdsMap.get(mp.Account__c).add(mp);
        }
    }
    
    List<Mandatory_Products__c> newMandatoryProducts = new List<Mandatory_Products__c>();

    //Map of Mandatory Product ID and PARENT-CHLD Account IDs to ADD
    Map<Id,Id> mandProdNewAccountMap = new Map<Id,Id>();

    for(Account a : trigger.new)
    {
        if(a.ParentId != null && accountMandProdsMap.get(a.ParentId) != null)
        {
            for(Mandatory_Products__c mp : accountMandProdsMap.get(a.ParentId))
            {
                Mandatory_Products__c new_mp = new Mandatory_Products__c(Account__c = a.Id);
                for(Schema.FieldSetMember field : mpFieldMap)
                {
                    if(field.getFieldPath().equals('Account__c'))
                        new_mp.Account__c = a.Id;
                    else
                        new_mp.put(field.getFieldPath(), mp.get(field.getFieldPath()));
                }
                new_mp.Controlled_by__c = 'Parent';
                newMandatoryProducts.add(new_mp);

                mandProdNewAccountMap.put(mp.Id,a.Id);
            }
        }
        
        if(a.Supplier__c != null && accountMandProdsMap.get(a.Supplier__c) != null)
        {
            for(Mandatory_Products__c mp : accountMandProdsMap.get(a.Supplier__c))
            {
                Mandatory_Products__c new_mp = new Mandatory_Products__c(Account__c = a.Id);
                for(Schema.FieldSetMember field : mpFieldMap)
                {
                    if(field.getFieldPath().equals('Account__c'))
                        new_mp.Account__c = a.Id;
                    else
                        new_mp.put(field.getFieldPath(), mp.get(field.getFieldPath()));
                }
                new_mp.Controlled_by__c = 'Supplier';
                newMandatoryProducts.add(new_mp);
            }
        }
    }
    
    //Delete OLD Mandatory Products
    if (accountMandProdsToDel.size() > 0) {
        for(Mandatory_Products__c[] mandProdDel:[SELECT Id FROM Mandatory_Products__c WHERE Account__c IN: accountMandProdsToDel])
        {
            delete mandProdDel;
        }
    }
    
    if(newMandatoryProducts.size() > 0)
    {
        insert newMandatoryProducts;
    }

    //Update Account ID JSON for Parent-Hierarchy Accounts
    if(mandProdNewAccountMap.size() > 0)
    {
        System.Debug('>>>>>> mandProdNewAccountMap >>>>>' + mandProdNewAccountMap);
        try {
            
            //Map of Mandatory Product ID and Attachment String JSON
            Map<Id,String> mandProdJSONMap = new Map<Id,String>();

            for(Attachment attMandProd:[SELECT Id, Body, ParentId,ContentType FROM Attachment 
                                        WHERE ParentId IN:mandProdNewAccountMap.keyset() 
                                        AND Name = 'AccountIDsJSONMandatoryProduct'
                                        AND ContentType = 'text'])
            {
                if(attMandProd.ContentType == 'text')
                {
                    mandProdJSONMap.put(attMandProd.ParentId,attMandProd.Body.toString());
                }
            }

            System.Debug('>>>>>> mandProdJSONMap >>>>>' + mandProdJSONMap);

            //List of new Attachments to insert
            List<Attachment> newJSONAttachments = new List<Attachment>();

            //Update Mandatory Products with new Account JSON
            for(Mandatory_Products__c[] mandProds:[SELECT Id, Account_ID_JSON__c 
                                             FROM Mandatory_Products__c
                                             WHERE Id IN:mandProdNewAccountMap.keyset()])
            {
                for(Mandatory_Products__c mandP:mandProds)
                {
                    //IF attachment exists
                    if(mandProdJSONMap.get(mandP.Id) != null)
                    {
                        System.Debug('>>>>>>IF ATTACHMENT EXISTS >>>>>>>');
                        //Get JSON from record and deserialize to SET<Id>
                        String jsonFromRecord = mandProdJSONMap.get(mandP.Id);
                        
                        Set<Id> accountIdsSaved = new Set<Id>();

                        if(jsonFromRecord != null && jsonFromRecord != '')
                        {
                            System.Type typeSetId = Type.forName('Set<Id>');
                            
                            //Deserialize JSON to SET<Id>
                            accountIdsSaved = (Set<Id>)JSON.deserialize(jsonFromRecord,typeSetId);
                        }

                        if(mandProdNewAccountMap.get(mandP.Id) != null)
                        {
                            accountIdsSaved.add(mandProdNewAccountMap.get(mandP.Id));
                        }

                        String accountIdsInJson = JSON.serialize(accountIdsSaved);

                        //Insert Attachment
                        Attachment att = new Attachment();
                        att.Name = 'AccountIDsJSONMandatoryProduct';
                        att.ParentId = mandP.Id;
                        att.Body = Blob.valueOf(accountIdsInJson);
                        att.ContentType = 'text';
                        att.Description = 'This contains a JSON of Account IDs to which this Mandatory Product will be assigned';
                        newJSONAttachments.add(att);
                    }
                    else
                    {
                        System.Debug('>>>>>>NO ATTACHMENT EXISTS >>>>>>>');

                        //Get JSON from record and deserialize to SET<Id>
                        String jsonFromRecord = mandP.Account_ID_JSON__c;

                        Set<Id> accountIdsSaved = new Set<Id>();

                        if(jsonFromRecord != null && jsonFromRecord != '')
                        {
                            System.Type typeSetId = Type.forName('Set<Id>');
                            
                            //Deserialize JSON to SET<Id>
                            accountIdsSaved = (Set<Id>)JSON.deserialize(jsonFromRecord,typeSetId);
                        }

                        if(mandProdNewAccountMap.get(mandP.Id) != null)
                        {
                            accountIdsSaved.add(mandProdNewAccountMap.get(mandP.Id));
                        }

                        
                        String accountIdsInJson = JSON.serialize(accountIdsSaved);

                        mandP.Account_ID_JSON__c = accountIdsInJson;
                    }
                }
                
                update mandProds;

                
            }

            if(newJSONAttachments.size() > 0)
            {
                for(Attachment[] attMandDEL:[SELECT Id, Body, ParentId FROM Attachment 
                                        WHERE ParentId IN:mandProdNewAccountMap.keyset() 
                                        AND Name = 'AccountIDsJSONMandatoryProduct'])
                {
                    delete attMandDEL;
                }

                insert newJSONAttachments;
            }

        }
        catch(Exception ex)
        {
            System.Debug('>>>>>> EXCEPTION JSON >>>>>' + ex.getMessage());
        }
    }
    //***** END - MANDATORY PRODUCT LOGIC REVAMPED - Suri (PARX) August 4, 2014
    
    //***** Add logic for creating Account Characteristic junction records for Reporting
    //Get all account Characteristics for the current accounts and if we have any map the correct
    //account characteristic junctions
    /*list <Account> accountsToMap = new list<Account>();
    for (Account account : trigger.new){
        if (account.account_characteristics__c != null){
           accountsToMap.add(account); 
        }
    }
    if (!accountsToMap.isEmpty()){
        Account_Characteristics_Helper.mapCharacteristics(accountsToMap,trigger.oldMap);
    }*/
 
    System.debug('*** onAccount trigger end ***');
    
}