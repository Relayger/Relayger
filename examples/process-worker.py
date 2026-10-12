"""A process worker in Python, standard library only.

Run it for each message with `relayger worker run NAME --process ./worker.json`, where
worker.json names this script by absolute path:

    {"command": "/usr/bin/python3", "args": ["/absolute/path/to/process-worker.py"], "env": []}

The worker writes one JSON line to stdin (at most 131072 bytes) and reads exactly one JSON
line from stdout. Message text is untrusted data; this example calls no model, shell or URL.
"""

import json
import sys

LIMIT = 131072


def main():
    raw = sys.stdin.buffer.readline(LIMIT + 1)
    if len(raw) > LIMIT or not raw.endswith(b"\n"):
        raise ValueError("invalid_frame")
    request = json.loads(raw.decode("utf-8"))
    if request["schemaVersion"] != 1 or request["untrustedExternalData"] is not True:
        raise ValueError("invalid_request")
    message = request["message"]
    if message["type"] != "text":
        result = {"skip": True}
    else:
        result = {"reply": "Received: " + message["body"]["text"]}
    # Report real usage when a model is called; zero means no model was used.
    result["usage"] = {"modelCalls": 0, "inputTokens": 0, "outputTokens": 0}
    response = {"schemaVersion": 1, "jobKey": request["jobKey"], "result": result}
    sys.stdout.buffer.write(json.dumps(response, ensure_ascii=False).encode("utf-8") + b"\n")
    sys.stdout.buffer.flush()


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, TypeError):
        # Errors go to stderr without message content or credentials.
        print("invalid_process_request", file=sys.stderr)
        sys.exit(1)
