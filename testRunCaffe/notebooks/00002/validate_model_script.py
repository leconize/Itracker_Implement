from caffe.proto import caffe_pb2
import json
import PIL
import numpy as np
import caffe

face_mean_blob = caffe_pb2.BlobProto()
with open('mean_images/mean_face_224.binaryproto') as f:
    face_mean_blob.ParseFromString(f.read())
face_mean_array = np.asarray(face_mean_blob.data, dtype=np.float32).reshape(
    (face_mean_blob.channels, face_mean_blob.height, face_mean_blob.width))

right_mean_blob = caffe_pb2.BlobProto()
with open('mean_images/mean_right_224.binaryproto') as f:
    right_mean_blob.ParseFromString(f.read())
left_mean_array = np.asarray(right_mean_blob.data, dtype=np.float32).reshape(
    (right_mean_blob.channels, right_mean_blob.height, right_mean_blob.width))

left_mean_blob = caffe_pb2.BlobProto()

with open('mean_images/mean_left_224.binaryproto') as f:
    left_mean_blob.ParseFromString(f.read())
right_mean_array = np.asarray(left_mean_blob.data, dtype=np.float32).reshape(
    (left_mean_blob.channels, left_mean_blob.height, left_mean_blob.width))

caffe.set_mode_cpu()
net = caffe.Net('itracker_deploy copy.prototxt',
                'snapshots/itracker25x_iter_92000.caffemodel', caffe.TEST)

before_reshape = [(k, v.data.shape) for k, v in net.blobs.items()]

# print("\n".join(map(lambda x: "%s %s" %(x[0], x[1]), before_reshape)))

net.blobs['image_face'].reshape(1, 3, 224, 224)
net.blobs['image_left'].reshape(1, 3, 224, 224)
net.blobs['image_right'].reshape(1, 3, 224, 224)
net.blobs['facegrid'].reshape(1, 625, 1, 1)


net.reshape()

after_reshape = [(k, v.data.shape) for k, v in net.blobs.items()]

image_tranformer = caffe.io.Transformer({'image_face': net.blobs['image_face'].data.shape,
'image_left': net.blobs['image_left'].data.shape,
'image_right': net.blobs['image_right'].data.shape
}
)
image_tranformer.set_mean('image_face', face_mean_array)
image_tranformer.set_transpose('image_face', (2, 0, 1))
# image_tranformer.set_raw_scale('image_face', 255)
image_tranformer.set_channel_swap('image_face', (2,1,0))

image_tranformer.set_mean('image_left', left_mean_array)
image_tranformer.set_transpose('image_left', (2, 0, 1))
# image_tranformer.set_raw_scale('image_left', 255)
image_tranformer.set_channel_swap('image_left', (2,1,0))

image_tranformer.set_mean('image_right', right_mean_array)
image_tranformer.set_transpose('image_right', (2, 0, 1))
# image_tranformer.set_raw_scale('image_right', 255)
image_tranformer.set_channel_swap('image_right', (2,1,0))

# print("After ++++++++++++")
# print("\n".join(map(lambda x: "%s %s" %(x[0], x[1]), after_reshape)))
# info = [(k, v[0].data.shape, v[1].data.shape) for k, v in net.params.items()]
# # print("\n".join(map(lambda x: "%s %s" %(x[0], x[1], x[2]), info)))
# print(before_reshape == after_reshape)

with open('appleFace.json') as data_file:
    faceJson = json.load(data_file)

with open('appleLeftEye.json') as data_file:
    leftEye = json.load(data_file)

with open('appleRightEye.json') as data_file:
    rightEye = json.load(data_file)

with open('faceGrid.json') as data_file:
    facegrid = json.load(data_file)

with open('dotInfo.json') as data_file:
    dot_info = json.load(data_file)

def euclidean_distance(x1, y1, x2, y2):
    return np.sqrt( (x1-x2)**2 + (y1-y2)**2)

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

def face_grid_param_to_array(x, y, width, height):
    array = [0]*625
    for i in range(625):
        row = i / 25
        col = i % 25
        if row >= y and row < y+height and col >= x and col < x+width:
            array[i] = 1

    return array

from os import listdir
from os.path import isfile, join
onlyfiles = sorted([f for f in listdir('./frames') if isfile(join('./frames', f))])

valid_count = 0
total_distance = 0
for i in range(len(onlyfiles)):
# for i in range(1):
    face_data = to_item_value(faceJson, i)
    left_eye_data = to_item_value(leftEye, i)
    right_eye_data = to_item_value(rightEye, i)
    face_grid_data = to_item_value(facegrid, i)
    if(face_data and left_eye_data and right_eye_data):
        valid_count += 1
        fullImage = PIL.Image.open('./frames/'+onlyfiles[i])
        face_crop_image = fullImage.crop((face_data['x']
                                          , face_data['y']
                                    , face_data['width']+face_data['x']
                                          , face_data['height']+face_data['y']))

        left_eye_crop_image = face_crop_image.crop((left_eye_data['x']
                                                    , left_eye_data['y']
                                              , left_eye_data['width']+left_eye_data['x']
                                                    , left_eye_data['height']+left_eye_data['y']))

        right_eye_crop_image = face_crop_image.crop((right_eye_data['x']
                                                     , right_eye_data['y']
                                              , right_eye_data['width']+right_eye_data['x']
                                                     , right_eye_data['height']+right_eye_data['y']))

        face_grid_preprocessed = face_grid_param_to_array(face_grid_data['x']
                                                          , face_grid_data['y'],
                                                         face_grid_data['width']
                                                          , face_grid_data['height'])

        face_crop_array = np.array(face_crop_image)
        left_eye_crop_array = np.array(left_eye_crop_image)
        right_eye_crop_array = np.array(right_eye_crop_image)
        net.blobs['image_face'].data[...] = image_tranformer.preprocess('image_face', face_crop_array)
        net.blobs['image_left'].data[...] = image_tranformer.preprocess('image_left', left_eye_crop_array)
        net.blobs['image_right'].data[...] = image_tranformer.preprocess('image_right', right_eye_crop_array)
        net.blobs['facegrid'].data[...] = np.array(face_grid_preprocessed).reshape((1, 625, 1, 1))
        net.forward()
        result_x, result_y = net.blobs['fc3'].data[0]
        dot_pos_x, dot_pos_y = dot_info['XCam'][i], dot_info['YCam'][i]
        print(result_x, result_y, dot_pos_x, dot_pos_y)
        dis = euclidean_distance(result_x, result_y, dot_pos_x, dot_pos_y)
        total_distance += dis
total_distance /= valid_count

print("total valid = %d" %valid_count)
print(total_distance)
