public class ProductSyncUtils {

    public final ApiConst    API    = new ApiConst();
    public final StatusConst STATUS = new StatusConst();

    public class ApiConst {
        public String  NAMED_CREDENTIAL { get { return 'callout:Org_B_API'; } }
        public String  ENDPOINT         { get { return '/services/apexrest/v1/products/'; } }
        public Integer TIMEOUT          { get { return 120000; } }
    }

    public class StatusConst {
        public String SUCCESS { get { return 'Success'; } }
        public String FAILED  { get { return 'Failed'; } }
    }
}
