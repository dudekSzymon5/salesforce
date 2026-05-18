public class ProductSyncBeforeDelete implements TriggerAction.BeforeDelete {
    public void beforeDelete(List<Product2> oldList) {
        for (Product2 product : oldList) {
            product.addError('Use the soft delete option instead classic delete');
        }
    }
}
