public class DiscountSettingsUtils {

    public Record RECORD { get { return new Record(); } }
    public Field FIELD { get { return new Field(); } }

    public class Record {
        public String FULL_NAME { get { return 'Discount_Settings__mdt.Default'; } }
        public String LABEL { get { return 'Default'; } }
        public String DEVELOPER_NAME { get { return 'Default'; } }
    }

    public class Field {
        public String STRATEGY { get { return 'Discount_Strategy__c'; } }
        public String MIN_PCT { get { return 'Minimum_Discount_Percentage__c'; } }
    }
}
