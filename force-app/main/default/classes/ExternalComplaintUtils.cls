public class ExternalComplaintUtils {

    public Api API { get {return new Api();} }
    public ResponseStatus RESPONSE_STATUS { get {return new ResponseStatus();} }

    public class Api {
        public String FORWARD_ENDPOINT { get {return 'callout:Org_B_API/services/data/v60.0/sobjects/External_Complaint__e';} }
        public String RESPONSE_ENDPOINT { get {return 'callout:Org_B_API/services/data/v60.0/sobjects/External_Complaint_Response__e';} }
    }

    public class ResponseStatus {
        public String CREATED { get {return 'Created';} }
        public String APPROVED { get {return 'Approved';} }
        public String REJECTED { get {return 'Rejected';} }
        public String APPROVED_FULL { get {return 'Approved Full Refund';} }
        public String APPROVED_PARTIAL { get {return 'Approved Partial Refund';} }
    }
}
