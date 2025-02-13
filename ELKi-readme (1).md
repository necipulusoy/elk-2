# INSTALL 3 NODES ELASTICSEARCH,LOGSTASH, KIBANA and FileBeat

[elastic-install-link](https://www.elastic.co/guide/en/elasticsearch/reference/current/install-elasticsearch.html)
[logstash-install-link](https://www.elastic.co/guide/en/logstash/current/installing-logstash.html)
[kibana-install-link](https://www.elastic.co/guide/en/kibana/current/install.html)
[filebeat-install-link](https://artifacthub.io/packages/helm/elastic/filebeat)


### ELASTICSEARCH

## Install Elasticsearch-1

- Download and install the public signing key

```bash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
```

- You may need to install the apt-transport-https package on Debian before proceeding

```bash
sudo apt-get install apt-transport-https
```

- Save the repository definition to /etc/apt/sources.list.d/elastic-8.x.list

```bash
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
```

- You can install the Elasticsearch Debian package with

```bash
sudo apt-get update && sudo apt-get install elasticsearch
```

When installing Elasticsearch, security features are enabled and configured by default. When you install Elasticsearch, the following security configuration occurs automatically:

- Authentication and authorization are enabled, and a password is generated for the elastic built-in superuser.
- Certificates and keys for TLS are generated for the transport and HTTP layer, and TLS is enabled and configured with these keys and certificates.

The password and certificate and keys are output to your terminal.

- Go to /etc/elasticsearch/elasticsearch.yml config file and update below parameters 

```bash
cluster.name: "tg-elk"
node.name: "es-1"
network.host: 172.19.24.8
http.port: 9200
```

If you want to store Elasticsearch's own logs and the logs it retains in a different folder, you need to update the following parameters. For example, if you have attached an additional volume to an AWS instance and want to keep the logs on this volume, you need to update the paths below according to the mounted volume path.

```bash
# ----------------------------------- Paths ------------------------------------
#
# Path to directory where to store the data (separate multiple locations by comma):
#
path.data: /data/elasticsearch
#
# Path to log files:
#
path.logs: /var/log/elasticsearch
```

- To create folders in a specified path and set the necessary permissions

```bash
mkdir -p /data/elasticsearch
chown -R elasticsearch:elasticsearch /data/elasticsearch
chmod -R 755 /data/elasticsearch
```


- To configure Elasticsearch to start automatically when the system boots up, run the following commands

```bash
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service
sudo systemctl start elasticsearch.service
```

- You can test that your Elasticsearch node is running by sending an HTTPS request to port 9200 on localhost

```bash
export ELASTIC_PASSWORD="xxx" # change me
curl --cacert /etc/elasticsearch/certs/http_ca.crt -u elastic:$ELASTIC_PASSWORD https://localhost:9200 

```



- The call returns a response like this

```bash
curl --cacert /etc/elasticsearch/certs/http_ca.crt -u elastic:$ELASTIC_PASSWORD https://localhost:9200
{
  "name" : "es-1",
  "cluster_name" : "tg-elk",
  "cluster_uuid" : "k9dPKjHpQ_-7ozutlGOgqQ",
  "version" : {
    "number" : "8.16.1",
    "build_flavor" : "default",
    "build_type" : "deb",
    "build_hash" : "ffe992aa682c1968b5df375b5095b3a21f122bf3",
    "build_date" : "2024-11-19T16:00:31.793213192Z",
    "build_snapshot" : false,
    "lucene_version" : "9.12.0",
    "minimum_wire_compatibility_version" : "7.17.0",
    "minimum_index_compatibility_version" : "7.0.0"
  },
  "tagline" : "You Know, for Search"
}
```

## Install ElasticSearch-2

- Download and install the public signing key

```bash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
```

- You may need to install the apt-transport-https package on Debian before proceeding

```bash
sudo apt-get install apt-transport-https
```

- Save the repository definition to /etc/apt/sources.list.d/elastic-8.x.list

```bash
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
```

- You can install the Elasticsearch Debian package with

```bash
sudo apt-get update && sudo apt-get install elasticsearch
```

Reconfigure a node to join an existing cluster

- Go to Elasticsearch-1 terminal and generate a node enrollment token

Note: This token is only valid for 30 minutes. When you need to add a new node in the future, you must generate a new token

```bash
/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s node
```

- Save and Copy the enrollment token, which is output to your terminal 

- On your new Elasticsearch node, pass the enrollment token 

```bash
/usr/share/elasticsearch/bin/elasticsearch-reconfigure-node --enrollment-token <enrollment-token>
```

- Go to /etc/elasticsearch/elasticsearch.yml file update below parameter and See that the security config section is created and the discovery.seed_hosts parameter is added with the IP address of elasticsearch-1

```bash
cluster.name: <same name elasticsearch-1 config>
node.name: "es-2"
network.host: <vm-ip>
http.port: 9200
```

If you want to store Elasticsearch's own logs and the logs it retains in a different folder, you need to update the following parameters. For example, if you have attached an additional volume to an AWS instance and want to keep the logs on this volume, you need to update the paths below according to the mounted volume path.


```bash
# ----------------------------------- Paths ------------------------------------
#
# Path to directory where to store the data (separate multiple locations by comma):
#
path.data: /data/elasticsearch
#
# Path to log files:
#
path.logs: /var/log/elasticsearch
```


```bash
#----------------------- BEGIN SECURITY AUTO CONFIGURATION -----------------------
#
# The following settings, TLS certificates, and keys have been automatically      
# generated to configure Elasticsearch security features on 28-05-2024 11:00:39
#
# --------------------------------------------------------------------------------

# Enable security features
xpack.security.enabled: true

xpack.security.enrollment.enabled: true

# Enable encryption for HTTP API client connections, such as Kibana, Logstash, and Agents
xpack.security.http.ssl:
  enabled: true
  keystore.path: certs/http.p12

# Enable encryption and mutual authentication between cluster nodes
xpack.security.transport.ssl:
  enabled: true
  verification_mode: certificate
  keystore.path: certs/transport.p12
  truststore.path: certs/transport.p12
# Discover existing nodes in the cluster
discovery.seed_hosts: ["172.19.24.8:9300"]  #elasticsearch-1 ip adress

# Allow HTTP API connections from anywhere
# Connections are encrypted and require user authentication
http.host: 0.0.0.0

# Allow other nodes to join the cluster from anywhere
# Connections are encrypted and mutually authenticated
transport.host: 0.0.0.0

#----------------------- END SECURITY AUTO CONFIGURATION -------------------------
```
- To create folders in a specified path and set the necessary permissions

```bash
mkdir -p /data/elasticsearch
chown -R elasticsearch:elasticsearch /data/elasticsearch
chmod -R 755 /data/elasticsearch
```
- To configure Elasticsearch-2 to start automatically when the system boots up, run the following commands

```bash
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service
sudo systemctl start elasticsearch.service
```

- Check whether elasticsearch-2 added existing cluster

```bash
export ELASTIC_PASSWORD="XXXXXXXXXXXX" # change me
curl --cacert /etc/elasticsearch/certs/http_ca.crt -u elastic:$ELASTIC_PASSWORD https://localhost:9200/_cluster/health?pretty 
```
- The call returns a response like this

```bash
{
  "cluster_name" : "tg-elk",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 2,
  "number_of_data_nodes" : 2,
  "active_primary_shards" : 3,
  "active_shards" : 6,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "unassigned_primary_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 100.0
}
```

- Check Which node is master

```bash
curl --cacert /etc/elasticsearch/certs/http_ca.crt -u elastic:$ELASTIC_PASSWORD https://localhost:9200/_cat/master?v
```


## Install ElasticSearch-3 and Join existing Cluster.

- Repeat the same steps we performed for Elasticsearch-2 for Elasticsearch-3

NOTE: When a new node is added to an existing Elasticsearch cluster using a token, the IP addresses of all the nodes in the cluster are added to the discovery.seed_hosts parameter of the new node. However, the IP address of the newly added node is not added to the existing nodes' configurations. You need to add this new node's IP address to the discovery.seed_hosts parameter of the existing nodes manually.

node-1 /etc/elasticsearch/elasticsearch.yml
node-2 /etc/elasticsearch/elasticsearch.yml
node-3 /etc/elasticsearch/elasticsearch.yml

```bash
discovery.seed_hosts: ["<all-vm-ip-address:port>"] #You need to manually add the IP addresses of all subsequently added nodes
```

- check node and cluster

```bash
for es health
curl --cacert /etc/elasticsearch/certs/http_ca.crt -u elastic:$ELASTIC_PASSWORD https://localhost:9200

check cluster health
curl --cacert /etc/elasticsearch/certs/http_ca.crt -u elastic:$ELASTIC_PASSWORD https://localhost:9200/_cluster/health?pretty

check which one master
curl --cacert /etc/elasticsearch/certs/http_ca.crt -u elastic:$ELASTIC_PASSWORD https://localhost:9200/_cat/master?v
```

## Install Kibana 

- Import the Elastic PGP key

```bash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
```

- You may need to install the apt-transport-https package on Debian before proceeding

```bash
sudo apt-get install apt-transport-https
```

- Save the repository definition to /etc/apt/sources.list.d/elastic-8.x.list

```bash
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
```

- You can install the Kibana Debian package with

```bash
sudo apt-get update && sudo apt-get install kibana
```

- To configure Kibana to start automatically when the system starts, run the following commands

```bash
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable kibana.service
sudo systemctl start kibana.service
```

- Go to Elasticsearch-1 terminal and generate  enrollment token for kibana

Note: This token is only valid for 30 minutes. When you need to add a new node in the future, you must generate a new token

```bash
/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana
```

- Go to localhost:5601 adress and paste enrollment token for kibana and click auto configure for elasticsearch

- Go to kibana server and run command and paste the verification code

```bash
/usr/share/kibana/bin/kibana-verification-code
```

```bash
username: elastic
password: <elasticsearch-password>
```


## Install Logstash

- Download and install the Public Signing Key


```bash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elastic-keyring.gpg
```

- You may need to install the apt-transport-https package on Debian before proceeding

```bash
sudo apt-get install apt-transport-https
```

- Save the repository definition to /etc/apt/sources.list.d/elastic-8.x.list

```bash
echo "deb [signed-by=/usr/share/keyrings/elastic-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-8.x.list
```

- Run sudo apt-get update and the repository is ready for use. You can install it with

```bash
sudo apt-get update && sudo apt-get install logstash
```

- Logstash needs to securely send logs to Elasticsearch via HTTPS, which requires us to copy the http_ca.crt certificate located under the /etc/elasticsearch/certs/ path in Elasticsearch to Logstash.

Create a folder under /etc/logstash named certs in logstash

```bash
mkdir -p /etc/logstash/certs
```

copy /etc/elasticsearch/certs/http_ca.crt file to /etc/logstash/certs/http_ca.crt  in logstash


```bash
vi http_ca.crt 
```

- Go to /etc/logstash/jvm.options and update below parameters depends on logstash vm memory size.Best practice %50

```bash
## JVM configuration

# Xms represents the initial size of total heap space
# Xmx represents the maximum size of total heap space
-Xms4g  #memory 8gb
-Xmx4g
```


- Go to /etc/logstash/conf.d folder in logstash and create new file .conf extension

```bash
vi tg-prod.conf

input {
  beats {
   port => 5044
  }
}

filter {
}

output {
      elasticsearch {
         hosts => ["https://172.19.24.8:9200", "https://172.19.24.9:9200", "https://172.19.24.10:9200"]
         data_stream => "true"
         #data_stream_type => "logs"
         data_stream_dataset => "tg-prod"
         data_stream_namespace => "default"
         ssl_enabled => true
         ssl_certificate_authorities => "/etc/logstash/certs/http_ca.crt"
         ssl_verification_mode => "full"
         user => "ChangeMe"
         password => "ChangeMe"
         compression_level => 3
      }
}

```


- Update <elasticsearch-ips>, index,user and password.
- You can add filter based on the status of the logs
- You can check whether Logstash has established a connection with Elasticsearch by inspecting the /var/log/logstash/logstash-plain.log file

- Start and Enable logstash

```bash
sudo systemctl start logstash.service
sudo systemctl enable logstash.service
```

To check if your Logstash pipeline is running, you can use this command. This command will help you ensure that Logstash is properly configured and running

```bash
tail -f /var/log/logstash/logstash-plain.log
```

- The call returns a response like this.

```bash
[2024-05-28T12:07:11,925][INFO ][logstash.outputs.elasticsearch][main] Installing Elasticsearch template {:name=>"ecs-logstash"}
[2024-05-28T12:07:12,549][INFO ][logstash.javapipeline    ][main] Pipeline Java execution initialization time {"seconds"=>0.7}
[2024-05-28T12:07:12,559][INFO ][logstash.inputs.beats    ][main] Starting input listener {:address=>"0.0.0.0:5044"}
[2024-05-28T12:07:12,568][INFO ][logstash.javapipeline    ][main] Pipeline started {"pipeline.id"=>"main"}
[2024-05-28T12:07:12,588][INFO ][logstash.agent           ] Pipelines running {:count=>1, :running_pipelines=>[:main], :non_running_pipelines=>[]}
```


## Filebeat Installation

- Create a `filebeat-values.yaml` 

```bash
vi filebeat-values.yaml 
```

```yaml
daemonset:
  extraEnvs:
    - name: "ELASTICSEARCH_USERNAME"
      valueFrom:
        secretKeyRef:
          name: elasticsearch-master-credentials
          key: username
    - name: "ELASTICSEARCH_PASSWORD"
      valueFrom:
        secretKeyRef:
          name: elasticsearch-master-credentials
          key: password
  hostNetworking: false
  secretMounts:
    - name: elasticsearch-master-certs
      secretName: elasticsearch-master-certs
      path: /usr/share/filebeat/certs/
  filebeatConfig:
    filebeat.yml: |
      filebeat.config:
        modules:
          path: ${path.config}/modules.d/*.yml
          # Reload module configs as they change:
          reload.enabled: false
      filebeat.autodiscover:
        providers:
          - type: kubernetes
            templates:
              - condition:
                  not:
                    or:
                      - equals:
                          kubernetes.namespace: "kube-system"
                      - equals: 
                          kubernetes.namespace: "calico-system"
                      - equals:
                          kubernetes.namespace: "default"
                      - equals:
                          kubernetes.namespace: "elastic-system"
                      - equals: 
                          kubernetes.namespace: "instana-agent"
                      - equals:
                          kubernetes.namespace: "ingress-basic"
                      - equals:
                          kubernetes.namespace: "kube-public"
                      - equals: 
                          kubernetes.namespace: "kube-node-lease"
                      - equals:
                          kubernetes.namespace: "monitoring"
                      - equals:
                          kubernetes.namespace: "tigera-operator"

                config:
                  - type: container
                    paths:
                      - /var/log/containers/*-${data.kubernetes.container.id}.log
                    containers.ids:
                      -  "${data.kubernetes.container.id}"
      output.logstash:
        hosts: ["172.19.24.11:5044"]

      processors:
        - include_fields: 
            fields: ["kubernetes.deployment.name", "container.image.name", "kubernetes.namespace", "kubernetes.node.name", "kubernetes.pod.name", "message", "kubernetes.pod.ip", "kubernetes cronjob.name"]

  maxUnavailable: 1
  securityContext:
    runAsUser: 0
    privileged: false
  resources:
    requests:
      cpu: "100m"
      memory: "100Mi"
    limits:
      cpu: "1000m"
      memory: "500Mi"
  tolerations:
          - key: node-role.kubernetes.io/control-plane
            effect: NoSchedule
          - key: node-role.kubernetes.io/master
            effect: NoSchedule
          - key: workload
            operator: Equal
            value: b2b
          - key: workload
            operator: Equal
            value: appuser
          - key: workload
            operator: Equal
            value: merch
          - key: workload
            operator: Equal
            value: newuser
          - key: workload
            operator: Equal
            value: order

replicas: 1

hostPathRoot: /var/lib

image: "docker.elastic.co/beats/filebeat"
imageTag: "8.5.1"
imagePullPolicy: "IfNotPresent"
imagePullSecrets: []

livenessProbe:
  exec:
    command:
      - sh
      - -c
      - |
        #!/usr/bin/env bash -e
        curl --fail 127.0.0.1:5066
  failureThreshold: 3
  initialDelaySeconds: 10
  periodSeconds: 10
  timeoutSeconds: 5

readinessProbe:
  exec:
    command:
      - sh
      - -c
      - |
        #!/usr/bin/env bash -e
        filebeat test output
  failureThreshold: 3
  initialDelaySeconds: 10
  periodSeconds: 10
  timeoutSeconds: 5

managedServiceAccount: true

clusterRoleRules:
  - apiGroups:
      - ""
    resources:
      - namespaces
      - nodes
      - pods
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - "apps"
    resources:
      - replicasets
    verbs:
      - get
      - list
      - watch

updateStrategy: RollingUpdate

nameOverride: ""
fullnameOverride: ""
```

- Create a `Secret` for Elasticsearch credentials

```bash
vi elasticsearch-master-credentials.yaml
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: elasticsearch-master-credentials
  namespace: logging
data:
  username: <BASE64_ENCODED_USERNAME>
  password: <BASE64_ENCODED_PASSWORD>
```

- Create a `Secret` for Elasticsearch certificates

```bash
vi elasticsearch-master-certs.yaml
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: elasticsearch-master-certs
  namespace: logging
data:
  ca.crt: |
  <BASE64_ENCODED_CA_CERT>
```

Note: If a namespace named logging does not already exist, create a namespace named logging

- Apply the Secrets

```bash
kubectl apply -f elasticsearch-master-credentials.yaml
kubectl apply -f elasticsearch-master-certs.yaml
```

- Install Filebeat with Helm

```bash
helm repo add elastic https://helm.elastic.co
helm upgrade --install filebeat elastic/filebeat --version 8.5.1 -n logging -f filebeat-values.yaml
```

## Index Life Cycle Management

### Index Lifecycle Policy

- Go to Kibana UI and select Stack Management Under Left Hand Menu

- Click Index Lifecycle Policies and Create Policy section.

- Give a name whatever you want such as `tg-policy` and determine your necessity for example --> `Maximum primary shard size: 30`  , `Maximum age: 15`  under Hot phase --> Advance Settings.

- Enable `Delete data after this phase` section and determine `Move data into phase when` under `Delete Phase`. such as 15 days and save policy.
 
### Index Template

- Go to Kibana UI and select Stack Management Under Left Hand Menu.

- Click Index Management, Click Index Templates and Create Template button.

- Enter Index Template Name and Index Index pattern such as `logs-tg-prod-default`. Enable `Create data stream` Click Next button.

- Leave as a Default `Component templates` Section and click Next button.

- Add Parameter as a your necessity like as and click next
```json
{
  "index": {
    "lifecycle": {
      "name": "tg-policy"
    },
    "number_of_shards": "1",
    "number_of_replicas": "1"
  }
}
```

-  Leave as a Default `Mapping` Section and click Next button.

- Leave as a Default `Aliases (optional)` Section and click Next button.

- Lastly save template.

### Create Index via Dev Tool

- Go to Kibana UI and select Dev Tool from Left Hand Menu under Management Section.

- Paste below command and run.

```json
PUT /logs-tg-prod-default
```

### Check your Index Policy and Template

- Go to Kibana UI and select Stack Management Under Left Hand Menu.

- Click Index Management section and select Data Stream.

- Select your Index and Check your `Index lifecycle policy` and Index `template`.

## Enable Stack Monitoring
- Go to Kibana WebUI,click hamburger menu and select Stack Monitoring.

- Click metricbeat configuration

- Go to elasticsearch-1 VM terminal and Install Metricbeat

```bash
curl -L -O https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-8.17.0-amd64.deb
sudo dpkg -i metricbeat-8.17.0-amd64.deb
```

- Set the host and port where Metricbeat can find the Elasticsearch installation, and set the username and password of a user who is authorized to set up Metricbeat 

`/etc/metricbeat/metricbeat.yml`

```bash
setup.kibana:
  host: "https://172.19.24.12:5601"

output.elasticsearch:
  hosts: ["https://172.19.24.8:9200", "https://172.19.24.9:9200", "https://172.19.24.10:9200"]
  preset: balanced
  protocol: "https"
  username: "elastic"
  password: <elasticsearch-password> #update
  ssl:
    enabled: true
    ca_trusted_fingerprint: <update>
```

- You can learn ca_trusted_fingerprint by using below command:

```bash
openssl x509 -fingerprint -sha256 -in /etc/elasticsearch/certs/http_ca.crt
```

```bash
9D:18:8D:D7:45:85:7F:43:27:D2:5B:40:67:0A:7E:C4:15:EB:CF:11:2F:77:07:CD:C9:EF:18:C2:3D:EC:D3:CB
```
- Remove the colons and convert all letters to lowercase you can use this website `https://convertcase.net/` or chatgpt :-)

- Enable the Elasticsearch module in Metricbeat on each Elasticsearch node.

```bash
metricbeat modules enable elasticsearch-xpack
```

Configure the Elasticsearch module in Metricbeat on Elasticsearch node. First create /etc/metricbeat/http_ca.crt file and add elasticsearch /etc/elasticsearch/certs/http_ca.crt to this file 

```bash
/etc/metricbeat/modules.d/elasticsearch-xpack.yml

- module: elasticsearch
  xpack.enabled: true
  period: 10s
  hosts: ["https://localhost:9200"]
  username: "elastic"
  password: <elasticsearch-password> #update
  ssl.enabled: true
  ssl.certificate_authorities: ["/etc/metricbeat/http_ca.crt"]
```

- Start and enabled metricbeat

```bash
systemctl start metricbeat
systemctl enable metricbeat
```

- Set xpack.monitoring.collection.enabled to true on the Elasticcluster. By default, it is is disabled (false).

Run Dev Tools


```bash
PUT _cluster/settings
{
  "persistent": {
    "xpack.monitoring.collection.enabled": true
  }
}
```

```bash
PUT _cluster/settings
{
  "persistent": {
    "xpack.monitoring.history.duration" : "2d"
  }
}
```

- Bu komutları tek tek serverlara girmemiz gerekiyor ki versionlar sabit kalsın ElastichSearch ile kibana aynı sürüm olması lazım

```bash
sudo apt-mark hold kibana
sudo apt-mark hold elasticsearch
```
