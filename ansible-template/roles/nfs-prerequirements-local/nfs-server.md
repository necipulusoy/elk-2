#### Nfs Server için Kubernetes cluster gereklilik kurulumu
  ```
    cd ~/ansible-template    ## ansible server dan yapılmalıdır
    ansible-playbook playbooks/nfs-playbook-nfs-server.yaml
  ```

  ```
ansible-template/roles/nfs-prerequirements-local/vars/main.yaml

ip_of_master_node: <master-node-ip> 
ip_of_worker_node: <worker-node-ip> 

bilgileri girilmelidir
  ```