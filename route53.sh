#!/bin/bash

# route53.sh

# Copyright (C) 2017 by Yuval Adam
# All rights reserved

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

set -euo pipefail
IFS=$'\n\t'

ENDPOINT="route53.amazonaws.com"
RECORD_TTL=300
#RECORD_NAME=""
RECORD_TYPE="A"
#RECORD_VALUE=""
#HOSTED_ZONE_ID=""
API_PATH="/2013-04-01/hostedzone/${HOSTED_ZONE_ID}/rrset/"

# AWS_ACCESS_KEY_ID=''
# AWS_SECRET_ACCESS_KEY=''
AWS_REGION='us-east-1'
AWS_SERVICE='route53'

hash() {
    msg=$1
    echo -en "$msg" | openssl dgst -sha256 | sed 's/^.* //'
}

sign_plain() {
    # Sign message using a plaintext key
    key=$1
    msg=$2
    echo -en "$msg" | openssl dgst -hex -sha256 -hmac "$key" | sed 's/^.* //'
}

sign() {
    # Sign message using a hex formatted key
    key=$1
    msg=$2
    echo -en "$msg" | openssl dgst -hex -sha256 -mac HMAC -macopt "hexkey:${key}" | sed 's/^.* //'
}

request_body="<?xml version=\"1.0\" encoding=\"UTF-8\"?> \
<ChangeResourceRecordSetsRequest xmlns=\"https://route53.amazonaws.com/doc/2013-04-01/\"> \
<ChangeBatch> \
   <Changes> \
      <Change> \
         <Action>UPSERT</Action> \
         <ResourceRecordSet> \
            <Name>${RECORD_NAME}</Name> \
            <Type>${RECORD_TYPE}</Type> \
            <TTL>${RECORD_TTL}</TTL> \
            <ResourceRecords> \
               <ResourceRecord> \
                  <Value>${RECORD_VALUE}</Value> \
               </ResourceRecord> \
            </ResourceRecords> \
         </ResourceRecordSet> \
      </Change> \
   </Changes> \
</ChangeBatch> \
</ChangeResourceRecordSetsRequest>"

fulldate=$(date --utc +%Y%m%dT%H%M%SZ)
shortdate=$(date --utc +%Y%m%d)
signed_headers="host;x-amz-date"
request_hash=$(hash "$request_body")
canonical_request="POST\n${API_PATH}\n\nhost:route53.amazonaws.com\nx-amz-date:${fulldate}\n\n${signed_headers}\n${request_hash}"

date_key=$(sign_plain "AWS4${AWS_SECRET_ACCESS_KEY}" "${shortdate}")
region_key=$(sign "$date_key" $AWS_REGION)
service_key=$(sign "$region_key" $AWS_SERVICE)
signing_key=$(sign "$service_key" aws4_request)

credential="${shortdate}/${AWS_REGION}/${AWS_SERVICE}/aws4_request"
sigmsg="AWS4-HMAC-SHA256\n${fulldate}\n${credential}\n$(hash "$canonical_request")"

signature=$(sign "$signing_key" "$sigmsg")

authorization="AWS4-HMAC-SHA256 Credential=${AWS_ACCESS_KEY_ID}/${credential}, SignedHeaders=${signed_headers}, Signature=${signature}"

curl \
    -X "POST" \
    -H "Host: route53.amazonaws.com" \
    -H "X-Amz-Date: ${fulldate}" \
    -H "Authorization: ${authorization}" \
    -H "Content-Type: text/xml" \
    -d "$request_body" \
    "https://${ENDPOINT}${API_PATH}"
