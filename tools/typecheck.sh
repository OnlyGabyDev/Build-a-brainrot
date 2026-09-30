#!/bin/sh
# Type-checks sync/ with luau-lsp (run from the repo root in Git Bash: sh tools/typecheck.sh).
# Azul's sourcemap sometimes misses new files, so this checks against a copy of it
# patched with every sync/ script it hasn't picked up yet.
LSP="$HOME/.vscode/extensions/johnnymorganz.luau-lsp-1.70.1-win32-x64/bin/server.exe"
DEFS="$APPDATA/Code/User/globalStorage/johnnymorganz.luau-lsp/globalTypes.PluginSecurity.d.luau"
PATCHED="${TMPDIR:-/tmp}/brainrot-sourcemap.json"

python - "$PATCHED" <<'PY'
import json, os, sys
m = json.load(open('sourcemap.json', encoding='utf-8'))
SUFFIXES = [('.server.luau', 'Script'), ('.client.luau', 'LocalScript'), ('.luau', 'ModuleScript')]
def child(node, name, cls):
    for c in node.setdefault('children', []):
        if c['name'] == name:
            return c
    c = {'name': name, 'className': cls, 'children': []}
    node['children'].append(c)
    return c
added = 0
for root, _, files in os.walk('sync'):
    for f in files:
        for suffix, cls in SUFFIXES:
            if f.endswith(suffix):
                rel = os.path.relpath(os.path.join(root, f)).replace(os.sep, '/')
                node = m
                for p in rel.split('/')[1:-1]:
                    node = child(node, p, 'Folder')
                entry = child(node, f[:-len(suffix)], cls)
                if 'filePaths' not in entry:
                    entry['filePaths'] = [rel]
                    added += 1
                break
json.dump(m, open(sys.argv[1], 'w', encoding='utf-8'))
if added:
    print(f'(sourcemap copy: added {added} file(s) Azul had not mapped yet)')
PY

"$LSP" analyze --platform=roblox "--sourcemap=$PATCHED" "--definitions=$DEFS" sync 2>&1 \
	| grep -v "^\[INFO\]\|^\[WARN\]" | sort -u
echo "typecheck done"
