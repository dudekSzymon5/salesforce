@IsTest
public class TestDataFactory {
    public class ProductBuilder {
        private Product2 product = new Product2(
                Name = Utils.TEST.PRODUCT.DEFAULT_NAME,
                ProductCode = Utils.TEST.PRODUCT.DEFAULT_CODE,
                Family = Utils.TEST.PRODUCT.DEFAULT_FAMILY,
                IsActive = true,
                Is_External__c = false,
                Is_Deleted__c = false,
                External_Product_Id__c = null,
                External_Org_Id__c = null,
                Description = null,
                Language__c = null
        );

        public ProductBuilder withName(String productName) {
            product.Name = productName; return this;
        }
        public ProductBuilder withCode(String productCode) {
            product.ProductCode = productCode; return this;
        }
        public ProductBuilder withFamily(String productFamily) {
            product.Family = productFamily; return this;
        }
        public ProductBuilder withDescription(String productDescription) {
            product.Description = productDescription; return this;
        }
        public ProductBuilder withLanguage(String productLanguage) {
            product.Language__c = productLanguage; return this;
        }
        public ProductBuilder inactive() {
            product.IsActive = false; return this;
        }

        public ProductBuilder external() {
            product.Is_External__c = true;
            return this;
        }

        public ProductBuilder external(String newExternalId, String orgId) {
            product.Is_External__c = true;
            product.External_Product_Id__c = newExternalId;
            product.External_Org_Id__c = orgId;
            return this;
        }

        public ProductBuilder deleted() {
            product.Is_Deleted__c = true;
            product.Is_External__c = true;
            return this;
        }

        public Product2 build() {
            return product;
        }

        public Product2 create() {
            insert product;
            return product;
        }
    }

    public class DiscountBuilder {
        private Discount__c discount = new Discount__c(
                Name = Utils.TEST.DISCOUNT.DEFAULT_NAME,
                Type__c = Utils.DISCOUNT.TYPE.ONE_TIME,
                Discount_Form__c = Utils.DISCOUNT.FORM.PERCENTAGE,
                Value__c = Utils.TEST.DISCOUNT.DEFAULT_VALUE,
                Is_Active__c = true,
                Condition_Type__c = null,
                Recurrence_Pattern__c = null,
                Minimum_Order_Amount__c = null,
                Minimum_Quantity__c = null,
                Target_Application__c = null,
                Target_Families__c = null,
                Start_Date__c = null,
                End_Date__c = null
        );

        public DiscountBuilder withName(String discountName) {
            discount.Name = discountName; return this;
        }
        public DiscountBuilder withValue(Decimal discountValue) {
            discount.Value__c = discountValue; return this;
        }
        public DiscountBuilder asAmount() {
            discount.Discount_Form__c = Utils.DISCOUNT.FORM.AMOUNT; return this;
        }
        public DiscountBuilder inactive() {
            discount.Is_Active__c = false; return this;
        }
        public DiscountBuilder oneTime() {
            discount.Type__c = Utils.DISCOUNT.TYPE.ONE_TIME; return this;
        }
        public DiscountBuilder withMinOrder(Decimal minimumAmount) {
            discount.Minimum_Order_Amount__c = minimumAmount; return this;
        }
        public DiscountBuilder withMinQuantity(Decimal minimumQuantity) {
            discount.Minimum_Quantity__c = minimumQuantity; return this;
        }
        public DiscountBuilder forProducts() {
            discount.Target_Application__c = Utils.DISCOUNT.TARGET.PRODUCTS; return this;
        }
        public DiscountBuilder validFrom(Date startDate) {
            discount.Start_Date__c = startDate; return this;
        }
        public DiscountBuilder validUntil(Date endDate) {
            discount.End_Date__c = endDate; return this;
        }

        public DiscountBuilder recurring(String recurrencePattern) {
            discount.Type__c = Utils.DISCOUNT.TYPE.RECURRING;
            discount.Recurrence_Pattern__c = recurrencePattern;
            return this;
        }

        public DiscountBuilder conditional(String conditionType) {
            discount.Type__c = Utils.DISCOUNT.TYPE.CONDITIONAL;
            discount.Condition_Type__c = conditionType;
            return this;
        }

        public DiscountBuilder forFamilies(String familyList) {
            discount.Target_Application__c = Utils.DISCOUNT.TARGET.FAMILIES;
            discount.Target_Families__c = familyList;
            return this;
        }

        public Discount__c build() {
            return discount;
        }

        public Discount__c create() {
            insert discount;
            return discount;
        }
    }

    public class QueueBuilder {
        private Product_Sync_Queue__c record = new Product_Sync_Queue__c(
                Product__c = null,
                Operation__c = Utils.PRODUCT_SYNC.OPERATION.INSERT_OP,
                Payload__c = Utils.TEST.QUEUE.DEFAULT_PAYLOAD,
                Status__c = Utils.PRODUCT_SYNC.STATUS.FAILED,
                Attempt_Count__c = 1,
                Last_Attempt__c = DateTime.now().addHours(-1),
                Target_Org__c = Utils.PRODUCT_SYNC.API.NAMED_CREDENTIAL
        );

        public QueueBuilder forProduct(Id productId) {
            record.Product__c = productId; return this;
        }
        public QueueBuilder withAttempts(Integer attemptCount) {
            record.Attempt_Count__c = attemptCount; return this;
        }
        public QueueBuilder withPayload(String queuePayload) {
            record.Payload__c = queuePayload; return this;
        }

        public QueueBuilder asDelete(String externalId) {
            record.Operation__c = Utils.PRODUCT_SYNC.OPERATION.DELETE_OP;
            record.Product__c = null;
            record.Payload__c = externalId;
            return this;
        }

        public Product_Sync_Queue__c build() {
            return record;
        }

        public Product_Sync_Queue__c create() {
            insert record;
            return record;
        }
    }

    public class OrderBuilder {
        private Order order = new Order(
                AccountId = null,
                ContractId = null,
                Pricebook2Id = null,
                Status = 'Draft',
                EffectiveDate = Date.today()
        );
        private Boolean shouldActivate = false;

        public OrderBuilder forAccount(Id accountId) {
            order.AccountId = accountId; return this;
        }
        public OrderBuilder withContract(Id contractId) {
            order.ContractId = contractId; return this;
        }
        public OrderBuilder withPricebook(Id pricebookId) {
            order.Pricebook2Id = pricebookId; return this;
        }
        public OrderBuilder activated() {
            shouldActivate = true; return this;
        }

        public Order build() {
            if (order.Pricebook2Id == null) {
                order.Pricebook2Id = Test.getStandardPricebookId();
            }
            return order;
        }

        public Order create() {
            build();
            insert order;
            if (shouldActivate) {
                order.Status = 'Activated';
                update order;
            }
            return order;
        }
    }

    public class HttpMock implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        public HttpMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setBody(body);
            return response;
        }
    }

    public static ProductBuilder product() {
        return new ProductBuilder();
    }
    public static DiscountBuilder discount() {
        return new DiscountBuilder();
    }
    public static QueueBuilder queueRecord() {
        return new QueueBuilder();
    }
    public static OrderBuilder order() {
        return new OrderBuilder();
    }

    public static HttpMock httpSuccess() {
        return new HttpMock(200, '{"status":"success"}');
    }
    public static HttpMock httpSuccess(String body) {
        return new HttpMock(200, body);
    }
    public static HttpMock httpError() {
        return new HttpMock(500, '{"status":"error","message":"Internal Server Error"}');
    }
    public static HttpMock httpError(Integer statusCode, String body) {
        return new HttpMock(statusCode, body);
    }

    public static Account createAccount() {
        Account account = new Account(Name = 'Test Account');
        insert account;
        return account;
    }

    public static Opportunity createOpportunity(Id accountId) {
        Opportunity opportunity = new Opportunity(
                Name = 'Test Opportunity',
                AccountId = accountId,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Pricebook2Id = Test.getStandardPricebookId()
        );
        insert opportunity;
        return opportunity;
    }

    public static Contract createContract(Id accountId) {
        Contract contract = new Contract(
                AccountId = accountId,
                StartDate = Date.today(),
                ContractTerm = 12,
                Status = 'Draft'
        );
        insert contract;
        contract.Status = 'Activated';
        update contract;
        return contract;
    }

    public static PricebookEntry addToPricebook(Id productId, Decimal price) {
        PricebookEntry pricebookEntry = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = productId,
                UnitPrice = price,
                IsActive = true
        );
        insert pricebookEntry;
        return pricebookEntry;
    }

    public static void setupRestPost(String uri, String jsonBody) {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestURI = uri;
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);
    }

    public static void setupRestDelete(String uri) {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestURI = uri;
        RestContext.request.httpMethod = 'DELETE';
    }

    public static String buildProductPayload(String externalProductId, String externalOrgId, String productName) {
        return JSON.serialize(new Map<String, Object>{
                'externalProductId' => externalProductId,
                'externalOrgId' => externalOrgId,
                'name' => productName,
                'description' => 'Test Description',
                'productCode' => Utils.TEST.PRODUCT.DEFAULT_CODE,
                'family' => Utils.TEST.PRODUCT.DEFAULT_FAMILY,
                'language' => 'English'
        });
    }

    public class RaceTireRowBuilder {
        private Map<String, Object> row = new Map<String, Object>{
            'trackName'    => 'Silverstone',
            'raceCountry'  => 'United Kingdom',
            'raceName'     => 'British GP',
            'driver'       => 'Lewis Hamilton',
            'team'         => 'Ferrari',
            'tireCompound' => 'Hard',
            'laps'         => '38',
            'wearPercent'  => '46.3'
        };

        public RaceTireRowBuilder withTrackName(String trackName) {
            row.put('trackName', trackName); return this;
        }
        public RaceTireRowBuilder withRaceName(String raceName) {
            row.put('raceName', raceName); return this;
        }
        public RaceTireRowBuilder withDriver(String driver) {
            row.put('driver', driver); return this;
        }
        public RaceTireRowBuilder withTeam(String team) {
            row.put('team', team); return this;
        }
        public RaceTireRowBuilder withCompound(String compound) {
            row.put('tireCompound', compound); return this;
        }
        public RaceTireRowBuilder withLaps(String laps) {
            row.put('laps', laps); return this;
        }
        public RaceTireRowBuilder withWear(String wearPercent) {
            row.put('wearPercent', wearPercent); return this;
        }

        public Map<String, Object> build() {
            return row;
        }
    }

    public static RaceTireRowBuilder raceTireRow() {
        return new RaceTireRowBuilder();
    }

    public static String buildProductPayload(Product2 product) {
        String extId = String.isNotBlank(product.External_Product_Id__c) ? product.External_Product_Id__c : product.Id;
        return JSON.serialize(new Map<String, Object>{
                'externalProductId' => extId,
                'externalOrgId' => product.External_Org_Id__c,
                'name' => product.Name,
                'description' => product.Description,
                'productCode' => product.ProductCode,
                'family' => product.Family,
                'language' => product.Language__c
        });
    }
}