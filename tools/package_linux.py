"""Package the standalone Linux build and its notices."""
import hashlib
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parent.parent
binary = root / 'build/linux/AtriumStrike.x86_64'
assert binary.is_file(), 'Export the Linux Desktop preset first'
header = binary.read_bytes()[:20]
assert header[:6] == b'\x7fELF\x02\x01', 'Not a little-endian ELF64 executable'
assert int.from_bytes(header[18:20], 'little') == 62, 'Not x86-64'
binary.chmod(0o755)
output = root / 'downloads/AtriumStrike-Linux-x64.zip'
output.parent.mkdir(exist_ok=True)
with ZipFile(output, 'w', ZIP_DEFLATED, compresslevel=9) as archive:
    archive.write(binary, 'AtriumStrike/AtriumStrike.x86_64')
    archive.write(root / 'docs/LINUX.txt', 'AtriumStrike/ISHGA-TUSHIRISH.txt')
    archive.write(root / 'THIRD_PARTY_NOTICES.md', 'AtriumStrike/THIRD_PARTY_NOTICES.md')
    archive.write(root / 'GODOT-COPYRIGHT.txt', 'AtriumStrike/GODOT-COPYRIGHT.txt')
(root / 'downloads/SHA256SUMS.txt').write_text(''.join(
    f'{hashlib.sha256(package.read_bytes()).hexdigest()}  {package.name}\n'
    for package in sorted((root / 'downloads').glob('AtriumStrike-*.zip'))
))
print(f'Linux archive: {output.name} ({output.stat().st_size:,} bytes)')
print(f'SHA256: {hashlib.sha256(output.read_bytes()).hexdigest()}')
