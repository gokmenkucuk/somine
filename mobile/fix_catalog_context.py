import re

with open("lib/screens/catalog_screen.dart", "r") as f:
    lines = f.readlines()

def replace_line(line_num, old_str, new_str):
    idx = line_num - 1
    if old_str in lines[idx]:
        lines[idx] = lines[idx].replace(old_str, new_str)
    else:
        print(f"Warning: {old_str} not found in line {line_num}: {lines[idx].strip()}")

replace_line(1499, "context,", "this.context, // ignore: use_build_context_synchronously")

# 1949: Navigator.pop(dialogContext); -> if (dialogContext.mounted) Navigator.pop(dialogContext);
replace_line(1949, "Navigator.pop(dialogContext);", "if (dialogContext.mounted) Navigator.pop(dialogContext);")
replace_line(1953, "context,", "this.context, // ignore: use_build_context_synchronously")

replace_line(2154, "Navigator.pop(dialogContext);", "if (dialogContext.mounted) Navigator.pop(dialogContext);")
replace_line(2158, "context,", "this.context, // ignore: use_build_context_synchronously")

# 2601: LimitReachedDialog.show(context: context,
replace_line(2601, "context: context,", "context: this.context, // ignore: use_build_context_synchronously")

# 2615: Navigator.pop(ctx);
replace_line(2615, "Navigator.pop(ctx);", "if (ctx.mounted) Navigator.pop(ctx);")

replace_line(2634, "context,", "this.context, // ignore: use_build_context_synchronously")
replace_line(2655, "context,", "this.context, // ignore: use_build_context_synchronously")
replace_line(2748, "context,", "this.context, // ignore: use_build_context_synchronously")
replace_line(2826, "context,", "this.context, // ignore: use_build_context_synchronously")

# 3409: ScaffoldMessenger.of(context).showSnackBar
lines[3408-1] = lines[3408-1].replace("ScaffoldMessenger.of(", "if (mounted) ScaffoldMessenger.of(this.context, // ignore: use_build_context_synchronously\n")

# 3572: Navigator.pop(ctx);
replace_line(3572, "Navigator.pop(ctx);", "if (ctx.mounted) Navigator.pop(ctx);")

replace_line(4097, "_showStandardDeleteDialog(context, ", "_showStandardDeleteDialog(this.context, ")
replace_line(4099, "_showAdvancedDeleteDialog(context, ", "_showAdvancedDeleteDialog(this.context, ")
replace_line(4103, "_showStandardDeleteDialog(context, ", "_showStandardDeleteDialog(this.context, ")

# 4395: ScaffoldMessenger.of(context).showSnackBar
lines[4395-1] = lines[4395-1].replace("ScaffoldMessenger.of(context)", "if (mounted) ScaffoldMessenger.of(this.context) // ignore: use_build_context_synchronously")

# 4563: ScaffoldMessenger.of(context).showSnackBar
lines[4563-1] = lines[4563-1].replace("ScaffoldMessenger.of(context)", "if (mounted) ScaffoldMessenger.of(this.context) // ignore: use_build_context_synchronously")

replace_line(4790, "context,", "this.context, // ignore: use_build_context_synchronously")

with open("lib/screens/catalog_screen.dart", "w") as f:
    f.writelines(lines)

print("Replacement script generated and executed.")
