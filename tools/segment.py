import sys, cv2, numpy as np
from scipy import ndimage as ndi
def grad(img, s=1.0):
    lab=cv2.cvtColor(img,cv2.COLOR_BGR2LAB).astype(np.float32)
    lab=cv2.GaussianBlur(lab,(0,0),s)
    g=np.zeros(lab.shape[:2],np.float32)
    for c,w in zip(range(3),(1.0,1.5,1.5)):
        gx=cv2.Sobel(lab[:,:,c],cv2.CV_32F,1,0,ksize=3); gy=cv2.Sobel(lab[:,:,c],cv2.CV_32F,0,1,ksize=3)
        g=np.maximum(g,w*np.hypot(gx,gy))
    return g
def run(img, box, T=40, close=2, min_loop=1500, loop_seeds=()):
    x0,y0,x1,y1=box
    c=img[y0:y1,x0:x1]
    G=grad(c)
    E=G>T
    E=cv2.dilate(E.astype(np.uint8),np.ones((3,3),np.uint8),iterations=close)>0
    lab,n=ndi.label(~E)
    border=set(np.unique(np.r_[lab[0],lab[-1],lab[:,0],lab[:,-1]]))-{0}
    bg=np.isin(lab,list(border))
    for (sx,sy) in loop_seeds:   # manual enclosed-background seeds (cell coords)
        l=lab[sy-y0,sx-x0]
        if l: bg|=lab==l
    # give back the dilation margin to bg where gradient low
    bg=cv2.dilate(bg.astype(np.uint8),np.ones((3,3),np.uint8),iterations=close)>0 & ~(G>T)
    fg=~bg
    k=cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(5,5))
    b=8; fg[:b]=0; fg[-b:]=0; fg[:,:b]=0; fg[:,-b:]=0
    fg=cv2.morphologyEx(fg.astype(np.uint8),cv2.MORPH_OPEN,k)>0
    l2,n2=ndi.label(fg)
    if n2>1:
        sz=ndi.sum(fg,l2,range(1,n2+1)); fg=l2==(1+np.argmax(sz))
    k9=cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(9,9))
    core=cv2.morphologyEx(fg.astype(np.uint8),cv2.MORPH_OPEN,k9)>0
    l3,n3=ndi.label(core)
    if n3>1:
        sz=ndi.sum(core,l3,range(1,n3+1)); core=l3==(1+np.argmax(sz))
    near=cv2.dilate(core.astype(np.uint8),cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(11,11)))>0
    fg=fg&near
    fg=ndi.binary_fill_holes(fg) if not loop_seeds else fg
    return c,fg,G
def save(c,fg,out,feather=1.0):
    a=fg.astype(np.float32)
    a=cv2.erode(a,np.ones((3,3),np.uint8))
    a=cv2.GaussianBlur(a,(0,0),feather)
    a=np.clip(a,0,1)
    ys,xs=np.where(a>0.01)
    rgba=cv2.cvtColor(c,cv2.COLOR_BGR2BGRA); rgba[:,:,3]=(a*255).astype(np.uint8)
    rgba=rgba[ys.min():ys.max()+1,xs.min():xs.max()+1]
    cv2.imwrite(out,rgba); return rgba
if __name__=='__main__':
    img=cv2.imread(sys.argv[1]); box=list(map(int,sys.argv[3:7])); T=float(sys.argv[7]) if len(sys.argv)>7 else 40
    c,fg,G=run(img,box,T)
    save(c,fg,sys.argv[2])
    cv2.imwrite('G.png',np.clip(G*2,0,255).astype(np.uint8))
