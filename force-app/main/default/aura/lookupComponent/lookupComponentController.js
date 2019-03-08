({
    /**
     * do Init
     */
    init : function(cmp, event, helper) {
    	helper.doInit(cmp);    
    },
    
    /**
     * Search an SObject for a match
     */
    search : function(cmp, event, helper) {
        helper.doSearch(cmp);        
    },
    handleKeyUp : function(cmp, event, helper) {
    	let isEnterKey = event.keyCode === 13;
        if (isEnterKey) {
            helper.doSearch(cmp);
        }
    },
    /**
     * Select an SObject from a list
     */
    select: function(cmp, event, helper) {
        helper.handleSelection(cmp, event);
    },
     
    /**
     * Hide result list
     */
    hideSelection: function(cmp, event, helper) {
    	helper.hasLostFocus(cmp, event);    
    },
    
    /**
     * Clear the currently selected SObject
     */
    clear: function(cmp, event, helper) {
        helper.clearSelection(cmp);    
    },
    
    /**
     * Has lost focus
     */
    lostFocus: function(cmp, event, helper) {
    	helper.hasLostFocus(cmp);
	},

    /**
     * Will create new record
     */
    createNewOption: function(cmp, event, helper) {
        helper.willCreateNew(cmp, event);
    },
    handleReadOnlyChange : function(cmp, event) {
        console.log('[lookupComponent.controller.handleReadOnlyChange]');
        let v = event.getParam("value");
        console.log('[lookupComponent.controller.handleReadOnlyChange] readonly', v);
        
    },
    handleFilterClauseChange : function(cmp, event) {
        console.log('[lookupComponent.controller.handleFilterClauseChange]');
        let v = event.getParam("value");
        console.log('[lookupComponent.controller.handleFilterClauseChange] filterClause', v);
    }
})