"""The final deterministic step of accepted Raven local-inpaint production."""
import argparse
from pathlib import Path
import numpy as np
from PIL import Image, PngImagePlugin

def restore(source, raw, mask, crop, output):
    original=np.array(Image.open(source).convert('RGBA'))
    result=np.array(Image.open(raw).convert('RGBA'))
    matte=np.array(Image.open(mask).convert('L'))
    x,y,w,h=map(int,crop)
    if result.shape!=original.shape or matte.shape!=(h,w):raise ValueError('Wrong source/output/mask dimensions')
    if min(x,y)<0 or x+w>original.shape[1] or y+h>original.shape[0]:raise ValueError('Crop outside source')
    protected=np.ones(original.shape[:2],dtype=bool)
    protected[y:y+h,x:x+w]=matte==0
    delta=np.abs(original[protected].astype(int)-result[protected].astype(int))
    if delta.size and (delta.max()>1 or delta[:,:3].max()!=0):raise ValueError('Unexpected changes outside mask: inspect before publishing')
    result[protected]=original[protected]
    metadata=PngImagePlugin.PngInfo()
    with Image.open(raw) as raw_image:
        for key,value in raw_image.info.items():
            if isinstance(value,str):metadata.add_text(key,value)
    output=Path(output);output.parent.mkdir(parents=True,exist_ok=True)
    Image.fromarray(result).save(output,pnginfo=metadata)
    assert np.array_equal(original[protected],np.array(Image.open(output))[protected])
    return {'output':str(output),'protected_pixels':int(protected.sum()),'outside_mask_exact':True}

if __name__=='__main__':
    p=argparse.ArgumentParser()
    for key in ['source','raw','mask','output']:p.add_argument('--'+key,required=True,type=Path)
    p.add_argument('--crop',required=True,nargs=4,type=int,metavar=('X','Y','W','H'))
    a=p.parse_args();print(restore(a.source,a.raw,a.mask,a.crop,a.output))
