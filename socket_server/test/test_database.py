import unittest
from src import db
import yaml

class TestSocketServer(unittest.TestCase):

    def setUp(self):
        with open("config.yaml") as config:
            config_dict = yaml.load(config)['database']
            self.database = db.Database(**config_dict)

    def test_constructor_work_correctly(self):
        self.assertEqual("eye_gaze_db", self.database.dbname)
        self.assertEqual("admin", self.database.user)
        self.assertEqual("localhost", self.database.host)
        self.assertEqual("mysecretpassword", self.database.password)