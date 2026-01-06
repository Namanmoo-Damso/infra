variable "instance_count" {
  description = "Number of instances"
  type        = number
}

variable "ami_id" {
  description = "AMI ID to use"
  type        = string
}

variable "instance_type" {
  description = "Type of instance"
  type        = string
}

variable "key_name" {
  description = "SSH Key Name"
  type        = string
}

variable "security_group_id" {
  description = "Security Group ID"
  type        = string
}

variable "tag_name" {
  description = "Name tag for the instance"
  type        = string
}

variable "volume_size" {
  description = "Size of volume"
  type        = number
}

resource "aws_instance" "this" {
  count         = var.instance_count
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]

  tags = {
    Name = "${var.tag_name}-${count.index + 1}"
  }

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }
}

resource "aws_eip" "this" {
  count    = var.instance_count
  instance = aws_instance.this[count.index].id
  tags = {
    Name = "${var.tag_name}-eip-${count.index + 1}"
  }
}

output "instance_ids" {
  description = "List of Instance IDs"
  value       = aws_instance.this[*].id
}

output "public_ips" {
  description = "Public IPs of the instances"
  value       = aws_eip.this[*].public_ip
}
