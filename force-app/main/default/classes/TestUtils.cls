public class TestUtils {

    public ProductTest PRODUCT { get { return new ProductTest(); } }
    public DiscountTest DISCOUNT { get { return new DiscountTest(); } }
    public QueueTest QUEUE { get { return new QueueTest(); } }

    public class ProductTest {
        public String DEFAULT_NAME { get { return 'Test Product'; } }
        public String DEFAULT_EXT_ID { get { return 'EXT-001'; } }
        public String DEFAULT_ORG_ID { get { return '00DTEST000000001'; } }
        public String DEFAULT_CODE { get { return 'PROD-001'; } }
        public String DEFAULT_FAMILY { get { return 'Software'; } }
    }

    public class DiscountTest {
        public String DEFAULT_NAME { get { return 'Test Discount'; } }
        public Decimal DEFAULT_VALUE { get { return 10.0; } }
    }

    public class QueueTest {
        public String DEFAULT_PAYLOAD { get { return '{"test":"payload"}'; } }
    }
}
