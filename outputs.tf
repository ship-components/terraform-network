output "subnet_public01_id" {
  value = "${aws_subnet.public01.id}"
}

output "subnet_private01_id" {
  value = "${aws_subnet.private01.id}"
}

output "subnet_private02_id" {
  value = "${aws_subnet.private02.id}"
}

output "vpc_id" {
  description = "VPC ID"
  value = "${aws_vpc.this.id}"
}
