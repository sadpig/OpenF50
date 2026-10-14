#!/usr/bin/env python3
"""scp to the OPENF50 with password auth (no sshpass). usage: openf50-scp.py LOCAL REMOTE_PATH
env: OPENF50_HOST (ubuntu@192.168.77.1; a U30 Air is ubuntu@192.168.78.1), OPENF50_PASS"""
import os, pty, select, sys
pw = os.environ.get('OPENF50_PASS', 'ubuntu').encode()
cmd = ['scp', '-O', '-o', 'StrictHostKeyChecking=no', '-o', 'UserKnownHostsFile=/dev/null', '-o', 'LogLevel=ERROR',
       '-o', 'PubkeyAuthentication=no', sys.argv[1], os.environ.get('OPENF50_HOST', 'ubuntu@192.168.77.1') + ':' + sys.argv[2]]
pid, fd = pty.fork()
if pid == 0:
    os.execvp(cmd[0], cmd)
buf = b''; sent = False
while True:
    r, _, _ = select.select([fd], [], [], 600)
    if not r: break
    try: d = os.read(fd, 4096)
    except OSError: break
    if not d: break
    buf += d
    if not sent and b'assword:' in buf:
        os.write(fd, pw + b'\n'); sent = True; buf = b''
_, status = os.waitpid(pid, 0)
sys.stdout.write(buf.decode(errors='replace'))
sys.exit(os.WEXITSTATUS(status))
