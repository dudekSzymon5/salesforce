public class RaceTireDataImportUtils {

    public Status STATUS { get { return new Status(); } }
    public TireCompound TIRE_COMPOUND { get { return new TireCompound(); } }

    public class Status {
        public String SUCCESS { get { return 'success'; } }
        public String ERROR { get { return 'error'; } }
    }

    public class TireCompound {
        public Set<String> VALID { get { return new Set<String>{ 'Soft', 'Medium', 'Hard' }; } }
    }
}
