# Summary
Issue/Manage  Letsencrypt SSL with DNS TXT based domain verification. This script manage the DNS TXT record(create and delete) on GCP DNS & AWS route53 while issuing the SSL from letsencrypt.

## Pre-requisites
`Certbot` utility should be installed on machine, [Installation link](https://certbot.eff.org/)

## Variables
For AWS route53
```
PROVIDER=GCP
```

For GCP DNS
```
PROVIDER=GCP
ZONE=<zone name>
```

## How to?
For AWS:
```
PROVIDER=AWS bash certbot-gcp-aws-dns.sh --agree-tos --manual-public-ip-logging-ok --domains <subdomain name> --email <your email addr>
```
For GCP:
```
PROVIDER=GCP ZONE=example bash certbot-gcp-aws-dns.sh --agree-tos --manual-public-ip-logging-ok --domains <subdomain name> --email <your email addr> --expand
```

All issued certificate will be save inside "letsencrypt" in the current directory
