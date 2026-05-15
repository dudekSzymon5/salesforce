public class ProductSyncUtils {

    public Api API { get { return new Api(); } }
    public Status STATUS { get { return new Status(); } }
    public Operation OPERATION { get { return new Operation(); } }

    public class Api {
        public String NAMED_CREDENTIAL { get { return 'callout:Org_B_API'; } }
        public String ENDPOINT { get { return '/services/apexrest/v1/products/'; } }
        public Integer TIMEOUT { get { return 120000; } }
    }

    public class Status {
        public String SUCCESS { get { return 'Success'; } }
        public String FAILED { get { return 'Failed'; } }
        public String PENDING { get { return 'Pending'; } }
    }

    public class Operation {
        public String INSERT_OP { get { return 'INSERT'; } }
        public String UPDATE_OP { get { return 'UPDATE'; } }
        public String DELETE_OP { get { return 'DELETE'; } }
    }
}
