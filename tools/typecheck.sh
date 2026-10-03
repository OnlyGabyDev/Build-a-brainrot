#!/bin/sh
# Type-checks sync/ with luau-lsp (run from the repo root in Git Bash: sh tools/typecheck.sh).
# Azul's sourcemap sometimes misses new files, so this checks against a copy of it
# patched with every sync/ script it hasn't picked up yet.
# luau-lsp comes from the VS Code extension (Luau Language Server) or, without it, from
# %LOCALAPPDATA%/luau-lsp: the release's luau-lsp.exe next to globalTypes.PluginSecurity.d.luau
# (github.com/JohnnyMorganz/luau-lsp, scripts/ folder). Elsewhere (Linux, a cloud
# session) set LUAU_LSP and LUAU_DEFS to the binary and the definitions file.
# Without Azul's sourcemap.json (it's generated, not committed) the map is built from
# sync/ alone.
LSP="${LUAU_LSP:-}"
[ -n "$LSP" ] || LSP=$(ls "$HOME"/.vscode/extensions/johnnymorganz.luau-lsp-*/bin/server.exe 2>/dev/null | tail -n 1)
[ -n "$LSP" ] || LSP="$LOCALAPPDATA/luau-lsp/luau-lsp.exe"
DEFS="${LUAU_DEFS:-$APPDATA/Code/User/globalStorage/johnnymorganz.luau-lsp/globalTypes.PluginSecurity.d.luau}"
[ -f "$DEFS" ] || DEFS="$LOCALAPPDATA/luau-lsp/globalTypes.PluginSecurity.d.luau"
PYTHON=$(command -v python || command -v python3)
for need in "$LSP" "$DEFS"; do
	if [ ! -f "$need" ]; then
		echo "typecheck FAILED: missing $need"
		exit 1
	fi
done
PATCHED="${TMPDIR:-/tmp}/brainrot-sourcemap.json"

"$PYTHON" - "$PATCHED" <<'PY'
import json, os, sys
if os.path.exists('sourcemap.json'):
    m = json.load(open('sourcemap.json', encoding='utf-8'))
else:
    # the services our code lives in (their classes matter to the type checker)
    m = {'name': 'Game', 'className': 'DataModel', 'children': [
        {'name': 'ReplicatedFirst', 'className': 'ReplicatedFirst', 'children': []},
        {'name': 'ReplicatedStorage', 'className': 'ReplicatedStorage', 'children': []},
        {'name': 'ServerScriptService', 'className': 'ServerScriptService', 'children': []},
        {'name': 'ServerStorage', 'className': 'ServerStorage', 'children': []},
        {'name': 'StarterPlayer', 'className': 'StarterPlayer', 'children': [
            {'name': 'StarterPlayerScripts', 'className': 'StarterPlayerScripts', 'children': []},
        ]},
        {'name': 'Workspace', 'className': 'Workspace', 'children': []},
    ]}
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
