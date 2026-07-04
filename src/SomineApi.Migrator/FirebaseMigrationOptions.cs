internal sealed class FirebaseMigrationOptions
{
    private static readonly string[] DefaultModules =
    [
        "users",
        "categories",
        "items",
        "reminders",
        "notifications",
        "shares"
    ];

    public bool Commit { get; init; }
    public bool IncludeFirebaseAuthUsers { get; init; } = true;
    public int AuthPageSize { get; init; } = 1000;
    public IReadOnlySet<string> Modules { get; init; } = DefaultModules.ToHashSet(StringComparer.OrdinalIgnoreCase);

    public bool ShouldRun(string moduleName) => Modules.Contains(moduleName);

    public static FirebaseMigrationOptions Parse(string[] args)
    {
        var commit = false;
        var includeFirebaseAuthUsers = true;
        var authPageSize = 1000;
        IReadOnlySet<string> modules = DefaultModules.ToHashSet(StringComparer.OrdinalIgnoreCase);

        foreach (var rawArg in args)
        {
            var arg = rawArg.Trim();

            if (arg.Equals("--commit", StringComparison.OrdinalIgnoreCase))
            {
                commit = true;
                continue;
            }

            if (arg.Equals("--skip-auth-users", StringComparison.OrdinalIgnoreCase))
            {
                includeFirebaseAuthUsers = false;
                continue;
            }

            if (arg.StartsWith("--modules=", StringComparison.OrdinalIgnoreCase))
            {
                var value = arg["--modules=".Length..];
                var selectedModules = value
                    .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                    .Select(module => module.ToLowerInvariant())
                    .ToHashSet(StringComparer.OrdinalIgnoreCase);

                if (selectedModules.Count == 0)
                {
                    throw new ArgumentException("--modules requires at least one module.");
                }

                modules = selectedModules;
                continue;
            }

            if (arg.StartsWith("--auth-page-size=", StringComparison.OrdinalIgnoreCase))
            {
                var value = arg["--auth-page-size=".Length..];
                if (!int.TryParse(value, out authPageSize) || authPageSize <= 0 || authPageSize > 1000)
                {
                    throw new ArgumentException("--auth-page-size must be between 1 and 1000.");
                }

                continue;
            }

            if (arg.Equals("--help", StringComparison.OrdinalIgnoreCase) ||
                arg.Equals("-h", StringComparison.OrdinalIgnoreCase))
            {
                PrintUsage();
                Environment.Exit(0);
            }

            throw new ArgumentException($"Unknown argument: {arg}");
        }

        return new FirebaseMigrationOptions
        {
            Commit = commit,
            IncludeFirebaseAuthUsers = includeFirebaseAuthUsers,
            AuthPageSize = authPageSize,
            Modules = modules
        };
    }

    private static void PrintUsage()
    {
        Console.WriteLine("SoMine Firebase content migration");
        Console.WriteLine("  --commit                Persist changes. Default is dry-run with rollback.");
        Console.WriteLine("  --modules=...           Comma-separated subset: users,categories,items,reminders,notifications,shares");
        Console.WriteLine("  --skip-auth-users       Skip Firebase Auth user export backfill.");
        Console.WriteLine("  --auth-page-size=1000   Firebase Auth page size, max 1000.");
    }
}
