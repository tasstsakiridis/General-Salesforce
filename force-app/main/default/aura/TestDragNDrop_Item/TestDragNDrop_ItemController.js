({
	doInit : function(component, event, helper) {          
		let account = component.get("v.account");  
        let accountCode = component.get("v.accountCode");
        $('#'+accountCode).data('event', {
            title: account.Name,
            stick: true,
            account: JSON.stringify(account)
        });
        $('.draggable-item').draggable({
            helper: 'original',
            stack: true,
            revert: true,
            revertDuration: 0            
        });
	},
    handleDragStart : function(component, event, helper) {
        console.log("[TestAccountListItem] drag started");
        let account = component.get("v.account");
        event.dataTransfer.setData("account", JSON.stringify(account));
        event.dataTransfer.effectAllowed='copy';
        event.dataTransfer.dropEffect='copy';
    },
})