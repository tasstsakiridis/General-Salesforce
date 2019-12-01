public class LinkedObject {
    public string controllingObject                         { get; set; }
    public string linkedObject                              { get; set; }
    public Map<String, String> linkedObjectItemConfigs      { get; set; }
    public Map<String, String> controllingObjectItemConfigs { get; set; }

    public LinkedObject() {
        init();
    }

    public LinkedObject(String controllingObject, String linkedObject) {
        init();

        this.controllingObject = controllingObject;
        this.linkedObject = linkedObject;
         
    }
    void init() {
        this.controllingObject = '';
        this.linkedObject = '';
        this.linkedObjectItemConfigs = new Map<String, String>();
        this.controllingObjectItemConfigs = new Map<String, String>();
    }

    public Boolean recordMatchesCriteria(String theRecordId, Boolean isControllingObject) {
        Boolean doesMatch = true;
        String soql = '';
        if (isControllingObject) {
            for(String s : controllingObjectItemConfigs.keySet()) {
                soql += s + ',';
            }
        } else {
            for(String s : linkedObjectItemConfigs.keySet()) {
                soql += s + ',';
            }
        }

        soql = soql.removeEnd(',');
        soql = 'SELECT ' +  soql + ' FROM ' + (isControllingObject ? controllingObject : linkedObject);
        soql += ' WHERE Id = \'' + theRecordId + '\'';
        System.debug('[LinkedObject] soql: ' + soql);
        SObject obj = Database.query(soql);
        if (isControllingObject) {
            for(String s : controllingObjectItemConfigs.keySet()) {
                if (obj.get(s) != controllingObjectItemConfigs.get(s)) {
                    doesMatch = false; break;
                }
            }
        }

        return doesMatch;
    }
}
