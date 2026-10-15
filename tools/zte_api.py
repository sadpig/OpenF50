#!/usr/bin/env python3
"""ZTE F50 (B16) stock web-UI API helper: login, nv reads, AD-signed set commands.

Usage:
  zte_api.py get  KEY[,KEY...]            read (some keys work without login)
  zte_api.py login PASSWORD               login and print loginfo
  zte_api.py lget PASSWORD KEY[,KEY...]   read while logged in
  zte_api.py set  PASSWORD GOFORM_ID k=v [k=v...]   run a signed set command while logged in
"""
import hashlib
import json
import sys
import urllib.parse
import urllib.request
import http.cookiejar

BASE = "http://192.168.0.1"
HDRS = {
    "Referer": BASE + "/index.html",
    "X-Requested-With": "XMLHttpRequest",
    "Accept": "application/json, text/javascript, */*; q=0.01",
}

cj = http.cookiejar.CookieJar()
opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))


def sha256_upper(s: str) -> str:
    return hashlib.sha256(s.encode()).hexdigest().upper()


def get(cmd: str):
    q = {"isTest": "false", "cmd": cmd}
    if "," in cmd:
        q["multi_data"] = "1"
    req = urllib.request.Request(BASE + "/goform/goform_get_cmd_process?" + urllib.parse.urlencode(q), headers=HDRS)
    with opener.open(req, timeout=10) as r:
        body = r.read().decode(errors="replace")
    try:
        return json.loads(body)
    except Exception:
        return {"_raw": body}


def post(data: dict):
    body = urllib.parse.urlencode(data).encode()
    h = dict(HDRS)
    h["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF-8"
    h["Origin"] = BASE
    req = urllib.request.Request(BASE + "/goform/goform_set_cmd_process", data=body, headers=h, method="POST")
    with opener.open(req, timeout=15) as r:
        rb = r.read().decode(errors="replace")
    try:
        return json.loads(rb)
    except Exception:
        return {"_raw": rb}


def login(password: str):
    ld = get("LD").get("LD", "")
    if not ld:
        raise SystemExit("cannot fetch LD (login nonce)")
    pw = sha256_upper(sha256_upper(password) + ld)
    res = post({"isTest": "false", "goformId": "LOGIN", "password": pw})
    info = get("loginfo")
    return res, info


def ad():
    v = get("wa_inner_version,cr_version")
    rd = get("RD").get("RD", "")
    key = sha256_upper(v.get("wa_inner_version", "") + v.get("cr_version", ""))
    return sha256_upper(key + rd)


def set_cmd(goform_id: str, **kw):
    data = {"isTest": "false", "goformId": goform_id}
    data.update(kw)
    data["AD"] = ad()
    return post(data)


if __name__ == "__main__":
    a = sys.argv[1:]
    if not a:
        print(__doc__)
        sys.exit(2)
    if a[0] == "get":
        print(json.dumps(get(a[1]), ensure_ascii=False))
    elif a[0] == "login":
        res, info = login(a[1])
        print("login:", res, "loginfo:", info)
    elif a[0] == "lget":
        res, info = login(a[1])
        if info.get("loginfo") != "ok":
            raise SystemExit(f"login failed: {res} {info}")
        print(json.dumps(get(a[2]), ensure_ascii=False))
    elif a[0] == "set":
        res, info = login(a[1])
        if info.get("loginfo") != "ok":
            raise SystemExit(f"login failed: {res} {info}")
        kv = dict(x.split("=", 1) for x in a[3:])
        print(json.dumps(set_cmd(a[2], **kv), ensure_ascii=False))
    else:
        print(__doc__)
        sys.exit(2)
