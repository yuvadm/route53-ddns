# route53-ddns

A simple `{b,d,}ash` script aimed for usage on LEDE/OpenWRT devices which enables sending DDNS updates to Route53.

Attempts to reduce the Route53 REST API call dependencies on the minimum amount of additional packages.

## Requirements

 - [ca-bundle](https://lede-project.org/packages/pkgdata/ca-bundle)
 - [curl](https://lede-project.org/packages/pkgdata/curl)
 - [openssl-util](https://lede-project.org/packages/pkgdata/openssl-util)

## Usage

```bash
$ export HOSTED_ZONE_ID=ABCDEFGHIJKL
$ export AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXX
$ export AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXX
$ export RECORD_NAME=foo.example.com
$ export RECORD_VALUE=1.2.3.4
$ ./route53.sh
<?xml version="1.0"?>
<ChangeResourceRecordSetsResponse xmlns="https://route53.amazonaws.com/doc/2013-04-01/"><ChangeInfo><Id>/change/C1R7XXXXXXXX</Id><Status>PENDING</Status><SubmittedAt>2017-09-15T14:03:18.167Z</SubmittedAt></ChangeInfo></ChangeResourceRecordSetsResponse>
```

## Test

```bash
$ shellcheck -s ash -e SC2169 route53.sh
```

## License

Released under [GPLv3](LICENSE)

Copyright (C) 2017 by Yuval Adam
