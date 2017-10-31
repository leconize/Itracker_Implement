from PIL import Image
im = Image.open("faceScaleImage.png") #Can be many different formats.
pix = im.load()
x, y = im.size
for i in range(1):
    for j in range(20):
        print(pix[j,i])