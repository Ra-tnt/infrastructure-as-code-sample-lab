module "lab_labels" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = format("kh-lab-%s", var.name)
  environment = "lab"
  name        = format("DevOps-Bootcamp-%s", var.name)
  attributes  = ["public"]
  delimiter   = "_"

}

resource "aws_vpc" "lab" {
  cidr_block = "10.0.0.0/16"
  tags       = module.lab_labels.tags
}

resource "aws_internet_gateway" "lab_gateway" {
  vpc_id = aws_vpc.lab.id
  tags   = module.lab_labels.tags
}

resource "aws_route" "lab_internet_access" {
  route_table_id         = aws_vpc.lab.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lab_gateway.id
}

resource "aws_subnet" "lab_subnet" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags                    = module.lab_labels.tags
}

resource "aws_security_group" "lab_sg" {
  name        = format("%s_%s", var.name, "http_and_ssh")
  description = "Ingress on 22+80, +egress"
  vpc_id      = aws_vpc.lab.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [
    "10.0.0.0/16"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  tags = module.lab_labels.tags
}

resource "aws_elb" "lab_elb_web" {
  name = format("%selb", var.name)
  subnets = [
  aws_subnet.lab_subnet.id]
  security_groups = [
  aws_security_group.lab_sg.id]
  instances = aws_instance.lab_nodes.*.id

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  tags = module.lab_labels.tags
}

resource "aws_key_pair" "lab_keypair" {
  key_name   = format("%s%s", var.name, "_keypair")
  public_key = file(var.public_key_path)
}

data "aws_ami" "latest_agent" {
  most_recent = true
  owners      = ["772816346052"]

  filter {
    name   = "name"
    values = [format("%s-agent*", var.name)]
  }
}


data "aws_ami" "latest_server" {
  most_recent = true
  owners      = ["772816346052"]

  filter {
    name   = "name"
    values = [format("%s-server*", var.name)]
  }
}


resource "aws_instance" "agent" {
  count = 2

  instance_type          = "t3.xlarge"
  ami                    = data.aws_ami.latest_agent.id
  key_name               = aws_key_pair.lab_keypair.id
  vpc_security_group_ids = [aws_security_group.lab_sg.id]
  subnet_id              = aws_subnet.lab_subnet.id
  tags                   = module.lab_labels.tags
}
resource "aws_instance" "server" {
  count = 1

  instance_type          = "t3.xlarge"
  ami                    = data.aws_ami.latest_server.id
  key_name               = aws_key_pair.lab_keypair.id
  vpc_security_group_ids = [aws_security_group.lab_sg.id]
  subnet_id              = aws_subnet.lab_subnet.id
  tags                   = module.lab_labels.tags
}

