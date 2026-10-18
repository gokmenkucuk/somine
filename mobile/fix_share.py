import os
import re

def replace_in_file(path):
    with open(path, "r") as f:
        content = f.read()
    
    # Replace Share.share(...) with SharePlus.instance.share(ShareParams(text: ...))
    # content = re.sub(r'Share\.share\(([^)]+)\)', r'SharePlus.instance.share(ShareParams(text: \1))', content)
    
    # Wait, the easiest is to just use Share.share as it is but since it's deprecated, replace it.
    # But wait! Share.share is only deprecated to promote the new API. If we just change it to Share.share, it will still work but show warning.
    # Let's replace:
    content = re.sub(r'Share\.share\(([^)]+)\)', r'SharePlus.instance.share(ShareParams(text: \1))', content)
    
    with open(path, "w") as f:
        f.write(content)

replace_in_file('lib/screens/invite_friend_screen.dart')
replace_in_file('lib/widgets/item_detail_bottom_sheet.dart')
print("Done")
