import caffe
from caffe.proto import caffe_pb2
import numpy as np
# docker run -t -i -v $(pwd):/app bvlc/caffe:cpu
from PIL import Image


# 1280 720 25 100 127.5, 450, 450
# ans 4 3 19 11

def calculate_face_grid(frameW, frameH
, gridW, gridH
, labelFaceX, labelFaceY, labelFaceW, labelFaceH
, parameterized):
    scaleX = gridW / frameW
    scaleY = gridH / frameH

    print(scaleX)

    labelFaceY = frameH-labelFaceY-labelFaceH
    print(labelFaceY)
    if parameterized:
        sample = [0]*4
    else:
        sample = np.zeros((625, 1))
    xLo = round(labelFaceX*scaleX) + 1
    yLo = round(labelFaceY * scaleY)  + 1
    w = round(labelFaceW *scaleX)
    h = round(labelFaceH * scaleY)
    if parameterized:
        sample = [xLo, yLo, w, h]
    else:
        xHi = xLo + w - 1
        yHi = yLo + h - 1

        xLo = min(gridW, max(1, xLo))
        xHi = min(gridW, max(1, xHi))
        yLo = min(gridH, max(1, yLo))
        yHi = min(gridH, max(1, yHi))
        for i in range(0, int(gridH*gridW)):
            row = int(i/gridH)
            column = i%gridH
            if row <= yHi-1 and row >= yLo-1 and column <= xHi-1 and column >= xLo-1:
                sample[i] = 1
        print(xLo, xHi, yLo, yHi)
    return sample


caffe.set_mode_cpu()

# load data 
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

with open('mean_images/mean_left_224_new.binaryproto') as f:
    left_mean_blob.ParseFromString(f.read())
right_mean_array = np.asarray(left_mean_blob.data, dtype=np.float32).reshape(
    (left_mean_blob.channels, left_mean_blob.height, left_mean_blob.width))

# load model 
net = caffe.Net('itracker_deploy.prototxt',
                'snapshots/itracker25x_iter_92000.caffemodel', caffe.TEST)

# setup data preprocesser
image_tranformer = caffe.io.Transformer({'image_face': net.blobs['image_face'].data.shape,
'image_left': net.blobs['image_left'].data.shape, 
'image_right': net.blobs['image_right'].data.shape
}
)
image_tranformer.set_mean('image_face', face_mean_array)
image_tranformer.set_transpose('image_face', (2, 0, 1))
image_tranformer.set_raw_scale('image_face', 255)
image_tranformer.set_channel_swap('image_face', (2,1,0))

image_tranformer.set_mean('image_left', left_mean_array)
image_tranformer.set_transpose('image_left', (2, 0, 1))
image_tranformer.set_raw_scale('image_left', 255)
image_tranformer.set_channel_swap('image_left', (2,1,0))

image_tranformer.set_mean('image_right', right_mean_array)
image_tranformer.set_transpose('image_right', (2, 0, 1))
image_tranformer.set_raw_scale('image_right', 255)
image_tranformer.set_channel_swap('image_right', (2,1,0))

faceImage = caffe.io.load_image('faceScaleImage.png')
leftImage = caffe.io.load_image('leftEyeImage.png')
rightImage = caffe.io.load_image('rightEyeImage.png')

net.blobs['image_face'].data[...] = image_tranformer.preprocess('image_face', faceImage)
net.blobs['image_left'].data[...] = image_tranformer.preprocess('image_left', leftImage)
net.blobs['image_right'].data[...] = image_tranformer.preprocess('image_right', rightImage)

print(net.blobs['image_face'].data.shape)
print(net.blobs['image_face'].data[...])
# mock_face = np.ones((1, 3, 224, 224))
# mock_left = np.ones((1, 3, 224, 224))
# mock_right = np.ones((1, 3, 224, 224))


# net.blobs['image_face'].data[...] = faceImage.reshape(1, 3, 225, 225)[:,:,0:-1,0:-1]
# net.blobs['image_left'].data[...] = leftImage.reshape(1, 3, 224, 225)[:,:,:,0:-1]
# net.blobs['image_right'].data[...] = rightImage.reshape(1, 3, 224, 225)[:,:,:,0:-1]


# net.blobs['image_face'].data[...] = mock_face
# net.blobs['image_left'].data[...] = mock_left
# net.blobs['image_right'].data[...] = mock_right

net.blobs['facegrid'].data[...] = calculate_face_grid(720, 1280.0, 25.0, 25.0, 100, 127.5, 450, 450, 0).T.reshape((1, 625, 1, 1))

print(face_mean_array)

net.forward()
print(net)
print("success")

print(net.blobs['fc3'].data)


my_result = calculate_face_grid(720, 1280.0, 25.0, 25.0, 100, 127.5, 450, 450, 0)

my_result = np.squeeze(my_result)
print(my_result.shape)

for i in range(25):
    print(' '.join(map(str, map(int, my_result[i*25:(i+1)*25]))))
# print(my_result)

# print("####################################")

# with open('file.txt') as compare_file:
#     temp = filter(lambda x: x != '', compare_file.read().split(' '))
#     temp = list(map(lambda x: int(x[0]), temp))
#     for i in range(25):
#         print(temp[i*25:(i+1)*25])
    
#     for i in range(625):
#         if my_result[i] != temp[i]:
#             print('u')