"""Package only Asset Medic's public source and built artifacts."""
from pathlib import Path
import hashlib
import zipfile

root = Path(__file__).resolve().parents[1]
dist = root / "dist"
archive = dist / "AssetMedic-0.1.0-source.zip"
directories = ("src", "tests", "scripts", "docs", ".github")
files = ["README.md", "CONTRIBUTING.md", "CHANGELOG.md", "LICENSE", ".gitignore",
         "package.json", "package-lock.json", "rokit.toml", "default.project.json", "fixture.project.json"]
paths = [root / name for name in files]
for directory in directories:
    paths.extend(p for p in (root / directory).rglob("*") if p.is_file() and "__pycache__" not in p.parts)
with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as output:
    for file in sorted(paths):
        output.write(file, "asset-medic/" + file.relative_to(root).as_posix())
with zipfile.ZipFile(archive) as output:
    assert output.testzip() is None
    assert all("node_modules/" not in name and "/.git/" not in name for name in output.namelist())
    count = len(output.namelist())
artifacts = [dist / "AssetMedic-0.1.0.rbxmx", dist / "AssetMedic-TestPlace.rbxlx", archive]
checksums = "".join(f"{hashlib.sha256(file.read_bytes()).hexdigest()}  {file.name}\n" for file in artifacts)
(dist / "SHA256SUMS.txt").write_text(checksums, encoding="utf-8")
print(f"Packaged {count} source files; verified ZIP and checksums for {len(artifacts)} artifacts")
