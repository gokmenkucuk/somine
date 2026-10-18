internal sealed class FirebaseMigrationReport
{
    public Dictionary<string, ModuleCounters> Modules { get; } = new(StringComparer.OrdinalIgnoreCase);
    public List<string> Warnings { get; } = [];

    public ModuleCounters For(string moduleName)
    {
        if (!Modules.TryGetValue(moduleName, out var counters))
        {
            counters = new ModuleCounters();
            Modules[moduleName] = counters;
        }

        return counters;
    }

    public void AddWarning(string warning) => Warnings.Add(warning);

    public sealed class ModuleCounters
    {
        public int Created { get; set; }
        public int Updated { get; set; }
        public int Skipped { get; set; }
    }
}
