import coremltools

def create_model():
    model_location = 'snapshots/itracker25x_iter_92000.caffemodel'
    prototext_location = 'dep.prototxt'
    mean_location = {
        'image_face': 'mean_images/mean_face_224.binaryproto',
        'image_left': 'mean_images/mean_left_224.binaryproto',
        'image_right': 'mean_images/mean_right_224.binaryproto'
    }
    img_input = ['image_face', 'image_left', 'image_right']
    coreml_model = coremltools.converters.caffe.convert((model_location
    , prototext_location
    , mean_location)
    , is_bgr={'image_face': True, 'image_left': True, 'image_right': True}
    , image_input_names=img_input
    )

    coreml_model.save('model.mlmodel')
