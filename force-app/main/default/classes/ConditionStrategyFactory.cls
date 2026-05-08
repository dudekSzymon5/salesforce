public class ConditionStrategyFactory {

    public static IConditionStrategy forCondition(String conditionType) {
        if (conditionType == Utils.DISCOUNT.CONDITION.MIN_ORDER_VALUE) return new MinOrderValueStrategy();
        if (conditionType == Utils.DISCOUNT.CONDITION.TWO_FOR_ONE)     return new TwoForOneStrategy();
        return null;
    }
}
