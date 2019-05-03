@isTest
public class ContentDocumentLink_Test {
    static testMethod void test(){
//Create Certification Record (SOD__C)    
		INFW_TestHelper helper = new INFW_TestHelper();

        Map<String,Schema.RecordTypeInfo> accRTMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String, RecordTypeInfo> promoRecordTypes = Schema.SObjectType.Promotion__c.getRecordTypeInfosByName();

        String rtAccount_AU = accRTMap.get('AUD - Outlet').getRecordTypeId();
        String rtSalesPromotion = promoRecordTypes.get('Sales Promotion').getRecordTypeId();
        
        Market__c market = helper.createMarket('Australia');
        market.Vistex_Clearing_Account__c = '0123456789';
        insert market;
                
		Account account = helper.createAccount('Test Account', market.ID, 'On Premise');
        account.RecordTypeId = rtAccount_AU;
		insert account;

        Promotion_Activity__c activity1 = new Promotion_Activity__c();
        activity1.Name = 'Test Activity';
        activity1.RecordTypeId = Promotion_Activity__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('CRM - Australia').getRecordTypeId();
        activity1.Active__c = true;
        activity1.Begin_Date__c = Date.today();
        activity1.End_Date__c = activity1.Begin_Date__c.addDays(7);
        activity1.Promotion_Type__c = 'Sales Promo';
        activity1.Wombat_Active__c = true;
        activity1.Channel__c = 'On';
        activity1.Premise__c = 'Not Applicable';
		insert activity1;
        
        Promotion__c promo = new Promotion__c(RecordTypeId=rtSalesPromotion,Account__c = account.Id,Is_Active__c=true,Promotion_Activity_AUD__c=activity1.Id,Promotion_Start_Date__c=Date.today(),Promotion_End_Date__c=Date.today(),Channel__c='ON',AUD_Channel__c='On');
       	insert promo;       	
        
        SOD__C sod1 = new SOD__c();
        sod1.SOX_Contact_ID__c = 'Mike';
        sod1.UniqueID__c = '12345';
        insert sod1;
        
        Test.startTest();

        ContentVersion contentVersion = new ContentVersion(
        	Title = 'Penguins',
        	PathOnClient = 'Penguins.jpg',
        	VersionData = Blob.valueOf('Test Content'),
        	IsMajorVersion = true
        );
        ContentVersion contentVersion2 = new ContentVersion(
        	Title = 'Penguins',
        	PathOnClient = 'Penguins.jpg',
        	VersionData = Blob.valueOf('Test Content'),
        	IsMajorVersion = true,
            FirstPublishLocationId = sod1.Id
        );
        ContentVersion contentVersion3 = new ContentVersion(
        	Title = 'Penguins',
        	PathOnClient = 'Penguins2.jpg',
        	VersionData = Blob.valueOf('Test Content'),
        	IsMajorVersion = true,
            FirstPublishLocationId = promo.Id
        );
        
        ContentVersion[] newVersions = new ContentVersion[]{contentVersion, contentVersion2, contentVersion3};
        insert newVersions; 
        
        List<String> versionIds = new List<String>();
        for(ContentVersion cv : newVersions) {
            versionIds.add(cv.Id);
        }
        ContentVersion[] contentVersions = [SELECT ContentDocumentId, FirstPublishLocationId FROM ContentVersion WHERE Id =:versionIds];
        //String contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:newVersions[0].Id LIMIT 1].ContentDocumentId;
		String cdSODId = '';
        String cdPromoId = '';
        for(ContentVersion cv : contentVersions) {
            if(cv.FirstPublishLocationId.getSobjectType().getDescribe().getName() == 'SOD__c'){
                cdSODId = cv.ContentDocumentId;
            }
            
            if(cv.FirstPublishLocationId.getSobjectType().getDescribe().getName() == 'Promotion__c'){
                cdPromoId = cv.ContentDocumentId;
            }
        }

        SOD__c sir = new SOD__c();
        ApexPages.StandardController stdSI = new ApexPages.StandardController(sir);
        //SIAttachFile si1 = new SIAttachFile(stdSI);        
        
       	List<ContentDocument> documents = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId =:versionIds];
        List<String> documentIds = new List<String>();
        
        System.debug('# of documents: ' + documents.size());
        for(ContentDocument cd : documents) {
            System.debug('documentId: ' + cd.Id);
            documentIds.add(cd.Id);
        }
        
        delete documents;
        
        ContentVersion cv1 = new ContentVersion(
        	Title = 'Penguins',
        	PathOnClient = 'Penguins.jpg',
        	VersionData = Blob.valueOf('Test Content'),
        	IsMajorVersion = true
        );
        insert cv1;
        
        String cv1DocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv1.Id].ContentDocumentId;
        
        //create ContentDocumentLink  record 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = sod1.id;
        cdl.ContentDocumentId = cv1DocumentId;
        cdl.shareType = 'V';
        insert cdl;
        delete cdl;
        
        
        Test.stopTest();
    }
}