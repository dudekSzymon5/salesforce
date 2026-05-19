public class OrderComplaintUtils {

    public CaseStatus CASE_STATUS { get { return new CaseStatus(); } }
    public CaseOrigin CASE_ORIGIN { get { return new CaseOrigin(); } }
    public RefundStatus REFUND_STATUS { get { return new RefundStatus(); } }
    public RefundType REFUND_TYPE { get { return new RefundType(); } }
    public ApprovalAction APPROVAL_ACTION { get { return new ApprovalAction(); } }

    public class CaseStatus {
        public String NEW_CASE { get { return 'New'; } }
    }

    public class CaseOrigin {
        public String WEB { get { return 'Web'; } }
    }

    public class RefundStatus {
        public String PENDING { get { return 'Pending'; } }
    }

    public class RefundType {
        public String REJECTED { get { return 'Rejected'; } }
    }

    public class ApprovalAction {
        public String APPROVE { get { return 'Approve'; } }
        public String REJECT { get { return 'Reject'; } }
    }
}
