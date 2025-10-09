public with sharing class AzureDevOpsCacheUtil {
    public interface CacheSupplier { Object compute(); }
    public static Object getOrCompute(String key, Integer ttlSeconds, CacheSupplier supplier) {
        try {
            Cache.OrgPartition partition = Cache.Org.getPartition(null);
            Object existing = partition.get(key);
            if (existing != null) {
                return existing;
            }
            Object value = supplier == null ? null : supplier.compute();
            if (value != null) {
                if (ttlSeconds != null && ttlSeconds > 0) {
                    partition.put(key, value, ttlSeconds);
                } else {
                    partition.put(key, value);
                }
            }
            return value;
        } catch (Exception ex) {
            return inMemoryGetOrCompute(key, ttlSeconds, supplier);
        }
    }
    private class CacheEntry {
        public Object value; public Long expiresAt;
        public CacheEntry(Object v, Long expiresAt) { this.value = v; this.expiresAt = expiresAt; }
    }
    // Static cache map for fallback when platform cache is unavailable
    @SuppressWarnings('PMD.FieldNamingConventions')
    private static Map<String, CacheEntry> MEM = new Map<String, CacheEntry>();
    private static Object inMemoryGetOrCompute(String key, Integer ttlSeconds, CacheSupplier supplier) {
        if (MEM.containsKey(key)) {
            CacheEntry e = MEM.get(key);
            if (e.expiresAt == null || e.expiresAt > DateTime.now().getTime()) {
                return e.value;
            }
            MEM.remove(key);
        }
        Object v = supplier == null ? null : supplier.compute();
        MEM.put(key, new CacheEntry(v, ttlSeconds == null ? null : DateTime.now().getTime() + (ttlSeconds * 1000)));
        return v;
    }
}