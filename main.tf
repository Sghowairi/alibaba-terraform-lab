# Configure the AliCloud Provider

provider "alicloud" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = "me-central-1"
}

variable "name" {
  default = "terraform-alicloud-project"
}

data "alicloud_zones" "default-project" {
  available_disk_category     = "cloud_efficiency"
  available_resource_creation = "VSwitch"
}


# Create a VPC:
resource "alicloud_vpc" "vpc-project" {
  vpc_name   = "vpc-project"
  cidr_block = "10.0.0.0/8"
}


# Create a Vswitch: 
 resource "alicloud_vswitch" "publicv-project" {
  vpc_id       = alicloud_vpc.vpc-project.id
  cidr_block   = "10.0.21.0/24"
  zone_id      = data.alicloud_zones.default-project.zones.0.id
  vswitch_name = "public-vswitch-project"
}


# Create Security Groups and Rules:
resource "alicloud_security_group" "project-SG" {
  name        = "project-SG"
  description = "http ssh allow"
  vpc_id      = alicloud_vpc.vpc-project.id
}

# ssh Rule 
resource "alicloud_security_group_rule" "allow_ssh_project" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = alicloud_security_group.project-SG.id
  cidr_ip           = "0.0.0.0/0"
}

# http Rule 
resource "alicloud_security_group_rule" "allow_http_projet" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "80/80"
  priority          = 1
  security_group_id = alicloud_security_group.project-SG.id
  cidr_ip           = "0.0.0.0/0"
}


# Create Key
resource "alicloud_ecs_key_pair" "keyproject" {
  key_pair_name = "key-project"
  key_file = "key-project.pem"
}


# Cret ECS 
resource "alicloud_instance" "project-ecs" {
  availability_zone = data.alicloud_zones.default-project.zones.0.id
  security_groups   = [alicloud_security_group.project-SG.id]

  # series III
  instance_type              = "ecs.g6.large"
  system_disk_category       = "cloud_essd"
  system_disk_name           = "shahad-project"
  system_disk_size           = 40
  system_disk_description    = "system_disk_description"
  image_id                   = "ubuntu_22_04_x64_20G_alibase_20240926.vhd"
  instance_name              = "project"
  vswitch_id                 = alicloud_vswitch.publicv-project.id
  internet_max_bandwidth_out = 100
  internet_charge_type       = "PayByTraffic"
  instance_charge_type       = "PostPaid"
  key_name                   = alicloud_ecs_key_pair.keyproject.key_pair_name
  user_data = base64encode(file("nginx.sh"))
}

output "ecs_ip" {
  value = alicloud_instance.project-ecs.public_ip
  
}
