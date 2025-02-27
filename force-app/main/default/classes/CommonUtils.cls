public with sharing class CommonUtils {
    
    public class CustomException extends Exception {}
    
    @AuraEnabled(cacheable=true)
    public static User getCurrentUser(Id userId) {
        if (userId==null) {
            userId = UserInfo.getUserId();
        }
        return [SELECT Id, FirstName, LastName, Email, Phone FROM User WHERE Id = :userId LIMIT 1];
    }
    
    @AuraEnabled(cacheable=true)
    public static String getObjectApiName(Id recordId) {
        return recordId.getSObjectType().getDescribe().getName();
    }
    
    @AuraEnabled
    public static Object getCustomMetadataFieldValue(String metadataObjectName, String developerName, String fieldName) {
        Object fieldValue = null;
        try {
            String queryString = 'SELECT ' + fieldName + ' FROM ' + metadataObjectName + ' WHERE DeveloperName = \''+String.escapeSingleQuotes(developerName)+'\' LIMIT 1';
            SObject setting = Database.query(queryString);
            fieldValue = (setting != null) ? setting.get(fieldName) : fieldValue;
        } catch (Exception e) {
            System.debug('Error getting custom metadata field value: ' + e.getMessage());
        }
        return fieldValue;
    }

    @AuraEnabled
    public static Boolean doesRecordExist(Id recordId) {
        SObject record = getObjectRecordById(recordId, new List<String>{'Id'});
        return record != null;
    }
    
    @AuraEnabled
    public static void deleteSelectedRecords(String objectName, List<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            throw new AuraHandledException('There are no records to delete.');
        }
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey(objectName)) {
            throw new IllegalArgumentException('Invalid object name: ' + objectName);
        }
        try {
            String query = 'SELECT Id, Name FROM ' + objectName + ' WHERE Id IN :recordIds';
            List<SObject> delList = Database.query(query);
            delete delList;
        } catch (DmlException e) {
            throw new AuraHandledException('Error deleting: ' + e.getMessage());
        }
    }
    
    public static SObject getObjectRecordById(Id recordId, List<String> fields) {
        if (recordId == null) {
            throw new IllegalArgumentException('Record Id cannot be null');
        }
        try {
            // Get name and fields of object by Id
            Schema.SObjectType objType = recordId.getSObjectType();
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            String objName = objDescribe.getName();
            Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
            
            List<String> selectedFields = new List<String>();
            if (fields == null || fields.isEmpty()) {
                // Parameter Fields is empty, take all fields of object
                selectedFields.addAll(fieldMap.keySet());
            } else {
                // Checking which of parameter fields have object
                for (String field : fields) {
                    if (fieldMap.containsKey(field)) {
                        selectedFields.add(field);
                    } else {
                        System.debug('Field not found on object \' '+ objName + ' \': ' + field);
                        return null;
                    }
                }
                if (selectedFields.isEmpty()) {
                    throw new IllegalArgumentException('None of the fields in the list were found for the object. ' + objName);
                }
            }
            
            // SOQL-text
            String fieldList = String.join(selectedFields, ',');
            String query = 'SELECT ' + fieldList + ' FROM ' + objName + ' WHERE Id = :recordId';
            
            // SOQL-query
            List<SObject> records = Database.query(query);
            
            return records.isEmpty() ? null : records[0];
        } catch (Exception e) {
            System.debug('Error executing request: ' + e.getMessage());
            return null;
        }
    }
    
    public static List<SObject> executeDynamicQuerySOQL(String objName, String fieldList, Object conditionFilterQuery, String additionalSuffixQuery) {
        try {
            if (String.isBlank(objName) || String.isBlank(fieldList)) {
                throw new IllegalArgumentException('Object name and fields are required!');
            }
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            if (!gd.containsKey(objName)) {
                throw new IllegalArgumentException('Invalid object name: ' + objName);
            }
            
            // SOQL-text
            String query = 'SELECT ' + fieldList + ' FROM ' + objName;
            if (conditionFilterQuery != null) {
                if (conditionFilterQuery instanceOf Map<String, Object>) {
                    // Key/value - where Key is nameFilter and Value is valueFilter
                    Map<String, Object> conditionFilter = (Map<String, Object>) conditionFilterQuery;
                    if (!conditionFilter.isEmpty()) {
                        List<String> conditions = new List<String>();
                        for (String fieldName : conditionFilter.keySet()) {
                            Object value = conditionFilter.get(fieldName);
                            if (value instanceof String) {
                                conditions.add(fieldName + ' = \'' + String.escapeSingleQuotes((String)value) + '\'');
                            }
                            else if (value instanceof Id) {
                                conditions.add(fieldName + ' = \'' + String.escapeSingleQuotes(String.valueOf(value)) + '\'');
                            }
                            else {
                                conditions.add(fieldName + ' = ' + String.valueOf(value));
                            }
                        }
                        query += ' WHERE ' + String.join(conditions, ' AND ');
                    }
                } else if (conditionFilterQuery instanceOf String) {
                    // Query filter text
                    String conditionFilter = (String)conditionFilterQuery;
                    query += ' WHERE ' + conditionFilter;
                } else {
                    throw new IllegalArgumentException('Filter must be either "Map<String, Object>" or "String"');
                }
            }
            if (!String.isEmpty(additionalSuffixQuery)) {
                query += ' ' + additionalSuffixQuery;
            }
            
            // SOQL-query
            List<SObject> records = Database.query(query);
            
            return records;
        } catch (Exception e) {
            System.debug('Error executing request: ' + e.getMessage());
            return new List<SObject>();
        }
    }
    
    public static Boolean isFieldFilled(Object fieldValue) {
        if (fieldValue == null) {
            return false;
        }
        if (fieldValue instanceof String) {
            return !String.isEmpty((String) fieldValue);
        }
        if (fieldValue instanceof Integer || fieldValue instanceof Decimal ||
        fieldValue instanceof Double || fieldValue instanceof Long) {
            return ((Decimal) fieldValue) != 0;
        }
        if (fieldValue instanceof List<Object>) {
            return !((List<Object>) fieldValue).isEmpty();
        }
        if (fieldValue instanceof Set<Object>) {
            return !((Set<Object>) fieldValue).isEmpty();
        }
        if (fieldValue instanceof Map<Object, Object>) {
            return !((Map<Object, Object>) fieldValue).isEmpty();
        }
        return false; // for other types, always 'false'
    }
    
    public static Boolean checkPicklistValueAvailable(String objectName, String fieldName, String inputValue){
        Boolean exists = false;
        //Describe object
        SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Schema.SObjectField objField = objType.getDescribe().fields.getMap().get(fieldName);
        //Describe field object
        Schema.DescribeFieldResult fieldResult = objField.getDescribe();
        //Check exists value in Picklist
        Set<String> validField = new Set<String>();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry entry : picklistValues) {
            validField.add(entry.getValue());
        }
        if (validField.contains(inputValue)) {
            exists = true;
        }
        return exists;
    }
    
    public static String formatDate(Date dt) {
        if(dt == null) {
            return '';
        }
        Datetime myDateTime = DateTime.newInstance(dt, Time.newInstance(0, 0, 0, 0));
        return myDateTime.format('dd.MM.yyyy');
    }

    public static void logError(String textException, String context) {
        try {
            Error_Log__c logRecord = new Error_Log__c(
                Message__c = textException,
                Context__c = context,
                Occurred_At__c = System.now()
            );
            insert logRecord;
        } catch(Exception ex) {
            System.debug('Error log: ' + ex.getMessage());
        }
    }
    
}