import coremltools
import json
from PIL import Image
import numpy as np

model =  coremltools.models.MLModel('Itracker.mlmodel')

with open('appleFace.json') as data_file:
    faceJson = json.load(data_file)

with open('appleLeftEye.json') as data_file:
    leftEye = json.load(data_file)

with open('appleRightEye.json') as data_file:
    rightEye = json.load(data_file)

with open('faceGrid.json') as data_file:
    facegrid = json.load(data_file)

def to_item_value(items, index):
    if items['IsValid'][index]:
        dic = {
            'x': items['X'][index],
            'y': items['Y'][index],
            'width': items['W'][index],
            'height': items['H'][index]
        }
        return dic
    else:
        return 0

im = Image.open('./frames/00000.jpg')

face_data = to_item_value(faceJson, 0)
# face = im.crop((38, 230, 343+38, 343+230))
face = im.crop((face_data['x'], face_data['y'], face_data['width']+face_data['x'], face_data['height']+face_data['y']))
arrayface = np.array(face)

leftEyeImage = face.crop((166, 79, 103+166, 79+103))

arrayLeft = np.array(leftEyeImage)

rightEyeImage = face.crop((32, 89, 103+32, 103+89))

arrayRight = np.array(rightEyeImage)

def face_grid_param_to_array(x, y, width, height):
    array = [0]*625
    for i in range(625):
        row = i / 25
        col = i % 25
        if row >= y and row < y+height and col >= x and col < x+width:
            array[i] = 1

    return array

faceGridArray = face_grid_param_to_array(6, 10, 13, 13)

# import itertools
# flatten_face = list(itertools.chain.from_iterable(itertools.chain.from_iterable(arrayface.tolist())))
# flatten_left = list(itertools.chain.from_iterable(itertools.chain.from_iterable(arrayLeft.tolist())))
# flatten_right = list(itertools.chain.from_iterable(itertools.chain.from_iterable(arrayRight.tolist())))
# print(flatten_face)
# model.predict({
#     "image_face": flatten_face,
#      "image_left": flatten_left,
#       "image_right": flatten_right,"facegrid": faceGridArray
# })
# print(model.getspec())
with open('dotInfo.json') as data_file:
    dot_info = json.load(data_file)
