resource "aws_launch_template" "asg_template" {
  name_prefix   = "thesis-asg-template-"
  image_id      = "ami-03b3b5f65db7e5c6f"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name            = "ASGInstance"
      Environment     = "ThesisMonitoring"
      AutoRemediated  = "false"
    }
  }
}

resource "aws_autoscaling_group" "thesis_asg" {
  name                      = "thesis-auto-healing-asg"
  desired_capacity          = 1
  max_size                  = 1
  min_size                  = 1
  health_check_type         = "EC2"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.asg_template.id
    version = "$Latest"
  }

  vpc_zone_identifier = data.aws_subnets.default.ids

  tag {
    key                 = "Name"
    value               = "ASGMonitoredInstance"
    propagate_at_launch = true
  }

  tag {
    key                 = "AutoRemediated"
    value               = "false"
    propagate_at_launch = true
  }
}