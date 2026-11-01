"""Verify Rojo's output contains the exact sources we ship, not a stale build."""
from pathlib import Path
import json
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
version = json.loads((root / "package.json").read_text())["version"]
artifact = root / "dist" / f"AssetMedic-{version}.rbxmx"
tree = ET.parse(artifact).getroot()
items = tree.findall("Item")
assert len(items) == 1 and items[0].attrib["class"] == "Script"
plugin = items[0]
assert plugin.find("Properties/string[@name='Name']").text == "AssetMedic"
assert plugin.find("Properties/string[@name='Source']").text == (root / "src/init.server.luau").read_text(encoding="utf-8")
modules = {item.find("Properties/string[@name='Name']").text: item for item in plugin.findall("Item")}
expected = {file.stem: file for file in (root / "src").glob("*.luau") if file.name != "init.server.luau"}
assert set(modules) == set(expected), (set(modules), set(expected))
for name, file in expected.items():
    assert modules[name].attrib["class"] == "ModuleScript", name
    assert modules[name].find("Properties/string[@name='Source']").text == file.read_text(encoding="utf-8"), name
print(f"Artifact verified: root Script and {len(modules)} exact-source modules ({artifact.stat().st_size} bytes)")
