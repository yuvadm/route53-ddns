#!/bin/bash

### route53.sh
### For use in LEDE / OpenWRT DDNS scenarios
###
### Requires: curl, openssl-util

set -euo pipefail
IFS=$'\n\t'

ENDPOINT="route53.amazonaws.com"
RECORD_TTL=300
RECORD_NAME=""
RECORD_TYPE="A"
RECORD_VALUE="1.2.3.4"
HOSTED_ZONE_ID=""
PATH="/2013-04-01/hostedzone/${HOSTED_ZONE_ID}/rrset/"

AWS_ACCESS_KEY_ID=''
AWS_SECRET_ACCESS_KEY=''
AWS_REGION='us-east-1'
AWS_SERVICE='route53domains'

date=`date +%Y%m%d`

request_body=$(cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<ChangeResourceRecordSetsRequest xmlns="https://route53.amazonaws.com/doc/2013-04-01/">
<ChangeBatch>
   <Changes>
      <Change>
         <Action>UPSERT</Action>
         <ResourceRecordSet>
            <Name>${RECORD_NAME}</Name>
            <Type>${RECORD_TYPE}</Type>
            <TTL>${RECORD_TTL}</TTL>
            <ResourceRecords>
               <ResourceRecord>
                  <Value>${RECORD_VALUE}</Value>
               </ResourceRecord>
            </ResourceRecords>
         </ResourceRecordSet>
      </Change>
   </Changes>
</ChangeBatch>
</ChangeResourceRecordSetsRequest>
EOF
)

canonical_request="POST\n${PATH}\n\nhost:route53.amazon.com\nx-amz-date:`date -Iseconds`\n\nhost;x-amz-date"

sign() {
    key=$1
    msg=$2
    echo -n $msg | openssl dgst -sha256 -hmac $key | sed 's/^.* //'
}

getSignatureKey() {
    # usage: getSignatureKey date region service
    date_key=$(sign AWS4${AWS_SECRET_ACCESS_KEY_ID} ${date})
    region_key=$(sign $date_key $AWS_REGION)
    service_key=$(sign $region_key $AWS_SERVICE)
    signing_key=$(sign $service_key aws4_request)
    echo -n $signing_key
}

amzdate=`date -Iseconds`

credential="${AWS_ACCESS_KEY_ID}/${date}/${AWS_REGION}/${AWS_SERVICE}/aws4_request"
signed_headers="host;x-amz-date"
signature=""
authorization="AWS4-HMAC-SHA256 Credential=${credential},SignedHeaders=${signed_headers},Signature=${signature}"

curl \
    -H "x-amz-date=`date -Iseconds`" \
    -H "Authorization=${authorization}}"
    "https://${ENDPOINT}"
