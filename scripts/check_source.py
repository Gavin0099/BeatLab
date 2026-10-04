"""Source syntax/structure checks only. Does not typecheck Swift or run an iOS app."""
from pathlib import Path
import hashlib
import json
import os
import plistlib
import re
import struct
import xml.etree.ElementTree as ET
from openstep_parser import OpenStepDecoder
from tree_sitter import Language, Parser
import tree_sitter_swift

root = Path(__file__).resolve().parents[1]
os.chdir(root)
project = OpenStepDecoder.ParseFromString(Path('BeatLab.xcodeproj/project.pbxproj').read_text(encoding='utf-8'))
objects = project['objects']
targets = objects[project['rootObject']]['targets']
assert len(targets) == 3
for target in targets:
    item = objects[target]
    expected = {p.as_posix() for p in Path(item['name']).rglob('*.swift')}
    actual = set()
    for phase in item['buildPhases']:
        for build in objects[phase]['files']:
            entry = objects[build]
            if 'fileRef' in entry:
                reference = objects[entry['fileRef']]
                assert Path(reference['path']).exists(), reference
                if objects[phase]['isa'] == 'PBXSourcesBuildPhase': actual.add(reference['path'])
            else:
                dependency = objects[entry['productRef']]
                assert dependency['productName'] in ['BeatLabCore', 'BeatLabDSP']
                assert (Path(objects[dependency['package']]['relativePath']) / 'Package.swift').exists()
    assert actual == expected, (item['name'], expected - actual, actual - expected)
    if item['name'] != 'BeatLabUITests':
        assert {objects[p]['productName'] for p in item['packageProductDependencies']} == {'BeatLabCore', 'BeatLabDSP'}
scheme = ET.parse('BeatLab.xcodeproj/xcshareddata/xcschemes/BeatLab.xcscheme')
assert len(scheme.findall('./TestAction/Testables/TestableReference')) == 2
for ref in scheme.iter('BuildableReference'): assert ref.attrib['BlueprintIdentifier'] in targets
ET.parse('BeatLab.xcodeproj/project.xcworkspace/contents.xcworkspacedata')
privacy = plistlib.loads(Path('BeatLab/Resources/PrivacyInfo.xcprivacy').read_bytes())
assert privacy['NSPrivacyTracking'] is False
for path in Path('BeatLab/Resources').rglob('*.json'): json.loads(path.read_text())
for path in Path('BeatLab').rglob('*.swift'):
    for name in re.findall(r'Color\("([^"\n]+)"\)', path.read_text(encoding='utf-8')):
        assert Path(f'BeatLab/Resources/Assets.xcassets/{name}.colorset/Contents.json').exists(), (path, name)
icon = Path('BeatLab/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png').read_bytes()
assert icon[:8] == b'\x89PNG\r\n\x1a\n'
assert struct.unpack('>II', icon[16:24]) == (1024, 1024) and icon[25] == 2
catalog = json.loads(Path('Sources/BeatLabCore/Resources/lessons.json').read_text(encoding='utf-8'))
assert catalog['schemaVersion'] == 1 and len(catalog['lessons']) == 10
assert len({lesson['id'] for lesson in catalog['lessons']}) == 10
for lesson in catalog['lessons']:
    pattern = lesson['pattern']
    assert pattern['stepsPerBeat'] in [1, 2, 3, 4]
    assert len(pattern['steps']) == 4 * pattern['stepsPerBeat']
    assert set(pattern['steps']) <= {'R', 'L', '-'} and set(pattern['steps']) != {'-'}
    assert 30 <= lesson['bpm'] <= 240 and 1 <= lesson['bars'] <= 16
parser = Parser(Language(tree_sitter_swift.language()))
swift_files = [Path('Package.swift')] + [p for base in ['Sources', 'Tests', 'BeatLab', 'BeatLabTests', 'BeatLabUITests'] for p in Path(base).rglob('*.swift')]
test_definitions = 0
for path in swift_files:
    raw = path.read_bytes()
    assert not parser.parse(raw).root_node.has_error, path
    text = raw.decode()
    assert not re.search(r'NSMicrophoneUsageDescription|CoreMIDI|Timer\.scheduledTimer', text), path
    test_definitions += len(re.findall(r'func\s+test\w+\s*\(', text))
assert 'UIBackgroundModes' not in Path('BeatLab.xcodeproj/project.pbxproj').read_text()
kernel = Path('Sources/BeatLabDSP/BeatLabDSP.c').read_text()
render = kernel.split('void BLDSPRender(', 1)[1].split('bool BLDSPReadClock(', 1)[0]
assert not re.search(r'\b(malloc|calloc|free|pthread_mutex_lock)\s*\(', render)
hashes = {p.as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for base in ['Sources', 'Tests', 'BeatLab', 'BeatLabTests', 'BeatLabUITests', 'BeatLab.xcodeproj', 'scripts'] for p in Path(base).rglob('*') if p.is_file() and '__pycache__' not in p.parts}
result = dict(scope='S0-S17 syntax and source/project structure only', result='PASS', swift_files_parsed=len(swift_files),
              swift_test_definitions=test_definitions, xcode_objects=len(objects), lesson_count=10,
              xcode_membership='PASS', asset_privacy_parse='PASS', excluded_capabilities='ABSENT',
              realtime_render_allocations='ABSENT IN INSPECTED FUNCTION', swift_typechecking='NOT RUN',
              swift_tests='NOT RUN', iOS_build_UI_tests='NOT RUN', device_gates='NOT RUN', source_sha256=hashes)
Path('docs/slices/MVP-source-check.json').write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
print(json.dumps({k:v for k,v in result.items() if k != 'source_sha256'}, indent=2))
