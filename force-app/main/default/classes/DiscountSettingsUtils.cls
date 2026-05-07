public class DiscountSettingsUtils {

    public String FULL_NAME      { get { return 'Discount_Settings__mdt.Default'; } }
    public String LABEL          { get { return 'Default'; } }
    public String DEVELOPER_NAME { get { return 'Default'; } }

    public final FieldConst FIELD = new FieldConst();

    public class FieldConst {
        public String STRATEGY { get { return 'Discount_Strategy__c'; } }
        public String MIN_PCT  { get { return 'Minimum_Discount_Percentage__c'; } }
    }
}
