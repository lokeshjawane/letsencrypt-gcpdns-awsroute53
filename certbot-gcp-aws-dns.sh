#!/usr/bin/env bash -x

MYSELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

if [ -z "${CERTBOT_DOMAIN}" ]; then
  mkdir -p "${PWD}/letsencrypt"

  certbot certonly \
    --non-interactive \
    --manual \
    --manual-auth-hook "${MYSELF}" \
    --manual-cleanup-hook "${MYSELF}" \
    --preferred-challenge dns \
    --config-dir "${PWD}/letsencrypt" \
    --work-dir "${PWD}/letsencrypt" \
    --logs-dir "${PWD}/letsencrypt" \
    "$@"

else
 if [[ ${PROVIDER} == 'AWS' ]]; then
  [[ ${CERTBOT_AUTH_OUTPUT} ]] && ACTION="DELETE" || ACTION="UPSERT"

  printf -v QUERY 'HostedZones[?Name == `%s.`]|[?Config.PrivateZone == `false`].Id' "${CERTBOT_DOMAIN}"

  HOSTED_ZONE_ID="$(aws route53 list-hosted-zones --query "${QUERY}" --output text)"

  if [ -z "${HOSTED_ZONE_ID}" ]; then
    # CERTBOT_DOMAIN is a hostname, not a domain (zone)
    # We strip out the hostname part to leave only the domain
    DOMAIN=`echo ${CERTBOT_DOMAIN} | awk -F. 'BEGIN{OFS="."} {print $(NF-1), $(NF)}'`

    printf -v QUERY 'HostedZones[?Name == `%s.`]|[?Config.PrivateZone == `false`].Id' "${DOMAIN}"

    HOSTED_ZONE_ID="$(aws route53 list-hosted-zones --query "${QUERY}" --output text)"
  fi

  if [ -z "${HOSTED_ZONE_ID}" ]; then
    if [ -n "${DOMAIN}" ]; then
      echo "No hosted zone found that matches domain ${DOMAIN} or hostname ${CERTBOT_DOMAIN}"
    else
      echo "No hosted zone found that matches ${CERTBOT_DOMAIN}"
    fi
    exit 1
  fi

  aws route53 wait resource-record-sets-changed --id "$(
    aws route53 change-resource-record-sets \
    --hosted-zone-id "${HOSTED_ZONE_ID}" \
    --query ChangeInfo.Id --output text \
    --change-batch "{
      \"Changes\": [{
        \"Action\": \"${ACTION}\",
        \"ResourceRecordSet\": {
          \"Name\": \"_acme-challenge.${CERTBOT_DOMAIN}.\",
          \"ResourceRecords\": [{\"Value\": \"\\\"${CERTBOT_VALIDATION}\\\"\"}],
          \"Type\": \"TXT\",
          \"TTL\": 30
        }
      }]
    }"
  )"
  echo "##############################"
  echo ${CERTBOT_AUTH_OUTPUT}
  echo "##############################"

#####Run IF provider is GCP##############################

 elif [[ ${PROVIDER} == 'GCP' ]]; then
  echo "GCP"
  echo ${CERTBOT_AUTH_OUTPUT}
  [[ ${CERTBOT_AUTH_OUTPUT} ]] && ACTION=remove || ACTION=add

  gcloud dns record-sets transaction start --zone=${ZONE}
  gcloud dns record-sets transaction ${ACTION}  ${CERTBOT_VALIDATION}  --name _acme-challenge.${CERTBOT_DOMAIN} --ttl 300 --type TXT --zone ${ZONE}
  gcloud dns record-sets transaction execute --zone ${ZONE}

  echo _acme-challenge.${CERTBOT_DOMAIN}
  if [[ -z "${CERTBOT_AUTH_OUTPUT}" ]]; then
  while true ; do
    if [[ `nslookup -type=TXT  _acme-challenge.${CERTBOT_DOMAIN} | grep challenge | awk -F\" '{print $2}'` != "" && ${ACTION} == 'add' ]]; then
          break
    fi
  sleep 2
  done
  fi

 fi
#####provider IF is ending here##########################

 echo 1
fi
#####Enfding main IF#####################################
