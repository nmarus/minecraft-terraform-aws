resource "aws_security_group" "this" {
  name        = local.name
  description = local.name
  vpc_id      = aws_vpc.this.id

  tags = merge(local.default_tags, {
    Name = "${local.name}-sg"
  })
}

resource "aws_security_group_rule" "ingress_ssh" {
  description       = "Allow traffic from external networks to ssh port"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidrs
  type              = "ingress"
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "ingress_minecraft_tcp" {
  description       = "Allow traffic from external networks to minecraft port via TCP"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidrs
  type              = "ingress"
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "ingress_minecraft_tcp_v6" {
  description       = "Allow traffic from external networks to minecraft v6 port via TCP"
  from_port         = var.port_v6
  to_port           = var.port_v6
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidrs
  type              = "ingress"
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "ingress_minecraft_udp" {
  description       = "Allow traffic from external networks to minecraft port via UDP"
  from_port         = var.port
  to_port           = var.port
  protocol          = "udp"
  cidr_blocks       = var.allowed_cidrs
  type              = "ingress"
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "ingress_minecraft_udp_v6" {
  description       = "Allow traffic from external networks to minecraft v6 port via UDP"
  from_port         = var.port_v6
  to_port           = var.port_v6
  protocol          = "udp"
  cidr_blocks       = var.allowed_cidrs
  type              = "ingress"
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "egress_external" {
  description       = "Allow all external traffic"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "egress"
  security_group_id = aws_security_group.this.id
}
