# Network Setup

resource "aws_vpc" "this" {
  # Referencing the base_cidr_block variable allows the network address
  # to be changed without modifying the configuration.
  cidr_block = "${var.vpc_cidr_block}"

  # Turn on DNS hostnames for all instances
  enable_dns_hostnames = true

  tags = {
    Name = "app-${var.environment}-vpc"
    AppName = "app"
    Environment = "${var.environment}"
    Terraform = "yes"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = "${aws_vpc.this.id}"

  tags = {
    Name = "app-${var.environment}-gateway"
    AppName = "app"
    Environment = "${var.environment}"
    Terraform = "yes"
  }
}

resource "aws_subnet" "public01" {
  # How many
  count = 1

  # Where should we spin this up?
  availability_zone = "${var.availability_zone_one}"

  # By referencing the aws_vpc object, Terraform knows that the subnet
  # must be created only after the VPC is created.
  vpc_id = "${aws_vpc.this.id}"

  # Built-in functions and operators can be used for simple transformations of
  # values, such as computing a subnet address. Here we create a /20 prefix for
  # each subnet, using consecutive addresses for each availability zone,
  # such as 10.1.16.0/20 .
  cidr_block = "${cidrsubnet(aws_vpc.this.cidr_block, 8, 1)}"

  # Setup the the public gateway first
  depends_on = ["aws_internet_gateway.this"]

  map_public_ip_on_launch = true

  tags = {
    Name = "app-${var.environment}-public01"
    AppName = "app"
    Environment = "${var.environment}"
    Terraform = "yes"
  }
}

resource "aws_subnet" "private01" {
  # How Many
  count = 1

  # By referencing the aws_vpc object, Terraform knows that the subnet
  # must be created only after the VPC is created.
  vpc_id = "${aws_vpc.this.id}"

  # Where should we spin this up?
  availability_zone = "${var.availability_zone_one}"

  # Built-in functions and operators can be used for simple transformations of
  # values, such as computing a subnet address. Here we create a /20 prefix for
  # each subnet, using consecutive addresses for each availability zone,
  # such as 10.1.16.0/20 .
  cidr_block = "${cidrsubnet(aws_vpc.this.cidr_block, 8, 2)}"

  # Ensure the gateway is up first
  depends_on = ["aws_internet_gateway.this"]

  # Ensure we're not public
  map_public_ip_on_launch = false

  tags = {
    Name = "app-${var.environment}-private01"
    AppName = "app"
    Environment = "${var.environment}"
    Terraform = "yes"
  }
}

resource "aws_subnet" "private02" {
  # How Many
  count = 1

  # By referencing the aws_vpc object, Terraform knows that the subnet
  # must be created only after the VPC is created.
  vpc_id = "${aws_vpc.this.id}"

  # Built-in functions and operators can be used for simple transformations of
  # values, such as computing a subnet address. Here we create a /20 prefix for
  # each subnet, using consecutive addresses for each availability zone,
  # such as 10.1.16.0/20 .
  cidr_block = "${cidrsubnet(aws_vpc.this.cidr_block, 8, 3)}"

  # Which zone?
  availability_zone = "${var.availability_zone_two}"

  # Ensure the gateway is up first
  depends_on = ["aws_internet_gateway.this"]

  # Ensure we're not public
  map_public_ip_on_launch = false

  tags = {
    Name = "app-${var.environment}-private02"
    AppName = "app"
    Environment = "${var.environment}"
    Terraform = "yes"
  }
}

resource "aws_eip" "this" {
  # Which instance do we attach this to?
  instance = "${var.ingress_instance_id}"

  # Turn on VPC mode
  vpc = true

  # Ensure the gateway is up first
  depends_on = ["aws_internet_gateway.this"]

  tags = {
    Name = "app-${var.environment}-public-ip"
    AppName = "app"
    Environment = "${var.environment}"
    Terraform = "yes"
  }
}

resource "aws_eip" "consul" {
  # Which instance do we attach this to?
  instance = "${var.consul_instance_id}"

  # Turn on VPC mode
  vpc = true

  # Ensure the gateway is up first
  depends_on = ["aws_internet_gateway.this"]

  tags = {
    Name = "app-${var.environment}-public-consul-ip"
    AppName = "app"
    Environment = "${var.environment}"
    Terraform = "yes"
  }
}
resource "aws_eip" "nat" {
  # Turn on VPC mode
  vpc = true

  # Ensure the gateway is up first
  depends_on = ["aws_internet_gateway.this"]

  tags = {
    Name = "app-${var.environment}-eip-nat"
    AppName = "app"
    Environment = "${var.environment}"
    Terraform = "yes"
  }
}
resource "aws_nat_gateway" "this" {
  # Connect to our elastic ip
  allocation_id = "${aws_eip.nat.id}"

  # Connect to public subnet
  subnet_id = "${aws_subnet.public01.id}"

  # Wait for the internet gateway to be setup
  depends_on = ["aws_internet_gateway.this"]

  tags = {
    Name = "app-${var.environment}-nat"
    AppName = "app"
    Environment = "${var.environment}"
    Terraform = "yes"
  }
}


resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.this.id}"

  route {
    # Bind to all
    cidr_block = "0.0.0.0/0"

    # Attach to the internet gateway so we can reach this from the internet
    gateway_id = "${aws_internet_gateway.this.id}"
  }

  tags = {
    Name = "app-${var.environment}-route-public"
    AppName = "app"
    Environment = "${var.environment}"
    Terraform = "yes"
  }
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.this.id}"

  route {
    # Bind to all
    cidr_block = "0.0.0.0/0"

    # Bind to the NAT so we can connect to the internet but not receive requests
    nat_gateway_id = "${aws_nat_gateway.this.id}"
  }

  tags = {
    Name = "app-${var.environment}-route-private"
    AppName = "app"
    Environment = "${var.environment}"
    Terraform = "yes"
  }
}

resource "aws_route_table_association" "public01" {
  # Attach it to the public subnet
  subnet_id = "${aws_subnet.public01.id}"

  # Attach it to the public route
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "private01" {
  # Attach it to the private subnet
  subnet_id = "${aws_subnet.private01.id}"

  # Attach it to the private route
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "private02" {
  # Attach it to the private subnet
  subnet_id = "${aws_subnet.private02.id}"

  # Attach it to the private route
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_db_subnet_group" "this" {
  # Give it a friendly name
  name = "app-${var.environment}-db-subnet-group"

  # What is this?
  description = "Private Database Subnet"

  # We need at least two
  subnet_ids = [
    "${aws_subnet.private01.id}",
    "${aws_subnet.private02.id}"
  ]

  tags = {
    Name = "app-${var.environment}-web"
    AppName = "app"
    Environment = "${var.environment}"
    Terraform = "yes"
  }
}
