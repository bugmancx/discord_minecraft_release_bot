from pathlib import Path
import urllib.request, json, requests

# User Configurable Variables
TMP = 'tmp'
MANIFEST_VERSION_URL='https://launchermeta.mojang.com/mc/game/version_manifest.json'
DISCORD_USERNAME='Minecraft'
DISCORD_WEBHOOK_URL=''

# Setup Variables
tmp_path = Path(TMP)
cached_file = tmp_path.joinpath('cached_version_manifest.json')
cached_version_release = None
cached_version_snapshot = None
manifest_version_release = None
manifest_version_snapshot = None

# Helper Function
def send_to_discord(msg):
    requests.post(DISCORD_WEBHOOK_URL, json={"username": DISCORD_USERNAME, "content": msg})

# If data is cached, load it
if cached_file.is_file():
    with open(cached_file) as f:
        data = json.load(f)
        cached_version_release = data["latest"]["release"]
        cached_version_snapshot = data["latest"]["snapshot"]

# Load the manifest
with urllib.request.urlopen(MANIFEST_VERSION_URL) as url:
    datatxt = url.read().decode()
    data = json.loads(datatxt)

    manifest_version_release = data["latest"]["release"]
    manifest_version_snapshot = data["latest"]["snapshot"]

    # Check for differences, and send messages appropriately
    diff = False
    if not cached_version_release == manifest_version_release:
        send_to_discord("Release: " + manifest_version_release)
        diff = True

    if not cached_version_snapshot == manifest_version_snapshot:
        send_to_discord("Snapshot: " + manifest_version_snapshot)
        diff = True
    
    # Cache the manifest
    tmp_path.mkdir(exist_ok=True)
    with open(cached_file, 'w') as f:
        f.write(datatxt)
