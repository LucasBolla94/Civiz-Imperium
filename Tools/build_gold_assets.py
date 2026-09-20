"""Editable compositions for GOLD-01..05; reuse original native pixels.

Run export_art_references.gd first, then this script with Pillow installed.
Only the ingot is newly generated; its original RGBA is preserved in ArtSources.
"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
NEAREST = Image.Resampling.NEAREST

def source(path):
    return Image.open(ROOT / path).convert('RGBA')

def blank(size):
    return Image.new('RGBA', size)

def save(image, path):
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target)
    assert image.mode == 'RGBA' and image.getextrema()[3][0] == 0

minerals = source('Assets/Objects/Exterior/Mine and Dungeon/stone with minerals.png')
ore = blank((16,16))
ore.alpha_composite(minerals.crop((32,18,48,32)),(0,0))
save(ore, 'Assets/Items/Piles/gold_ore_pile.png')
save(ore.resize((32,32),NEAREST), 'Assets/Items/Resources/gold_ore.png')

original = source('Tools/ArtSources/gold_bar_original.png')
mask = original.getchannel('A').point(lambda v: 255 if v >= 128 else 0)
original.putalpha(mask)
bar = original.crop(mask.getbbox()).resize((14,11),NEAREST)
bar_pile = blank((16,16))
bar_pile.alpha_composite(bar,(1,1))
save(bar_pile, 'Assets/Items/Piles/gold_bar_pile.png')
save(bar_pile.resize((32,32),NEAREST), 'Assets/Items/Resources/gold_bar.png')

rock = source('Tools/ArtSources/Stone.png')
depleted = blank((48,48))
depleted.alpha_composite(rock,(0,16))
deposit = depleted.copy()
for point in [(6,16),(22,20),(13,30)]:
    deposit.alpha_composite(ore,point)
save(deposit,'Assets/Objects/Resources/Gold/gold_deposit.png')
save(depleted,'Assets/Objects/Resources/Gold/gold_deposit_depleted.png')

hut = source('Tools/ArtSources/Building-3.png')
post = blank((64,80))
post.alpha_composite(hut,(8,32))
post.alpha_composite(ore,(8,61))
post.alpha_composite(ore,(38,54))
pickaxe = source('Assets/Icons/RPG icons/Weapons and Armor/1. Wood/Pickaxe.png').crop((0,0,16,16))
post.alpha_composite(pickaxe,(41,35))
save(post,'Assets/Buildings/Gold/gold_mining_post.png')

furnaces = source('Assets/Objects/Work Benches/Furnace.png')
smelter = blank((64,80))
smelter.alpha_composite(hut,(8,32))
smelter.alpha_composite(furnaces.crop((0,0,32,32)),(16,43))
smelter.alpha_composite(ore,(1,62))
smelter.alpha_composite(bar_pile,(46,62))
save(smelter,'Assets/Buildings/Gold/smelter.png')
fire_sheet = blank((256,80))
idle = furnaces.crop((0,0,32,32))
for i in range(4):
    active = furnaces.crop(((i+1)*32,0,(i+2)*32,32))
    overlay = blank((32,32))
    # Only the existing lit mouth changes, never the furnace body.
    for y in range(16,29):
        for x in range(7,25):
            color = active.getpixel((x,y))
            if color != idle.getpixel((x,y)) and color[3]:
                overlay.putpixel((x,y),color)
    fire_sheet.alpha_composite(overlay,(i*64+16,43))
save(fire_sheet,'Assets/Buildings/Gold/smelter_fire.png')
for name, artwork in [('gold_mining_post',post),('smelter',smelter)]:
    icon=blank((32,32))
    tight=artwork.crop(artwork.getbbox())
    tight.thumbnail((30,30),NEAREST)
    icon.alpha_composite(tight,((32-tight.width)//2,(32-tight.height)//2))
    save(icon,f'Assets/UI/Buildings/{name}_icon.png')

# Review sheet is intentionally separate from runtime sprites.
sheet=Image.new('RGB',(720,240),'#55a831')
draw=ImageDraw.Draw(sheet)
items=[('Gold ore',ore),('Gold bars',bar_pile),('Deposit',deposit),('Depleted',depleted),('Mining post',post),('Smelter',smelter)]
x=8
for title,art in items:
    zoom=2 if art.width<64 else 1
    art=art.resize((art.width*zoom,art.height*zoom),NEAREST)
    sheet.paste(art,(x,122-art.height),art)
    draw.text((x,130),title,fill='#172a1a')
    x+=max(90,art.width+18)
sheet.save(ROOT/'Tests/v0061_gold_assets.png')
print('GOLD-01..05 composed with exact dimensions, RGBA transparency and native source pixels.')
