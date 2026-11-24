"""Inspect/apply the reviewed v23 Boundless citizen-return hotfix; default is read-only."""
from pathlib import Path
from datetime import datetime, timezone
from xml.etree import ElementTree as ET
import argparse, hashlib, re, subprocess

ROOT = Path(__file__).resolve().parents[1]
MOD_ID = 'f6859d5b-50bf-4a7e-b5d3-bdc2d6e69392'
MANIFEST = 'Cool Wacky Civs 2 (v 23).modinfo'
ORIGINALS = {
    'BoundlessCitizens.lua': '40a4924d749a82f8da617026f3ee142dca6ade732028afd1d41027edb4fa8cad',
    'BoundlessPlanner.lua': '938591ab42015a7992168790eea1befade5fd8016325ac91cbe5158e4ab1d2ac',
    'BoundlessPersistence.lua': 'fc2f6e68b2377665d5b342fe4cbaded646d0a00659b1416ef07c385eb4375a4b',
}
# The first deployed repair predates journaling completed withdrawals.
PREVIOUS_PATCHED = {
    'BoundlessCitizens.lua': '2caba65549690d81c366e4990182e4d9a807567cd1c89de2527378d7b223cf52',
}

def update_manifest(data, replacements):
    text = data.decode('utf-8')
    for relative, payload in replacements.items():
        pattern = r'<File\b[^>]*>' + re.escape(relative) + r'</File>'
        def replace(match):
            value, count = re.subn(r'md5="[0-9A-Fa-f]{32}"',
                                   'md5="' + hashlib.md5(payload).hexdigest().upper() + '"', match[0])
            if count != 1:
                raise ValueError('Missing/ambiguous MD5: ' + relative)
            return value
        text, count = re.subn(pattern, replace, text)
        if count != 1:
            raise ValueError('Missing/ambiguous file entry: ' + relative)
    return text.encode('utf-8')

def plan(target):
    target = target.resolve(strict=True)
    manifest = target / MANIFEST
    before = {MANIFEST: manifest.read_bytes()}
    parsed = ET.fromstring(before[MANIFEST])
    if parsed.get('id', '').lower() != MOD_ID or parsed.get('version') != '23':
        raise ValueError('Expected the reviewed Cool Wacky Civs 2 v23 UUID and version')
    entries = {row.text: row.get('md5', '').lower() for row in parsed.findall('Files/File')}
    replacements = {}
    for name, original_hash in ORIGINALS.items():
        relative = 'TheBoundlessCity/Lua/' + name
        path = target / relative
        if not path.resolve(strict=True).is_relative_to(target):
            raise ValueError('Target file escapes the mod directory')
        old, new = path.read_bytes(), (ROOT / relative).read_bytes()
        reviewed = {original_hash, PREVIOUS_PATCHED.get(name), hashlib.sha256(new).hexdigest()}
        if hashlib.sha256(old).hexdigest() not in reviewed:
            raise ValueError('Unreviewed installed source: ' + relative)
        if entries.get(relative) != hashlib.md5(old).hexdigest():
            raise ValueError('Installed manifest checksum mismatch: ' + relative)
        before[relative] = old
        replacements[relative] = new
    after = {**replacements, MANIFEST: update_manifest(before[MANIFEST], replacements)}
    return before, after

def apply(target, before, after, backup_root=None):
    # Refuse writes while a native session could retain the old Lua contexts.
    processes = subprocess.run(['tasklist', '/FO', 'CSV', '/NH'], check=True,
                               capture_output=True, text=True).stdout.lower()
    if any(name in processes for name in ('civilizationv.exe', 'civilizationv_dx11.exe', 'civilizationv_tablet.exe')):
        raise ValueError('Exit Civilization V before applying the hotfix')
    if all(before[name] == data for name, data in after.items()):
        print('Already installed; no files changed')
        return None
    backup_root = backup_root or ROOT / 'dist/turn135-backups'
    backup = backup_root / datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    for name, data in before.items():
        path = backup / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
    # Recheck after backup, then install only the three Lua files and their MD5s.
    if any((target / name).read_bytes() != data for name, data in before.items()):
        raise ValueError('Installed files changed during preflight; no patch written')
    try:
        for name, data in after.items():
            (target / name).write_bytes(data)
        if any((target / name).read_bytes() != data for name, data in after.items()):
            raise ValueError('Post-install byte verification failed')
    except Exception:
        for name, data in before.items():
            (target / name).write_bytes(data)
        raise
    print('Installed and verified three Lua files plus manifest MD5s')
    print('Backup:', backup)
    return backup

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--mod-dir', type=Path, default=Path.home() /
                        "Documents/My Games/Sid Meier's Civilization 5/MODS/Cool Wacky Civs 2 (v 23)")
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    target = args.mod_dir.resolve(strict=True)
    before, after = plan(target)
    print('Target:', target)
    print('Files needing changes:', sum(before[name] != data for name, data in after.items()))
    if args.apply:
        apply(target, before, after)
    else:
        print('Read-only check complete; use --apply to install')

if __name__ == '__main__':
    main()
