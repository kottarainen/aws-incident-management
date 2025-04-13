resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "deployer" {
  key_name   = "monitoring-key"
  public_key = tls_private_key.my_key.public_key_openssh
}

resource "aws_instance" "monitoring_instance" {
  ami             = "ami-03b3b5f65db7e5c6f"
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.ssh_access.name]

  tags = {
    Name = "MonitoringInstance"
  }
}

resource "aws_security_group" "ssh_access" {
  name        = "ssh_access"
  description = "Allow SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "private_key" {
  value     = tls_private_key.my_key.private_key_pem
  sensitive = true
}

resource "aws_security_group" "test_ssh_sg" {
  name        = "test_ssh_sg"
  description = "SG for testing public SSH"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TempTestSG"
  }
}
