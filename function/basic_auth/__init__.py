import base64
import os
import logging
import requests
import azure.functions as func

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Basic Auth function processing a request.")

    username = os.getenv("MUNKI_USERNAME")
    password = os.getenv("MUNKI_PASSWORD")
    auth_header = req.headers.get("authorization", "")

    expected = f"Basic {base64.b64encode(f'{username}:{password}'.encode()).decode()}"

    if auth_header != expected:
        return func.HttpResponse(
            "Authentication required",
            status_code=401,
            headers={"WWW-Authenticate": 'Basic realm="Secure Area"'}
        )

    blob_url = os.getenv("BLOB_STORAGE_URL") + (req.params.get("file") or "")
    try:
        resp = requests.get(blob_url, stream=True)
        resp.raise_for_status()
    except requests.exceptions.RequestException as exc:
        logging.error("Error accessing blob storage: %s", exc)
        return func.HttpResponse("Error accessing blob storage", status_code=500)

    return func.HttpResponse(
        resp.content,
        status_code=resp.status_code,
        mimetype=resp.headers.get("Content-Type")
    )
