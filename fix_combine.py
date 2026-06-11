import os
import re

directory = 'airsync-mac'

for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith('.swift'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r') as f:
                content = f.read()
            
            # Replace 'import Combine' with 'internal import Combine'
            # but only if it's exactly 'import Combine' or '@preconcurrency import Combine'
            new_content = re.sub(r'^import Combine$', 'internal import Combine', content, flags=re.MULTILINE)
            new_content = re.sub(r'^@preconcurrency import Combine$', '@preconcurrency internal import Combine', new_content, flags=re.MULTILINE)
            
            if new_content != content:
                with open(filepath, 'w') as f:
                    f.write(new_content)
                print(f"Fixed {filepath}")

