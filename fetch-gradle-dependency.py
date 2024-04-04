import json
import requests
import hashlib
import sys

def download_artifact(_output_file, _name, _group, _version, _artifact_name, _artifact_dir, unprotected_maven_urls=None, _sha256hash=None):

    if unprotected_maven_urls is None:
        unprotected_maven_urls = [
            "https://dl.google.com/dl/android/maven2",
            "https://repo.maven.apache.org/maven2",
            "https://plugins.gradle.org/m2",
            "https://maven.google.com"
        ]

    print(f"Downloading {_artifact_name} for {_group}:{_name}:{_version} from {_artifact_dir}")

    # Number of attempts
    attempts = 0

    component_identifier = f"{_group.replace('.', '/')}/{_name}/{_version}/{_artifact_name}"

    # Iterate through Maven2 URLs
    for maven_url in unprotected_maven_urls:
        # Increment the number of attempts
        attempts += 1

        # Construct the Maven2 URL for the current component
        package_url = f"{maven_url}/{component_identifier}"

        print(f"Attempting to download {_artifact_name} for {_group}:{_name}:{_version} from {package_url}")

        # Download the package
        response = requests.get(package_url, stream=True)

        if response.status_code == 200:

            with open(_output_file, 'wb') as _file:
                for chunk in response.iter_content(chunk_size=128):
                    _file.write(chunk)
            print(f"\n Downloaded '{_artifact_name}' for {_group}:{_name}:{_version} from {maven_url} to local repository. \n Repo URL: {package_url}")

            with open(_output_file, "rb") as f:
                # Read and update hash string value in blocks of 4K
                sha256_hash = hashlib.sha256()
                for byte_block in iter(lambda: f.read(4096), b""):
                    sha256_hash.update(byte_block)
                # Check if the computed hash matches the given hash
                if sha256_hash.hexdigest() == _sha256hash:
                    return

        else:
            print(f"\nFailed to download '{_artifact_name}' for {_group}:{_name}:{_version} from {maven_url}.")
            if attempts == len(unprotected_maven_urls):
                print(f"\n\nERROR: Failed to download '{_artifact_name}' for {_group}:{_name}:{_version} from all Maven2 URLs !!!!\n\n")


if sys.argv[2] == "True":
    download_artifact(sys.argv[1], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6], sys.argv[7], sys.argv[8])
else:
    #resolve the module file first
    download_artifact('/tmp/module_file.module', sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[9], sys.argv[7])
    #process the component
    with open('/tmp/module_file.module', 'r') as json_file:
        module_data = json.load(json_file)
        renaming_aliases = {}
        for variant in module_data.get('variants', []):
            for file in variant.get('files', []):
                renaming_aliases[file['name']] = file['url']

        artifact_name = sys.argv[6]
        if renaming_aliases.get(artifact_name):
            artifact_name = renaming_aliases.get(artifact_name)

        download_artifact(sys.argv[1],sys.argv[3], sys.argv[4], sys.argv[5], artifact_name, sys.argv[7], sys.argv[8])
