"""GOLD-06: editable native-pixel compositions, with the approved 5x5 masks.

Reuse the supplied pack's bridge wood, fences, hut and crates. Rotate the layout
coordinates, never a finished building image (roofs keep their lighting).
"""
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'Assets/Buildings/Port'
OUT.mkdir(parents=True, exist_ok=True)
def source(path):
    return Image.open(ROOT / path).convert('RGBA')
def rotate(cell, turns):
    x, y = cell
    for _ in range(turns): x, y = 4-y, x
    return x, y

bridge = source('Assets/Tileset/Bridge Beach Tileset.png')
plank = bridge.crop((16,32,32,48))
fence = source('Assets/Objects/Exterior/Fence and Bridge/Fence Wood.png')
post = fence.crop((0,0,16,16))
hut = source('Tools/ArtSources/Building-1.png').crop((5,7,36,44))
crate = source('Assets/Objects/Exterior/Beach/Fish Crate.png').crop((0,0,16,16))
names = ['south','west','north','east']
metadata = {'size':[80,96], 'grid_origin':[0,16], 'foot':[40,96],
            'visual_margin':{'top':16,'left':0,'right':0,'bottom':0},'orientations':{}}
artworks = []
for turns, name in enumerate(names):
    art = Image.new('RGBA',(80,96))
    def place(tile, cell):
        x, y = rotate(cell,turns)
        art.alpha_composite(tile,(x*16,16+y*16))
    # Narrow pier plus a loading apron; transparent sides expose the sea.
    for y in range(1,5):
        for x in range(1,4): place(plank,(x,y))
    # Existing wooden railing pixels retain their original top-down lighting.
    for y in range(2,5):
        for x in [0,4]: place(post,(x,y))
    hut_position = [(1,4),(49,4),(1,49),(1,4)][turns]
    art.alpha_composite(hut,hut_position)
    crate_x = 4 if turns<2 else 0
    place(crate,(crate_x,1))
    place(crate,(crate_x,0))
    art.save(OUT/f'trading_port_{name}.png')
    assert art.size==(80,96) and art.getextrema()[3][0]==0
    land = [rotate((x,y),turns) for y in range(2) for x in range(5)]
    water = [rotate((x,y),turns) for y in range(2,5) for x in range(5)]
    metadata['orientations'][name] = {
        'land_cells':land,'water_cells':water,
        'loading_cell':rotate((2,1),turns), 'dock_cell':rotate((2,5),turns),
        'approach_cells':[rotate((x,y),turns) for y in range(5,7) for x in range(1,4)]}
    artworks.append(art)
(OUT/'trading_port_layout.json').write_text(json.dumps(metadata,indent=2)+'\n',encoding='utf-8')
icon=Image.new('RGBA',(32,32))
tight=artworks[0].crop(artworks[0].getbbox())
tight.thumbnail((30,30),Image.Resampling.NEAREST)
icon.alpha_composite(tight,((32-tight.width)//2,(32-tight.height)//2))
icon.save(ROOT/'Assets/UI/Buildings/trading_port_icon.png')
# Review sheet, outside runtime assets; coastal cells match metadata exactly.
sheet=Image.new('RGB',(720,256),'#efe3c8')
draw=ImageDraw.Draw(sheet)
for i,(name,art) in enumerate(zip(names,artworks)):
    x=10+i*178
    draw.rectangle((x,24,x+159,215),fill='#0096ca')
    for cx,cy in metadata['orientations'][name]['land_cells']:
        draw.rectangle((x+cx*32,56+cy*32,x+cx*32+31,56+cy*32+31),fill='#55a831')
    sheet.paste(art.resize((160,192),Image.Resampling.NEAREST),(x,24),art.resize((160,192),Image.Resampling.NEAREST))
    draw.text((x,229),name,fill='#173b40')
sheet.save(ROOT/'Tests/v0061_port_assets.png')
print('GOLD-06: four native pixel compositions, metadata and icon exported.')
