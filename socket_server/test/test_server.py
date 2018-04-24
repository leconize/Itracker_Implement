import unittest
import asyncio
import uvloop
import socket
import time


from src.util import is_server_running, tcp_echo_client
from src.server import Server
from threading import Thread

def run_loop(loop):
    asyncio.set_event_loop(loop)
    loop.run_forever()

class TestSocketServer(unittest.TestCase):

    def setUp(self):
        self.host = "127.0.0.1"
        self.port = 1111
        self.server = Server(self.host, self.port)
        self.loop = asyncio.get_event_loop()
        self.server.start(self.loop)
        
    def test_init_server(self):
        self.assertEqual(self.server.host, "127.0.0.1")
        self.assertEqual(self.server.port, 1111)

    def test_server_is_running(self):
        self.assertTrue(is_server_running(self.host, self.port))
    
    def tearDown(self):
        self.server.close()
        if self.loop.is_running():
            self.loop.close()
        

if __name__ == '__main__':
    unittest.main()
