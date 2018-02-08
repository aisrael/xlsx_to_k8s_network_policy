# xlsx_to_k8s_network_policy

Converts an Excel (`.xlsx`) spreadsheet into a Kubernetes network policy resource definition YAML file.

See [https://kubernetes.io/docs/concepts/services-networking/network-policies/](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

See test/fixtures/network_policy.xlsx, or [this Google sheet](https://docs.google.com/spreadsheets/d/e/2PACX-1vRj2xVTUJERb9oP9rBth1hbAef5XwXO5NrBUIK1HbryBFMhrE7J5YtXiWNUuxEnb3oB7kcJBKDWoIT2/pubhtml) for a sample Excel file.

#### Sample Network Policy

First, define a `Zones` sheet that contains the zones and their corresponding network CIDRs. Separate multiple CIDRs using commas. For example:

|Zone          |CIDRs                     |
|--------------|--------------------------|
|Front End     |10.10.1.0/24, 10.10.2.0/24|
|Back End      |10.11.0.0/24              |
|Infrastructure|10.12.0.0/24              |

Next, define a `ZoneToZone` sheet that defines the zone to zone network access. For example:

|              |Front End|Back End|Infrastructure|
|--------------|---------|--------|--------------|
|Front End     |Y        |Y       |N             |
|Back End      |         |Y       |Y             |
|Infrastructure|         |        |Y             |

This defines rules that allow intra-zone traffic for all zones, and one-way traffic from the `Front End` zone to the `Back End` zone, and from the `Back End` zone to the `Infrastructure` zone.


#### Generated YAML

That Excel file generates the following YAML file:

```
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: front-end-zone
spec:
  podSelector:
    matchLabels:
      zone: front-end
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          zone: front-end
    - ipBlock: 10.10.1.0/24
    - ipBlock: 10.10.2.0/24
  egress:
  - to:
    - podSelector:
        matchLabels:
          zone: front-end
    - ipBlock: 10.10.1.0/24
    - ipBlock: 10.10.2.0/24
    - podSelector:
        matchLabels:
          zone: back-end
    - ipBlock: 10.11.0.0/24
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: back-end-zone
spec:
  podSelector:
    matchLabels:
      zone: back-end
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          zone: back-end
    - ipBlock: 10.11.0.0/24
    - podSelector:
        matchLabels:
          zone: front-end
    - ipBlock: 10.10.1.0/24
    - ipBlock: 10.10.2.0/24
  egress:
  - to:
    - podSelector:
        matchLabels:
          zone: back-end
    - ipBlock: 10.11.0.0/24
    - podSelector:
        matchLabels:
          zone: infrastructure
    - ipBlock: 10.12.0.0/24
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: infrastructure-zone
spec:
  podSelector:
    matchLabels:
      zone: infrastructure
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          zone: infrastructure
    - ipBlock: 10.12.0.0/24
    - podSelector:
        matchLabels:
          zone: back-end
    - ipBlock: 10.11.0.0/24
  egress:
  - to:
    - podSelector:
        matchLabels:
          zone: infrastructure
    - ipBlock: 10.12.0.0/24
```

#### Contributing to `xlsx_to_k8s_network_policy`
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

#### Copyright

Copyright (c) 2018 Alistair A. Israel. See LICENSE.txt for
further details.
