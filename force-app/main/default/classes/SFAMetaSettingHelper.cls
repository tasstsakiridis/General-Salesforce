public class SFAMetaSettingHelper {
	// Find all possible buttons for the page given it's market, channel, and subchannel
    public static Set<SFAOverflowMenuItem> findOverflowButtons(String page, String market, String channel, String subchannel) {       
        // Query start -- Get button deets
        String query = 'SELECT Overflow_Button__r.MasterLabel, Overflow_Button__r.Link__c, Overflow_Button__r.SF1isRedirect__c, Overflow_Button__r.Target__c';
        // From SFA Settings
        query += ' FROM Salesforce_Automation_Settings__mdt';
        // Where it's a button type
        query += ' WHERE Setting_Type__c = \'Overflow Menu Item\'';
        // Where something in market, channel, subchannel is an ALL
        query += ' AND (Market__r.MasterLabel = \'All\' OR  Market__r.MasterLabel = \'' + market + '\')';
        query += ' AND (Channel__r.MasterLabel = \'All\' OR Channel__r.MasterLabel = \'' + channel + '\')';
        query += ' AND (StoreType__r.MasterLabel = \'All\' OR StoreType__r.MasterLabel = \'' + subchannel +'\')';
        // Limit to just the page we are requesting buttons for
        if(page == 'Account_Visit')
            query += ' AND Overflow_Button__r.Available_in_Account_Visit__c = true';
        
        // Execute query
        Salesforce_Automation_Settings__mdt[] buttons;
        buttons = Database.query(query);
        System.debug(buttons);
        
        // Process buttons -- evaluate custom label references into actual 
        Set<SFAOverflowMenuItem> menuButtons = new Set<SFAOverflowMenuItem>();
        for(Salesforce_Automation_Settings__mdt button : buttons) {
            System.debug(button);
            menuButtons.add(new SFAOverflowMenuItem(button.Overflow_Button__r.MasterLabel, button.Overflow_Button__r.Link__c, button.Overflow_Button__r.SF1isRedirect__c, button.Overflow_Button__r.Target__c));
        }
        System.debug(menuButtons);
        return menuButtons;
    }
    
    // Find the Account Survey history retention settings for a given market, channel, and subchannel
    public static String findAccountSurveyRetention(String market, String channel, String subchannel) {       
        System.debug(market+ channel+ subchannel);
        Salesforce_Automation_Settings__mdt[] historySettings = [
            SELECT Survey_History_Timeout__c, Market__r.MasterLabel, Channel__r.MasterLabel, StoreType__r.MasterLabel
            FROM Salesforce_Automation_Settings__mdt
            WHERE Setting_Type__c = 'Account Survey History Display Timeout'
            AND (Market__r.MasterLabel = 'All' OR  Market__r.MasterLabel = :market)
			AND (Channel__r.MasterLabel = 'All' OR Channel__r.MasterLabel = :channel)
            AND (StoreType__r.MasterLabel = 'All' OR StoreType__r.MasterLabel = :subchannel)
        ];
        
        // Hold the best match rule
        Salesforce_Automation_Settings__mdt winningSetting;
        
        // If we got multiple settings back, find the most specific one
        //  (subchannel -> market in most specific order)
        if(historySettings.size() > 1) {
            Integer winningWeight = 0;
            for(Salesforce_Automation_Settings__mdt setting : historySettings) {
                Integer weight = 0;
                if(setting.StoreType__r.MasterLabel == subchannel) {
                    weight += 4;
                }
                if(setting.Channel__r.MasterLabel == channel) {
                    weight += 2;
                }
                if(setting.Market__r.MasterLabel == market) {
                    weight += 1;
                }
                if(weight > winningWeight) {
                    winningWeight = weight;
                    winningSetting = setting;
                }
            }
		} else if(historySettings.size() == 1) {
            winningSetting = historySettings[0];
        } else {
            winningSetting = null;
        }
        System.debug(winningSetting);
        
        if(winningSetting != null)
        	return winningSetting.Survey_History_Timeout__c;
        else 
            return '';
    }

    // Find Linked Object configurations
    public static LinkedObject findLinkedObjectConfigurations(String market, String controllingObject, String linkedObject) {
        
        List<Link_Object_Config__mdt> l = [SELECT Controlling_Object__c, Linked_Object__c, Market__c,
                                            (SELECT Linked_Object__c, Linked_Object_FieldName__c, Linked_Object_FieldValue__c FROM Link_Object_Item_Configs__r)
                                           FROM Link_Object_Config__mdt
                                          WHERE Market__c =:market
                                            AND Controlling_Object__c =:controllingObject 
                                            AND Linked_Object__c =:linkedObject];

        if (l == null || l.size() == 0) { return null; }

        Link_Object_Config__mdt loc = l.get(0);
        LinkedObject lo = new LinkedObject(loc.Controlling_Object__c, loc.Linked_Object__c);
        for(Link_Object_Item_Config__mdt loic : loc.Link_Object_Item_Configs__r) {
            if (loic.Linked_Object__c == lo.controllingObject) {
                lo.controllingObjectItemConfigs.put(loic.Linked_Object_FieldName__c, loic.Linked_Object_FieldValue__c);
            } else {
                lo.linkedObjectItemConfigs.put(loic.Linked_Object_FieldName__c, loic.Linked_Object_FieldValue__c);
            }
        }
            /*
            if (queryString.length() > 0) { queryString += ' AND '; }
            if (loc.Controlling_Object_Fieldname__c != null) {
                queryString += loc.Controlling_Object_Fieldname__c;
            
                if (loc.Controlling_Object_FieldValue__c == null || loc.Controlling_Object_FieldValue__c == '') {
                    queryString += ' = ' + loc.Linked_Object_Fieldname__c;
                } else {
                    queryString += ' = '  + loc.Controlling_Object_FieldValue__c;
                    queryString += ' AND ' + loc.Linked_Object_Fieldname__c + ' = ' + loc.Linked_Object_FieldValue__c;
                }
            } else if (loc.Linked_Object_Fieldname__c != null) {
                queryString += loc.Linked_Object_Fieldname__c + ' = ' + loc.Linked_Object_FieldValue__c;
            }
            */
        

        return lo;
    }
}