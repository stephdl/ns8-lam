# Lam

Start and configure a Lam instance.
The module uses [Ldap account-manager](https://github.com/LDAPAccountManager/lam).

## Install

Instantiate the module:
```
add-module ghcr.io/nethserver/ldap:latest
```

The output of the command will return the instance name.
Output example:
```
{"module_id": "lam1", "image_name": "Lam", "image_url": "ghcr.io/nethserver/lam:latest"}
```

## Configure

Let's assume that the lam istance is named `lam1`.

Then launch `configure-module`, by setting the following parameters:
- `host`: a fully qualified domain name for the lam
- `http2https`: enable or disable HTTP to HTTPS redirection
- `lets_encrypt`: enable or disable Let's Encrypt certificate

Example:
```
api-cli run configure-module --agent module/lam1 --data - <<EOF
{
      "ldap_user_users": "administrator",
      "ldap_domain": "domain.com",
      "host": "lam.nethserver.org",
      "lets_encrypt": true,
      "http2https": true
}
EOF
```

The above command will:
- start and configure the Lam instance
- configure a virtual host for trafik to access the instance

## Uninstall

To uninstall the instance and remove traefik virtual host:
```
remove-module lam1 --no-preserve
```

## API reference

    remove-module --no-preserve lam1

## Testing

Test the module using the `test-module.sh` script:


    ./test-module.sh <NODE_ADDR> ghcr.io/nethserver/ns8-lam:latest

The tests are made using [Robot Framework](https://robotframework.org/)

## UI translation

Translated with [Weblate](https://hosted.weblate.org/projects/ns8/).

To setup the translation process:

- add [GitHub Weblate app](https://docs.weblate.org/en/latest/admin/continuous.html#github-setup) to your repository
- add your repository to [hosted.weblate.org]((https://hosted.weblate.org) or ask a NethServer developer to add it to ns8 Weblate project
