// This class consolidates finding images on an object from both its Feed and its Attachments
// and updates a Boolean Field on the object.
// Ideally put triggers on ContentDocument, ContentVersion, and Attachment to fire updateAttachmentStatus() when applicable records are inserted/updated/delete
//   Attachment store singular, no versioning attachments to a record
//   ContentDocument is wrapper for a versioned attachment via a Chatter Feed Item post
//   ContentVersion stores the versions of a ContentDocument
// 
//
// Author Clay Colwell 
// First implemented with Promotion__c object

public class GenericAttachmentUtility {
    
    // Take a set of object IDs to process, the name of the field to save the result into on the object, a set of acceptable file types, and a set of ContentDocuments to ignore in the case of a (before) deletion
    // Note that the set of objects must all contain the same object type
    // Note that an Empty fileTypeFilter means if any file is attached at all (in Attachments or Feed) eval is true
    // Note that the fileTypeFilter members should be in lowercase
    // Note that deletingContentDocuments set is useful if this is being triggered before a delete on ContentDocument
    // 		If not provided, will eval incorrectly if a ContentDocument is deleted from a Feed item
    // 		When deleteing ContentDocuments, evaluation must be done before delete completes due to the relationshops between ContentDocument and ContentVersion.
    // 		On the ContentDocument trigger, you must be able to query the ContentVersion data to find the original object the ContentDocument was posted on
    // 		 so that you can determine in the trigger if the ContentDocument is related to the object you want to update the attachment status on.
    // 		 If you perform the trigger after delete on ContentDocument, you can't query the ContentVersion data (as it will have been deleted already)
    // 		 to determine the original object the ContentDocument was posted to. You cannot do a delete trigger on ContentVersion as it does not support trigger before|after delete.
	public static void updateAttachmentStatus(Set<Id> toUpdate, GenericAttachmentBehavior behaviour, Set<String> fileTypeFilter, Set<Id> deletingContentDocuments) {
        if(!toUpdate.isEmpty()) {
            // Get string representations of object
        	String objectName = getSetObjectType(toUpdate);
            //System.debug('objectName: ' + objectName);
            
            // Result list of objects to update
            String listType = 'List<' + objectName + '>';
            List<SObject> objectsToUpdate = (List<SObject>)Type.forName(listType).newInstance();
            
            // Query and get all relevant objects
            List<sObject> objects = getObjects(toUpdate, behaviour, fileTypeFilter, objectName);
            //System.debug('objects: ' + objects);
            
            // Check all objects for Attachments. If they have, short-circuit and set record for updating to true, remove from object list
            // If no attachments, leave in object list for Feed check
            // Iterate through all objects, Use count notation so we can dynamically remove from list
            // Count backwards since we'll be removing indices
            for(Integer i = objects.size() - 1; i >= 0 ; i--) {
                sObject obj = objects.get(i);
                //System.debug('obj: ' + obj);
                
                // Get attachments from object
                List<Attachment> attachments = new List<Attachment>();
                List<Attachment> nullCheckAttachments = obj.getSObjects('Attachments');
                if(nullCheckAttachments != null)
                    attachments.addAll(nullCheckAttachments);
                //System.debug('attachments.isEmpty: ' + attachments.isEmpty());
                
                // Get current value of fieldStore
                Boolean currentFieldStoreVal = (Boolean)obj.get(behaviour.getBooleanFieldName());
                //System.debug('currentFieldStoreVal: ' + currentFieldStoreVal);
                
                // If has attachments, we can short-circuit
                if(!attachments.isEmpty()) {
                    //System.debug('fileTypeFilter criteria met: attachment found in Attachments');
                    // If currentFieldStoreVal is false, set fieldStore true, add to update list, remove from objects list
                    if(currentFieldStoreVal == false) {
                        System.debug('Short-circuit processing, update fieldStore to true and add to update list');
                        //obj.put(fieldStore, true);
                        behaviour.onImageAttached(obj);
                        objectsToUpdate.add(obj);
                        objects.remove(i);
                    }
                    // If currentFieldStoreVal already true, ignore record entirely, already what it needs to be
                    else if(currentFieldStoreVal == true) {
                        //System.debug('Short-circuit processing, record already up-to-date. Ignoring.');
                        objects.remove(i);
                    }
                } else {
                    //System.debug('fileTypeFilter criteria not met: continue search (later) in Feed');
                }
            }
            
            //System.debug('objectsToUpdate: ' + objectsToUpdate);
            //System.debug('objects: ' + objects);
            
            //
            // Process remaining objects that don't have Attachments. See if they have attachments in Feed
            //  Check the latest version of every Feed item content document against filetype filter
            
            if(objects.size() > 0) {
                //System.debug('Processing remaining objects for Feed attachments');
                
                // Get set of RelatedRecordIds from object List.
                Set<Id> relatedRecordIds = getRelatedRecordIds(objects);
                //System.debug('relatedRecordIds: ' + relatedRecordIds);
                
                // Get a mapping of each related record ID to the content document to which it belongs
                Map<Id, Id> relatedRecordId2ContentDocumentId = getRelatedRecord2ContentId(relatedRecordIds);
                //System.debug('relatedRecordId2ContentDocumentId: ' + relatedRecordId2ContentDocumentId);
                
                // Create a set of ContentDocument IDs
                Set<Id> contentDocumentIds = new Set<Id>();
                contentDocumentIds.addAll(relatedRecordId2ContentDocumentId.values());
                //System.debug('contentDocumentIds: ' + contentDocumentIds);
                
                // Generate a Map of each ContentDocument to the latest ContentVersion of that file
                Map<Id, ContentVersion> cd2LatestContentVersion = getCD2LatestContentVersion(contentDocumentIds);
                //System.debug('cd2LatestContentVersion: ' + cd2LatestContentVersion);
                
                // Iterate through remaining objects and check if latest version of related record is in filetype filter
                for(SObject obj : objects) {
                    //System.debug('obj: ' + obj);
                    
                    // Get current value of fieldStore
                    Boolean currentFieldStoreVal = (Boolean)obj.get(behaviour.getBooleanFieldName());
                    //System.debug('currentFieldStoreVal: ' + currentFieldStoreVal);
                    
                    // Variable for new fieldStore value
                    Boolean newFieldStoreVal = false;
                    
                    for(SObject feed : obj.getSObjects('Feeds')) {
                        //System.debug('feed: ' + feed);
                        
                        // Check if feed item here
                        if(feed != null) {
                            // Try to get RelatedRecordId field and do check
                            Id recordId = (Id) feed.get('RelatedRecordId');
                            if(recordId != null) {
                                // Get the ContentDocumentId associated with the ContentVersion (RelatedRecordId)
                                Id contentDocId = relatedRecordId2ContentDocumentId.get(recordId);
                                //System.debug('contentDocId: ' + contentDocId);
                                
                                // Get the latest ContentVersion associated with the ContentDocumentId
                                ContentVersion cv = cd2LatestContentVersion.get(contentDocId);
                                //System.debug('cv: ' + cv);
                                
                                // Get the filetype associated with the ContentVersion
                                // Do not get fileType if it belongs to a to be deleted ContentDocument
                                String fileType = '';
                                if(cv != null) {
                                    if(!deletingContentDocuments.contains(contentDocId)) {
	                                    fileType = cv.FileType.toLowerCase();
                                    } else {
                                        //System.debug('ContentDocument for ContentVersion being deleted. Do not get FileType.');
                                    }
                                }
                                //System.debug('fileType: ' + fileType);
                                
                                // Check if filetype is in fileType filter
                                // Or if fileType filter is empty, any file is accepted
                                if(!fileTypeFilter.isEmpty()) {
                                    if(fileTypeFilter.contains(fileType)) {
                                        //System.debug('fileTypeFilter criteria met: attachment found in Feed');
                                        newFieldStoreVal = true;
                                        break;
                                        
                                    } else {
                                        //System.debug('fileTypeFilter criteria not met by this Feed item');
                                    }
                                } else {
                                    // If document is not being deleted, allow it to meet filter, otherwise it doesn't meet filter
                                    if(!deletingContentDocuments.contains(contentDocId)) {
                                        //System.debug('fileTypeFilter criteria met: attachment found in Feed');
                                        newFieldStoreVal = true;
                                        break;
                                    } else {
                                        //System.debug('fileTypeFilter criteria not met by this Feed item (being deleted)');
                                    }
                                }
                            }
                        }
                    }
                    
                    //System.debug('newFieldStoreVal: ' + newFieldStoreVal);
                    
                    // Check if we need to update the object or not and add to objectsToUpdate if needed
                    if(currentFieldStoreVal != newFieldStoreVal) {
                        System.debug('Update fieldStore to newFieldStoreVal and add to update list');
                        System.debug('currentFieldStoreVal: ' + currentFieldStoreVal + ' newFieldStoreVal: ' + newFieldStoreVal);
                        if(newFieldStoreVal == true) {
                            behaviour.onImageAttached(obj);
                        } else {
                            behaviour.onImageDeleted(obj);
                        }
                        //obj.put(fieldStore, newFieldStoreVal);
                        objectsToUpdate.add(obj);
                    } else {
                        //System.debug('Short-circuit processing, record already up-to-date. Ignoring.');
                    }
                }
                
                //System.debug('objectsToUpdate: ' + objectsToUpdate);
            } else {
                //System.debug('No more records to process for Feed attachments');
            }
            
            // Finally update records
            if(objectsToUpdate.size() > 0) {
                //System.debug('Updating objects');
            	update objectsToUpdate;
            } else {
                //System.debug('Nothing to update');
            }
            
        } else {
            // Empty set, nothing to do
            return;
        }
    }
    
    // Overload method to accept any file type for attachment status and no to be deleted ContentDocuments
	public static void updateAttachmentStatus(Set<Id> toUpdate, GenericAttachmentBehavior behavior) {
        updateAttachmentStatus(toUpdate, behavior, new Set<String>(), new Set<Id>());
    }
    
    // Overload method to accept file type filter and no to be deleted ContentDocuments
	public static void updateAttachmentStatus(Set<Id> toUpdate, GenericAttachmentBehavior behavior, Set<String> fileTypeFilter) {
        updateAttachmentStatus(toUpdate, behavior, fileTypeFilter, new Set<Id>());
    }
   
    // Find the (string) object name for the given set
    private static String getSetObjectType(Set<Id> objectSet) {
        // Find the object type of our set
        // Pull a value from the set
        string firstId = null;
        for (string obj : objectSet) {
            firstId = (String) obj;
            break;
        }
        // Use helper class to go from ID to type
        return SchemaGlobalDescribe.findObjectNameFromRecordIdPrefix(firstId);
    }
    
    // Get all objects from Set
    private static List<sObject> getObjects(Set<Id> objectSet, GenericAttachmentBehavior behavior, Set<String> fileTypeFilter, String objectName) {
        // Create where clause for Attachment file type filter
        String attachmentWhereClause = attachmentWhereClauseBuilder(fileTypeFilter);
        
        // Create query
        String dbQuery = 'SELECT Id, ' + behavior.getSOQLFieldNames() + ', (SELECT Id FROM Attachments' + attachmentWhereClause + '), ';
        dbQuery +=			'(SELECT RelatedRecordId FROM Feeds) FROM ' + objectName + ' WHERE Id IN :objectSet';
        //System.debug('dbQuery: ' + dbQuery);
        
        // Run query and return
        return database.query(dbQuery);
    }
    
    // Used in getObjects() to create where clause for Attachments
    private static String attachmentWhereClauseBuilder(Set<String> fileTypefilter) {
        if(!fileTypefilter.isEmpty()) {
            String clause = ' WHERE ';
            for (string fileType : fileTypefilter) {
                clause += 'ContentType LIKE \'' + fileType + '\' OR ';
            }
            clause = clause.substring(0, clause.length() - 4);
            //System.debug('clause: ' + clause);
            return clause;
        } else {
            //System.debug('clause: ');
            return '';
        }
    }
    
    // get a set of all RelatedRecordIds from Object List
    private static Set<Id> getRelatedRecordIds(List<sObject> objects) {
        Set<Id> relatedRecordIds = new Set<Id>();
        
        // Iterate through all objects
        for(SObject obj : objects) {
            // Get Feeds object from object (guarenteed present from SOQL)
            for(SObject feed : obj.getSObjects('Feeds')) {
                // Check if feed item here
                if(feed != null) {
                    // Try to get RelatedRecordId field, add to set if present
                    Id recordId = (Id) feed.get('RelatedRecordId');
                    if(recordId != null)
	                    relatedRecordIds.add(recordId);
                }
            }

        }
        
        return relatedRecordIds;
    }
    
    // Get a map of all ContentDocumentIds for all RelatedRecordIds
    private static Map<Id, Id> getRelatedRecord2ContentId(Set<Id> relatedRecordIds) {
        Map<Id, Id> relatedRecordId2ContentDocumentId = new Map<Id, Id>();
        for(ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE id IN :relatedRecordIds]) {
            relatedRecordId2ContentDocumentId.put(cv.Id, cv.ContentDocumentId);
        }
        return relatedRecordId2ContentDocumentId;
    }
    
    // Get a map of ContentDocument IDs to the latest ContentVersion of that file
    private static Map<Id, ContentVersion> getCD2LatestContentVersion(Set<Id> contentDocumentIds) {
        Map<Id, ContentVersion> cd2LatestContentVersion = new Map<Id, ContentVersion>();
        for(ContentVersion cv : [SELECT CreatedDate, Id, ContentDocumentId, FirstPublishLocationId, FileType FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds]) {
            //System.debug(cv);
            ContentVersion mapCV = cd2LatestContentVersion.get(cv.ContentDocumentId);
            if(mapCV == null) {
                cd2LatestContentVersion.put(cv.ContentDocumentId, cv);
            } else {
                if(cv.CreatedDate > mapCV.CreatedDate)
                    cd2LatestContentVersion.put(cv.ContentDocumentId, cv);
            }
        }
        return cd2LatestContentVersion;
    }
}