import sys, re, json
sys.path.insert(0,str(__import__("pathlib").Path(__file__).resolve().parents[2]))
from pathlib import Path
import numpy as np
from PIL import Image
from slrender.skins import SkinRenderer
SP=Path(__file__).resolve().parent/".out"; SP.mkdir(exist_ok=True)
sr=SkinRenderer(Path(__file__).resolve().parents[2], software=True) if 'software' in SkinRenderer.__init__.__code__.co_varnames else SkinRenderer(Path(__file__).resolve().parents[2])
W,H=1100,240
def hexc(h): h=h.lstrip('#'); return tuple(int(h[i:i+2],16)/255 for i in (0,2,4))+(1.0,)
PAL=dict(A="#FF2D6A",B="#FFB000",C="#22E0A0",D="#2E7BFF")
GLOW=re.compile(r"^_(Edge|Border|KnobEdge|NubEdge|Line|Fill|TrackValueFilled|Icon)GlobalBlend$")
def layout(prefix):
    # (part, x, y, w, h, extra)
    return [(prefix+"Face",0,0,W,H,{}),
      (prefix+"KnobHero",30,30,170,170,{"_Value":0.65}),(prefix+"Knob",230,60,110,110,{"_Value":0.4}),
      (prefix+"Knob",370,60,110,110,{"_Value":0.8}),(prefix+"KnobSmall",510,80,70,70,{"_Value":0.5}),
      (prefix+"Pad",610,40,120,120,{}),(prefix+"Button",750,60,110,60,{}),(prefix+"Lamp",880,60,50,50,{}),
      (prefix+"Slider",610,180,320,36,{"_Value":0.6}),(prefix+"Pill",960,70,90,44,{})]
def strip(prefix, mode, offset, blend, name):
    img=np.zeros((H,W,4),np.float32)
    canvas=Image.new("RGBA",(W,H),(0,0,0,255))
    for part,x,y,w,h,extra in layout(prefix):
        st=sr.states_path(part)
        try: doc=json.loads(Path(st).read_text(encoding="utf-8-sig"))
        except Exception as e: print("skip",part,e); continue
        sh=sr.r.load_shader(doc["shaderName"])
        sets=dict(extra)
        isface = part.endswith("Face")
        for p in sh.properties:
            m=re.match(r"^(_\w+GlobalBlend)$",p)
            if not m: continue
            if isface and mode!="all": continue
            if mode=="all" or GLOW.match(p): sets[p]=blend
        cell=dict(states=part,w=w,h=h,set=sets,ss=1,bg="#00000000")
        cell["globals"]={"_ScreenParams":(W/w,H/h,1,1),"_GlobalGradientType":0,
          "_GlobalGradientColorA":hexc(PAL["A"]),"_GlobalGradientColorB":hexc(PAL["B"]),
          "_GlobalGradientColorC":hexc(PAL["C"]),"_GlobalGradientColorD":hexc(PAL["D"]),
          "_GlobalGradientDirection":(1.0,0.0),"_GlobalGradientScale":1.0,
          "_GlobalGradientOffset":offset+x/W,"_GlobalGradientTime":0.0}
        a=sr.render_cell(cell)
        tile=Image.fromarray(a,"RGBA"); canvas.alpha_composite(tile,(x,y)) if False else canvas.paste(tile,(x,y),tile)
    canvas.convert("RGB").save(SP/f"{name}.png"); print(name)
if __name__=="__main__":
    pre=sys.argv[1]
    strip(pre,"off",0,0.0,f"{pre}_off")
    strip(pre,"accent",0.0,1.0,f"{pre}_accent_p0")
    strip(pre,"accent",0.5,1.0,f"{pre}_accent_p1")
    strip(pre,"all",0.0,1.0,f"{pre}_all_p0")
    strip(pre,"all",0.0,0.5,f"{pre}_all_half")
