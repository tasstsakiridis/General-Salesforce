({
	doInit : function(component, event, helper) {
		let accounts = [
            { 'Id':'012346789', 'Name': 'Test Account 1', 'AccountNumber':'7000001234'},
            { 'Id':'112346789', 'Name': 'Test Account 2', 'AccountNumber':'7000001235'},
            { 'Id':'212346789', 'Name': 'Test Account 3', 'AccountNumber':'7000001236'},
            { 'Id':'312346789', 'Name': 'Test Account 4', 'AccountNumber':'7000001237'},
            { 'Id':'412346789', 'Name': 'Test Account 5', 'AccountNumber':'7000001238'},
            { 'Id':'512346789', 'Name': 'Test Account 6', 'AccountNumber':'7000001239'},
        ];
        component.set("v.accounts", accounts);
	}
})