import os
import nomad
import aiohttp
import secrets
import asyncio
import argparse

from aiohttp import web
from ..www import WWW_DIR

# -----------------------------------------------------------------------------
# Environment configurable variables:
#   - HTTP_JOB_READY_TIMEOUT: 60 seconds timeout
#   - HTTP_JOB_ALLOCATION_ROOT: use request schema/host
#
# CLI:
#   --port 8080
#   --timeout 60                 # <-- HTTP_JOB_READY_TIMEOUT
#   --redirect http://xyz.com    # <-- HTTP_JOB_ALLOCATION_ROOT
#
# Nomad environment variables:
#   - NOMAD_ADDR=http://127.0.0.1:4646
#   - NOMAD_NAMESPACE=default
#   - NOMAD_TOKEN=xxxx-xxxx-xxxx-xxxx
#   - NOMAD_REGION=us-east-1a
#   - NOMAD_CLIENT_CERT=/path/to/tls/client.crt
#   - NOMAD_CLIENT_KEY=/path/to/tls/client.key
# -----------------------------------------------------------------------------

parser = argparse.ArgumentParser(description="Trame launcher for nomad")
parser.add_argument("--port", default=8080)
parser.add_argument("--timeout", default=60)
parser.add_argument("--redirect")
ARGS = parser.parse_args()

HTTP_JOB_READY_TIMEOUT = int(os.environ.get("HTTP_JOB_READY_TIMEOUT", ARGS.timeout))
HTTP_JOB_ALLOCATION_ROOT = os.environ.get("HTTP_JOB_ALLOCATION_ROOT", ARGS.redirect)

# remove any tailing / on our base url (we add it after)
while HTTP_JOB_ALLOCATION_ROOT[-1] == "/":
    HTTP_JOB_ALLOCATION_ROOT = HTTP_JOB_ALLOCATION_ROOT[:-1]

print(f"HTTP_JOB_ALLOCATION_ROOT: {HTTP_JOB_ALLOCATION_ROOT}")
print(f"HTTP_JOB_READY_TIMEOUT: {HTTP_JOB_READY_TIMEOUT}")

# -----------------------------------------------------------------------------

NOMAD_CLIENT = nomad.Nomad()

STATUS_OK = 200
STATUS_SERVICE_UNAVAILABLE = 503

# -----------------------------------------------------------------------------


async def test_endpoint(url, timeout=60):
    async with aiohttp.ClientSession(
        timeout=aiohttp.ClientTimeout(total=3, connect=1, sock_connect=1, sock_read=1)
    ) as client:
        for i in range(timeout):
            async with client.get(url) as resp:
                if resp.status == 200:
                    return True
                # await resp.text()

            await asyncio.sleep(1)

    return False


# -----------------------------------------------------------------------------


async def handle_launcher(request):
    payload = await request.json()
    application = payload.get("application")
    meta = {"SECRET": secrets.token_urlsafe(16)}
    for key, value in payload.items():
        if key.isupper():
            meta[key] = value

    # Nomad job dispatching
    dispatched_job = NOMAD_CLIENT.job.dispatch_job(application, meta=meta)
    allocations = NOMAD_CLIENT.job.get_allocations(
        dispatched_job.get("DispatchedJobID")
    )
    allocation_id = None
    if len(allocations) == 1:
        allocation_id = allocations[0].get("ID")

    # No allocation found
    if allocation_id is None:
        return web.json_response(
            {
                "error": f"Nomad was not able to allocate the job",
                "job": dispatched_job,
                "allocations": allocations,
            },
            status=STATUS_SERVICE_UNAVAILABLE,
        )

    # Response payload
    server_address = (
        f"{request.scheme}://{request.host}"
        if HTTP_JOB_ALLOCATION_ROOT is None
        else HTTP_JOB_ALLOCATION_ROOT
    )
    response_payload = {
        **meta,
        "redirect": f"{server_address}/{allocation_id}/?name&secret={meta.get('SECRET')}",
        "sessionURL": f"{server_address}/{allocation_id}/ws",
        "secret": meta.get("SECRET"),
    }

    # Test endpoint
    valid = await test_endpoint(
        f"{server_address}/{allocation_id}/", HTTP_JOB_READY_TIMEOUT
    )

    if valid:
        return web.json_response(response_payload, status=STATUS_OK)

    return web.json_response(
        {
            "error": f"Nomad job did not registered within {HTTP_JOB_READY_TIMEOUT}s",
            "job": dispatched_job,
            "allocations": allocations,
            "allocation_id": allocation_id,
        },
        status=STATUS_SERVICE_UNAVAILABLE,
    )


def main():
    # Setup web server
    app = web.Application()
    app.add_routes([web.post("/launcher", handle_launcher), web.static("/", WWW_DIR)])

    # Start
    web.run_app(app, port=ARGS.port)


if __name__ == "__main__":
    main()
