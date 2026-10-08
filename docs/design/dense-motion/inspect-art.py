"""Read-only image registration/provenance; source PNG bytes are never edited."""
import hashlib, json
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[3]
result = {}
errors = []
for theme, name in [('dinosaur','DenseDinosaurMotion'),('cat','DenseCatMotion'),('robot','DenseRobotMotion')]:
    path = root/'BeatLab/Resources/Assets.xcassets'/f'{name}.imageset/artwork.png'
    image = Image.open(path)
    assert image.mode == 'RGBA'
    frames=[]
    for index in range(32):
        x,y=index%8,index//8
        cellbox=[round(x*image.width/8),round(y*image.height/4),round((x+1)*image.width/8),round((y+1)*image.height/4)]
        cell=image.crop(cellbox)
        alpha=cell.getchannel('A'); solid=alpha.point(lambda a:255 if a>128 else 0)
        box=solid.getbbox(); assert box
        frames.append(dict(index=index,cell=cellbox,bounds=list(box),rgba_sha256=hashlib.sha256(cell.tobytes()).hexdigest(),transparent_pixels=alpha.histogram()[0]))
    height=frames[28]['bounds'][3]-frames[28]['bounds'][1]
    ready=image.crop(frames[28]['cell']); floor=frames[28]['bounds'][3]
    feet=ready.getchannel('A').crop((0,max(0,floor-round(height*.1)),ready.width,floor))
    weights=[sum(feet.getpixel((x,y)) for y in range(feet.height)) for x in range(feet.width)]
    foot_center=sum((x+.5)*v for x,v in enumerate(weights))/sum(weights)
    for f in frames:
        cell=image.crop(f['cell']); a=cell.getchannel('A'); top=f['bounds'][1]
        # Register the upper head mass, excluding tails, feet and held props.
        band=a.crop((0,top,cell.width,min(cell.height,top+round(height*.40))))
        sums=[0]*cell.width
        for y in range(band.height):
            for x in range(band.width):
                value=band.getpixel((x,y)); sums[x]+=value if value>128 else 0
        center=sum((x+.5)*v for x,v in enumerate(sums))/sum(sums)
        f['head_center_x']=round(center,4)
        f['baseline_y']=f['bounds'][3] if f['index'] >= 24 else top+height
        f['reference_height']=height
        f['touches_cell_edge']=f['bounds'][0]==0 or f['bounds'][1]==0 or f['bounds'][2]==cell.width or f['bounds'][3]==cell.height
    offset=foot_center-frames[28]['head_center_x']
    for f in frames:
        f['anchor_x']=round(f['head_center_x']+offset,4)
    if any(f['touches_cell_edge'] for f in frames): errors.append([theme,'cropped/gutter edge',[f['index'] for f in frames if f['touches_cell_edge']]])
    assert len({f['rgba_sha256'] for f in frames[:12]})==12
    assert len({f['rgba_sha256'] for f in frames[12:24]})==12
    assert image.getchannel('A').histogram()[0]>image.width*image.height*.3
    result[theme]=dict(asset=name,size=list(image.size),mode=image.mode,sha256=hashlib.sha256(path.read_bytes()).hexdigest(),generation='built-in image_gen; original source copied unchanged',frames=frames)
out=Path(__file__).parent/'art-source.json'; out.write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({k:dict(size=v['size'],frames=len(v['frames']),reference_height=v['frames'][28]['reference_height'],anchors=[[f['head_center_x'],f['baseline_y']] for f in v['frames']]) for k,v in result.items()}))
assert not errors, errors
