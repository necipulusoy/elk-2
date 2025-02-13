# Ansible playbook for ELK + Filebeat Setup

## Scenario

There are 6 VMs in this configuration: 1 for Bastion Host, 3 for Elasticsearch, 1 for Logstash, 1 for Kibana. Also, attach volumes to Elasticsearch VMs. Then, connect to bastion host to start the configuration. In addition, you can find the playbooks of seperately configuration of ELK components in the `elk-ansible-template/playbooks/elk-stack/single-installment` directory. Follow the instructions for the configuration of ELK stack.

## Task 1: VM Configuration

- Launch 6 VMs: 1 for Bastion Host, 3 for Elasticsearch, 1 for Logstash, 1 for Kibana

- Attach external volumes while launching Elasticsearch VMs.

- Connect to bastion host and clone the repository to it.

## Task 2: inventory.ini Configuration

- Open the `inventory.ini` and fill the below values with corresponding Private IPs of the VMs.

- Note that the `ip` value of the dev_downstream_rke2_master is the bastion host's private ip.

```ini
[dev_downstream_rke2_master]
dev-ds-m-01 ansible_host=<ip>

[elk-master]
elk1 ansible_host=<ip> node_name=es-1

[elk-node]
elk2 ansible_host=<ip> node_name=es-2
elk3 ansible_host=<ip> node_name=es-3

[elk-all:children]
elk-master
elk-node

[kibana]
kibana ansible_host=<ip>

[logstash]
logstash ansible_host=<ip>
```

- Fill the below values with corresponding values.

```ini
[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_private_key_file=<path-to-your-pem-file>
ansible_user=<name-of-VM-user>
seed_hosts=<private-ip-of-elk1>:9300,<private-ip-of-elk3>:9300,<private-ip-of-elk3>:9300
elastic_hosts=https://<private-ip-of-elk1>:9200,https://<private-ip-of-elk2>:9200,https://<private-ip-of-elk3>:9200
elk_cluster_name=<your-cluster-name>
initial_master_node=[<private-ip-of-elk1>]
elasticsearch_path=/mnt/data/elasticsearch
vm_disk_path=<external-volume-disk-path-in-VM>
filebeat_namespace=logging
```

- Be careful that you should only change the <...> parts and leave the rest as it is.

## Task 3: Running mount-disk.yaml

- Don't forget to change the value of partition name in `elk-ansible-template/roles/mount-disk/tasks/main.yaml` file. In the file, it is named as `/dev/nvme1n1p1` in lines 21, 32 and 40.

- Go to `elk-ansible-template` directory.

```bash
cd elk-ansible-template
```

- Run the playbook `playbooks/elk-stack/mount-disk.yaml`.

```bash
ansible-playbook playbooks/elk-stack/mount-disk.yaml
```

## Task 4: Modifications

- The line 74 in `elk-ansible-template/roles/elasticsearch-node/tasks/main.yml` is commented. Uncomment it after the first running of playbook.

- Change the `logstash_jvm_xmx` in the file `elk-ansible-template/roles/logstash/vars/main.yml`. You can consider `vm_ram_size/2`.

- Change the `index name` in the file `elk-ansible-template/roles/logstash/templates/elasticsearch-output.conf.j2`.

- Configure the file `elk-ansible-template/roles/filebeat/templates/filebeat-values.yaml.j2`.

- Change the private `logstash_ip` in the file `elk-ansible-template/roles/filebeat/vars/main.yaml`.

- Make sure that you have a k8s cluster and helm on the bastion host to configure Filebeat.

- Run the following commands to place `.kube/config` under `/root`.

```bash
mkdir -p /root/.kube
cp /home/ubuntu/.kube/config /root/.kube
kubectl get node --kubeconfig=/root/.kube/config
```

## Task 5: Running elk.yaml

- Go to `elk-ansible-template` directory.

```bash
cd elk-ansible-template/playbooks/
```

- Run the playbook `playbooks/elk-stack/elk.yaml`.

```bash
ansible-playbook playbooks/elk-stack/elk.yaml
```

- Note that there is folder `elk-stack/single-installment` which gives an option for installing the ELK components seperately.

## Acknowledgement

- We thank the authors for their valuable contributions. For further questions, support or advice, please contact Hepapi Devops Team.
