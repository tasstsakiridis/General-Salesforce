public class Account_Survey_Helper {

    public static boolean hasAlreadyRun = false;
    private static final String GERMANMARKETNAME='Germany';
    public static boolean runIt = false;
    public static boolean mpRunIt = false;

    public static void main(Set<Id> accountIds) {
        if(AccountIDs.size() == 0)
            return;
        
        /**
         *Trigger on all events
         *Conditions: 
         *  +Account RecordType: EUR_Outlets (or "DEU_Outlets")
         *  +Status__c is 'Complete'
         *
         * We refresh always all the rows of the account to make sure everything is fine for every event.
         * We sort the retrieved records from the Account by Visit_Date__c. The last Visit_Date__c record gets the 
         * Last_Visit__c true. The next gets the field Next_to_Last_Visit__c true and Last_Visit__c to false
         * and all other records are set back to false.
         *          
         * @date    28.11.2011
         * @author  Christophe Vidal
         *
         * Updated by Tass Tsakiridis 15th January 2019 to only update the last 3 Account Surveys instead of the
         * entire history of account surveys.  All surveys past the third last survey will already be marked as
         * NOT the last visit and next to last visit
         *
        **/

        Map<String, List<Account_Survey__c>> m_AccountSurveys = new Map<String, List<Account_Survey__c>>();
        Map<Id, Account> m_Accounts = new Map<Id, Account>([SELECT Id, Last_Visit_Date__c FROM Account WHERE Id IN :accountIds]);
        String surveyKey = '';

        for (Account_Survey__c survey : [SELECT Id, Account__c, Last_Visit__c, Next_To_Last_Visit__c, Visit_Date__c, Survey_Channel__c
                                           FROM Account_Survey__c 
                                          WHERE Status__c = 'Complete' 
                                            AND Account__c IN :accountIds 
                                            AND (LastModifiedDate = TODAY OR Last_Visit__c = true OR Next_to_Last_Visit__c = true)
                                       ORDER BY Visit_Date__c DESC, Survey_Channel__c]) {

            surveyKey = survey.Account__c;
            if (survey.Survey_Channel__c != null && survey.Survey_Channel__c != '') {
                surveyKey += '_' + survey.Survey_Channel__c;
            }

            if (!m_AccountSurveys.containsKey(surveyKey)) {
                m_AccountSurveys.put(surveyKey, new List<Account_Survey__c>());
            }

            m_AccountSurveys.get(surveyKey).add(survey);
        }

        if (!m_AccountSurveys.isEmpty()) {
            String accountId = '';
            String surveyChannel = '';
            String[] keyParts;

            Integer i = 0;

            Date lastVisitDate;

            for(String key : m_AccountSurveys.keySet()) {
                accountId = key;
                if (key.contains('_')) {
                    keyParts = key.split('_');
                    accountId = keyParts[0];
                    surveyChannel = keyParts[1];
                }

                i = 0;
                for(Account_Survey__c survey : m_AccountSurveys.get(key)) {
                    if (i == 0) {
                        survey.Last_Visit__c = true;
                        survey.Next_to_Last_Visit__c = false;

                        lastVisitDate = m_Accounts.get(accountId).Last_Visit_Date__c;
                        if (lastVisitDate < survey.Visit_Date__c) {
                            m_Accounts.get(accountId).Last_Visit_Date__c = survey.Visit_Date__c;
                        }
                    } else if (i == 1) {
                        survey.Last_Visit__c = false;
                        survey.Next_to_Last_Visit__c = true;                        
                    } else {
                        survey.Last_Visit__c = false;
                        survey.Next_to_Last_Visit__c = false;
                    }

                    i++;
                }
            }
        }

        Map<Id, Account_Survey__c> m_AllAccountSurveys = new Map<Id, Account_Survey__c>();
        for(List<Account_Survey__c> l : m_AccountSurveys.values()) {
            m_AllAccountSurveys.putAll(l);
        }
        if (!m_AllAccountSurveys.values().isEmpty()) {
            update m_AllAccountSurveys.values();
        }

        if (!m_Accounts.isEmpty()) {
            update m_Accounts.values();
        }

        /*
        map<String, list<Account_Survey__c>> Outlets_Visit = new map<String, list<Account_Survey__c>>();
        String key = '';
        for(Account_Survey__c OV:[
            select Account__c, Last_Visit__c, Next_to_Last_Visit__c, Visit_Date__c, Survey_Channel__c
            from Account_Survey__c 
            where Status__c = 'Complete' AND Account__c IN: AccountIds order by Visit_Date__c desc, Name desc]) { 
                key = OV.Account__c;
                if (OV.Survey_Channel__c != null && OV.Survey_Channel__c != '') {
                    key += '_' + OV.Survey_Channel__c;
                }
                if(!Outlets_Visit.containsKey(key)) {
                    Outlets_Visit.put(key, new list<Account_Survey__c>());
                }
                Outlets_Visit.get(key).add(OV);
            }
        
        map<ID, Account> accounts = new map<ID, Account>(); 
        for(Account account : [Select Last_Visit_Date__c From Account Where ID IN :AccountIds])   {
            accounts.put(account.ID, account);
        }  
        
      if(!Outlets_Visit.isEmpty()) {
            Integer i = 0;
          String AccountId = '';
          String surveyChannel = '';
          String[] keyParts;
            for(String OV_KEY:Outlets_Visit.keySet()) {
                if (OV_KEY.contains('_')) {
                    keyParts = OV_KEY.split('_');
                    AccountId = keyParts[0];
                    surveyChannel = keyParts[1];
                } else {
                    AccountId = OV_KEY;
                }
                i = 0;
                for(Account_Survey__c OVHelper:Outlets_Visit.get(OV_KEY)) {
                    if(i == 0) {
                        //first element
                        OVHelper.Last_Visit__c = true;
                        OVHelper.Next_to_Last_Visit__c = false;
                        accounts.get(AccountId).Last_Visit_Date__c = OVHelper.Visit_Date__c;
                    }
                    else if(i == 1) {
                        //second element
                        OVHelper.Last_Visit__c = false;
                        OVHelper.Next_to_Last_Visit__c = true;
                    }
                    else {
                        //for the other elements, we set all checkboxes to false 
                        OVHelper.Last_Visit__c = false;
                        OVHelper.Next_to_Last_Visit__c = false;
                    }
                    
                    i++;
                }
            }
          
            
          map<id,Account_Survey__c> allAccountSurveysMap = new map<id,Account_Survey__c>();
            for(list<Account_Survey__c> OV:Outlets_Visit.values()) {                
                    allAccountSurveysMap.putAll(OV);
            }
          if(!allAccountSurveysMap.values().isEmpty()) {
                update allAccountSurveysMap.values();
            }
        }
        update accounts.values();
        */
    }

    
    public static void map_to_Account_Products(list<Id> ovi_Ids) {
           /**
             * we run the trigger on Outlet Visit Item to update the account products.
             *Conditions: 
             *  + Outlet Visit Items have to been created already
             *
             * We want to map all necessary information from the selected outlet visit item to a account product 
             * (custom object) for more refined product information.
             * If the account product does not exist, it has to be created, else it has to be updated with information
             * from the outlet visit item.
             * 
             * @date    21.12.2011
             * @author  Michael Mickiewicz
             * 
             * Updated on the 8th June 2016 by Tass Tsakiridis to update the New Listing and New Listing Date fields
             * when a product becomes available for the Account/Venue
            */
                
        if(ovi_Ids.size() > 0) {
            // now we want only the available ones
            Map<ID, Account_Survey_Item__c> ovi_Map = new Map<Id, Account_Survey_Item__c>();
            Map<String, Account_Survey_Item__c> asiMap = new Map<String, Account_Survey_Item__c>();
            Map<String, List<String>> ProductVenueMap = new Map<String, List<String>> ();
            List<Account_Product__c> existingAccountProducts = new List<Account_Product__c>();
            Set<Id> accountIDs = new Set<Id>();
            
            for(Account_Survey_Item__c ovi : [SELECT Id, CurrencyIsoCode, Location_On__c, Location_Off__c,Location_Reporting__c,Available__c, Bottle_Price__c, Bottle_Price_Special__c, 
                Brand__c, Delisted__c, Double_Price__c, Double_Price_Special__c, Drink_Price__c, Drink_Price_Special__c, Facing__c, Half_Pallet__c, 
                Mandatory_Product__c, Product__c, Shelf__c, Out_of_Stock__c, Account_Survey__r.Account__c, Account_Survey__r.Account__r.Market__r.Name, 
                Account_Survey__r.Name, Account_Survey__r.Last_Visit_Date__c, Account_Survey__r.Survey_Channel__c, Account_Survey__r.Account__r.Name
                //FROM Account_Survey_Item__c WHERE ID IN: ovi_Ids AND Id NOT IN: deletedIds AND Account_Survey__r.Last_Visit__c=true]) {
                FROM Account_Survey_Item__c WHERE Account_Survey__r.id IN: ovi_Ids AND Account_Survey__r.Last_Visit__c=true]) {
                	
                    
                asiMap.put(ovi.Product__c+''+ovi.Account_Survey__r.Account__c+''+ovi.Account_Survey__r.Survey_Channel__c,ovi);
                    
	            if(!accountIDs.contains(ovi.Account_Survey__r.Account__c)) {
	            	accountIDs.add(ovi.Account_Survey__r.Account__c);
                    System.debug('[Account_Survey_Helper] account name: ' + ovi.Account_Survey__r.Account__r.Name);
	            }
                              
    		}	

            System.debug('[Account_Survey_Helper] # of account ids: ' + accountIDS.size());
            for(String id : accountIDs) {
	            System.debug('[Account_Survey_Helper] accountId: ' + id);   
            }
            // get existing Account Products to calculate the differences
            // the string key is the combination of account id and product id, because each product can only exists once for each account, unless it's a venue
            // added location__c as one field to store either on or off premise location, whichever applies - BW
            map<String, Account_Product__c> oldAccountProducts = new map<String, Account_Product__c>();
            list <Account_Product__c> allAccountProducts = [SELECT Account_Channel__c, Account__c, Account_survey_Item__c, Available__c, Bottle_Price_Special__c, Bottle_Price__c, Brand__c, CurrencyIsoCode,
            							Deleted__c, Delisted__c, Drink_Price__c, Facings_Delta_Indicator__c, Facings_Delta__c, Facings__c, id, Last_Outlet_Visit_Date__c, 
            							Location_Off__c, Location_On__c, Mandatory_Product__c, Market_Name__c, Name, Out_of_Stock__c, Product__c, Product_Surveyed__c, Shelf__c, Survey_Channel__c 
        								FROM Account_Product__c 
				                        WHERE Account__c IN :accountIds
                                        ];

            System.debug('[Account_Survey_Helper] # of account products: ' + allAccountProducts.size());
            String key;
            for (Account_product__c prodVenue : allAccountProducts){
                id prodId = prodVenue.Product__c;
                key = prodVenue.Account__c + '_' + prodVenue.Survey_Channel__c;
                if (ProductVenueMap.containsKey(prodId)){
                    List<String> channels = ProductVenueMap.get(prodId);
                    channels.add(key);
                    ProductVenueMap.put(prodId, channels);
                } else {
                    List<String> channelList = new List<String>();
                    channelList.add(key);
                    ProductVenueMap.put(prodId, channelList);
                }
            }

            for (Account_Product__c ap: allAccountProducts) {
                String foreignKey = ap.Product__c+''+ ap.Account__c+''+ap.Survey_Channel__c;
                String venueKey = ap.Account__c+'_'+ap.product__c+'_'+ap.Survey_Channel__c;
                
                //Loop through all the account Products and if we have a new asi, update it
                if(asiMap.get(foreignKey) != null){
                	//Copy all values from ASI to AP
                    Account_Survey_Item__c thisASI = asiMap.get(foreignKey);

                    ap.New_Listing__c = false;
                    if (thisASI.Available__c == true && ap.Available__c == false) {
                        ap.New_Listing__c = true;
                        ap.New_Listing_Date__c = Date.today();
                    }
                    
                    ap.Available__c = thisASI.Available__c;
                    
                	//This is in case we have null values from the ASI, we want to make sure we only copy over the correct status             	
                	if (thisASI.Available__c == true || thisASI.Half_Pallet__c == true) {
                		System.debug('ASI is Available');
                		ap.Available__c = true;
                		ap.Delisted__c = false;
                		ap.Out_of_Stock__c = false;
                	} 
                	
                	if (thisASI.Delisted__c == true) {
                		System.debug('ASI is delisted');
                		ap.Delisted__c = true;
                		ap.Available__c = false;                		
                		ap.Out_of_Stock__c = false;
                	}
                	
                	if (thisASI.Out_of_Stock__c == true) {
                		System.debug('ASI is out of stock');
                		ap.Out_of_Stock__c = true;
                		ap.Available__c = false;
                		ap.Delisted__c = false;
                	}                	
                	
                	ap.Account_Survey__c = thisASI.Account_Survey__c;
                	ap.Account_Survey_Item__c = thisASI.id;					
					ap.Bottle_Price_Special__c = thisASI.Bottle_Price_Special__c;
					ap.Bottle_Price__c = thisASI.Bottle_Price__c;
					ap.Brand__c = thisASI.Brand__c;
					ap.CurrencyIsoCode = thisASI.CurrencyIsoCode;
					ap.Drink_Price__c = thisASI.Drink_Price__c;
					//Calculate Delta
					if (ap.Facings__c == null){
						if (thisASI.Facing__c != null){
							ap.Facings_Delta__c = thisASI.Facing__c;
						}						
					} else {
						if (thisASI.Facing__c == null) {
							ap.Facings_Delta__c = 0 - ap.Facings__c; 
						} else {
							ap.Facings_Delta__c = thisASI.Facing__c - ap.Facings__c;
						}						
					}
					ap.Facings__c = thisASI.Facing__c;
					ap.Last_Outlet_Visit_Date__c = thisASI.Account_Survey__r.Last_Visit_Date__c;
					ap.Shelf__c = thisASI.Shelf__c;
					ap.Location_Off__c = thisASI.Location_Off__c;
					ap.Location_On__c = thisASI.Location_On__c;
	
                } else {
                	//remove everything from the AP except last surveyed date, account, brand, product and market, mandatory Product, delisted, account survey
                	//however, we need to check if this is blank because we are editing a different venue's account Survey, or we actuall don't have a new ASI
                    if (ProductVenueMap.get(ap.Product__c).size() <= 1) {
                        //Means we only have this product on one venue
                        ap.Available__c = false;
                        ap.Bottle_Price_Special__c = false;
                        ap.Bottle_Price__c = null;
                        ap.Deleted__c = false;
                        ap.Drink_Price__c = null;
                        //Make sure to show the delta facings change (ie we had a facing previously and now we do not)
                        if(ap.Facings__c != null) {
                            ap.Facings_Delta__c = 0 - ap.Facings__c;
                        }
                        ap.Facings__c = null;
                        ap.Out_of_Stock__c = false;
                        ap.Shelf__c = null;
                        ap.Location_Off__c = null;
                        ap.Location_On__c = null;
                    }
                }
                existingAccountProducts.add(ap);
                                             
            }
            
            if(existingAccountProducts.size() > 0){
                update existingAccountProducts;
            }
            runIt=true;
        }
        
    }   
    
}