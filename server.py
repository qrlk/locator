#!/usr/bin/env python3
from aiohttp import web
import urllib.parse
import time
import linecache
import json

vehicles = {}
last_clear = time.time()
async def handle(request):
    global last_clear
    global vehicles
    info = json.loads(urllib.parse.unquote(request.path.replace("/","")))
    if time.time() - last_clear > 60:
        last_clear = time.time()
        for item in list(vehicles):
            pass
    for item in info["vehicles"]:
        print(item)
        pass
    return web.Response(text='')


app = web.Application()
app.router.add_get('/{name}', handle)
web.run_app(app, host = '0.0.0.0', port=46547)

