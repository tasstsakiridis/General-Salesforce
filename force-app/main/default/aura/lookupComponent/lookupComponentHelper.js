({
    doInit : function(cmp) {
        var sObjectAPIName = cmp.get('v.label');
        var lookupResultId = cmp.find("lookupResultId");
        $A.util.addClass(lookupResultId, sObjectAPIName+"_lookupId");
        //cmp.set('v.isReadOnly', true);
        let readOnly = cmp.get('v.isReadOnly');
        console.log('[lookupComponent.helper.doInit] isReadOnly', readOnly);
        /*
        var isReadOnly = cmp.get('v.isReadOnly');        
        if (isReadOnly == true) {
            cmp.find('lookup').set('v.disabled', isReadOnly);            
        }
        console.log('[lookupComponent.helper.doInit] isReadOnly: ' + isReadOnly);
        */
        var lookupResultValue = cmp.find("lookupResultValue");
        $A.util.addClass(lookupResultValue, sObjectAPIName+"_lookupValue");        
        
        var showCreateNew = cmp.get('v.showCreateNewOption');
        console.log('[lookupComponent.helper.doInit] showCreateNew: ' + showCreateNew);
        var createNewDiv = cmp.find('createNewDiv');
        if (showCreateNew == true) {
            $A.util.removeClass(createNewDiv, 'hideOption');
        } else {
            $A.util.addClass(createNewDiv, 'hideOption')
        }
        
    },
        
    /**
     * Perform the SObject search via an Apex Controller
     */
    doSearch : function(cmp) {
        // Get the search string, input element and the selection container
        var searchString = cmp.get('v.searchString');
        //var inputElement = cmp.find('lookup');
        var lookupList = cmp.find('lookuplist');
		cmp.set("v.isSearching", true);
        console.log('[lookupComponent.helper.doSearch] searchstring: ' + searchString);
        $A.log('searchstring: ' + searchString);
        // Clear any errors and destroy the old lookup items container
        //inputElement.set('v.errors', null);
        
        // We need at least 2 characters for an effective search
        //if (typeof searchString === 'undefined' || searchString.length < 2)
        //{
            // Hide the lookuplist
        //    $A.util.addClass(lookupList, 'slds-hide');
        //    return;
        //}

        // Show the lookuplist
        $A.util.removeClass(lookupList, 'slds-hide');
        $A.util.addClass(lookupList, 'slds-show');
		console.log('[lookupComponent.helper.doSearch] lookuplist', lookupList);
        // Get the API Name
        var sObjectAPIName = cmp.get('v.sObjectAPIName');

        // Create an Apex action
        var action = cmp.get('c.lookupComponent_DoSearch');
		
        var filterClause = cmp.get('v.filterClause');
        var nameField = cmp.get('v.nameField');
        if (nameField == undefined || nameField == null) { nameField = 'Name'; }
        
        var limit = cmp.get("v.resultLimit");
        if (limit == null || limit == 0) { limit = 49999; }
        
        console.log('[lookupComponent.helper.doSearch] sObjectAPINmae', sObjectAPIName);
        console.log('[lookupComponent.helper.doSearch] filterclause', filterClause);
        console.log('[lookupComponent.helper.doSearch] limit', limit);
        //var whereClause = '';
        $A.log('[lookupComponent.helper.doSearch] filter: ' + filterClause); 
        console.log('[lookupComponent.helper.doSearch] namefield',nameField);
        // Mark the action as abortable, this is to prevent multiple events from the keyup executing
        action.setAbortable();

        // Set the parameters
        action.setParams({ 
            "searchString" : searchString, 
            "sObjectAPIName" : sObjectAPIName, 
            "filterClause" : filterClause, 
            "nameField" : nameField, 
            "resultLimit" : limit 
        });
                          
        // Define the callback
        let helper = this;
        action.setCallback(this, function(response) {
            var state = response.getState();

            // Callback succeeded
            if (cmp.isValid() && state === "SUCCESS")
            {
				cmp.set("v.isSearching", false);
                
                // Get the search matches
                var matches = response.getReturnValue();

                // If we have no matches, return nothing
                if (matches.length == 0)
                {
                    cmp.set('v.matches', null);
                    return;
                }
                
                // Store the results
                cmp.set('v.matches', matches);
            }
            else if (state === "ERROR") // Handle any error by reporting it
            {
                var errors = response.getError();
                
                if (errors) 
                {
                    if (errors[0] && errors[0].message) 
                    {
                        helper.displayToast('Error', errors[0].message);
                    }
                }
                else
                {
                    helper.displayToast('Error', 'Unknown error.');
                }
            }
        });
        
        // Enqueue the action                  
        $A.enqueueAction(action);                
    },

    /**
     * Handle the Selection of an Item
     */
    handleSelection : function(cmp, event) {
        console.log('[lookupComponent.helper.handleSelection] handleSelection');
        // Resolve the Object Id from the events Element Id (this will be the <a> tag)
        var objectId = this.resolveId(event.currentTarget.id);

        // The Object label is the inner text)
        var objectLabel = event.currentTarget.innerText;

        // Hide the Lookup List
        var lookupList = cmp.find("lookuplist");
        console.log('[lookupComponent.helper.handleSelection] will hide lookuplist component');
        $A.util.removeClass(lookupList, 'slds-show');
        $A.util.addClass(lookupList, 'slds-hide');

        // Log the Object Id and Label to the console
        console.log('[lookupComponent.helper.handleSelection] objectId', objectId);
        console.log('[lookupComponent.helper.handleSelection] objectLabel', objectLabel);
        if (objectId != null && objectId.length > 0) { 
        
            // Create the UpdateLookupId event
            var updateEvent = cmp.getEvent("updateLookupIdEvent");
            console.log("[lookup.handleSelection] get reference to updateLookupIdEvent", updateEvent);
            
            // Get the Instance Id of the Component
            let instanceId = cmp.get('v.instanceId');
            let objectName = cmp.get('v.sObjectAPIName');
            console.log('[lookupComponent.helper.handleSelection] instanceId: ' + instanceId + ', objectName: ' + objectName);
            
            try {
            // Populate the event with the selected Object Id and Instance Id
            updateEvent.setParams({
                "sObjectId" : objectId, "instanceId" : instanceId, "sObjectName" : objectLabel
            });
    
            // Fire the event
            updateEvent.fire();
                
            }catch(ex) {
				console.log('[lookupComponent.helper.handleSelection] ex', ex);                
            }
                
    		console.log("[lookup.handleselection] firing updateevent")
            // Update the Searchstring with the Label
            cmp.set("v.searchString", objectLabel);
            cmp.set("v.recordId", objectId);
            console.log('[lookupComponent.helper.handleSelection] instanceid: ' + instanceId + ', objectlabel: ' + objectLabel + ', objectId: ' + objectId);
        }
            
        /*
        var lookupResultId = cmp.find("lookupResultId");
        $A.util.addClass(lookupResultId, objectName+"_lookupId");
        
        var lookupResultValue = cmp.find("lookupResultValue");
        $A.util.addClass(lookupResultValue, objectName+"_lookupValue");
        */

        // Hide the Input Element
        //var inputElement = cmp.find('lookup');
        //$A.util.addClass(inputElement, 'slds-hide');

        // Show the Lookup pill
        //var lookupPill = cmp.find("lookup-pill");
        //$A.util.removeClass(lookupPill, 'slds-hide');

        // Lookup Div has selection
        //var inputElement = cmp.find('lookup-div');
        //$A.util.addClass(inputElement, 'slds-has-selection');

        var clearSelectionButton = cmp.find("clearSelectionButton");
        $A.util.removeClass(clearSelectionButton, "slds-hide");

    },

    /**
     * Clear the Selection
     */
    clearSelection : function(cmp) {
        console.log("lookupComponent.helper.clearSelection]");
        // Create the ClearLookupId event
        var clearEvent = cmp.getEvent("clearLookupIdEvent");

        // Get the Instance Id of the Component
        var instanceId = cmp.get('v.instanceId');

        // Populate the event with the Instance Id
        clearEvent.setParams({
            "instanceId" : instanceId
        });
        
        // Fire the event
        clearEvent.fire();

        // Clear the Searchstring
        cmp.set("v.searchString", '');

        // Hide the Lookup pill
        /*
        var lookupPill = cmp.find("lookup-pill");
        $A.util.addClass(lookupPill, 'slds-hide');
		*/
        var clearSelectionButton = cmp.find("clearSelectionButton");
        $A.util.addClass(clearSelectionButton, "slds-hide");
        
        // Show the Input Element
        //var inputElement = cmp.find('lookup');
        //$A.util.removeClass(inputElement, 'slds-hide');

        // Lookup Div has no selection
        var inputElement = cmp.find('lookup-div');
        $A.util.removeClass(inputElement, 'slds-has-selection');
    },

    /**
     * Resolve the Object Id from the Element Id by splitting the id at the _
     */
    resolveId : function(elmId)
    {
        var i = elmId.lastIndexOf('_');
        return elmId.substr(i+1);
    },

    /**
     * Display a message
     */
    displayToast : function (title, message) 
    {
        var toast = $A.get("e.force:showToast");

        // For lightning1 show the toast
        if (toast)
        {
            //fire the toast event in Salesforce1
            toast.setParams({
                "title": title,
                "message": message
            });

            toast.fire();
        }
        else // otherwise throw an alert
        {
            alert(title + ': ' + message);
        }
    },
    
    hasLostFocus : function(cmp) 
    {
        console.log('lookupComponent.helper.hasLostFocus]');
        var lookupList = cmp.find("lookuplist");
        $A.util.removeClass(lookupList, 'slds-show');
        $A.util.addClass(lookupList, 'slds-hide');

	},

    willCreateNew : function(cmp, event) {   
        var objectLabel = cmp.get('v.objectLabel');
      	cmp.set("v.searchString", 'Create New ' + objectLabel);
        cmp.set("v.recordId", 'new');    
        
        var lookupList = cmp.find("lookuplist");
        $A.util.removeClass(lookupList, 'slds-show');
        $A.util.addClass(lookupList, 'slds-hide');
    }
    
})