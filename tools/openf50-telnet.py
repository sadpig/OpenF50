#!/usr/bin/env python3
"""Run commands on the OPENF50 over telnet (busybox telnetd + /bin/login). stdlib only.
usage: openf50-telnet.py 'command'   env: OPENF50_HOST (192.168.77.1), OPENF50_USER/OPENF50_PASS (ubuntu)"""
import os, re, socket, sys, time
IAC, DONT, DO, WONT, WILL, SB, SE = 255, 254, 253, 252, 251, 250, 240

def strip_negotiation(sock, data):
    out = bytearray(); i = 0
    while i < len(data):
        b = data[i]
        if b == IAC and i + 1 < len(data):
            cmd = data[i + 1]
            if cmd in (DO, DONT, WILL, WONT) and i + 2 < len(data):
                opt = data[i + 2]
                reply = WONT if cmd in (DO, DONT) else DONT
                sock.sendall(bytes([IAC, reply, opt])); i += 3; continue
            if cmd == SB:
                j = data.find(bytes([IAC, SE]), i)
                i = len(data) if j < 0 else j + 2; continue
            i += 2; continue
        out.append(b); i += 1
    return bytes(out)

def read_until(sock, needles, timeout):
    buf = b''; end = time.time() + timeout
    sock.settimeout(0.5)
    while time.time() < end:
        try:
            d = sock.recv(65536)
            if not d: break
            buf += strip_negotiation(sock, d)
            if any(n in buf for n in needles): break
        except socket.timeout:
            pass
    return buf

s = socket.create_connection((os.environ.get('OPENF50_HOST', '192.168.77.1'), 23), 10)
read_until(s, [b'login: '], 15); s.sendall(os.environ.get('OPENF50_USER', 'ubuntu').encode() + b'\r\n')
read_until(s, [b'assword: '], 15); s.sendall(os.environ.get('OPENF50_PASS', 'ubuntu').encode() + b'\r\n')
read_until(s, [b'$ ', b'# '], 20)
tag = 'OPENF50END%d' % int(time.time())
s.sendall(('stty -echo; %s; echo; echo %s\r\n' % (' '.join(sys.argv[1:]), tag)).encode())
out = read_until(s, [('\n' + tag).encode()], float(os.environ.get('OPENF50_TIMEOUT', '120')))
text = out.decode(errors='replace').replace('\r', '')
text = re.sub(r'\x1b\][^\x07\x1b]*(\x07|\x1b\\)', '', text); text = re.sub(r'\x1b\[[0-9;?]*[A-Za-z]', '', text)
body = text.split('\n' + tag)[0]
sys.stdout.write('\n'.join(l for l in body.split('\n') if 'stty -echo' not in l).strip() + '\n')
