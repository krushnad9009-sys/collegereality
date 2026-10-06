"""Hosting predeploy guard: refuse to deploy while [[PLACEHOLDER]] business details remain."""
import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent / 'hosting' / 'public'
found = []
for page in sorted(root.glob('*.html')):
    for label in sorted(set(re.findall(r'\[\[([^\]]+)\]\]', page.read_text(encoding='utf-8')))):
        found.append(f'  {page.name}: {label}')
if found:
    print('Hosting deploy blocked: fill in these business details first:')
    print('\n'.join(found))
    sys.exit(1)
print('Hosting pages: no placeholders left.')
