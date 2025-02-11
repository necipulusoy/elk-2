https://medium.com/@abdullah.pelit/ansible-ile-elk-stack-8-9-versiyon-kurulumu-7296a904d06f


1. ubuntu makineye ansible kurulumu

```bash
sudo apt update -y
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
```

2.  Ansible Yüklemesini Doğrulama

```bash
ansible --version
```

3. SSH Anahtarını mevcut makineye kopyalama

```bash
scp -i THIRDKEYPAIR.pem  THIRDKEYPAIR.pem ec2-user@<Conrtrol Node PUCLIC IP>:/home/ubuntu
<bağlanmak için key'i tanıtıyorum> <göndereceğim dosya>                  <göndereceğim yer> 

chmod 400 THIRDKEYPAIR.pem
```
Bu komut yerine direkt kendin de kopyalabilirsin.

4. Playbook_roles oluşturma

- ELK stack için 3 farklı role’e ihtiyaç duyuyoruz. Elasticsearch, Kibana ve Logstash. Bunlar için ayrı ayrı role oluşturmamız gerekiyor. Biz group_vars ve host_vars dosyalarını kullanmayacağız.

- group_vars içerisinde değişkenlerinizi tutabileceğiniz bir dosya oluşturabilirsiniz. Biz bu çalışmada değişkenlerimizi main.yaml içerisinde tanımlayacağız.

```bash
mkdir elk-ansible
cd elk-ansible
mkdir -p group_vars host_vars playbooks roles
touch ansible.cfg LICENSE README.md
```

Oluşturulan dosyanın yapısı

```text

elk-ansible/
├── ansible.cfg
├── LICENSE
├── README.md
├── group_vars/
├── host_vars/
├── playbooks/
└── roles/
```

5. Dosya yapımızı bu şekilde kurguladıktan sonra yukarıda belirlediğimiz 3 role için template oluşturuyoruz. Ansible bu tamplateleri oluşturmamız için bize bir komut sunuyor

```bash
cd roles
ansible-galaxy init elasticsearch
ansible-galaxy init kibana
ansible-galaxy init logstash
```

6. 
- komutlarını çalıştırarak rolelerimizi oluşturuyoruz. Oluşturulan templatelerin içerisinde “tasks” dosyasının içerisinde main.yml'da role.yaml’larımızı oluşturmaya başlayabiliriz.

- Öncelikle elasticsearch kurulumundan başlayacağız.Rolün içerisinde konfigure etmek ve kurulum yapmak için farklı yaml dosyaları oluşturacağız. ./roles/elasticsearch/tasks dosyasının içerisine “elasticsearch-install.yaml ve elasticsearch-configure.yaml” dosyaları oluşturuyoruz.

```bash
touch /home/ubuntu/elk-ansible/roles/elasticsearch/tasks/elasticsearch-install.yml
touch /home/ubuntu/elk-ansible/roles/elasticsearch/tasks/elasticsearch-configure.yml
```

7. Elasticsearch kurulumu için öncelikle sunucunun ihtiyaç duyduğu araçları indiriyoruz. Sonrasında elasticsearch kurulumu için gerekli komutları yazıyoruz. 


```bash
vi /home/ubuntu/elk-ansible/roles/elasticsearch/tasks/elasticsearch-install.yml
```

```yaml
- name: Install apt package requirements
  ansible.builtin.apt:
    name: "{{ item }}"
    state: present
    update_cache: yes
  with_items:
    - gpg-agent
    - curl
    - procps
    - net-tools
    - gnupg

- name: Install Elasticsearch
  block:
    - name: elasticsearch-install | Import Elasticsearch GPG Key
      ansible.builtin.shell: "curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg"

    - name: Add Elasticsearch APT Repository
      ansible.builtin.apt_repository:
        repo: "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main"
        state: present
        filename: "elastic-8.x.list"

    - name: Install Elasticsearch package
      ansible.builtin.apt:
        name: elasticsearch
        state: present
```

8. Gerekli kurulumu yaptıktan sonra elasticsearch için konfigurasyonu ayarlamamız gerekiyor. Öncelikle /etc/elasticsearch/elasticsearch.yml içerisindeki “network.host”,”http.port” ayarlarını güncellememiz ve elastic için bir şifre create etmemiz gerekiyor bunun için ./roles/elasticsearch/tasks içerisine elasticsearch-configure.yaml dosyamızı oluşturuyoruz.

```bash
vi /home/ubuntu/elk-ansible/roles/elasticsearch/tasks/elasticsearch-configure.yml
```

```yaml
- name: Update Elasticsearch Configuration File
  lineinfile:
    path: /etc/elasticsearch/elasticsearch.yml
    regexp: "{{ item.regexp }}"
    line: "{{ item.line }}"
  loop:
    - { regexp: '^network\.host:', line: 'network.host: {{ inventory_hostname }}' }
    - { regexp: '^http\.port:', line: 'http.port: {{ elasticsearch.http_port }}' }

- name: Enable and start Elasticsearch service
  service:
    name: elasticsearch
    state: started
    enabled: yes

- name: Run Elasticsearch Reset Password Command
  command: /usr/share/elasticsearch/bin/elasticsearch-reset-password auto -u elastic
  args:
    stdin: "y\n"
  register: reset_password_output

- name: Restart Elasticsearch service
  service:
    name: elasticsearch
    state: restarted
```

9. roles/elasticsearch/tasks/main.yml dosyasını oluşturun ve aşağıdaki içerikleri ekleyin: Böylece Oluşturduğumuz yaml dosyalarını çağırıyoruz

```bash
vi /home/ubuntu/elk-ansible/roles/elasticsearch/tasks/main.yml
```

```yaml
- include_tasks: elasticsearch-install.yml
- import_tasks: elasticsearch-configure.yml
```

- Elasticsearch kurulumunu ve konfigurasyonunu tamamlamış olduk.

## Kibana Kurulum

1. Kibana kurulumu ile devam ediyoruz. ./roles/kibana/tasks içerisine elasticsearchde olduğu gibi “kibana-install.yaml ve kibana-configure.yaml” dosyalarımızı oluşturuyoruz.

```bash
touch /home/ubuntu/elk-ansible/roles/kibana/tasks/kibana-install.yml
touch /home/ubuntu/elk-ansible/roles/kibana/tasks/kibana-configure.yml
```
- Kibana kurulumunda zaten elasticsearchte gerekli araçları kurduğumuz için direkt kurulum komutu ile kurulumu yapıyoruz.

```bash
vi /home/ubuntu/elk-ansible/roles/kibana/tasks/kibana-install.yml
```

```yaml
- name: Install Kibana
  block:
    - name: Import Kibana GPG Key
      ansible.builtin.shell: "curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg"

    - name: Add Kibana APT Repository
      ansible.builtin.apt_repository:
        repo: "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main"
        state: present
        filename: "elastic-8.x.list"

    - name: Install Kibana package
      ansible.builtin.apt:
        name: kibana
        state: present
```

2.  Bizim kurulumumuzda ssl entegrasyonu yapılmadan ilerlenmiştir. Eğer ssl’e ihtiyaç varsa ona göre konfigursayonları özelleştirebilirsiniz.

- /etc/kibana/kibana.yml içerisinde “server.port, server.host ve server.publicBaseUrl entegrasyonlarını yapıyoruz” bu entegrasyonlar için gerekli olan değişkenleri yine playbook main.yaml dosyamızın içerisinde geçiyor olacağız.

```bash
vi /home/ubuntu/elk-ansible/roles/kibana/tasks/kibana-configure.yml
```

```yaml
- name: Update Kibana Configuration File
  lineinfile:
    path: /etc/kibana/kibana.yml
    regexp: "{{ item.regexp }}"
    line: "{{ item.line }}"
  loop:
    - { regexp: '^server\.port:', line: 'server.port: {{ kibana.server_port }}' }
    - { regexp: '^server\.host:', line: 'server.host: {{ kibana.server_host }}' }
    - { regexp: '^server\.publicBaseUrl:', line: 'server.publicBaseUrl: {{ kibana.publicBaseUrl }}' }

- name: Run Kibana Enrollment Token Command
  shell: /usr/share/kibana/bin/kibana-setup --enrollment-token {{ enrollment_token }}
  args:
    stdin: "y\n"

- name: Enable and start Kibana service
  service:
    name: kibana
    state: started
    enabled: yes
```

3. Yine elasticserachte olduğu gibi oluşturduğumuz bu iki yaml dosyasını main.yaml içerisinde çağırıyoruz.

```bash
vi /home/ubuntu/elk-ansible/roles/kibana/tasks/main.yml
```

```yaml
- include_tasks: kibana-install.yml
- import_tasks: kibana-configure.yml
```

## Logstash Kurulum

1. Son rolümüz olan logstash kurulumuna geçebiliriz. ./roles/logstash/tasks dosyası içerisine diğer rollerde de olduğu gibi “logstash-install.yaml ve logstash-configure.yaml” dosyalarını oluşturuyoruz.

```bash
touch /home/ubuntu/elk-ansible/roles/logstash/tasks/logstash-install.yml
touch /home/ubuntu/elk-ansible/roles/logstash/tasks/logstash-configure.yml
```

2. Logstash kurulumu için “logstash-install.yaml” içerisinde dokumanı takip ederek gerekli komutları giriyoruz.

```bash
vi /home/ubuntu/elk-ansible/roles/logstash/tasks/logstash-install.yml
```

```yaml
- name: Install Logstash
  block:
    - name: Import Logstash GPG Key
      ansible.builtin.shell: "curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg"

    - name: Add Logstash APT Repository
      ansible.builtin.apt_repository:
        repo: "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main"
        state: present
        filename: "elastic-8.x.list"

    - name: Install Logstash package
      ansible.builtin.apt:
        name: logstash
        state: present
```
