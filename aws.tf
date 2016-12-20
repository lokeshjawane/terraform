variable "access_key" {}
variable "secret_key" {}
variable "ansible_ssh_private_keyfile" {}
variable "instance_count" {}


provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "ap-south-1"
}

resource "aws_vpc" "myvpc" {
    cidr_block = "192.168.0.0/24"
    enable_dns_support=true
    enable_dns_hostnames=true
    tags {
      Name="myvpc"
    }
}

resource "aws_internet_gateway" "gw" {
    vpc_id = "${aws_vpc.myvpc.id}"

    tags {
        Name = "myvpc-gw"
    }
}


resource "aws_route_table" "r" {
    vpc_id = "${aws_vpc.myvpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gw.id}"
    }

    tags {
        Name = "main"
    }
}

resource "aws_subnet" "main" {
    vpc_id = "${aws_vpc.myvpc.id}"
    cidr_block = "192.168.0.64/26"
    map_public_ip_on_launch=true
  
    tags {
        Name = "myvpc-sbn1"
    }
}

resource "aws_route_table_association" "a" {
    subnet_id = "${aws_subnet.main.id}"
    route_table_id = "${aws_route_table.r.id}"
}

resource "aws_security_group" "default" {
    name = "VPC Security Group"
    description = "VPC Security Group"
    vpc_id = "${aws_vpc.myvpc.id}"

    tags {
        Name = "Sacle VPC Secutiry Group"
    }

    egress {
        from_port = 0
        to_port   = 65535
        protocol  = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0","49.248.198.248/32"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }


}

resource "null_resource" "cluster" {
      provisioner "local-exec" {
        command = "echo [master] > hosts"
    }
}

resource "aws_instance" "example" {
  count="${var.instance_count}"
  ami           = "ami-0155216e"
  instance_type = "t2.micro"
  key_name = "lokesh"
  subnet_id = "${aws_subnet.main.id}"
  vpc_security_group_ids = ["${aws_security_group.default.id}"]
  tags {
      Name = "${format("ec2-%02d", count.index+1)}"
  }
 
}

resource "null_resource" "configure-mesos-ips" {
  count = "${var.instance_count}"
    provisioner "local-exec" {
        command = "echo ${element(aws_instance.example.*.public_ip, count.index)} ansible_ssh_private_key_file=${var.ansible_ssh_private_keyfile} ansible_ssh_user=ubuntu >> hosts"
    }
}

resource "null_resource" "configure-wordpress" {
    provisioner "local-exec" {
        command = "sleep 60 && ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -i hosts site.yml --sudo"
    }
    depends_on = ["aws_instance.example"]
}

# LB setup
# Create a new load balancer
resource "aws_elb" "bar" {
  name = "foobar-terraform-elb"

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/index.html"
    interval = 30
  }

  security_groups = ["${aws_security_group.default.id}"]
  subnets = ["${aws_subnet.main.id}"]
  instances = ["${aws_instance.example.*.id}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
}