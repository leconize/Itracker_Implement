import asyncio
import uvloop

class Server():

    def __init__(self, host, port):
        self.host = host
        self.port = port

    async def handle_client(self, reader, writer):
        writer.close()
        return

    def start(self, loop):
        coro = asyncio.start_server(self.handle_client, self.host, self.port, loop=loop)
        self.server = loop.run_until_complete(coro)
    
    def close(self):
        self.server.close()
        self.server
 

if __name__ == "__main__":
    asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())
    server = Server("127.0.0.1", 8888)
    loop = asyncio.get_event_loop()
    server.start(loop)
    try:
        loop.run_forever()
    except KeyboardInterrupt:
        server.close()
    loop.run_until_complete(server.server.wait_closed())
    loop.close()