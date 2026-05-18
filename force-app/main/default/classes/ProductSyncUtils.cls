public class ProductSyncUtils {

    public Api API { get { return new Api(); } }
    public Status STATUS { get { return new Status(); } }
    public Operation OPERATION { get { return new Operation(); } }
    public JobStatus JOB_STATUS { get { return new JobStatus(); } }

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

    public class JobStatus {
        public String QUEUED { get { return 'Queued'; } }
        public String HOLDING { get { return 'Holding'; } }
        public String PREPARING { get { return 'Preparing'; } }
        public String PROCESSING { get { return 'Processing'; } }
        public Set<String> ACTIVE { get { return new Set<String>{'Queued', 'Holding', 'Preparing', 'Processing'}; } }
    }
}
