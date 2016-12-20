# Terraform Example
Here we will create simple infra with the two EC2 instances with ELB listening on port 80 & run ansible cokbook on EC2 instances.

### Steps
1. Download the repo
2. Create terraform variables file
```
access_key="<aws access key>"
secret_key="<aws access key>"
ansible_ssh_private_keyfile="<.pem file path>"
ansible_ssh_user="<ssh login user>"
```

3. Ansible playbook main file already there: site.yml
```yaml
---
- name: Install WordPress, MySQL, Nginx, and PHP-FPM
  hosts: all
  tasks:
    - apt: name="nginx" update_cache=yes state=present
    - service: name=nginx enabled=yes state=started
```
4. plan the terraform
```sh
terraform plan -var-file=./terraform.tfvars
```
5. Apply changes to infra
```sh
terraform apply
```