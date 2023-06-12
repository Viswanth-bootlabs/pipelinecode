locals {
  common_tags = {
    "Project" = "Watermelon"
  }
  name = {
    "Name" = "Watermelon"
  }
  vpc_name = {
    Name = var.vpc_name
  }
  subnet = {
    Name = var.subnet2_cidir
  }
  ig = {
    Name = "My-internet-gateway"
  }
  route_table = {
    Name = "my-routing-table"
  }
  route_table_tag = merge(local.common_tags, local.route_table)
  ig_tag          = merge(local.common_tags, local.ig)
  subnet_tag      = merge(local.common_tags, local.subnet)
  ec2             = merge(local.common_tags, local.name)
  vpc             = merge(local.common_tags, local.vpc_name)
}
resource "aws_iam_role" "iam_role" {
  name = var.iam_name
  tags = local.common_tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "role_policy" {
  name = var.iam_policy_name
  role = aws_iam_role.iam_role.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "iam:*",
          "s3:*",
          "route53:*",
          "ec2:*",
          "elasticloadbalancing:*",
          "autoscaling:*"
        ],
        "Resource" : "*"
      }
    ]
  })
}



resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidir

  tags = local.vpc
}
resource "aws_route53_zone" "private_zone" {
  name = "${var.clustername}.k8s.local"
  vpc {
    vpc_id     = aws_vpc.my_vpc.id
    vpc_region = var.region
  }
  tags = local.common_tags
}

resource "aws_subnet" "second_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet2_cidir
  availability_zone = var.subnet_zone

  tags = local.subnet_tag
}
resource "aws_internet_gateway" "chaos-internet-gateway" {
  vpc_id = aws_vpc.my_vpc.id
  tags   = local.ig_tag
}
resource "aws_route_table" "chaos-rout-table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.chaos-internet-gateway.id
  }

  tags = local.route_table_tag
}
resource "aws_route_table_association" "chaos-association" {
  subnet_id      = aws_subnet.second_subnet.id
  route_table_id = aws_route_table.chaos-rout-table.id
}

resource "aws_security_group" "security_group" {
  name   = var.security_group_name
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = var.form_port
    to_port     = var.to_port
    protocol    = var.protocol
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = var.protocol
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = var.protocol
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "TLS from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = var.protocol
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "TLS from VPC"
    from_port   = 1024
    to_port     = 65535
    protocol    = var.protocol
    cidr_blocks = [aws_vpc.my_vpc.cidr_block]

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = local.common_tags

}


data "aws_ami" "ubuntu" {

  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "aws_ec2_instance_profile_wm_test"
  role = aws_iam_role.iam_role.name
  tags = local.common_tags
}
resource "aws_instance" "web-server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  key_name                    = aws_key_pair.generated_key.key_name
  subnet_id                   = aws_subnet.second_subnet.id
  vpc_security_group_ids      = [aws_security_group.security_group.id]
  monitoring                  = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  user_data                   = <<-EOL
    #!/bin/bash -xe
    sudo su 
    mkdir testing
    curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
    chmod +x ./kops
    mv ./kops /usr/local/bin/
    curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
    sudo apt-get update
    snap install aws-cli --classic

  EOL
  root_block_device {
    volume_size           = var.volume_size
    delete_on_termination = false
  }

  tags = local.ec2

  depends_on = [
    aws_subnet.second_subnet
  ]
}
resource "null_resource" "cluster" {
  connection {
    type        = "ssh"
    host        = aws_instance.web-server.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.private_key.private_key_pem
  }

  provisioner "file" {
    source      = "./kops-cluster.sh"
    destination = "/home/ubuntu/kops-cluster.sh"
  }
  provisioner "file" {
    source      = "./Deployment"
    destination = "/home/ubuntu/Deployment"
  }
  provisioner "remote-exec" {
    inline = [
      "export zone1=${var.zone}",
      "export bucket=${var.bucket_name}",
      "export clustername=${var.clustername}",
      "export node_count=${var.node_count}",
      "echo $bucket",
      "chmod +x kops-cluster.sh",
      "./kops-cluster.sh ",
      "kubectl apply -f Deployment"

    ]
  }
  depends_on = [
    aws_instance.web-server
  ]
}

resource "tls_private_key" "private_key" {
  algorithm = var.ec2_algorithm
  rsa_bits  = var.ec2_rsa_bits
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.private_key.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.private_key.private_key_pem}' > ./chaos-key.pem"
  }
}


resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "chaos-dasboard"

  dashboard_body = <<EOF
{ 
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 9,
            "height": 6,
            "properties": {
                "view": "bar",
                "stacked": false,
                "metrics": [
                    [ "AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", "Momo-Test-ASG1" ],
                    [ ".", "GroupMaxSize", ".", "." ],
                    [ ".", "GroupTotalCapacity", ".", "." ],
                    [ ".", "GroupTotalInstances", ".", "." ],
                    [ ".", "GroupInServiceInstances", ".", "." ]
                ],
                "region": "${var.region}",
                "title": "ASG1 statistics"
            }
        },
        {
            "type": "metric",
            "x": 9,
            "y": 0,
            "width": 9,
            "height": 6,
            "properties": {
                "view": "bar",
                "stacked": false,
                "metrics": [
                 [
                 "AWS/EC2",
                 "CPUUtilization",
                 "InstanceId",
                 "${aws_instance.web-server.id}"
                 ]
                ],
                "region": "${var.region}",
                "period": 300,
                "title": "ASG2 statistics"
            }
        },
        {
            "type": "explorer",
            "x": 0,
            "y": 6,
            "width": 24,
            "height": 15,
            "properties": {
                "metrics": [
                    {
                        "metricName": "CPUUtilization",
                        "resourceType": "AWS::EC2::Instance",
                        "stat": "Average"
                    },
                    {
                        "metricName": "NetworkIn",
                        "resourceType": "AWS::EC2::Instance",
                        "stat": "Average"
                    },
                    {
                        "metricName": "DiskReadOps",
                        "resourceType": "AWS::EC2::Instance",
                        "stat": "Average"
                    },
                    {
                        "metricName": "DiskWriteOps",
                        "resourceType": "AWS::EC2::Instance",
                        "stat": "Average"
                    },
                    {
                        "metricName": "NetworkOut",
                        "resourceType": "AWS::EC2::Instance",
                        "stat": "Average"
                    }
                ],
                "aggregateBy": {
                    "key": "*",
                    "func": "AVG"
                },
                "labels": [
                    {
                        "key": "aws:autoscaling:groupName",
                        "value": "Momo-Test-ASG1"
                    },
                    {
                        "key": "aws:autoscaling:groupName",
                        "value": "Momo-Test-ASG2"
                    }
                ],
                "widgetOptions": {
                    "legend": {
                        "position": "bottom"
                    },
                    "view": "timeSeries",
                    "stacked": false,
                    "rowsPerPage": 40,
                    "widgetsPerRow": 3
                },
                "period": 300,
                "splitBy": "",
                "title": "Average ASG1 and ASG2"
            }
        }
        
    ]
}
EOF
  depends_on = [
    aws_instance.web-server
  ]
}
