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

resource "aws_security_group_rule" "ingress_minecraft" {
  description       = "Allow traffic from external networks to minecraft port"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
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
