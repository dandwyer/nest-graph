#!/usr/bin/python3

import json
import nest
import oauthlib
import os
import pathlib

print("Nest Authenticator")
access_token_cache_file = "/data/nest.json"


def get_param_from_env_or_user(environment_variable_name: str, user_prompt: str) -> str:
    """Get a parameter from environment variable or user."""
    param_value = os.getenv(environment_variable_name)
    if not param_value:
        param_value = input(user_prompt)
    return param_value.strip()


nest_config_json_file = pathlib.Path("/data/nest-config.json")
if nest_config_json_file.is_file() and (f := open(nest_config_json_file, "r")):
    # Try to get parameters from the nest-config.json file
    j = json.load(f)
    project_id = j.get("project_id")
    client_id = j.get("client_id")
    client_secret = j.get("client_secret")
    assert access_token_cache_file == j.get(
        "access_token_cache_file"
    ), "Access token cache file does not match expected path"
else:
    # Otherwise, try to get parameters from environment variable or user
    # as last resort
    project_id = get_param_from_env_or_user("NEST_PROJECT_ID", "Project ID: ")
    client_id = get_param_from_env_or_user("NEST_OATH_CLIENT_ID", "Client ID: ")
    client_secret = get_param_from_env_or_user(
        "NEST_OATH_CLIENT_SECRET", "Client Secret: "
    )


def reauthorize_callback(url):
    print("Go here and follow the instructions")
    print(url)
    result_url = input(
        "Paste the final url you landed on from Google's auth flow (e.g.google.com?state=...): "
    )
    return result_url


def create_or_confirm_validity_of_access_token_cache_file(
    client_id: str,
    client_secret: str,
    project_id: str,
    access_token_cache_file: str,
    reauthorize_callback: callable,
):
    with nest.Nest(
        client_id=client_id,
        client_secret=client_secret,
        project_id=project_id,
        access_token_cache_file=access_token_cache_file,
        reautherize_callback=reauthorize_callback,
    ) as napi:
        # Will trigger initial auth and fetch of data
        devices = napi.get_devices()
        print(devices)
        with open(nest_config_json_file, "w") as fp:
            json.dump(
                {
                    "project_id": project_id,
                    "client_id": client_id,
                    "client_secret": client_secret,
                    "access_token_cache_file": access_token_cache_file,
                },
                fp,
            )


try:
    create_or_confirm_validity_of_access_token_cache_file(
        client_id=client_id,
        client_secret=client_secret,
        project_id=project_id,
        access_token_cache_file=access_token_cache_file,
        reauthorize_callback=reauthorize_callback,
    )
except oauthlib.oauth2.rfc6749.errors.InvalidGrantError as e:
    print(f"Nest API error: {e}")
    pathlib.Path.unlink(access_token_cache_file)
    create_or_confirm_validity_of_access_token_cache_file(
        client_id=client_id,
        client_secret=client_secret,
        project_id=project_id,
        access_token_cache_file=access_token_cache_file,
        reauthorize_callback=reauthorize_callback,
    )
