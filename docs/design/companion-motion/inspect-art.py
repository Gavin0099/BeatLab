"""Read-only alpha/cell registration; never edits generated pixels."""
import hashlib, json
from pathlib import Path
from PIL import Image
root = Path(__file__).resolve().parents[3]
result = {}
for name in ['CatMotionAtlas', 'RobotMotionAtlas']:
    path = root / 'BeatLab/Resources/Assets.xcassets' / (name + '.imageset/artwork.png')
    source = Image.open(path)
    alpha = source.getchannel('A')
    frames = []
    # Reviewed empty alpha gutters: generated cat rows are not a perfect grid.
    rows = [0, 280, 534, 828, 1082, 1328, 1536] if name == 'CatMotionAtlas' else [0, 256, 512, 768, 1024, 1280, 1536]
    for index in range(24):
        x, y = index % 4, index // 4
        box = [round(x*source.width/4), rows[y], round((x+1)*source.width/4), rows[y+1]]
        cell = source.crop(box)
        bbox = cell.getchannel('A').point(lambda a: 255 if a > 100 else 0).getbbox()
        assert bbox and bbox[2] > bbox[0] and bbox[3] > bbox[1]
        frames.append(dict(index=index, cell=[box[0],box[1],box[2]-box[0],box[3]-box[1]], bbox=bbox, rgba_sha256=hashlib.sha256(cell.tobytes()).hexdigest()))
    assert len({f['rgba_sha256'] for f in frames[:8]}) == 8
    assert alpha.histogram()[0] > source.width*source.height*.3
    result[name] = dict(size=source.size, mode=source.mode, sha256=hashlib.sha256(path.read_bytes()).hexdigest(), transparent_pixels=alpha.histogram()[0], frames=frames)
(Path(__file__).parent/'art-source.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({k:dict(size=v['size'],transparent_pixels=v['transparent_pixels'],bounds=[f['bbox'] for f in v['frames']]) for k,v in result.items()}))
