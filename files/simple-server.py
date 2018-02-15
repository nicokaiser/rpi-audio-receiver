#!/usr/bin/python
# -*- coding: utf-8 -*-

from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
from collections import OrderedDict
from datetime import timedelta
import codecs
import os
import re
import socket
import SocketServer
import subprocess

###

html = """<!doctype html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
        <title>%(hostname)s - Device Info</title>
        <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">
    </head>
    <body>
        <main role="main" class="container">
            <h1 class="mt-5">%(pretty_hostname)s</h1>

            <!--
            <h5 class="mt-4">Bluetooth</h5>
            <button type="button" class="btn btn-outline-primary" disabled="disabled">Disable</button>
            <button type="button" class="btn btn-outline-primary" disabled="disabled">Make discoverable</button>

            <h5 class="mt-4">AirPlay</h5>
            <button type="button" class="btn btn-outline-primary" disabled="disabled">Disable</button>
            -->

            <table class="mt-5 table table-bordered">
                <tbody>
                    <tr>
                        <th>Operating System</th>
                        <td>%(os_name)s %(os_pretty_name)s</td>
                    </tr>
                    <tr>
                        <th>Hostname / IP</th>
                        <td>%(hostname)s (%(ip)s)</td>
                    </tr>
                    <tr>
                        <th>System Uptime</th>
                        <td>%(uptime)s</td>
                    </tr>
                    <tr>
                        <th>System Load</th>
                        <td>%(system_load)s</td>
                    </tr>
                    <tr>
                        <th>CPU Temperature</th>
                        <td>%(temp)s (%(clock_arm)s)</td>
                    </tr>
                    <tr>
                        <th>Playback Device</th>
                        <td>%(audio_device)s</td>
                    </tr>
                    <tr>
                        <th>Playback</th>
                        <td>%(audio_playback)s</td>
                    </tr>
                </tbody>
            </table>
        </main>
    </body>
</html>"""

###

__escape_decoder = codecs.getdecoder('unicode_escape')

def decode_escaped(escaped):
    return __escape_decoder(escaped)[0]

def parse_dotenv(dotenv_path):
    with open(dotenv_path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue
            k, v = line.split('=', 1)

            k, v = k.strip(), v.strip().encode('unicode-escape').decode('ascii')

            if len(v) > 0:
                quoted = v[0] == v[-1] in ['"', "'"]

                if quoted:
                    v = decode_escaped(v[1:-1])

            yield k, v

def get_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

###

dict = {}

uname = os.uname()
dict['os_name'] = "%s %s" % (uname[0], uname[2])

dict['os_pretty_name'] = ''
if os.path.exists('/etc/os-release'):
    values = OrderedDict(parse_dotenv('/etc/os-release'))
    if 'PRETTY_NAME' in values:
        dict['os_pretty_name'] = values['PRETTY_NAME']

dict['hostname'] = socket.gethostname()

dict['pretty_hostname'] = dict['hostname']
if os.path.exists('/etc/os-release'):
    values = OrderedDict(parse_dotenv('/etc/machine-info'))
    if 'PRETTY_HOSTNAME' in values:
        dict['pretty_hostname'] = values['PRETTY_HOSTNAME']
        
def update_dict():
    dict['system_load'] = ', '.join(str(round(x, 2)) for x in os.getloadavg())
    dict['ip'] = get_ip()

    if os.path.exists('/proc/uptime'):
        with open('/proc/uptime', 'r') as f:
            uptime_seconds = round(float(f.readline().split()[0]))
            dict['uptime'] = str(timedelta(seconds = uptime_seconds))

    vcgencmd = '/usr/bin/vcgencmd'
    if os.path.isfile(vcgencmd):
        output = subprocess.check_output([vcgencmd, 'measure_temp'])
        dict['temp'] = output[output.find('=') + 1:].strip().rstrip('\'C') + ' &deg;C'
        output = subprocess.check_output([vcgencmd, 'measure_clock', 'arm'])
        dict['clock_arm'] = "{:,} MHz".format(int(int(output[output.find('=') + 1:].strip()) / 1e6))

    dict['audio_device'] = ''
    dict['audio_playback'] = 'stopped'
    try:
        grep_output = subprocess.check_output(["""grep -l RUNNING /proc/asound/card*/pcm*p/sub*/status"""], shell=True)
        for status_path in grep_output.strip().split('\n'):
            base_path = re.sub(r"/status$", '', status_path)
            if os.path.isfile(base_path + '/hw_params'):
                with open(base_path + '/hw_params', 'r') as f:
                    audio_rate = ''
                    audio_format = ''
                    audio_channels = ''
                    for line in f:
                        k, v = line.strip().split(':', 1)
                        if k == 'format':
                            v = v.strip()
                            if re.match(r"^\w16_", v):
                                audio_format = '16 Bit'
                            elif re.match(r"^\w24_", v):
                                audio_format = '24 Bit'
                            elif re.match(r"^\w32_", v):
                                audio_format = '32 Bit'
                            else:
                                audio_format = v
                        elif k == 'channels':
                            audio_channels = v.strip()
                            if audio_channels == "1":
                                audio_channels += " channel"
                            elif audio_channels:
                                audio_channels += " channels"                            
                        elif k == 'rate':
                            audio_rate = str(float(v.strip().split(' ')[0]) / 1000) + ' kHz'
                    dict['audio_playback'] = ', '.join([audio_rate, audio_format, audio_channels])

            if os.path.isfile(base_path + '/info'):
                with open(base_path + '/info', 'r') as f:
                    device_name = ""
                    device_id = ""
                    for line in f:
                        k, v = line.strip().split(':', 1)
                        if k == 'name':
                            device_name = v.strip()
                        elif k == 'id':
                            device_id = v.strip()
                    if device_name:
                        dict['audio_device'] = device_name
                    else:
                        dict['audio_device'] = device_id

    except Exception:
        dict['audio_device'] = 'none'

###

class MyServer(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            do_index(self)
        elif self.path == '/discoverable':
            do_discoverable(self)
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write('Not Found')

def do_index(self):
    self.send_response(200)
    self.send_header('Content-type', 'text/html')
    self.end_headers()
    update_dict()
    self.wfile.write(html % dict)

def do_discoverable(self):
    self.send_response(200)
    self.end_headers()
    self.wfile.write("ok")

httpd = HTTPServer(('', 8000), MyServer)

try:
    httpd.serve_forever()
except KeyboardInterrupt:
    pass

https.server_close()
