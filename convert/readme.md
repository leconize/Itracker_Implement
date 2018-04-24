you should create virtualenv and install coremltools

then run convert_script.py

Then reason normal you can't convert with normal prototxt in the owner repository because of the original prototxt declare inputs layer in ambigous way.You can see the prove of my theory by using [Netscope tool](http://ethereon.github.io/netscope/quickstart.html) to visualize the model by compare my prototext with the original prototxt.