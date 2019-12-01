public with sharing class Call_Card_Helper {
	public static boolean hasAlreadyRun = false;
    private static final String GERMANMARKETNAME='Germany';
    public static boolean runIt = false;
    public static boolean mpRunIt = false;

    public static void main(set<Id> AccountIds) {
        system.debug('in call card helper class');
        if(AccountIDs.size() == 0){
            return;
        }
        List<Account> accounts = [SELECT Id, Name, Last_Visit_Date__c, (SELECT Id, Account__c, Last_Visit__c, Next_to_Last_Visit__c, Call_Card_Date__c FROM CallCards__r ORDER BY Call_Card_Date__c DESC LIMIT 3) FROM Account WHERE Id=:AccountIds];
        
        List<Account> acctsToUpdate = new List<Account>();
        List<CallCard__c> callCardsToUpdate = new List<CallCard__c>();
        Integer i = 0;
        for(Account acc : accounts) {
            i = 0;
            for(CallCard__c cc : acc.CallCards__r) {
                if (i == 0) {
                    // first element
                    cc.Last_Visit__c = true;
                    cc.Next_to_Last_Visit__c = false;
                    if (acc.Last_Visit_Date__c != cc.Call_Card_Date__c) {
                        acc.Last_Visit_Date__c = cc.Call_Card_Date__c;
                        acctsToUpdate.add(acc);
                    }
                    
                    callCardsToUpdate.add(cc);
                } else if (i == 1) {
                    cc.Last_Visit__c = false;
                    cc.Next_to_Last_Visit__c = true;
                    callCardsToUpdate.add(cc);
                } else if (i == 2) {
                    cc.Last_Visit__c = false;
                    cc.Next_to_Last_Visit__c = false;
                    callCardsToUpdate.add(cc);
                }
                
                i++;
            }
        }
        
        if (!callCardsToUpdate.isEmpty()) {
            update callCardsToUpdate;
        }
        if (!acctsToUpdate.isEmpty()) {
            update acctsToUpdate;
        }
    }
}