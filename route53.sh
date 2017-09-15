#!/bin/bash

### route53.sh
### For use in LEDE / OpenWRT DDNS scenarios
###
### Requires: curl, openssl-util

set -euo pipefail
IFS=$'\n\t'

ENDPOINT="route53.amazonaws.com"
RECORD_TTL=300
#RECORD_NAME=""
RECORD_TYPE="A"
RECORD_VALUE="1.2.3.4"
HOSTED_ZONE_ID=""
API_PATH="/2013-04-01/hostedzone/${HOSTED_ZONE_ID}/rrset/"

# AWS_ACCESS_KEY_ID=''
# AWS_SECRET_ACCESS_KEY=''
AWS_REGION='us-east-1'
AWS_SERVICE='route53domains'

request_body="
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<ChangeResourceRecordSetsRequest xmlns=\"https://route53.amazonaws.com/doc/2013-04-01/\">
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
"

fulldate=$(date -Iseconds)
shortdate=$(date +%Y%m%d)
signed_headers="host;z-amx-date"
canonical_request="POST\n${PATH}\n\nhost:route53.amazon.com\nx-amz-date:${fulldate}\n\n${signed_headers}\n$(hash "${request_body}")"

hash() {
    msg=$1
    echo -n "$msg" | openssl dgst -sha256 | sed 's/^.* //'
}

sign() {
    key=$1
    msg=$2
    echo -n "$msg" | openssl dgst -sha256 -hmac "$key" | sed 's/^.* //'
}

getSignatureKey() {
    # usage: getSignatureKey date region service
    date_key=$(sign "AWS4${AWS_SECRET_ACCESS_KEY_ID}" "${shortdate}")
    region_key=$(sign "$date_key" $AWS_REGION)
    service_key=$(sign "$region_key" $AWS_SERVICE)
    signing_key=$(sign "$service_key" aws4_request)
    echo -n "$signing_key"
}

credential="${shortdate}/${AWS_REGION}/${AWS_SERVICE}/aws4_request"
sigmsg="AWS4-HMAC-SHA256\n${credential}\n$(hash "$(echo -e canonical_request)")"
sigkey=$(getSignatureKey)
signature=$(sign sigkey sigmsg)

authorization="AWS4-HMAC-SHA256 Credential=${AWS_ACCESS_KEY_ID}/${credential},SignedHeaders=${signed_headers},Signature=${signature}"

curl \
    -X "POST" \
    -H "host:route53.amazonaws.com" \
    -H "x-amz-date:${fulldate}" \
    -H "authorization:${authorization}}" \
    --data "$request_body" \
    "https://${ENDPOINT}${API_PATH}"
