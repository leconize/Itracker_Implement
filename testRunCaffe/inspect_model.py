import os
import sys
import Model_pb2

model = Model_pb2.Model()

with open("Itracker.mlmodel", "rb") as f:
    model.ParseFromString(f.read())
