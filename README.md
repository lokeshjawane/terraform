# Terraform Example
Here we will create simple infra with the two EC2 instances with ELB listening on port 80 & run ansible cokbook on EC2 instances.

### Steps
* Download the repo
* Create terraform variables file
```
access_key="<aws access key>"
secret_key="<aws access key>"
ansible_ssh_private_keyfile="<.pem file path>"
ansible_ssh_user="<ssh login user>"
```

* Ansible playbook main file already there: site.yml
```yaml
---
- name: Install WordPress, MySQL, Nginx, and PHP-FPM
  hosts: all
  tasks:
    - apt: name="nginx" update_cache=yes state=present
    - service: name=nginx enabled=yes state=started
```
* plan the terraform
```sh
terraform plan -var-file=./terraform.tfvars
```
* Apply changes to infra
```sh
terraform apply
```