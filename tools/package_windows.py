"""Package the Windows build and its notices; run from the repository root."""
import hashlib
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parent.parent
exe = root / 'build/windows/AtriumStrike.exe'
assert exe.is_file(), 'Export the Windows Desktop preset first'
assert exe.read_bytes()[:2] == b'MZ', 'Not a Windows executable'
output = root / 'downloads/AtriumStrike-Windows-x64.zip'
output.parent.mkdir(exist_ok=True)
with ZipFile(output, 'w', ZIP_DEFLATED, compresslevel=9) as archive:
    archive.write(exe, 'AtriumStrike/AtriumStrike.exe')
    archive.write(root / 'docs/WINDOWS.txt', 'AtriumStrike/ISHGA-TUSHIRISH.txt')
    archive.write(root / 'THIRD_PARTY_NOTICES.md', 'AtriumStrike/THIRD_PARTY_NOTICES.md')
    archive.write(root / 'GODOT-COPYRIGHT.txt', 'AtriumStrike/GODOT-COPYRIGHT.txt')
checksum = hashlib.sha256(output.read_bytes()).hexdigest()
(root / 'downloads/SHA256SUMS.txt').write_text(''.join(
    f'{hashlib.sha256(package.read_bytes()).hexdigest()}  {package.name}\n'
    for package in sorted((root / 'downloads').glob('AtriumStrike-*.zip'))
))
print(f'Windows archive: {output.name} ({output.stat().st_size:,} bytes)')
print(f'SHA256: {checksum}')
